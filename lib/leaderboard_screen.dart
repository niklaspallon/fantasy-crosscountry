import 'package:flutter/material.dart';
import 'team_details_screen.dart';
import 'team_details_handler.dart'; // 🔹 Importera för att hämta data

class LeaderboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[100], // Mörkare toppbar
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B)
            ], // Snygg mörk gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder(
          future:
              fetchBestAvailableLeaderboard(), // 🔹 Hämtar data från `team_details_handler.dart`
          builder:
              (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('❌ Något gick fel: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  '🚫 Inga lag hittades!',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            var teams = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                var teamData = teams[index];

                return AnimatedContainer(
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
                      teamData['teamName'] ?? "Okänt lag",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      "📅 Veckopoäng: ${teamData['weeklyPoints']}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber[600],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "🏆 ${teamData['totalPoints'] ?? 0}",
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
                          builder: (context) => TeamDetailsScreen(teamData),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 🔹 **Funktion för att färga rank-badgen** beroende på plats
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
}
