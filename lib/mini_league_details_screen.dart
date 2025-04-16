import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MiniLeagueDetailScreen extends StatelessWidget {
  final String code;
  final String leagueName;

  const MiniLeagueDetailScreen({
    Key? key,
    required this.code,
    required this.leagueName,
  }) : super(key: key);

  Future<List<String>> fetchTeamNames() async {
    final db = FirebaseFirestore.instance;

    final snapshot = await db
        .collection('miniLeagues')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final data = snapshot.docs.first.data();
    final List<dynamic> teamIds = data['teams'] ?? [];

    // Exempel: team-id till team-namn. Du kanske måste anpassa detta beroende på var lagens namn finns.
    List<String> names = [];

    for (String id in teamIds) {
      final teamSnap = await db.collection('teams').doc(id).get();
      if (teamSnap.exists) {
        final teamData = teamSnap.data();
        names.add(teamData?['teamName'] ?? "Okänt lag");
      }
    }

    return names;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liga: $leagueName"),
        backgroundColor: Colors.lightBlue,
      ),
      body: FutureBuilder<List<String>>(
        future: fetchTeamNames(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Fel vid hämtning"));
          }

          final teams = snapshot.data ?? [];

          if (teams.isEmpty) {
            return const Center(child: Text("Inga lag i denna liga ännu."));
          }

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (_, index) => ListTile(
              leading: const Icon(Icons.group),
              title: Text(teams[index]),
            ),
          );
        },
      ),
    );
  }
}
