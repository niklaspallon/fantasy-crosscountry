import 'package:flutter/material.dart';
import 'main.dart';

import 'adminScreen.dart';
import 'button_design.dart';

class LayoutTablet extends StatelessWidget {
  final String teamName;
  final int gameWeek;
  final String? deadline;
  final bool isAdmin;

  const LayoutTablet({
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text("$teamName", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Gameweek: $gameWeek",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              "Deadline: $deadline",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    leaderboardWidget(context),
                    const SizedBox(width: 8),
                    HoverButton(
                      text: "Miniliga",
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
                          skierContainer(context, 0, 110, 14, 12, 10),
                          skierContainer(context, 1, 110, 14, 12, 10),
                          skierContainer(context, 2, 110, 14, 12, 10),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 3, 110, 14, 12, 10),
                          skierContainer(context, 4, 110, 14, 12, 10),
                          skierContainer(context, 5, 110, 14, 12, 10),
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
