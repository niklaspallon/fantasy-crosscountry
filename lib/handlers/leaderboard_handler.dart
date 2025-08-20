import 'package:flutter/material.dart' show BuildContext;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_handler.dart';
import '../providers/team_provider.dart';
import 'package:provider/provider.dart';
import 'team_details_handler.dart';

/// 🔢 Räkna ut aktuell leaderboard (live) för given vecka
Future<List<Map<String, dynamic>>> calculateLiveLeaderboard(int week) async {
  print("calculateLiveLeaderboard, körs");
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
  print("cacheTemporaryLeaderboard, körs");
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
  print("finalizeLeaderboardCache, körs");
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
  print("fetchLatestAvailableLeaderboard, körs");
  try {
    final db = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await db.collection('cachedData').get();

    List<QueryDocumentSnapshot> leaderboardDocs = snapshot.docs.where((doc) {
      return doc.id.startsWith('leaderboard_week') && !doc.id.endsWith('_temp');
    }).toList();

    if (leaderboardDocs.isEmpty) {
      print(
          "⚠️ Ingen leaderboard-cache hittades., visar lagnamn före första deadline");
      final teamNames = await fetchTeamNamesBeforeFirstGwDeadline();
      return teamNames;
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
  print("fetchBestAvailableLeaderboard, körs");
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

Future<List<Map<String, dynamic>>> fetchTeamNamesBeforeFirstGwDeadline() async {
  try {
    // Hämta ALLA dokument i 'teams'
    final db = FirebaseFirestore.instance;

    QuerySnapshot<Map<String, dynamic>> snapshot =
        await db.collection('teams').get();

    final teamList = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'teamId': doc.id,
        'teamName': data['teamName'] ?? 'Okänt lagnamn',
      };
    }).toList();
    print("🔍 Hämtade ${teamList.length} lagnamn före första deadline");
    return teamList;
  } catch (e) {
    print("❌ Fel vid hämtning av lagnamn före första deadline: $e");
    return [];
  }
}
