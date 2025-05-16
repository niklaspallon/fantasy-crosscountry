import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_handler.dart';

Future<void> updateAllSkiersTotalPoints() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot skiersSnapshot = await db.collection('SkiersDb').get();
    if (skiersSnapshot.docs.isEmpty) {
      print("❌ Inga skidåkare hittades.");
      return;
    }

    WriteBatch batch = db.batch();

    for (var skierDoc in skiersSnapshot.docs) {
      String skierId = skierDoc.id;

      DocumentReference weekRef = db
          .collection('SkiersDb')
          .doc(skierId)
          .collection('weeklyResults')
          .doc("week$currentWeek");

      DocumentSnapshot weekDoc = await weekRef.get();
      if (!weekDoc.exists) continue;

      Map<String, dynamic> weekData = weekDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> competitions =
          Map<String, dynamic>.from(weekData['competitions'] ?? {});
      List<dynamic> alreadyCounted =
          List<dynamic>.from(weekData['countedInTotal'] ?? []);

      int newPoints = 0;
      List<String> newlyCounted = [];

      for (var entry in competitions.entries) {
        String compId = entry.key;
        int points = entry.value is int ? entry.value : 0;

        if (!alreadyCounted.contains(compId)) {
          newPoints += points;
          newlyCounted.add(compId);
        }
      }

      if (newPoints > 0) {
        print("✅ $skierId +$newPoints poäng (nya tävlingar: $newlyCounted)");

        // 🔹 Lägg till poäng till totalPoints
        batch.update(
          db.collection('SkiersDb').doc(skierId),
          {'totalPoints': FieldValue.increment(newPoints)},
        );

        // 🔹 Uppdatera countedInTotal för denna vecka
        batch.update(
          weekRef,
          {
            'countedInTotal': FieldValue.arrayUnion(newlyCounted),
          },
        );
      } else {
        print("⏭ $skierId – inga nya poäng att räkna in.");
      }
    }

    await batch.commit();
    print("🎉 Skidåkarnas totalpoäng uppdaterades (vecka $currentWeek)!");
  } catch (e) {
    print("❌ Fel vid uppdatering av totalpoäng: $e");
  }
}

Future<void> updateAllTeamsTotalPoints() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    if (teamsSnapshot.docs.isEmpty) {
      print("❌ Inga lag hittades.");
      return;
    }

    WriteBatch batch = db.batch();

    for (var teamDoc in teamsSnapshot.docs) {
      String teamId = teamDoc.id;

      DocumentSnapshot weeklyTeamDoc = await db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$currentWeek")
          .get();

      if (!weeklyTeamDoc.exists) {
        print("⚠️ Laget $teamId har inget registrerat för vecka $currentWeek.");
        continue;
      }

      Map<String, dynamic> weekData =
          weeklyTeamDoc.data() as Map<String, dynamic>;
      List<dynamic> skierList = weekData['skiers'] ?? [];
      String? captainId = weekData['captain']?.toString().trim();

      if (skierList.isEmpty) {
        print("⚠️ Laget $teamId har inga åkare vecka $currentWeek.");
        continue;
      }

      int teamWeekPoints = 0;
      bool captainFound = false;

      for (var skier in skierList) {
        if (skier is Map<String, dynamic>) {
          String skierId = skier['skierId'] ?? '';
          int points = skier['totalWeeklyPoints'] ?? 0;

          if (skierId == captainId) {
            points *= 2;
            captainFound = true;
            print("👑 Kapten $skierId får dubbla poäng: $points");
          }

          print("🔹 Åkare $skierId ger $points poäng.");
          teamWeekPoints += points;
        }
      }

      if (captainId != null && !captainFound) {
        print("⚠️ Kapten $captainId fanns inte i veckolistan för lag $teamId");
      }

      if (teamWeekPoints > 0) {
        print("✅ Lag $teamId får $teamWeekPoints poäng till totalen.");
        batch.update(db.collection('teams').doc(teamId), {
          'totalPoints': FieldValue.increment(teamWeekPoints),
        });
      } else {
        print("⚠️ Lag $teamId får inga poäng denna vecka.");
      }
    }

    await batch.commit();
    print("🎉 Alla lags totalpoäng har uppdaterats för vecka $currentWeek!");
  } catch (e) {
    print("❌ Fel vid uppdatering av alla lags totalpoäng: $e");
  }
}

Future<void> undoAllTeamsTotalPoints() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    if (teamsSnapshot.docs.isEmpty) {
      print("❌ Inga lag hittades.");
      return;
    }

    WriteBatch batch = db.batch();

    for (var teamDoc in teamsSnapshot.docs) {
      String teamId = teamDoc.id;

      DocumentSnapshot weeklyTeamDoc = await db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$currentWeek")
          .get();

      if (!weeklyTeamDoc.exists) {
        print("⚠️ Laget $teamId saknar data för vecka $currentWeek.");
        continue;
      }

      Map<String, dynamic> weekData =
          weeklyTeamDoc.data() as Map<String, dynamic>;
      List<dynamic> skiers = weekData['skiers'] ?? [];
      String? captainId = weekData['captain'];

      int pointsToSubtract = 0;

      for (var skier in skiers) {
        if (skier is Map<String, dynamic>) {
          int points = skier['totalWeeklyPoints'] ?? 0;
          if (skier['skierId'] == captainId) {
            points *= 2;
            print("🔁 Tar bort dubbla poäng för kapten: ${skier['skierId']}");
          }
          pointsToSubtract += points;
        }
      }

      if (pointsToSubtract > 0) {
        print("🔻 Minskar totalPoints för $teamId med $pointsToSubtract");
        batch.update(
          db.collection('teams').doc(teamId),
          {'totalPoints': FieldValue.increment(-pointsToSubtract)},
        );
      } else {
        print("ℹ️ Inga poäng att återställa för lag $teamId.");
      }
    }

    await batch.commit();
    print("✅ Alla totalPoints har återställts för vecka $currentWeek!");
  } catch (e) {
    print("❌ Fel vid återställning av totalPoints: $e");
  }
}

Future<void> updateAllTeamsWeeklyPoints() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    if (teamsSnapshot.docs.isEmpty) {
      print("❌ Inga lag hittades.");
      return;
    }

    WriteBatch batch = db.batch();

    for (var teamDoc in teamsSnapshot.docs) {
      String teamId = teamDoc.id;

      DocumentSnapshot weeklyTeamDoc = await db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$currentWeek")
          .get();

      if (!weeklyTeamDoc.exists) {
        print("⚠️ Laget $teamId har inget registrerat för vecka $currentWeek.");
        continue;
      }

      final data = weeklyTeamDoc.data() as Map<String, dynamic>;
      final List<dynamic> skiers = data['skiers'] ?? [];
      final String? captainId = data['captain']?.toString();

      if (skiers.isEmpty) {
        print("⚠️ Laget $teamId har inga åkare vecka $currentWeek.");
        continue;
      }

      int totalTeamWeeklyPoints = 0;

      for (var skier in skiers) {
        if (skier is Map<String, dynamic>) {
          int points = skier['totalWeeklyPoints'] ?? 0;
          String skierId = skier['skierId'] ?? '';

          if (skierId == captainId) {
            points *= 2;
            print("👑 Kapten $skierId får dubbla poäng: $points");
          }

          totalTeamWeeklyPoints += points;
        }
      }

      print("✅ Lag $teamId - Uppdaterad veckopoäng: $totalTeamWeeklyPoints");

      batch.set(
        db
            .collection('teams')
            .doc(teamId)
            .collection('weeklyTeams')
            .doc("week$currentWeek"),
        {'weeklyPoints': totalTeamWeeklyPoints},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    print("🎉 Alla lags veckopoäng har uppdaterats för vecka $currentWeek!");
  } catch (e) {
    print("❌ Fel vid uppdatering av alla lags veckopoäng: $e");
  }
}
