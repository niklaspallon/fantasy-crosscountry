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
