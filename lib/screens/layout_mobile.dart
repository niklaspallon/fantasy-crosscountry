import 'package:flutter/material.dart';
import 'package:real_fls/screens/mini_league_screen.dart';
import '../main.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'admin_screen.dart';
import '../designs/appbar_design.dart';

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
    double contSize = 95;
    double nameSize = 11;
    double countrySize = 7;
    double priceSize = 10;
    return Scaffold(
      appBar: CompactAppBar(
        teamName: teamName,
        gameWeek: gameWeek,
        deadline: deadline,
      ),
      drawer: ThemedDrawer(isAdmin: isAdmin),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/skitracks_back.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          totalTeamPointsWidget(context),
                          budgetWidget(context),
                          weekPoints(context),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 0, contSize, nameSize,
                              countrySize, priceSize),
                          skierContainer(context, 1, contSize, nameSize,
                              countrySize, priceSize),
                          skierContainer(context, 2, contSize, nameSize,
                              countrySize, priceSize),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 3, contSize, nameSize,
                              countrySize, priceSize),
                          skierContainer(context, 4, contSize, nameSize,
                              countrySize, priceSize),
                          skierContainer(context, 5, contSize, nameSize,
                              countrySize, priceSize),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        width: 150,
                        child: saveTeam(context),
                      ),
                      const SizedBox(height: 16),
                      showUpcomingEvents(context),
                      const SizedBox(height: 24),
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
