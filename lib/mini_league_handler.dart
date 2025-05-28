import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'teamProvider.dart';
import 'package:provider/provider.dart';

Future<List<Map<String, dynamic>>> getLeaguesForUser(String userId) async {
  final db = FirebaseFirestore.instance;
  final snapshot = await db
      .collection('miniLeagues')
      .where('teams', arrayContains: userId)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'name': data['leagueName'],
      'code': data['code'],
      'teamsCount': (data['teams'] as List).length,
    };
  }).toList();
}

/// Creates a new league with the given name
Future<bool> createLeague({
  required String leagueName,
  required String userId,
  required BuildContext context,
}) async {
  if (leagueName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter a league name")),
    );
    return false;
  }

  try {
    final success = await createMiniLeagueWithAutoCode(
      leagueName: leagueName,
      createdByUid: userId,
      createdAt: DateTime.now(),
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("League created successfully!")),
      );
      return true;
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create league")),
      );
    }
    return false;
  }
}

Future<bool> createMiniLeagueWithAutoCode({
  required String leagueName,
  required String createdByUid,
  required DateTime createdAt,
}) async {
  try {
    final db = FirebaseFirestore.instance;

    // 🔐 Generera unik kod
    String code = await generateUniqueLeagueCode();

    // 📝 Spara ligan med code som dokument-ID
    await db.collection('miniLeagues').doc(code).set({
      'code': code,
      'createdBy': createdByUid,
      'leagueName': leagueName,
      'teams': [createdByUid],
      'createdAt': Timestamp.fromDate(createdAt),
    });

    print("✅ Miniliga '$leagueName' skapades med kod: $code");
    return true;
  } catch (e) {
    print("❌ Fel vid skapande av miniliga: $e");
    return false;
  }
}

Future<String> generateUniqueLeagueCode() async {
  final db = FirebaseFirestore.instance;
  String code = "";
  bool isUnique = false;

  while (!isUnique) {
    code = generateRandomCode(6);
    final snapshot = await db.collection('miniLeagues').doc(code).get();
    isUnique = !snapshot.exists;
  }

  return code;
}

String generateRandomCode(int length) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Undvik liknande tecken
  final rand = Random();
  return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
}

Future<List<Map<String, dynamic>>> fetchTeams(String code) async {
  final db = FirebaseFirestore.instance;

  print("🔍 Letar efter liga med kod: $code");
  final snapshot = await db
      .collection('miniLeagues')
      .where('code', isEqualTo: code)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) {
    print("❌ Ingen liga hittades med koden: $code");
    return [];
  }

  final data = snapshot.docs.first.data();
  final List<dynamic> teamIds = data['teams'] ?? [];

  print("🧠 Team ownerIds: $teamIds");

  List<Map<String, dynamic>> teams = [];

  const int batchSize = 10;
  for (int i = 0; i < teamIds.length; i += batchSize) {
    final batch = teamIds.skip(i).take(batchSize).toList();

    final query =
        await db.collection('teams').where('ownerId', whereIn: batch).get();

    for (var doc in query.docs) {
      final teamData = doc.data();
      final name = teamData['teamName'] ?? "Okänt lag";
      final totalPoints = teamData['totalPoints'] ?? 0;

      teams.add({
        "id": doc.id,
        "teamId": doc.id,
        "name": name,
        "teamName": name,
        "totalPoints": totalPoints,
      });

      print(
          "✅ Hittade lag: $name (ägare: ${teamData['ownerId']}) poäng: $totalPoints");
    }
  }

  teams.sort(
      (a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));

  return teams;
}

Future<void> leaveLeague(String code) async {
  final db = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) return;

  try {
    final leagueRef = db.collection('miniLeagues').doc(code);
    await leagueRef.update({
      'teams': FieldValue.arrayRemove([userId])
    });
  } catch (e) {
    print("❌ Error leaving league: $e");
    rethrow;
  }
}

Future<void> joinMiniLeague({
  required String leagueCode,
  required String userId,
}) async {
  try {
    // Hämta ligan med den angivna koden
    final leagueQuery = await FirebaseFirestore.instance
        .collection('teams')
        .where('code', isEqualTo: leagueCode)
        .get();

    if (leagueQuery.docs.isEmpty) {
      throw Exception('Ligan hittades inte');
    }

    final league = leagueQuery.docs.first;
    final leagueId = league.id;

    // Kontrollera om användaren redan är med i ligan
    final userTeamQuery = await FirebaseFirestore.instance
        .collection('teams')
        .doc(leagueId)
        .collection('userTeams')
        .where('userId', isEqualTo: userId)
        .get();

    if (userTeamQuery.docs.isNotEmpty) {
      throw Exception('Du är redan med i denna liga');
    }

    // Lägg till användaren i ligan
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(leagueId)
        .collection('userTeams')
        .add({
      'userId': userId,
      'teamName': 'Team ${userId.substring(0, 4)}',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Uppdatera antalet lag i ligan
    await FirebaseFirestore.instance.collection('teams').doc(leagueId).update({
      'teamCount': FieldValue.increment(1),
    });
  } catch (e) {
    print('Error joining league: $e');
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchJoinedLeagues(String userId) async {
  final db = FirebaseFirestore.instance;
  final snapshot = await db
      .collection('miniLeagues')
      .where('teams', arrayContains: userId)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'code': doc.id,
      'name': data['leagueName'] ?? 'Unknown League',
      'teamsCount': (data['teams'] as List?)?.length ?? 0,
    };
  }).toList();
}
