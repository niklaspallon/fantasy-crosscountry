import 'package:flutter/material.dart';
import 'main.dart';
import 'loginScreen.dart';
import 'leaderboard_screen.dart';
import 'adminScreen.dart';
import 'button_design.dart';
import 'mini_league_screen.dart';
import 'appbar_design.dart';

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
      appBar: CustomAppBar(
        teamName: teamName,
        gameWeek: gameWeek,
        deadline: deadline,
      ),
      body: Stack(
        children: [
          // Bakgrundsbild
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
              // Översta rad med info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  totalTeamPointsWidget(context),
                  budgetWidget(context),
                  weekPoints(context),
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vänster sidebar
                    Container(
                      width: 300,
                      height: 400,
                      padding: const EdgeInsets.all(8),
                      child: sidebar(context),
                    ),

                    // Huvudinnehåll
                    Expanded(
                      child: Column(
                        children: [
                          // Övre rad med spelare + events
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              skierContainer(context, 0, 120, 12, 10, 10),
                              skierContainer(context, 1, 120, 12, 10, 10),
                              skierContainer(context, 2, 120, 12, 10, 10),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Nedre rad med spelare
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              skierContainer(context, 3, 120, 12, 10, 10),
                              skierContainer(context, 4, 120, 12, 10, 10),
                              skierContainer(context, 5, 120, 12, 10, 10),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // Spara-knapp
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 200,
                                child: saveTeam(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Högerpanel
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [showUpcomingEvents(context)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
