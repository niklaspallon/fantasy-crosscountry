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
        title: Text("$teamName, GW: $gameWeek"),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
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
                image: AssetImage("bilder/backgrund.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              deadlineWidget(context),
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
                          skierContainer(context, 0, 90, 12, 10, 8),
                          skierContainer(context, 1, 90, 12, 10, 8),
                          skierContainer(context, 2, 90, 12, 10, 8),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 3, 90, 12, 10, 8),
                          skierContainer(context, 4, 90, 12, 10, 8),
                          skierContainer(context, 5, 90, 12, 10, 8),
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
