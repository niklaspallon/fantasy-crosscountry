import 'package:cloud_firestore/cloud_firestore.dart';
import 'teamProvider.dart';
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

    print("🔄 Updating teams for new game week: $nextWeek...");

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    WriteBatch batch = db.batch();

    for (var teamDoc in teamsSnapshot.docs) {
      if (!teamDoc.exists) continue;
      String teamId = teamDoc.id;

      // 🔹 Fetch previous week's team
      DocumentSnapshot previousWeekDoc = await db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$currentWeek")
          .get();

      List<dynamic> previousSkiers = [];
      String previousCaptain = "";
      if (previousWeekDoc.exists) {
        previousSkiers = previousWeekDoc.get('skiers') ?? [];
        previousCaptain = previousWeekDoc.get('captain') ?? "";
      }

      // ✅ Ensure each team gets an entry even if they had no skiers
      batch.set(
        db
            .collection('teams')
            .doc(teamId)
            .collection('weeklyTeams')
            .doc("week$nextWeek"),
        {
          'weekNumber': nextWeek,
          'skiers': previousSkiers, // Retain previous skiers
          'weeklyPoints': 0, // Reset weekly points
          'captain': previousCaptain
        },
        SetOptions(merge: true),
      );

      print("✅ Team $teamId copied over to week $nextWeek!");
    }

    await batch.commit();
    print("🎉 All teams successfully updated for week $nextWeek!");
  } catch (e) {
    print("❌ Error updating teams for new week: $e");
  }
}
