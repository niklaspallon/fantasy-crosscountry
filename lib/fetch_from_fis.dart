import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'week_handler.dart';

/// 🔹 Funktion för att hämta resultat & uppdatera poäng från FIS
Future<void> fetchAndSetCompetitionPoints(
    String compName, String compURL) async {
  final response = await http.get(Uri.parse(compURL));

  if (response.statusCode == 200) {
    final document = parser.parse(response.body);
    final rows = document.querySelectorAll('a.table-row');

    Map<String, int> skierPointsByName = {};
    int placement = 1;

    for (var row in rows) {
      final nameElement = row.querySelector('.athlete-name');
      if (nameElement != null) {
        final name = nameElement.text.trim();
        int points = getPoints(placement);
        skierPointsByName[name] = points;
        placement++;
      }
    }

    if (skierPointsByName.isNotEmpty) {
      await addPointsFromCompToWeeklySkierPoints(compName, skierPointsByName);
      print("✅ fetchAndSetCompetitionPoints slutförd!");
    } else {
      print("⚠️ Inga resultat hittades.");
    }
  } else {
    print('❌ Kunde inte hämta data från FIS-ski.');
  }
}

Future<void> addPointsFromCompToWeeklySkierPoints(
    String competitionId, Map<String, int> skierPointsByName) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot skiersSnapshot = await db.collection('SkiersDb').get();
    Map<String, String> skierNameToId = {
      for (var doc in skiersSnapshot.docs)
        if (doc.data().toString().contains('name'))
          (doc.get('name') as String): doc.id
    };

    Map<String, int> validSkiers = {};
    for (var entry in skierPointsByName.entries) {
      if (skierNameToId.containsKey(entry.key)) {
        validSkiers[entry.key] = entry.value;
      }
    }

    WriteBatch skierBatch = db.batch();

    for (var entry in validSkiers.entries) {
      final skierName = entry.key;
      final skierId = skierNameToId[skierName]!;
      final points = entry.value;

      final weekRef = db
          .collection('SkiersDb')
          .doc(skierId)
          .collection('weeklyResults')
          .doc("week$currentWeek");

      final weekSnap = await weekRef.get();
      Map<String, dynamic> data =
          weekSnap.exists ? (weekSnap.data() as Map<String, dynamic>) : {};

      Map<String, dynamic> competitions =
          Map<String, dynamic>.from(data['competitions'] ?? {});
      List<dynamic> counted =
          List<dynamic>.from(data['countedCompetitions'] ?? []);
      int currentTotal = data['totalWeeklyPoints'] ?? 0;

      if (counted.contains(competitionId)) {
        print(
            "⏩ Tävlingen $competitionId har redan lagts till för $skierName ($skierId)");
        continue;
      }

      competitions[competitionId] = points;
      counted.add(competitionId);
      int newTotal = currentTotal + points;

      skierBatch.set(
          weekRef,
          {
            'competitions': competitions,
            'countedCompetitions': counted,
            'totalWeeklyPoints': newTotal,
          },
          SetOptions(merge: true));
    }

    await skierBatch.commit();
    print("✅ addPointsFromCompToWeeklySkierPoints slutförd!");

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    for (var teamDoc in teamsSnapshot.docs) {
      DocumentReference weeklyRef = db
          .collection('teams')
          .doc(teamDoc.id)
          .collection('weeklyTeams')
          .doc("week$currentWeek");

      DocumentSnapshot weekSnap = await weeklyRef.get();
      if (!weekSnap.exists) continue;

      Map<String, dynamic> weekData = weekSnap.data() as Map<String, dynamic>;
      List<dynamic> skiers = List.from(weekData['skiers'] ?? []);

      bool updated = false;

      for (var skier in skiers) {
        String name = skier['name'];
        if (validSkiers.containsKey(name)) {
          skier['totalWeeklyPoints'] =
              (skier['totalWeeklyPoints'] ?? 0) + validSkiers[name]!;
          updated = true;
        }
      }

      if (updated) {
        await weeklyRef.update({'skiers': skiers});
        print("🔁 weeklyTeams uppdaterade för ${teamDoc.id}");
      }
    }
  } catch (e) {
    print("❌ Fel i addPointsFromCompToWeeklySkierPoints: $e");
  }
}

Future<void> undoCompetitionPoints(String competitionId) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot skiersSnapshot = await db.collection('SkiersDb').get();
    List<Future<DocumentSnapshot>> weekDocsFutures = skiersSnapshot.docs
        .map(
          (skierDoc) => db
              .collection('SkiersDb')
              .doc(skierDoc.id)
              .collection('weeklyResults')
              .doc("week$currentWeek")
              .get(),
        )
        .toList();

    List<DocumentSnapshot> weekDocs = await Future.wait(weekDocsFutures);
    WriteBatch skierBatch = db.batch();

    for (int i = 0; i < skiersSnapshot.docs.length; i++) {
      String skierId = skiersSnapshot.docs[i].id;
      DocumentSnapshot weekDoc = weekDocs[i];

      if (!weekDoc.exists || weekDoc.data() == null) continue;

      Map<String, dynamic> data = weekDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> competitions =
          Map<String, dynamic>.from(data['competitions'] ?? {});
      List<dynamic> counted =
          List<dynamic>.from(data['countedCompetitions'] ?? []);

      if (competitions.containsKey(competitionId)) {
        competitions.remove(competitionId);
        counted.remove(competitionId);
        int newTotal = competitions.values.fold(0, (a, b) => a + (b as int));

        skierBatch.update(weekDoc.reference, {
          'competitions': competitions,
          'countedCompetitions': counted,
          'totalWeeklyPoints': newTotal,
        });
      }
    }

    await skierBatch.commit();
    print("✅ undoCompetitionPoints (SkiersDb) slutförd!");

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    for (var teamDoc in teamsSnapshot.docs) {
      DocumentReference weeklyRef = db
          .collection('teams')
          .doc(teamDoc.id)
          .collection('weeklyTeams')
          .doc("week$currentWeek");

      DocumentSnapshot weekSnap = await weeklyRef.get();
      if (!weekSnap.exists) continue;

      Map<String, dynamic> weekData = weekSnap.data() as Map<String, dynamic>;
      List<dynamic> skiers = List.from(weekData['skiers'] ?? []);
      bool updated = false;

      for (var skier in skiers) {
        Map<String, dynamic> competitions =
            Map<String, dynamic>.from(skier['competitions'] ?? {});
        if (competitions.containsKey(competitionId)) {
          competitions.remove(competitionId);
          skier['competitions'] = competitions;
          skier['totalWeeklyPoints'] =
              competitions.values.fold(0, (a, b) => a + (b as int));
          updated = true;
        }
      }

      if (updated) {
        await weeklyRef.update({'skiers': skiers});
        print("🔁 weeklyTeams uppdaterade efter ångring: ${teamDoc.id}");
      }
    }
  } catch (e) {
    print("❌ Fel vid ångring av tävlingspoäng: $e");
  }
}

int getPoints(int placement) {
  if (placement == 1) return 100;
  if (placement == 2) return 80;
  if (placement == 3) return 60;
  if (placement == 4) return 50;
  if (placement == 5) return 45;
  if (placement == 6) return 40;
  if (placement == 7) return 35;
  if (placement == 8) return 30;
  if (placement == 9) return 25;
  if (placement == 10) return 20;
  if (placement >= 11 && placement <= 30) return 30 - placement + 1;
  return 0;
}
