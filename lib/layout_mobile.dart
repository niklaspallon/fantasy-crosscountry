import 'package:flutter/material.dart';
import 'package:real_fls/mini_league_screen.dart';
import 'main.dart';
import 'loginScreen.dart';
import 'leaderboard_screen.dart';
import 'adminScreen.dart';
import 'appbar_design.dart';

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
      appBar: CompactAppBar(
          teamName: teamName, gameWeek: gameWeek, deadline: deadline),
      drawer: ThemedDrawer(isAdmin: isAdmin),
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
                      SizedBox(
                        height: 50,
                        width: 150,
                        child: saveTeam(context),
                      ),
                      showUpcomingEvents(context),
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

class ThemedDrawer extends StatelessWidget {
  final bool isAdmin;

  const ThemedDrawer({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E).withOpacity(0.95),
              Colors.blue[900]!.withOpacity(0.85),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
              ),
              child: const Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Menu",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, thickness: 1),
            _drawerItem(
              context,
              icon: Icons.leaderboard,
              text: "Leaderboard",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => LeaderboardScreen()));
              },
            ),
            _divider(),
            _drawerItem(
              context,
              icon: Icons.emoji_events,
              text: "Mini Leagues",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MiniLeagueScreen()));
              },
            ),
            _divider(),
            _drawerItem(
              context,
              icon: Icons.logout,
              text: "Logout",
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
            ),
            if (isAdmin) ...[
              _divider(),
              _drawerItem(
                context,
                icon: Icons.admin_panel_settings,
                text: "Admin",
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()));
                },
              ),
            ],
            const Divider(color: Colors.white24, thickness: 1, height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Fantasy Crosscountry 2025",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.amberAccent),
              const SizedBox(width: 12),
              Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(color: Colors.white24, thickness: 1);
}
