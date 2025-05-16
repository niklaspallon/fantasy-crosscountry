import 'package:flutter/material.dart';
import 'package:real_fls/mini_league_screen.dart';
import 'main.dart';
import 'loginScreen.dart';
import 'leaderboard_screen.dart';
import 'adminScreen.dart';

class LayoutMobile extends StatelessWidget {
  final String teamName;
  final int gameWeek;
  final String? deadline;
  final bool isAdmin;

  const LayoutMobile({
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
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                teamName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "GW: $gameWeek",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.timer,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      deadline ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.lightBlue),
              child: Text("Meny", style: TextStyle(fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text("Leaderboard"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeaderboardScreen(),
                    ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text("Miniliga (Kommer snart)"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MiniLeagueScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logga ut"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(),
                    ));
              },
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text("Admin"),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminScreen(),
                      ));
                },
              ),
          ],
        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          skierContainer(context, 0, 95, 8, 7, 8),
                          skierContainer(context, 1, 95, 8, 7, 8),
                          skierContainer(context, 2, 95, 8, 7, 8),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 3, 95, 8, 7, 8),
                          skierContainer(context, 4, 95, 8, 7, 8),
                          skierContainer(context, 5, 95, 8, 7, 8),
                        ],
                      ),
                      const SizedBox(height: 3),
                      saveTeam(context),
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
