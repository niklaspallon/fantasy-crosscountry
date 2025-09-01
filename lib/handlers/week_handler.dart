import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_fls/handlers/update_points.dart';
import '../providers/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_batch_helper.dart';

Future<void> incrementWeek(BuildContext context, String location,
    DateTime deadline, List<String> competitions) async {
  try {
    final db = FirebaseFirestore.instance;

    int currentWeek = await getCurrentWeek();
    int nextWeek = currentWeek + 1;

    print("🚀 Uppdaterar spelvecka från $currentWeek till $nextWeek...");

    // 🔹 Hämta provider via context
    await updateTeamsForNewWeek(nextWeek);

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

    if (!weekDoc.exists) {
      throw Exception("Dokumentet 'currentWeek' finns inte i gameData.");
    }

    if (!weekDoc.data().toString().contains("weekNumber")) {
      throw Exception("Fältet 'weekNumber' saknas i currentWeek-dokumentet.");
    }

    return weekDoc.get('weekNumber');
  } catch (e, stack) {
    print("❌ Fel vid hämtning av aktuell spelvecka: $e");
    print("📌 Stacktrace: $stack");
    rethrow; // kasta vidare felet istället för att returnera 1
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
  Stopwatch stopwatch = Stopwatch()..start();
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();
    int previousWeek = nextWeek - 1;

    print(
        "🔄 Updating teams for new game week: $nextWeek (current: $currentWeek)...");

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();

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

        return weekDoc;
      }),
    );

    List<BatchOperation> operations = [];

    for (int i = 0; i < teamsSnapshot.docs.length; i++) {
      var teamDoc = teamsSnapshot.docs[i];
      String teamId = teamDoc.id;

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
      operations.add((batch) {
        batch.update(db.collection('teams').doc(teamId), {
          'freeTransfers': updatedFreeTransfers,
          'unlimitedTransfers': false,
        });
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
      operations.add((batch) {
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
      });
    }

    // Commit alla batch-uppdateringar
    await commitInBatches(db, operations);
    print("🎉 Alla lag uppdaterades till vecka $nextWeek!");
    await updateSkierPrices(nextWeek);
    await syncSkierPointsToWeeklyTeams(nextWeek);
    await syncMarketPricesToWeeklyTeams(nextWeek);

    // Uppdatera även provider
    print("updateTeamsForNewWeek tog ${stopwatch.elapsedMilliseconds} ms");
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

Future<List<String>> updateSkierPrices(int nextweek) async {
  Stopwatch stopwatch = Stopwatch()..start();
  if (_isUpdatingPrices) return [];
  _isUpdatingPrices = true;
  int previousWeek = nextweek - 1;
  List<String> activityLog = []; // 🔹 Samlar all aktivitet

  try {
    print("🔄 Startar prisuppdatering för skidåkare...");
    FirebaseFirestore db = FirebaseFirestore.instance;
    final skierSnapshot = await db.collection('SkiersDb').get();

    List<BatchOperation> operations = [];

    for (final doc in skierSnapshot.docs) {
      final skier = doc.data();
      final docRef = doc.reference;
      final skierName = skier['name'] ?? doc.id;

      final dynamic priceRaw = skier['price'];
      final double price = (priceRaw is num)
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw.toString()) ?? 5.0;

      final weeklyResultsSnapshot = await db
          .collection('SkiersDb')
          .doc(doc.id)
          .collection('weeklyResults')
          .doc("week$previousWeek")
          .get();

      if (!weeklyResultsSnapshot.exists) {
        continue;
      }

      final List<dynamic> placementsRaw = skier['recentPlacements'] ?? [];

      if (placementsRaw.isEmpty) {
        continue;
      }

      final List<int> placements =
          placementsRaw.map((p) => int.tryParse(p.toString()) ?? 50).toList();

      final double avgPlacement =
          placements.reduce((a, b) => a + b) / placements.length;

      final double expected = 1 + ((30 - price) / 15) * 29;
      final double delta = expected - avgPlacement;

      double rawChange = (delta / expected) * 75000;
      final double roundedChange = (rawChange / 100000).round() * 100000;

      activityLog.add(
          "$skierName: förväntat plac=$expected, faktisk plac=$avgPlacement, "
          "avrundad=$roundedChange");

      if (roundedChange.abs() < 100000) {
        continue;
      }

      final double limitedChange = roundedChange.clamp(-100000, 100000);

      if (limitedChange != roundedChange) {
        activityLog
            .add("⚠️ $skierName: Ändring begränsad till $limitedChange.");
      }

      final double newPriceRaw =
          ((price * 1000000) + limitedChange).clamp(5000000, 34000000);

      final double newPriceDownRounded =
          (newPriceRaw / 1000000 * 10).floor() / 10;

      activityLog
          .add("✅ $skierName: pris ändrat $price → $newPriceDownRounded M.");

      operations.add((batch) {
        batch.update(docRef, {
          "price": newPriceDownRounded,
        });
      });
    }

    await commitInBatches(db, operations);

    // 📌 Spara loggen i Firestore
    await db.collection("priceUpdateLogs").add({
      "timestamp": FieldValue.serverTimestamp(),
      "week": previousWeek,
      "entries": activityLog,
    });

    print("📑 Sammanfattning av ändrade priser:");
    activityLog.forEach(print);

    print('✅ Prisuppdatering slutförd.');
    print("⏱ updateSkierPrices tog ${stopwatch.elapsedMilliseconds} ms");
  } catch (e) {
    print('❌ Fel under prisuppdatering: $e');
  } finally {
    _isUpdatingPrices = false;
  }
  return activityLog;
}

Future<void> syncMarketPricesToWeeklyTeams(nextWeek) async {
  Stopwatch stopwatch = Stopwatch()..start();
  FirebaseFirestore db = FirebaseFirestore.instance;

  try {
    final skiersSnapshot = await db.collection('SkiersDb').get();
    final skierPrices = <String, double>{};

    for (var skierDoc in skiersSnapshot.docs) {
      final data = skierDoc.data();
      final price = (data['price'] is num) ? data['price'].toDouble() : 0.0;
      skierPrices[skierDoc.id] = price;
    }

    final teamsSnapshot = await db.collection('teams').get();

    List<BatchOperation> operations = [];

    for (final teamDoc in teamsSnapshot.docs) {
      final weekDocRef =
          teamDoc.reference.collection('weeklyTeams').doc("week$nextWeek");

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
        operations.add((batch) {
          batch.update(weekDocRef, {'skiers': skiers});
        });
      }
    }

    // 🔹 4. Commit i batchar om >500 operationer
    await commitInBatches(db, operations);

    print(
        "🎯 Klart: Alla weeklyTeams för vecka $nextWeek har fått marketPrice synkade.");
    print(
        "syncMarketPricesToWeeklyTeams tog  ${stopwatch.elapsedMilliseconds} ms");
  } catch (e) {
    print("❌ Fel vid marketPrice-synk: $e");
  }
}
