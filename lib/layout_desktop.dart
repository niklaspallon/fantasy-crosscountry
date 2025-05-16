import 'package:flutter/material.dart';
import 'main.dart';
import 'loginScreen.dart';
import 'leaderboard_screen.dart';
import 'adminScreen.dart';
import 'button_design.dart';

class LayoutDesktop extends StatelessWidget {
  final String teamName;
  final int gameWeek;
  final String? deadline;
  final bool isAdmin;

  const LayoutDesktop({
    super.key,
    required this.teamName,
    required this.gameWeek,
    required this.deadline,
    required this.isAdmin,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              teamName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                "Gameweek: $gameWeek",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer,
                    size: 18,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Deadline: $deadline",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
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
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    leaderboardWidget(context),
                    const SizedBox(width: 8),
                    HoverButton(
                      text: "Mini Leagues",
                      onPressed: () {
                        // 👷 Kommer snart...
                      },
                    ),
                    const SizedBox(width: 8),
                    saveTeam(context),
                    const SizedBox(width: 8),
                    logoutWidget(context),
                    const SizedBox(width: 8),
                    if (isAdmin)
                      HoverButton(
                        text: "Admin",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminScreen()),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  totalTeamPointsWidget(context),
                  budgetWidget(context),
                  weekPoints(context),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 0, 120, 12, 10, 10),
                          skierContainer(context, 1, 120, 12, 10, 10),
                          skierContainer(context, 2, 120, 12, 10, 10),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 3, 120, 12, 10, 10),
                          skierContainer(context, 4, 120, 12, 10, 10),
                          skierContainer(context, 5, 120, 12, 10, 10),
                        ],
                      ),
                      const SizedBox(height: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
