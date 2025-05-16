import 'package:flutter/material.dart';
import 'screen_utils.dart';
import 'flags.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'team_details_handler.dart';
import 'alertdialog_skier.dart';

class TeamDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> teamData;
  final Future<List<Map<String, dynamic>>> skierFuture;
  final Future<int> weekPointsFuture;

  TeamDetailsScreen(this.teamData, BuildContext context)
      : skierFuture = getTeamSkiersWithPoints(
          teamData['teamId'],
          _getInitialWeekToShow(teamData),
          context,
        ),
        weekPointsFuture = getWeeklyTeamPoints(
          teamData['teamId'],
          _getInitialWeekToShow(teamData),
        );

  static int _getInitialWeekToShow(Map<String, dynamic> teamData) {
    // Default to latest week, or fallback if needed
    return teamData['week'] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final String? teamId = teamData['teamId'];

    if (teamId == null || teamId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Okänt lag",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
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
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("bilder/backgrund.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: Text(
              "⚠️ Lagdata saknas!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    final size = ScreenUtils.size(context);
    return buildScaffold(context, teamId, size);
  }

  Widget buildScaffold(
      BuildContext context, String teamId, ScreenSize screenSize) {
    double containerSize, nameSize, countrySize, containerHeightRatio;

    switch (screenSize) {
      case ScreenSize.sm:
        containerSize = 80.0;
        nameSize = 12.0;
        countrySize = 10.0;
        containerHeightRatio = 0.75; // Mindre höjdreduktion för små skärmar
        break;
      case ScreenSize.md:
        containerSize = 100.0;
        nameSize = 14.0;
        countrySize = 12.0;
        containerHeightRatio = 0.70; // Medelstor höjdreduktion för tablets
        break;
      case ScreenSize.lg:
        containerSize = 120.0;
        nameSize = 16.0;
        countrySize = 14.0;
        containerHeightRatio = 0.55; // Större höjdreduktion för stora skärmar
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          teamData['teamName'] ?? "Okänt lag",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: skierFuture,
        builder: (context, skierSnapshot) {
          if (skierSnapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("bilder/backgrund.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }
          if (skierSnapshot.hasError ||
              !skierSnapshot.hasData ||
              skierSnapshot.data!.isEmpty) {
            return Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("bilder/backgrund.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Text(
                  'Inga skidåkare hittades!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          var skiers = skierSnapshot.data!;

          return Stack(
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
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildWeekPoints(context),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Totalpoäng: ${teamData['totalPoints'] ?? 0}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        buildSkierGrid(context, skiers, containerSize, nameSize,
                            countrySize, containerHeightRatio),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildWeekPoints(BuildContext context) {
    return FutureBuilder<int>(
      future: weekPointsFuture,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: Colors.amber,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Veckopoäng: ${snapshot.data ?? 0}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildSkierGrid(
      BuildContext context,
      List<Map<String, dynamic>> skiers,
      double size,
      double nameSize,
      double countrySize,
      double containerHeightRatio) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: skierContainer(context, skiers[0], size, nameSize,
                  countrySize, containerHeightRatio),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: skierContainer(context, skiers[1], size, nameSize,
                  countrySize, containerHeightRatio),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: skierContainer(context, skiers[2], size, nameSize,
                  countrySize, containerHeightRatio),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: skierContainer(context, skiers[3], size, nameSize,
                  countrySize, containerHeightRatio),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: skierContainer(context, skiers[4], size, nameSize,
                  countrySize, containerHeightRatio),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: skierContainer(context, skiers[5], size, nameSize,
                  countrySize, containerHeightRatio),
            ),
          ],
        ),
        const SizedBox(height: 3),
      ],
    );
  }

  Widget skierContainer(
      BuildContext context,
      Map<String, dynamic> skierData,
      double size,
      double nameSize,
      double countrySize,
      double containerHeightRatio) {
    final containerHeight = size * containerHeightRatio;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: flagWidget(skierData["country"]),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1A237E).withOpacity(0.6),
                            Colors.transparent,
                            const Color(0xFF1A237E).withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[600]!,
                      Colors.blue[800]!,
                    ],
                  ),
                  shape: BoxShape.circle,
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
                child: IconButton(
                  icon: const Icon(
                    Icons.info,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () {
                    showSkierInfo(context, skierData["skierId"].toString());
                  },
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
            if (skierData["isCaptain"] == true)
              Positioned(
                bottom: 5,
                left: 7,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFFD700),
                        const Color(0xFFFFA000),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    "C",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: size * 0.6,
          width: size * 0.7,
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                skierData["name"].split(" ").first.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                minFontSize: 8,
                maxFontSize: nameSize,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              AutoSizeText(
                skierData["country"].toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
                minFontSize: 6,
                maxFontSize: countrySize,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
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
            skierData["isCaptain"] == true
                ? "${((skierData["points"] ?? 0) * 2)}"
                : "${skierData["points"] ?? 0}",
            style: TextStyle(
              color: Colors.white,
              fontSize: countrySize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
