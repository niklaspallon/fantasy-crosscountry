import 'package:flutter/material.dart' show BuildContext;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_handler.dart';
import '../providers/team_provider.dart';
import 'package:provider/provider.dart';
import 'leaderboard_handler.dart';

/// 🔹 Hämta veckopoäng (`weeklyPoints`) för ett lag en given vecka
Future<int> getWeeklyTeamPoints(String teamID, int weeknumber) async {
  try {
    print("getWeeklyTeamPoints, körs");
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot weeklyTeamDoc = await db
        .collection('teams')
        .doc(teamID)
        .collection('weeklyTeams')
        .doc("week$weeknumber")
        .get();

    if (!weeklyTeamDoc.exists) {
      print("weeklyteam doc finns inte för $teamID för vecka $weeknumber");
      return 0; // or any fallback value
    }
    Map<String, dynamic> data = weeklyTeamDoc.data() as Map<String, dynamic>;
    int weeklyPoints = data['weeklyPoints'] ?? 0;
    return weeklyPoints;
  } catch (e) {
    print(e);
    return 0;
  }
}

/// 🔹 Hämta alla lagens `weeklyPoints` direkt från weeklyTeams
Future<Map<String, int>> getAllTeamsWeeklyPoints(
    List<String> teamIds, int weekNumber) async {
  print("getAllTeamsWeeklyPoints, körs");
  Map<String, int> teamPointsMap = {};
  FirebaseFirestore db = FirebaseFirestore.instance;

  try {
    // 🔹 Hämta alla weeklyTeams-dokument i en batch
    List<Future<DocumentSnapshot>> futures = teamIds.map((teamId) {
      return db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$weekNumber")
          .get();
    }).toList();

    List<DocumentSnapshot> teamDocs = await Future.wait(futures);

    for (int i = 0; i < teamIds.length; i++) {
      String teamId = teamIds[i];
      DocumentSnapshot teamDoc = teamDocs[i];

      if (!teamDoc.exists) {
        print("⚠️ Lag $teamId saknar dokument för vecka $weekNumber.");
        teamPointsMap[teamId] = 0;
        continue;
      }

      final data = teamDoc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('weeklyPoints')) {
        int points = data['weeklyPoints'] ?? 0;
        teamPointsMap[teamId] = points;
        print("✅ Lag $teamId har $points poäng för vecka $weekNumber.");
      } else {
        print("⚠️ Lag $teamId saknar `weeklyPoints`-fält.");
        teamPointsMap[teamId] = 0;
      }
    }
  } catch (e) {
    print("❌ Fel vid hämtning av weeklyPoints: $e");
  }

  return teamPointsMap;
}

/// 🔹 Hämta skidåkare och deras poäng direkt från weeklyTeams (ingen extra läsning från SkiersDb)
/// 🔹 Lokal cache
final Map<String, List<Map<String, dynamic>>> _teamCache = {};

/// 🔹 Hämtar skidåkare + poäng från cache eller Firestore
Future<List<Map<String, dynamic>>> getTeamSkiersWithPoints(
    String teamId, int weekNumber, BuildContext context) async {
  print("getTeamSkiersWithPoints, körs");
  final String cacheKey = "$teamId-$weekNumber";
  FirebaseFirestore db = FirebaseFirestore.instance;
  final deadline = context.read<TeamProvider>().weekDeadline;

  if (deadline == null) {
    print("⚠️ Ingen deadline hittad i TeamProvider");
    return [];
  }

  // 🔹 Om det redan finns i cachen – använd det direkt
  if (_teamCache.containsKey(cacheKey)) {
    print("♻️ Hämtar lag från cache: $cacheKey");
    return _teamCache[cacheKey]!;
  }

  try {
    print("📡 Hämtar lag från Firestore: $cacheKey");

    bool isDeadlinePassed = DateTime.now().isAfter(deadline);

    // Om deadline inte har passerat, försök hämta förra veckans lag
    if (!isDeadlinePassed) {
      print("⏰ Deadline har inte passerat för vecka $weekNumber");
      if (weekNumber > 1) {
        print("📅 Hämtar lag från vecka ${weekNumber - 1} istället");
        return getTeamSkiersWithPoints(teamId, weekNumber - 1, context);
      } else {
        print("⚠️ Första veckan och deadline har inte passerat");
        return [];
      }
    }

    // Hämta laget för den aktuella veckan
    DocumentSnapshot weeklyTeamDoc = await db
        .collection('teams')
        .doc(teamId)
        .collection('weeklyTeams')
        .doc("week$weekNumber")
        .get();

    if (!weeklyTeamDoc.exists) {
      print("⚠️ Inget lag hittades för vecka $weekNumber");
      return [];
    }

    Map<String, dynamic> data = weeklyTeamDoc.data() as Map<String, dynamic>;
    List<dynamic> skiersRaw = data['skiers'] ?? [];

    List<Map<String, dynamic>> skiers = skiersRaw.map((skierData) {
      return {
        'skierId': skierData['skierId'],
        'name': skierData['name'],
        'country': skierData['country'],
        'points': skierData['totalWeeklyPoints'],
        'isCaptain': skierData['isCaptain'] ?? false,
        'gender': skierData['gender'] ?? 'Male',
      };
    }).toList();

    // Sortera så att tjejer kommer först (index 0-2) och killar sist (index 3-5)
    skiers.sort((a, b) {
      // Först sortera på kön (tjejer först)
      if (a['gender'] != b['gender']) {
        return a['gender'] == 'Female' ? -1 : 1;
      }
      // Om samma kön, behåll originalordningen
      return 0;
    });

    // 🔹 Spara i cache
    _teamCache[cacheKey] = skiers;

    return skiers;
  } catch (e) {
    print("❌ Fel vid hämtning av lagets skidåkare med poäng: $e");
    return [];
  }
}

// /// 🔢 Räkna ut aktuell leaderboard (live) för given vecka ALLT DESSSA FUNKTIONER UNDER LIGGER I HANDLER
// Future<List<Map<String, dynamic>>> calculateLiveLeaderboard(int week) async {
//   print("calculateLiveLeaderboard, körs");
//   try {
//     final db = FirebaseFirestore.instance;

//     // 🔹 Hämta alla lag
//     QuerySnapshot teamsSnapshot = await db.collection('teams').get();

//     List<Map<String, dynamic>> teams = teamsSnapshot.docs.map((doc) {
//       final data = doc.data() as Map<String, dynamic>;
//       data['teamId'] = doc.id;
//       return data;
//     }).toList();

//     // 🔹 Hämta veckopoäng för lagen
//     List<String> teamIds =
//         teams.map((team) => team['teamId'] as String).toList();
//     Map<String, int> weeklyPointsMap =
//         await getAllTeamsWeeklyPoints(teamIds, week);

//     // 🔹 Lägg till poäng & sortera
//     for (var team in teams) {
//       team['weeklyPoints'] = weeklyPointsMap[team['teamId']] ?? 0;
//     }

//     teams.sort(
//         (a, b) => (b['totalPoints'] ?? 0).compareTo(a['totalPoints'] ?? 0));

//     return teams;
//   } catch (e) {
//     print("❌ Fel vid live-beräkning av leaderboard: $e");
//     return [];
//   }
// }

// /// 🟡 Tillfällig leaderboard-cache (för uppdateringar mellan tävlingar)
// Future<void> cacheTemporaryLeaderboard() async {
//   print("cacheTemporaryLeaderboard, körs");
//   try {
//     int currentWeek = await getCurrentWeek();
//     final db = FirebaseFirestore.instance;

//     final leaderboard = await calculateLiveLeaderboard(currentWeek);
//     print("🔍 Sparar följande leaderboard: ${leaderboard.length} lag");

//     await db
//         .collection('cachedData')
//         .doc("leaderboard_week${currentWeek}_temp")
//         .set({
//       'teams': leaderboard,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

//     print("🟡 Tillfällig leaderboard-cache uppdaterad för vecka $currentWeek!");
//   } catch (e) {
//     print("❌ Fel vid temporär leaderboard-cache: $e");
//   }
// }

// /// ✅ Slutgiltig leaderboard-cache (efter sista tävlingen)
// Future<void> finalizeLeaderboardCache() async {
//   print("finalizeLeaderboardCache, körs");
//   try {
//     int currentWeek = await getCurrentWeek();
//     final db = FirebaseFirestore.instance;

//     final leaderboard = await calculateLiveLeaderboard(currentWeek);

//     await db.collection('cachedData').doc("leaderboard_week$currentWeek").set({
//       'teams': leaderboard,
//       'timestamp': FieldValue.serverTimestamp(),
//     });

//     print("✅ Permanent leaderboard-cache sparad för vecka $currentWeek!");
//   } catch (e) {
//     print("❌ Fel vid sparande av permanent leaderboard-cache: $e");
//   }
// }

// /// 📲 Hämta senaste tillgängliga leaderboard (för att visa i UI)
// Future<List<Map<String, dynamic>>> fetchLatestAvailableLeaderboard() async {
//   print("fetchLatestAvailableLeaderboard, körs");
//   try {
//     final db = FirebaseFirestore.instance;
//     QuerySnapshot snapshot = await db.collection('cachedData').get();

//     List<QueryDocumentSnapshot> leaderboardDocs = snapshot.docs.where((doc) {
//       return doc.id.startsWith('leaderboard_week') && !doc.id.endsWith('_temp');
//     }).toList();

//     if (leaderboardDocs.isEmpty) {
//       print("⚠️ Ingen leaderboard-cache hittades.");
//       return [];
//     }

//     leaderboardDocs.sort((a, b) {
//       int aWeek = int.tryParse(a.id.replaceAll('leaderboard_week', '')) ?? 0;
//       int bWeek = int.tryParse(b.id.replaceAll('leaderboard_week', '')) ?? 0;
//       return bWeek.compareTo(aWeek);
//     });

//     DocumentSnapshot latestDoc = leaderboardDocs.first;
//     List<dynamic> teamsRaw = latestDoc.get('teams');

//     return List<Map<String, dynamic>>.from(teamsRaw);
//   } catch (e) {
//     print("❌ Fel vid hämtning av senaste leaderboard-cache: $e");
//     return [];
//   }
// }

// Future<List<Map<String, dynamic>>> fetchBestAvailableLeaderboard() async {
//   print("fetchBestAvailableLeaderboard, körs");
//   try {
//     final db = FirebaseFirestore.instance;
//     int currentWeek = await getCurrentWeek();

//     // 🔹 Försök hämta PERMANENT leaderboard först
//     DocumentSnapshot finalDoc = await db
//         .collection('cachedData')
//         .doc("leaderboard_week$currentWeek")
//         .get();

//     if (finalDoc.exists && finalDoc.data() != null) {
//       print("✅ Visar permanent leaderboard för vecka $currentWeek");
//       List<dynamic> teamsRaw = finalDoc.get('teams');
//       return List<Map<String, dynamic>>.from(teamsRaw);
//     }

//     // 🔹 Om ingen permanent finns, visa TEMP
//     DocumentSnapshot tempDoc = await db
//         .collection('cachedData')
//         .doc("leaderboard_week${currentWeek}_temp")
//         .get();

//     if (tempDoc.exists && tempDoc.data() != null) {
//       print("🟡 Visar tillfällig leaderboard för vecka $currentWeek");
//       List<dynamic> teamsRaw = tempDoc.get('teams');
//       return List<Map<String, dynamic>>.from(teamsRaw);
//     }

//     // 🔹 Om inget av ovan finns: visa senaste permanenta
//     print(
//         "⏭ Ingen leaderboard för vecka $currentWeek – visar senaste tillgängliga.");
//     return await fetchLatestAvailableLeaderboard();
//   } catch (e) {
//     print("❌ Fel vid hämtning av bästa tillgängliga leaderboard: $e");
//     return [];
//   }
// }
