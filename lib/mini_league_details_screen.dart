import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'team_details_handler.dart';
import 'team_details_screen.dart';

class MiniLeagueDetailScreen extends StatelessWidget {
  final String code;
  final String leagueName;

  const MiniLeagueDetailScreen({
    Key? key,
    required this.code,
    required this.leagueName,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchTeams() async {
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

    // 🔽 Sortera efter poäng (högst först)
    teams.sort(
        (a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int));

    return teams;
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber[700]!; // 🥇 Guld för plats 1
      case 1:
        return Colors.grey[400]!; // 🥈 Silver för plats 2
      case 2:
        return Colors.brown[400]!; // 🥉 Brons för plats 3
      default:
        return Colors.blueGrey[600]!; // Blågrå för övriga placeringar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liga: $leagueName"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[100],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchTeams(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Fel vid hämtning: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final teams = snapshot.data ?? [];

            if (teams.isEmpty) {
              return const Center(
                child: Text(
                  'Inga lag hittades i denna liga.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: teams.length,
              itemBuilder: (_, index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: _getRankColor(index),
                    radius: 22,
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Text(
                    teams[index]['name'] ?? "Okänt lag",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber[600],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "🏆 ${teams[index]['totalPoints'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamDetailsScreen(
                            teams[index],
                            context,
                          ),
                        ));
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
