import 'package:flutter/material.dart' show BuildContext;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_handler.dart';
import '../providers/team_provider.dart';
import 'package:provider/provider.dart';
import 'leaderboard_handler.dart';

/// 🔹 Hämta veckopoäng (`weeklyPoints`) för ett lag en given vecka
Future<int> getWeeklyTeamPoints(String teamID, int weekNumber) async {
  try {
    print("getWeeklyTeamPoints, körs, kollar vecka $weekNumber");
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot weeklyTeamDoc = await db
        .collection('teams')
        .doc(teamID)
        .collection('weeklyTeams')
        .doc("week$weekNumber")
        .get();

    if (!weeklyTeamDoc.exists) {
      print("⚠️ weeklyTeam doc finns inte för $teamID vecka $weekNumber");
      return 0;
    }

    Map<String, dynamic> data = weeklyTeamDoc.data() as Map<String, dynamic>;
    return data['weeklyPoints'] ?? 0;
  } catch (e) {
    print("❌ Fel i getWeeklyTeamPoints: $e");
    return 0;
  }
}

/// 🔹 Hämta alla lagens `weeklyPoints` direkt från weeklyTeams
Future<Map<String, int>> getAllTeamsWeeklyPoints(
    List<String> teamIds, int weekNumber) async {
  print("getAllTeamsWeeklyPoints, körs, vecka $weekNumber");
  Map<String, int> teamPointsMap = {};
  FirebaseFirestore db = FirebaseFirestore.instance;

  try {
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
        print("⚠️ Lag $teamId saknar dokument för vecka $weekNumber");
        teamPointsMap[teamId] = 0;
        continue;
      }

      final data = teamDoc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('weeklyPoints')) {
        teamPointsMap[teamId] = data['weeklyPoints'] ?? 0;
        print("✅ Lag $teamId har ${teamPointsMap[teamId]} poäng");
      } else {
        print("⚠️ Lag $teamId saknar `weeklyPoints`-fält");
        teamPointsMap[teamId] = 0;
      }
    }
  } catch (e) {
    print("❌ Fel vid hämtning av weeklyPoints: $e");
  }

  return teamPointsMap;
}

/// 🔹 Lokal cache för lagets skidåkare
final Map<String, List<Map<String, dynamic>>> _teamCache = {};
Future<List<Map<String, dynamic>>> getTeamSkiersWithPoints(
  String teamId,
  int weekNumber,
  BuildContext context,
) async {
  final String cacheKey = "$teamId-$weekNumber";
  FirebaseFirestore db = FirebaseFirestore.instance;
  final deadline = context.read<TeamProvider>().weekDeadline;

  // Returnera cache om tillgänglig
  if (_teamCache.containsKey(cacheKey)) {
    print("♻️ Hämtar lag från cache: $cacheKey");
    return _teamCache[cacheKey]!;
  }

  try {
    // Bestäm vilken vecka vi faktiskt ska hämta
    int weekToFetch = weekNumber;
    if (deadline != null &&
        DateTime.now().isBefore(deadline) &&
        weekNumber > 1) {
      weekToFetch = weekNumber - 1;
      print(
          "⏰ Deadline ej passerad för vecka $weekNumber, hämtar vecka $weekToFetch istället");
    }

    final fetchCacheKey = "$teamId-$weekToFetch";
    if (_teamCache.containsKey(fetchCacheKey)) {
      print("♻️ Hämtar lag från cache: $fetchCacheKey");
      return _teamCache[fetchCacheKey]!;
    }

    // Hämta dokument
    DocumentSnapshot weeklyTeamDoc = await db
        .collection('teams')
        .doc(teamId)
        .collection('weeklyTeams')
        .doc("week$weekToFetch")
        .get();

    if (!weeklyTeamDoc.exists) {
      print("⚠️ Inget lag hittades för vecka $weekToFetch");
      return [];
    }

    Map<String, dynamic> data = weeklyTeamDoc.data() as Map<String, dynamic>;
    List<dynamic> skiersRaw = data['skiers'] ?? [];

    List<Map<String, dynamic>> skiers = skiersRaw.map((skierData) {
      return {
        'skierId': skierData['skierId'] ?? '',
        'name': skierData['name'] ?? 'Unknown',
        'country': skierData['country'] ?? 'Unknown',
        'points': skierData['totalWeeklyPoints'] ?? 0,
        'isCaptain': skierData['isCaptain'] ?? false,
        'gender': skierData['gender'] ?? 'Male',
      };
    }).toList();

    // Sortera tjejer först
    skiers.sort((a, b) {
      if (a['gender'] != b['gender']) {
        return a['gender'] == 'Female' ? -1 : 1;
      }
      return 0;
    });

    // Spara i cache
    _teamCache[fetchCacheKey] = skiers;

    return skiers;
  } catch (e) {
    print("❌ Fel vid hämtning av lagets skidåkare med poäng: $e");
    return [];
  }
}
