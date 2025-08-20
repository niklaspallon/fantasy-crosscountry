import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_fls/handlers/updatePoints.dart';
import '../providers/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> incrementWeek(BuildContext context, String location,
    DateTime deadline, List<String> competitions) async {
  try {
    final db = FirebaseFirestore.instance;

    int currentWeek = await getCurrentWeek();
    int nextWeek = currentWeek + 1;

    print("🚀 Uppdaterar spelvecka från $currentWeek till $nextWeek...");

    // 🔹 Hämta provider via context
    updateTeamsForNewWeek(nextWeek);

    // Hämta nuvarande veckodata
    final currentWeekDoc =
        await db.collection('gameData').doc('currentWeek').get();
    if (currentWeekDoc.exists) {
      // Spara undan nuvarande vecka som weekX
      final data = currentWeekDoc.data();
      if (data != null) {
        await db.collection('gameData').doc('week$currentWeek').set(data);
        print("📦 Sparade vecka $currentWeek som week$currentWeek");
      }
    }

    // Uppdatera currentWeek till nästa vecka
    await db.collection('gameData').doc('currentWeek').set({
      'weekNumber': nextWeek,
      'location': location,
      'deadline': Timestamp.fromDate(deadline),
      'competitions': competitions
    });

    print(
      "✅ Vecka $nextWeek skapad med plats: $location, deadline: $deadline och tävlingar: $competitions",
    );
  } catch (e) {
    print("❌ Fel vid uppdatering av spelvecka: $e");
  }
}

// 🔹 Hämta aktuell spelvecka
Future<int> getCurrentWeek() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot weekDoc =
        await db.collection('gameData').doc('currentWeek').get();
    return weekDoc.exists ? (weekDoc.get('weekNumber') ?? 1) : 1;
  } catch (e) {
    print("❌ Fel vid hämtning av aktuell spelvecka: $e");
    return 1;
  }
}

Future<DateTime?> getCurrentDeadline() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot weekDoc =
        await db.collection('gameData').doc('currentWeek').get();

    if (weekDoc.exists && weekDoc.data().toString().contains("deadline")) {
      Timestamp timestamp = weekDoc.get('deadline');
      return timestamp.toDate();
    }

    return null;
  } catch (e) {
    print("❌ Fel vid hämtning av deadline: $e");
    return null;
  }
}

Future<void> updateTeamsForNewWeek(int nextWeek) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();
    int previousWeek = nextWeek - 1;

    print(
        "🔄 Updating teams for new game week: $nextWeek (current: $currentWeek)...");

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    WriteBatch batch = db.batch();

    print("📋 Totalt antal lag: ${teamsSnapshot.docs.length}");

    // Hämta alla tidigare veckodokument för alla lag samtidigt
    List<DocumentSnapshot> previousWeekDocs = await Future.wait(
      teamsSnapshot.docs.map((teamDoc) async {
        String teamId = teamDoc.id;
        DocumentSnapshot weekDoc = await db
            .collection('teams')
            .doc(teamId)
            .collection('weeklyTeams')
            .doc("week$previousWeek")
            .get();

        print(
            "📄 Hämtade week$previousWeek för team $teamId – exists: ${weekDoc.exists}");
        return weekDoc;
      }),
    );

    for (int i = 0; i < teamsSnapshot.docs.length; i++) {
      var teamDoc = teamsSnapshot.docs[i];
      String teamId = teamDoc.id;

      print("⚙️ Bearbetar lag $teamId...");

      // Hämta nuvarande antal freeTransfers
      int currentFreeTransfers = 0;
      try {
        currentFreeTransfers = teamDoc.get('freeTransfers') ?? 0;
      } catch (e) {
        print(
            "⚠️ Kunde inte läsa freeTransfers för team $teamId, defaultar till 0.");
      }

      int maxFreeTransfers = 5;
      int updatedFreeTransfers = currentFreeTransfers + 1;
      updatedFreeTransfers = updatedFreeTransfers > maxFreeTransfers
          ? maxFreeTransfers
          : updatedFreeTransfers;

      print(
          "🔁 Uppdaterar freeTransfers för $teamId: $currentFreeTransfers ➜ $updatedFreeTransfers");
      batch.update(db.collection('teams').doc(teamId), {
        'freeTransfers': updatedFreeTransfers,
        'unlimitedTransfers': false,
      });

      // Hämta förra veckans laguppställning
      DocumentSnapshot previousWeekDoc = previousWeekDocs[i];
      List<dynamic> previousSkiers = [];
      String previousCaptain = "";

      if (previousWeekDoc.exists) {
        final data = previousWeekDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          final rawSkiers = data['skiers'];
          if (rawSkiers is List) {
            previousSkiers = rawSkiers.map((e) {
              if (e is Map) {
                return Map<String, dynamic>.from(e);
              } else {
                print("⚠️ Ogiltigt åkarelement i team $teamId: $e");
                return <String, dynamic>{};
              }
            }).toList();
          } else {
            print("⚠️ 'skiers' är inte en lista i team $teamId");
          }

          previousCaptain = data['captain'] ?? "";
        } else {
          print("⚠️ previousWeekDoc saknar data för team $teamId");
        }
      } else {
        print(
            "⚠️ Ingen föregående veckodata för team $teamId (week$previousWeek)");
      }

      print(
          "📦 Team $teamId – föregående åkare: ${previousSkiers.length}, kapten: $previousCaptain");

      // Uppdatera laget för nästa vecka
      batch.set(
        db
            .collection('teams')
            .doc(teamId)
            .collection('weeklyTeams')
            .doc("week$nextWeek"),
        {
          'weekNumber': nextWeek,
          'skiers': previousSkiers,
          'weeklyPoints': 0,
          'captain': previousCaptain,
        },
        SetOptions(merge: true),
      );

      print("✅ Team $teamId copied over to week $nextWeek!");
    }

    // Commit alla batch-uppdateringar
    await batch.commit();
    print("🎉 Alla lag uppdaterades till vecka $nextWeek!");
    await updateSkierPrices(); // Uppdatera priser efter att alla lag har uppdaterats
    await syncSkierPointsToWeeklyTeams(); //för att inte poängen från förra veaken ska ligga kvar i ui och i weeklyteams
    await syncMarketPricesToWeeklyTeams();
  } catch (e, stacktrace) {
    print("❌ Fel vid uppdatering av lag för ny vecka: $e");
    print(stacktrace);
  }
}

Future<List<String>> fetchUpcomingEvents() async {
  try {
    final db = FirebaseFirestore.instance;

    final eventsSnapshot =
        await db.collection('gameData').doc('currentWeek').get();

    if (eventsSnapshot.exists) {
      final competitions = eventsSnapshot.get('competitions');
      if (competitions != null) {
        // Convert List<dynamic> to List<String>
        return List<String>.from(competitions);
      }
      return [];
    }
    return [];
  } catch (e) {
    print("❌ Error fetching upcoming events: $e");
    return [];
  }
}

bool _isUpdatingPrices = false;

Future<void> updateSkierPrices() async {
  if (_isUpdatingPrices) return;
  _isUpdatingPrices = true;

  try {
    print("🔄 Startar prisuppdatering för skidåkare...");
    FirebaseFirestore db = FirebaseFirestore.instance;
    WriteBatch batch = db.batch();
    final skierSnapshot = await db.collection('SkiersDb').get();

    int writes = 0;
    List<String> updatedPricesLog = [];

    for (final doc in skierSnapshot.docs) {
      final skier = doc.data();
      final docRef = doc.reference;

      final dynamic priceRaw = skier['price'];
      final double price = (priceRaw is num)
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw.toString()) ?? 5.0;

      final List<dynamic> placementsRaw = skier['recentPlacements'] ?? [];
      if (placementsRaw.isEmpty) continue;

      final List<int> placements =
          placementsRaw.map((p) => int.tryParse(p.toString()) ?? 50).toList();

      final double avgPlacement =
          placements.reduce((a, b) => a + b) / placements.length;

      // ✅ Justerad skala: 5M = plac 30, 20M = plac 1
      final double expected = 1 + ((30 - price) / 15) * 29;
      final double delta = expected - avgPlacement;

      // Här bestäms hur mycket som krävs för att ändra priset
      double rawChange = (delta / expected) * 75000;

      // 🔁 Avrunda till närmaste 100k
      rawChange = (rawChange / 100000).round() * 100000;

      // ⛔ Hoppa om mindre än 100k i skillnad
      if (rawChange.abs() < 100000) continue;

      // ⛔ Begränsa till max ±200k
      rawChange = rawChange.clamp(-100000, 100000);

      // ✅ Räkna ut nytt pris, minst 5000000 och max 20000000
      final double newPriceRaw =
          ((price * 1000000) + rawChange).clamp(5000000, 30000000);

      // 🔻 Avrunda nedåt till 0.1 M
      final double newPriceDownRounded =
          (newPriceRaw / 1000000 * 10).floor() / 10;

      // Logga ändringen
      final skierName = skier['name'] ?? doc.id;
      updatedPricesLog.add("$skierName: $price → $newPriceDownRounded");

      batch.update(docRef, {
        "price": newPriceDownRounded,
      });

      writes++;

      if (writes % 450 == 0) {
        await batch.commit();
        print("✅ Commit efter $writes uppdateringar");
        // Skriv ut loggar för denna batch
        updatedPricesLog.forEach(print);
        updatedPricesLog.clear();
        batch = db.batch();
      }
    }

    if (writes % 450 != 0) {
      await batch.commit();
      print("✅ Sista commit ($writes uppdateringar totalt)");
      updatedPricesLog.forEach(print);
    }

    print('✅ Prisuppdatering slutförd.');
  } catch (e) {
    print('❌ Fel under prisuppdatering: $e');
  } finally {
    _isUpdatingPrices = false;
  }
}

Future<void> syncMarketPricesToWeeklyTeams() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  int currentWeek = await getCurrentWeek();

  try {
    final skiersSnapshot = await db.collection('SkiersDb').get();
    final skierPrices = <String, double>{};

    for (var skierDoc in skiersSnapshot.docs) {
      final data = skierDoc.data();
      final price = (data['price'] is num) ? data['price'].toDouble() : 0.0;
      skierPrices[skierDoc.id] = price;
    }

    final teamsSnapshot = await db.collection('teams').get();

    WriteBatch batch = db.batch();
    int writes = 0;

    for (final teamDoc in teamsSnapshot.docs) {
      final weekDocRef =
          teamDoc.reference.collection('weeklyTeams').doc("week$currentWeek");

      final weekDoc = await weekDocRef.get();
      if (!weekDoc.exists) continue;

      final data = weekDoc.data()!;
      List<dynamic> skiers = List.from(data['skiers'] ?? []);
      bool needsUpdate = false;

      for (var skier in skiers) {
        final skierId = skier['skierId'];
        if (skierPrices.containsKey(skierId)) {
          final double currentMarketPrice = skierPrices[skierId]!;
          if (skier['marketPrice'] != currentMarketPrice) {
            skier['marketPrice'] = currentMarketPrice;
            needsUpdate = true;
          }
        }
      }

      if (needsUpdate) {
        batch.update(weekDocRef, {'skiers': skiers});
        writes++;

        if (writes >= 450) {
          await batch.commit();
          print("✅ Commit på $writes skrivningar");
          batch = db.batch();
          writes = 0;
        }
      }
    }

    if (writes > 0) {
      await batch.commit();
      print("✅ Sista commit ($writes skrivningar)");
    }

    print(
        "🎯 Klart: Alla weeklyTeams för vecka $currentWeek har fått marketPrice synkade.");
  } catch (e) {
    print("❌ Fel vid marketPrice-synk: $e");
  }
}
