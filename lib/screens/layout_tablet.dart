import 'package:flutter/material.dart';
import '../main.dart';
import '../designs/appbar_design.dart';

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
      appBar: CustomAppBar(
        teamName: teamName,
        gameWeek: gameWeek,
        deadline: deadline,
        backArrow: false,
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          totalTeamPointsWidget(context),
                          budgetWidget(context),
                          weekPoints(context),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 0, 110, 12, 10, 10),
                          skierContainer(context, 1, 110, 12, 10, 10),
                          skierContainer(context, 2, 110, 12, 10, 10),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skierContainer(context, 3, 110, 12, 10, 10),
                          skierContainer(context, 4, 110, 12, 10, 10),
                          skierContainer(context, 5, 110, 12, 10, 10),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(width: 150, child: saveTeam(context)),
                      const SizedBox(height: 16),
                      showUpcomingEvents(context),
                      const SizedBox(height: 30),
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
