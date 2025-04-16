import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_handler.dart';

/// 🔹 Hämta veckopoäng (`weeklyPoints`) för ett lag en given vecka
Future<int> getWeeklyTeamPoints(String teamID, int weeknumber) async {
  try {
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
    String teamId, int weekNumber) async {
  final String cacheKey = "$teamId-$weekNumber";

  // 🔹 Om det redan finns i cachen – använd det direkt
  if (_teamCache.containsKey(cacheKey)) {
    print("♻️ Hämtar lag från cache: $cacheKey");
    return _teamCache[cacheKey]!;
  }

  try {
    print("📡 Hämtar lag från Firestore: $cacheKey");

    FirebaseFirestore db = FirebaseFirestore.instance;
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
      };
    }).toList();

    // 🔹 Spara i cache
    _teamCache[cacheKey] = skiers;

    return skiers;
  } catch (e) {
    print("❌ Fel vid hämtning av lagets skidåkare med poäng: $e");
    return [];
  }
}

// /// 🔹 Hämta totalWeeklyPoints för en lista av skidåkare
// Future<Map<String, int>> getAllSkiersPoints(
//     List<String> skierIds, int weekNumber) async {
//   Map<String, int> skierPointsMap = {};

//   try {
//     List<Future<DocumentSnapshot>> futures = skierIds.map((skierId) {
//       return FirebaseFirestore.instance
//           .collection('SkiersDb')
//           .doc(skierId)
//           .collection('weeklyResults')
//           .doc("week$weekNumber")
//           .get();
//     }).toList();

//     List<DocumentSnapshot> results =
//         await Future.wait(futures); // 🔥 Batch-hämtning

//     for (int i = 0; i < results.length; i++) {
//       if (results[i].exists) {
//         skierPointsMap[skierIds[i]] =
//             (results[i].get('totalWeeklyPoints') ?? 0) as int;
//       } else {
//         skierPointsMap[skierIds[i]] = 0; // Ingen data = 0 poäng
//       }
//     }
//   } catch (e) {
//     print("❌ Fel vid hämtning av totalWeeklyPoints: $e");
//   }

//   return skierPointsMap;
// }

// /// 🔹 **Hämta skidåkare och deras poäng**
// Future<List<Map<String, dynamic>>> getTeamSkiersWithPoints(
//     String teamId, int weekNumber) async {
//   try {
//     FirebaseFirestore db = FirebaseFirestore.instance;
//     DocumentSnapshot weeklyTeamDoc = await db
//         .collection('teams')
//         .doc(teamId)
//         .collection('weeklyTeams')
//         .doc("week$weekNumber")
//         .get();

//     if (!weeklyTeamDoc.exists) {
//       print("⚠️ Inget lag hittades för vecka $weekNumber");
//       return [];
//     }

//     List<dynamic> skierIds = weeklyTeamDoc.get('skiers') ?? [];
//     if (skierIds.isEmpty) return [];

//     QuerySnapshot skiersSnapshot = await db
//         .collection('SkiersDb')
//         .where(FieldPath.documentId, whereIn: skierIds)
//         .get();

//     List<Map<String, dynamic>> skierDataList = skiersSnapshot.docs.map((doc) {
//       Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//       data["skierId"] = doc.id;
//       return data;
//     }).toList();

//     // 🔹 Hämta poäng för varje skidåkare
//     Map<String, int> skierPointsMap =
//         await getAllSkiersPoints(skierIds.cast<String>(), weekNumber);

//     // 🔹 Lägg till poäng i varje skidåkare
//     for (var skier in skierDataList) {
//       skier["points"] = skierPointsMap[skier["skierId"]] ?? 0;
//     }

//     return skierDataList;
//   } catch (e) {
//     print("❌ Fel vid hämtning av lagets skidåkare med poäng: $e");
//     return [];
//   }
// }

/*
/// 🔹 **Hämta och sortera lagens poäng i en batch**
Future<List<Map<String, dynamic>>> fetchLeaderboardData() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    // 🔹 Hämta alla lag
    QuerySnapshot teamsSnapshot = await db.collection('teams').get();
    List<Map<String, dynamic>> teams = teamsSnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['teamId'] = doc.id;
      return data;
    }).toList();

    // 🔹 Lista med teamId för batchhämtning av veckopoäng
    List<String> teamIds =
        teams.map<String>((team) => team['teamId'].toString()).toList();

    // 🔹 Hämta alla lagens veckopoäng i en batch
    Map<String, int> weeklyPointsMap =
        await getAllTeamsWeeklyPoints(teamIds, currentWeek);

    // 🔹 Lägg till veckopoängen i varje lagdata
    for (var team in teams) {
      team['weeklyPoints'] = weeklyPointsMap[team['teamId']] ?? 0;
    }

    // 🔹 Sortera listan efter totalpoäng
    teams.sort(
        (a, b) => (b['totalPoints'] ?? 0).compareTo(a['totalPoints'] ?? 0));

    return teams;
  } catch (e) {
    print("❌ Fel vid hämtning av leaderboard-data: $e");
    return [];
  }
}
*/

/// 🔢 Räkna ut aktuell leaderboard (live) för given vecka
Future<List<Map<String, dynamic>>> calculateLiveLeaderboard(int week) async {
  try {
    final db = FirebaseFirestore.instance;

    // 🔹 Hämta alla lag
    QuerySnapshot teamsSnapshot = await db.collection('teams').get();

    List<Map<String, dynamic>> teams = teamsSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['teamId'] = doc.id;
      return data;
    }).toList();

    // 🔹 Hämta veckopoäng för lagen
    List<String> teamIds =
        teams.map((team) => team['teamId'] as String).toList();
    Map<String, int> weeklyPointsMap =
        await getAllTeamsWeeklyPoints(teamIds, week);

    // 🔹 Lägg till poäng & sortera
    for (var team in teams) {
      team['weeklyPoints'] = weeklyPointsMap[team['teamId']] ?? 0;
    }

    teams.sort(
        (a, b) => (b['totalPoints'] ?? 0).compareTo(a['totalPoints'] ?? 0));

    return teams;
  } catch (e) {
    print("❌ Fel vid live-beräkning av leaderboard: $e");
    return [];
  }
}

/// 🟡 Tillfällig leaderboard-cache (för uppdateringar mellan tävlingar)
Future<void> cacheTemporaryLeaderboard() async {
  try {
    int currentWeek = await getCurrentWeek();
    final db = FirebaseFirestore.instance;

    final leaderboard = await calculateLiveLeaderboard(currentWeek);
    print("🔍 Sparar följande leaderboard: ${leaderboard.length} lag");

    await db
        .collection('cachedData')
        .doc("leaderboard_week${currentWeek}_temp")
        .set({
      'teams': leaderboard,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("🟡 Tillfällig leaderboard-cache uppdaterad för vecka $currentWeek!");
  } catch (e) {
    print("❌ Fel vid temporär leaderboard-cache: $e");
  }
}

/// ✅ Slutgiltig leaderboard-cache (efter sista tävlingen)
Future<void> finalizeLeaderboardCache() async {
  try {
    int currentWeek = await getCurrentWeek();
    final db = FirebaseFirestore.instance;

    final leaderboard = await calculateLiveLeaderboard(currentWeek);

    await db.collection('cachedData').doc("leaderboard_week$currentWeek").set({
      'teams': leaderboard,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print("✅ Permanent leaderboard-cache sparad för vecka $currentWeek!");
  } catch (e) {
    print("❌ Fel vid sparande av permanent leaderboard-cache: $e");
  }
}

/// 📲 Hämta senaste tillgängliga leaderboard (för att visa i UI)
Future<List<Map<String, dynamic>>> fetchLatestAvailableLeaderboard() async {
  try {
    final db = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await db.collection('cachedData').get();

    List<QueryDocumentSnapshot> leaderboardDocs = snapshot.docs.where((doc) {
      return doc.id.startsWith('leaderboard_week') && !doc.id.endsWith('_temp');
    }).toList();

    if (leaderboardDocs.isEmpty) {
      print("⚠️ Ingen leaderboard-cache hittades.");
      return [];
    }

    leaderboardDocs.sort((a, b) {
      int aWeek = int.tryParse(a.id.replaceAll('leaderboard_week', '')) ?? 0;
      int bWeek = int.tryParse(b.id.replaceAll('leaderboard_week', '')) ?? 0;
      return bWeek.compareTo(aWeek);
    });

    DocumentSnapshot latestDoc = leaderboardDocs.first;
    List<dynamic> teamsRaw = latestDoc.get('teams');

    return List<Map<String, dynamic>>.from(teamsRaw);
  } catch (e) {
    print("❌ Fel vid hämtning av senaste leaderboard-cache: $e");
    return [];
  }
}

Future<List<Map<String, dynamic>>> fetchBestAvailableLeaderboard() async {
  try {
    final db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    // 🔹 Försök hämta PERMANENT leaderboard först
    DocumentSnapshot finalDoc = await db
        .collection('cachedData')
        .doc("leaderboard_week$currentWeek")
        .get();

    if (finalDoc.exists && finalDoc.data() != null) {
      print("✅ Visar permanent leaderboard för vecka $currentWeek");
      List<dynamic> teamsRaw = finalDoc.get('teams');
      return List<Map<String, dynamic>>.from(teamsRaw);
    }

    // 🔹 Om ingen permanent finns, visa TEMP
    DocumentSnapshot tempDoc = await db
        .collection('cachedData')
        .doc("leaderboard_week${currentWeek}_temp")
        .get();

    if (tempDoc.exists && tempDoc.data() != null) {
      print("🟡 Visar tillfällig leaderboard för vecka $currentWeek");
      List<dynamic> teamsRaw = tempDoc.get('teams');
      return List<Map<String, dynamic>>.from(teamsRaw);
    }

    // 🔹 Om inget av ovan finns: visa senaste permanenta
    print(
        "⏭ Ingen leaderboard för vecka $currentWeek – visar senaste tillgängliga.");
    return await fetchLatestAvailableLeaderboard();
  } catch (e) {
    print("❌ Fel vid hämtning av bästa tillgängliga leaderboard: $e");
    return [];
  }
}
