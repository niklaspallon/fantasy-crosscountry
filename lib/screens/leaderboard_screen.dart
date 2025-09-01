import 'package:flutter/material.dart';
import 'package:real_fls/designs/button_design.dart';
import 'team_details_screen.dart';
import '../handlers/team_details_handler.dart';
import '../designs/appbar_design.dart';
import 'package:flutter/material.dart';
import 'team_details_screen.dart'; // Anpassa till din struktur
import '../handlers/leaderboard_handler.dart';

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int currentPage = 0;
  final int pageSize = 50; // Antal lag per sida

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Text(
              "Leaderboard",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E),
                Colors.blue[900]!.withOpacity(0.9),
                Colors.blue[800]!.withOpacity(0.8),
              ],
            ),
          ),
        ),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/skitracks_back.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: FutureBuilder(
              future: fetchBestAvailableLeaderboard(),
              builder: (context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Sometihing went wrong: ${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'No team found!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                var teams = snapshot.data!;
                int totalPages = (teams.length / pageSize).ceil();
                int start = currentPage * pageSize;
                int end = (start + pageSize).clamp(0, teams.length);
                List<Map<String, dynamic>> visibleTeams =
                    teams.sublist(start, end);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: visibleTeams.length,
                        itemBuilder: (context, index) {
                          var teamData = visibleTeams[index];
                          int globalIndex = start + index;
                          bool isTopThree = globalIndex < 3;

                          return AnimatedContainer(
                            height: 70,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1A237E).withOpacity(0.9),
                                  Colors.blue[900]!.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 3),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _getRankColor(globalIndex),
                                      _getRankColor(globalIndex)
                                          .withOpacity(0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getRankColor(globalIndex)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    isTopThree
                                        ? _getRankEmoji(globalIndex)
                                        : (globalIndex + 1).toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTopThree ? 20 : 16,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                teamData['teamName'] ?? "Unknown Team",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Week points: ${teamData['weeklyPoints'] ?? 0}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.amber[600]!,
                                      Colors.amber[700]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "${teamData['totalPoints'] ?? 0}p",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TeamDetailsScreen(teamData),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (currentPage > 0)
                            HoverButton(
                              size: const Size(50, 30),
                              onPressed: () => setState(() => currentPage--),
                              child: const Text(
                                "Previous",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Text(
                            "Page ${currentPage + 1} of $totalPages",
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          if (currentPage < totalPages - 1)
                            HoverButton(
                              size: const Size(50, 30),
                              onPressed: () => setState(() => currentPage++),
                              child: const Text(
                                "Next",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Emoji för topp 3
  String _getRankEmoji(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '';
    }
  }

  /// 🔹 Färg för rank-badge
  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}
