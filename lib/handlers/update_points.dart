import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_handler.dart';
import 'firebase_batch_helper.dart';

Future<void> updateAllSkiersTotalPoints() async {
  Stopwatch stopwatch = Stopwatch()..start();
  print("updateAllSkiersTotalPoints körs...");
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot skiersSnapshot = await db.collection('SkiersDb').get();
    if (skiersSnapshot.docs.isEmpty) {
      print("❌ Inga skidåkare hittades.");
      return;
    }

    List<BatchOperation> operations = [];

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
        final result = entry.value;

        // 🔹 Anpassad till nya strukturen där varje entry är en map { points: X, placement: Y }
        if (!alreadyCounted.contains(compId)) {
          if (result is Map && result['points'] is int) {
            newPoints += (result['points'] as num).toInt();
            newlyCounted.add(compId);
          }
        }
      }

      if (newPoints > 0) {
        operations.add((batch) {
          batch.update(db.collection('SkiersDb').doc(skierId),
              {'totalPoints': FieldValue.increment(newPoints)});
        });

        operations.add((batch) {
          batch.update(
              weekRef, {'countedInTotal': FieldValue.arrayUnion(newlyCounted)});
        });
      }
    }
    await commitInBatches(db, operations);
    print("updateAllSkiersTotalPoints tog $stopwatch.elapsedMilliseconds");
  } catch (e) {
    print("❌ Fel vid uppdatering av totalpoäng: $e");
  }
}

Future<List<String>> updateAllTeamsTotalPoints() async {
  final stopwatch = Stopwatch()..start();
  print("updateAllTeamsTotalPoints körs...");
  List<String> feedback = [];

  try {
    final db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    // 🔹 Hämta alla lag
    final teamsSnapshot = await db.collection('teams').get();
    if (teamsSnapshot.docs.isEmpty) {
      feedback.add("❌ Inga lag hittades.");
      return feedback;
    }

    // 🔹 Hämta alla weeklyTeams parallellt
    final weeklyDocsFutures = teamsSnapshot.docs.map((teamDoc) {
      return db
          .collection('teams')
          .doc(teamDoc.id)
          .collection('weeklyTeams')
          .doc("week$currentWeek")
          .get();
    }).toList();

    final weeklyDocs = await Future.wait(weeklyDocsFutures);

    List<BatchOperation> operations = [];

    for (int i = 0; i < teamsSnapshot.docs.length; i++) {
      final teamDoc = teamsSnapshot.docs[i];
      final teamId = teamDoc.id;
      final weeklyTeamDoc = weeklyDocs[i];

      if (!weeklyTeamDoc.exists) {
        feedback.add(
            "⚠️ Lag $teamId har inget veckodokument för vecka $currentWeek.");
        continue;
      }

      final weekData = weeklyTeamDoc.data() as Map<String, dynamic>;
      int weeklyPoints = weekData['weeklyPoints'] ?? 0;
      int alreadyCounted = weekData['weeklyPointsCountedInTotal'] ?? 0;

      int pointsToAdd = weeklyPoints - alreadyCounted;

      if (pointsToAdd > 0) {
        operations.add((batch) {
          batch.update(db.collection('teams').doc(teamId), {
            'totalPoints': FieldValue.increment(pointsToAdd),
          });
        });

        operations.add((batch) {
          batch.update(
              db
                  .collection('teams')
                  .doc(teamId)
                  .collection('weeklyTeams')
                  .doc("week$currentWeek"),
              {
                'weeklyPointsCountedInTotal': alreadyCounted + pointsToAdd,
              });
        });

        feedback.add(
            "Lag $teamId: Redan räknat = $alreadyCounted, nya poäng = $pointsToAdd");
      } else {
        feedback.add(
            "⚠️ Lag $teamId: inga nya poäng. Veckopoäng = $weeklyPoints, Redan räknade poäng = $alreadyCounted");
      }
    }

    // 🔹 Commit i batches
    await commitInBatches(db, operations);

    feedback.add("Funktion kördes som den skulle");
  } catch (e) {
    feedback.add("❌ Fel vid uppdatering av alla lags totalpoäng: $e");
  }

  stopwatch.stop();
  print("⏱️ updateAllTeamsTotalPoints tog ${stopwatch.elapsedMilliseconds} ms");
  return feedback;
}

Future<List<String>> undoAllTeamsTotalPointsWithWeekly() async {
  //kvar
  print("undoAllTeamsTotalPointsWithWeekly körs...");
  List<String> feedback = [];

  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    if (teamsSnapshot.docs.isEmpty) {
      feedback.add("❌ Inga lag hittades.");
      return feedback;
    }

    List<BatchOperation> operations = [];

    for (var teamDoc in teamsSnapshot.docs) {
      String teamId = teamDoc.id;

      DocumentReference weeklyRef = db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$currentWeek");

      DocumentSnapshot weeklyTeamDoc = await weeklyRef.get();

      if (!weeklyTeamDoc.exists) {
        feedback.add("⚠️ Lag $teamId saknar data för vecka $currentWeek.");
        continue;
      }

      Map<String, dynamic> weekData =
          weeklyTeamDoc.data() as Map<String, dynamic>;

      int alreadyCounted = weekData['weeklyPointsCountedInTotal'] ?? 0;

      if (alreadyCounted > 0) {
        feedback.add("🔻 Lag $teamId: -$alreadyCounted poäng togs bort");

        operations.add((batch) {
          batch.update(
            db.collection('teams').doc(teamId),
            {'totalPoints': FieldValue.increment(-alreadyCounted)},
          );
        });

        operations.add((batch) {
          batch.update(
            weeklyRef,
            {'weeklyPointsCountedInTotal': 0},
          );
        });
      } else {
        feedback
            .add("Lag $teamId hade inga poäng räknade för vecka $currentWeek.");
      }
    }

    // 🔹 Commita i batchar, fyll varje batch upp till 500 operationer först
    await commitInBatches(db, operations);
    feedback.add(
        "✅ Alla lag fick sina inräknade poäng återställda för vecka $currentWeek!");
  } catch (e) {
    feedback.add("❌ Fel vid återställning av totalPoints: $e");
  }

  return feedback;
}

Future<void> updateAllTeamsWeeklyPoints(bool restoringCachedLeaderboard) async {
  final stopwatch = Stopwatch()..start();
  print("updateAllTeamsWeeklyPoints körs...");

  try {
    final db = FirebaseFirestore.instance;
    final currentWeek = await getCurrentWeek();

    final teamsSnapshot = await db.collection('teams').get();
    if (teamsSnapshot.docs.isEmpty) {
      print("❌ Inga lag hittades.");
      return;
    }

    List<BatchOperation> operations = [];

    // 🔹 Hämta alla weeklyTeams-dokument parallellt
    final weeklyDocsFutures = teamsSnapshot.docs.map((teamDoc) {
      return db
          .collection('teams')
          .doc(teamDoc.id)
          .collection('weeklyTeams')
          .doc("week$currentWeek")
          .get();
    }).toList();

    final weeklyDocs = await Future.wait(weeklyDocsFutures);

    for (int i = 0; i < teamsSnapshot.docs.length; i++) {
      final teamDoc = teamsSnapshot.docs[i];
      final teamId = teamDoc.id;
      final weeklyDoc = weeklyDocs[i];

      if (!weeklyDoc.exists) {
        print("⚠️ Laget $teamId har inget registrerat för vecka $currentWeek.");
        continue;
      }

      final data = weeklyDoc.data() as Map<String, dynamic>;
      final skiers = data['skiers'] as List<dynamic>? ?? [];
      final captainId = data['captain']?.toString();

      if (skiers.isEmpty) {
        print("⚠️ Laget $teamId har inga åkare vecka $currentWeek.");
        continue;
      }

      int totalTeamWeeklyPoints = 0;
      for (var skier in skiers) {
        if (skier is Map<String, dynamic>) {
          int points = skier['totalWeeklyPoints'] ?? 0;
          if (skier['skierId'] == captainId) points *= 2;
          totalTeamWeeklyPoints += points;
        }
      }

      if (!restoringCachedLeaderboard) {
        operations.add((batch) {
          batch.set(
            db
                .collection('teams')
                .doc(teamId)
                .collection('weeklyTeams')
                .doc("week$currentWeek"),
            {
              'weeklyPoints': totalTeamWeeklyPoints,
              'weeklyPointsCountedInTotal': totalTeamWeeklyPoints,
            },
            SetOptions(merge: true),
          );
        });
      } else {
        operations.add((batch) {
          batch.set(
            db
                .collection('teams')
                .doc(teamId)
                .collection('weeklyTeams')
                .doc("week$currentWeek"),
            {
              'weeklyPoints': totalTeamWeeklyPoints,
            },
            SetOptions(merge: true),
          );
        });
      }
    }

    // 🔹 Kör alla operationer i batchar
    await commitInBatches(db, operations);

    if (restoringCachedLeaderboard) {
      print(
          "Kör inte totalpointsdecrease då boleanen är, $restoringCachedLeaderboard.");
    } else {
      await totalPointsSyncDecrease();
    }

    stopwatch.stop();
    print(
        "⏱ updateAllTeamsWeeklyPoints klar på ${stopwatch.elapsedMilliseconds} ms");
  } catch (e) {
    print("❌ Fel vid uppdatering av alla lags veckopoäng: $e");
  }
}

Future<Map<String, int>> getAllSkiersPoints(
    List<String> skierIds, int weekNumber) async {
  print("getAllSkiersPoints körs för vecka $weekNumber...");
  Stopwatch stopwatch = Stopwatch()..start();
  Map<String, int> skierPointsMap = {};

  try {
    List<Future<DocumentSnapshot>> futures = skierIds.map((skierId) {
      return FirebaseFirestore.instance
          .collection('SkiersDb')
          .doc(skierId)
          .collection('weeklyResults')
          .doc("week$weekNumber")
          .get();
    }).toList();

    List<DocumentSnapshot> results =
        await Future.wait(futures); // 🔥 Batch-hämtning

    for (int i = 0; i < results.length; i++) {
      DocumentSnapshot weekDoc = results[i];

      int totalWeeklyPoints = 0;

      if (weekDoc.exists && weekDoc.data() != null) {
        var data = weekDoc.data();
        if (data is Map<String, dynamic>) {
          totalWeeklyPoints = (data['totalWeeklyPoints'] ?? 0) as int;
        }
      }

      skierPointsMap[skierIds[i]] = totalWeeklyPoints;
      print("getAllSkiersPoints tog ${stopwatch.elapsedMilliseconds} ms");
    }
  } catch (e) {
    print("❌ Error fetching totalWeeklyPoints for skiers: $e");
  }

  return skierPointsMap;
}

Future<void> syncSkierPointsToWeeklyTeams([int? nextWeek]) async {
  Stopwatch stopwatch = Stopwatch()..start();
  print("syncSkierPointsToWeeklyTeams körs...");
  final db = FirebaseFirestore.instance;
  int weekNumber;
  if (nextWeek != null) {
    weekNumber = nextWeek;
    print("➡️ Syncar för nästa vecka: $weekNumber");
  } else {
    weekNumber = await getCurrentWeek();
    print("➡️ Syncar för nuvarande vecka: $weekNumber");
  }
  try {
    // 🔹 1. Hämta alla lag
    final teamsSnapshot = await db.collection('teams').get();

    // 🔹 2. Bygg en lista med alla unika åkare från alla lag
    Set<String> allSkierIds = {};
    Map<String, List<String>> teamToSkierIds =
        {}; // för att veta vilka åkare per lag
    for (var teamDoc in teamsSnapshot.docs) {
      final weeklyRef =
          teamDoc.reference.collection('weeklyTeams').doc("week$weekNumber");
      final weekSnap = await weeklyRef.get();
      if (!weekSnap.exists) continue;

      final skiers = List.from((weekSnap.data()?['skiers'] ?? []));
      final ids = skiers.map((s) => s['skierId'].toString()).toList();
      allSkierIds.addAll(ids);
      teamToSkierIds[teamDoc.id] = ids;
    }

    // 🔹 3. Hämta poängen för alla unika åkare en gång
    final allSkierPoints =
        await getAllSkiersPoints(allSkierIds.toList(), weekNumber);

    // 🔹 4. Uppdatera alla lag med poängen från kartan
    List<BatchOperation> operations = [];
    int updatedTeams = 0;

    for (var teamDoc in teamsSnapshot.docs) {
      final teamId = teamDoc.id;
      final weeklyRef =
          teamDoc.reference.collection('weeklyTeams').doc("week$weekNumber");
      final weekSnap = await weeklyRef.get();
      if (!weekSnap.exists) continue;

      final skiers = List.from((weekSnap.data()?['skiers'] ?? []));

      for (var skier in skiers) {
        final id = skier['skierId'];
        if (allSkierPoints.containsKey(id)) {
          skier['totalWeeklyPoints'] = allSkierPoints[id];
        }
      }

      operations.add((batch) {
        batch.update(weeklyRef, {'skiers': skiers});
      });
      updatedTeams++;
    }

    await commitInBatches(db, operations);
    print(
        "syncSkierPointsToWeeklyTeams tog ${stopwatch.elapsedMilliseconds} ms");
  } catch (e) {
    print(
        "❌ Fel vid optimerad synkning av poäng: $e i syncSkierPointsToWeeklyTeams");
  }
}

Future<void> restoreTeamPointsFromCachedLeaderboard(int weekNumber) async {
  // tror denna är anpassad för batch
  final db = FirebaseFirestore.instance;
  final cachedRef =
      db.collection('cachedData').doc('leaderboard_week$weekNumber');
  final cachedDoc = await cachedRef.get();

  if (!cachedDoc.exists) {
    print("❌ Ingen leaderboard-cache hittad för vecka $weekNumber.");
    return;
  }

  final List<dynamic> cachedTeams = cachedDoc.get('teams') ?? [];
  List<BatchOperation> operations = [];

  for (var cachedTeam in cachedTeams) {
    final String teamId = cachedTeam['teamId'];
    final int totalPoints = cachedTeam['totalPoints'] ?? 0;
    final int weeklyPoints = cachedTeam['weeklyPoints'] ?? 0;

    final teamRef = db.collection('teams').doc(teamId);

    operations.add((batch) {
      batch.update(teamRef, {
        'totalPoints': totalPoints,
        'weeklyPoints': weeklyPoints,
      });
    });
  }

  await commitInBatches(db, operations);
  print("✅ Återställde enbart poäng från cache för vecka $weekNumber.");
  resetWeekPointsData(
      false); //ÄR ENDAST FALSE NÄR MAN RESETAR FRÅN EN GAMMAL LEADERBOARD
  print("🔄 Poängen för veckans tävlingar har nollstälts.");
  await syncSkierPointsToWeeklyTeams();
}

Future<String> resetWeekPointsData(bool restoringCachedLeaderboard) async {
  //tror denna är anpassad för batch
  print("resetWeekPointsData körs...");
  try {
    int currentWeek = await getCurrentWeek();

    FirebaseFirestore db = FirebaseFirestore.instance;

    // 🔹 1. Radera veckodata för alla skidåkare
    final skiersSnapshot = await db.collection('SkiersDb').get();
    List<BatchOperation> skierOps = [];

    for (var skierDoc in skiersSnapshot.docs) {
      final skierId = skierDoc.id;
      final weekRef = db
          .collection('SkiersDb')
          .doc(skierId)
          .collection('weeklyResults')
          .doc("week$currentWeek");

      final weekSnap = await weekRef.get();
      if (weekSnap.exists && weekSnap.data() != null) {
        final weekData = weekSnap.data() as Map<String, dynamic>;
        final competitions =
            Map<String, dynamic>.from(weekData['competitions'] ?? {});
        final countedInTotal =
            List<String>.from(weekData['countedInTotal'] ?? []);

        int pointsToRemove = 0;

        for (var compId in countedInTotal) {
          if (competitions.containsKey(compId)) {
            final comp = competitions[compId];
            if (comp is Map && comp['points'] is num) {
              pointsToRemove += (comp['points'] as num).toInt();
            }
          }
        }

        if (pointsToRemove > 0) {
          final skierRef = db.collection('SkiersDb').doc(skierId);
          skierOps.add((batch) {
            batch.update(skierRef, {
              'totalPoints': FieldValue.increment(-pointsToRemove),
            });
          });
        }
      }

      // 🔹 Till sist: ta bort hela veckodokumentet
      skierOps.add((batch) => batch.delete(weekRef));
    }

    await commitInBatches(db, skierOps);

    // 🔹 2. Rensa poäng från alla lag för den veckan
    final teamsSnapshot = await db.collection('teams').get();
    List<BatchOperation> teamOps = [];

    int affectedTeams = 0;

    for (var teamDoc in teamsSnapshot.docs) {
      final weeklyRef =
          teamDoc.reference.collection('weeklyTeams').doc("week$currentWeek");

      final weekSnap = await weeklyRef.get();
      if (!weekSnap.exists) continue;

      final weekData = weekSnap.data() as Map<String, dynamic>;
      List<dynamic> skiers = List.from(weekData['skiers'] ?? []);

      // Nollställ poäng för varje åkare
      for (var skier in skiers) {
        skier['totalWeeklyPoints'] = 0;
        skier['competitions'] = {};
        skier['countedCompetitions'] = [];
      }

      teamOps.add((batch) => batch.update(weeklyRef, {'skiers': skiers}));
      affectedTeams++;
    }

    await commitInBatches(db, teamOps);
    await updateAllTeamsWeeklyPoints(
        restoringCachedLeaderboard); // boolean för att inte köra totalPointsSyncDecrease vid återställning från cache
    print("🧹 Rensade weeklyTeams-data för vecka $currentWeek");

    return "✅ Veckodata för vecka $currentWeek har raderats för ${skiersSnapshot.docs.length} åkare och $affectedTeams lag.";
  } catch (e) {
    print("❌ Fel vid resetWeekData: $e");
    return "❌ Fel vid radering av veckodata: $e";
  }
}

Future<List<String>> totalPointsSyncDecrease() async {
  //tror denna är anpassad för batch
  print("totalPointsSyncDecrease körs...");
  List<String> feedback = [];
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    if (teamsSnapshot.docs.isEmpty) {
      feedback.add("Inga lag hittades.");
      return feedback;
    }
    List<BatchOperation> operations = [];

    for (var teamDoc in teamsSnapshot.docs) {
      String teamId = teamDoc.id;

      DocumentReference weeklyRef = db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$currentWeek");

      DocumentSnapshot weeklyTeamDoc = await weeklyRef.get();

      if (!weeklyTeamDoc.exists) {
        feedback.add("Lag $teamId saknar data för vecka $currentWeek.");
        continue;
      }

      Map<String, dynamic> weekData =
          weeklyTeamDoc.data() as Map<String, dynamic>;

      int weeklyPoints = weekData['weeklyPoints'] ?? 0;
      int alreadyCounted = weekData['weeklyPointsCountedInTotal'] ?? 0;

      // 🔹 Om veckopoängen har minskat sedan sist
      if (weeklyPoints < alreadyCounted) {
        int diff = alreadyCounted - weeklyPoints;

        feedback.add(
            " Lag $teamId: -$diff poäng justeras (från $alreadyCounted → $weeklyPoints)");

        // Minska totalPoints med mellanskillnaden
        // Lägg till operationer i listan
        operations.add((batch) {
          batch.update(
            db.collection('teams').doc(teamId),
            {'totalPoints': FieldValue.increment(-diff)},
          );
        });

        operations.add((batch) {
          batch.update(
            weeklyRef,
            {'weeklyPointsCountedInTotal': weeklyPoints},
          );
        });
      } else {
        feedback.add(
            "Lag $teamId behövde ingen justering ($weeklyPoints / $alreadyCounted).");
      }
    }

    await commitInBatches(db, operations);
    feedback.add("✅ Kontroll och justering av minskade veckopoäng klar!");
  } catch (e) {
    feedback.add("❌ Fel vid kontroll/justering av minskade veckopoäng: $e");
  }

  return feedback;
}

Future<String> undoCompetitionPoints(String competitionId) async {
  //tror denna är anpassad för batch
  print("undoCompetitionPoints körs");
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot skiersSnapshot = await db.collection('SkiersDb').get();
    List<Future<DocumentSnapshot>> weekDocsFutures = skiersSnapshot.docs
        .map((skierDoc) => db
            .collection('SkiersDb')
            .doc(skierDoc.id)
            .collection('weeklyResults')
            .doc("week$currentWeek")
            .get())
        .toList();

    List<DocumentSnapshot> weekDocs = await Future.wait(weekDocsFutures);
    List<BatchOperation> operations = [];

    int affectedSkiers = 0;
    int totalPointsRemoved = 0;

    for (int i = 0; i < skiersSnapshot.docs.length; i++) {
      String skierId = skiersSnapshot.docs[i].id;
      DocumentSnapshot weekDoc = weekDocs[i];

      if (!weekDoc.exists || weekDoc.data() == null) continue;

      Map<String, dynamic> data = weekDoc.data() as Map<String, dynamic>;
      Map<String, dynamic> competitions =
          Map<String, dynamic>.from(data['competitions'] ?? {});
      List<dynamic> counted =
          List<dynamic>.from(data['countedCompetitions'] ?? []);
      List<dynamic> countedInTotal =
          List<dynamic>.from(data['countedInTotal'] ?? []);

      if (competitions.containsKey(competitionId)) {
        final removedComp = competitions[competitionId];
        affectedSkiers++;

        competitions.remove(competitionId);
        counted.remove(competitionId);

        // 🔹 Räkna om totalWeeklyPoints
        int newTotal = competitions.values.fold(
          0,
          (a, b) => b is Map && b['points'] is num
              ? a + (b['points'] as num).toInt()
              : a,
        );

        final weekRef = weekDoc.reference;
        operations.add((batch) {
          batch.update(weekRef, {
            'competitions': competitions,
            'countedCompetitions': counted,
            'totalWeeklyPoints': newTotal,
          });
        });

        // 🔹 Dra bort från totalPoints om den var räknad
        if (countedInTotal.contains(competitionId)) {
          if (removedComp is Map && removedComp['points'] is num) {
            int removedPoints = (removedComp['points'] as num).toInt();
            totalPointsRemoved += removedPoints;
            final skierRef = db.collection('SkiersDb').doc(skierId);
            operations.add((batch) {
              batch.update(skierRef,
                  {'totalPoints': FieldValue.increment(-removedPoints)});
            });

            countedInTotal.remove(competitionId);
            operations.add((batch) {
              batch.update(weekRef, {'countedInTotal': countedInTotal});
            });
          }
        }

        // 🔹 Ta bort placering från recentPlacements
        if (removedComp is Map && removedComp['placement'] is int) {
          int removedPlacement = removedComp['placement'];
          final skierRef = db.collection('SkiersDb').doc(skierId);
          final skierDoc = skiersSnapshot.docs[i];
          List<dynamic> recentPlacements =
              List.from(skierDoc.get('recentPlacements') ?? []);

          recentPlacements.remove(removedPlacement);
          operations.add((batch) {
            batch.update(skierRef, {'recentPlacements': recentPlacements});
          });
        }
      }
    }
    await commitInBatches(db, operations);
    return "$competitionId återställd för vecka $currentWeek.\n"
        "$affectedSkiers åkare påverkades och totalt $totalPointsRemoved poäng drogs bort från totalpoäng.";
  } catch (e) {
    return "❌ Fel vid undoCompetitionPoints: $e";
  }
}
