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

    // Hämta alla tidigare veckodokument för alla lag samtidigt för att optimera prestanda
    List<DocumentSnapshot> previousWeekDocs = await Future.wait(
      teamsSnapshot.docs.map((teamDoc) async {
        String teamId = teamDoc.id;
        return await db
            .collection('teams')
            .doc(teamId)
            .collection('weeklyTeams')
            .doc("week$currentWeek")
            .get();
      }),
    );

    for (int i = 0; i < teamsSnapshot.docs.length; i++) {
      var teamDoc = teamsSnapshot.docs[i];
      String teamId = teamDoc.id;

      // Hämta nuvarande antal freeTransfers
      int currentFreeTransfers = teamDoc.get('freeTransfers') ?? 0;

      int maxFreeTransfers = 5;
      int updatedFreeTransfers = currentFreeTransfers + 1;
      updatedFreeTransfers = updatedFreeTransfers > maxFreeTransfers
          ? maxFreeTransfers
          : updatedFreeTransfers;

      batch.update(db.collection('teams').doc(teamId), {
        'freeTransfers': updatedFreeTransfers,
      });

      // Hämta förra veckans laguppställning
      DocumentSnapshot previousWeekDoc = previousWeekDocs[i];
      List<dynamic> previousSkiers = [];
      String previousCaptain = "";

      if (previousWeekDoc.exists) {
        previousSkiers = previousWeekDoc.get('skiers') ?? [];
        previousCaptain = previousWeekDoc.get('captain') ?? "";
      }

      // Uppdatera laget för nästa vecka
      batch.set(
        db
            .collection('teams')
            .doc(teamId)
            .collection('weeklyTeams')
            .doc("week$nextWeek"),
        {
          'weekNumber': nextWeek,
          'skiers': previousSkiers, // Behåll tidigare åkare
          'weeklyPoints': 0, // Återställ veckopoäng
          'captain': previousCaptain,
        },
        SetOptions(merge: true),
      );

      print("✅ Team $teamId copied over to week $nextWeek!");
    }

    // Commit alla batch-uppdateringar
    await batch.commit();
    print("🎉 All teams successfully updated for week $nextWeek!");
  } catch (e) {
    print("❌ Error updating teams for new week: $e");
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
