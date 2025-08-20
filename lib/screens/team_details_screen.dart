import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/screen_utils.dart';
import '../providers/team_provider.dart';
import '../handlers/team_details_handler.dart';
import '../designs/flags.dart';
import '../designs/alertdialog_skier.dart';
import 'package:auto_size_text/auto_size_text.dart';

class TeamDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> teamData;

  const TeamDetailsScreen(this.teamData, {Key? key}) : super(key: key);

  @override
  _TeamDetailsScreenState createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  late int selectedWeek;
  final Map<int, List<Map<String, dynamic>>> skierCache = {};
  final Map<int, int> weekPointsCache = {};

  @override
  void initState() {
    super.initState();
    selectedWeek = context.read<TeamProvider>().currentWeek;
  }

  void _changeWeek(int newWeek) {
    setState(() {
      selectedWeek = newWeek;
    });
  }

  Future<List<Map<String, dynamic>>> getSkierData(
      String teamId, int week) async {
    if (skierCache.containsKey(week)) return skierCache[week]!;
    final result = await getTeamSkiersWithPoints(teamId, week, context);
    skierCache[week] = result;
    return result;
  }

  Future<int> getWeekPoints(String teamId, int week) async {
    if (weekPointsCache.containsKey(week)) return weekPointsCache[week]!;
    final result = await getWeeklyTeamPoints(teamId, week);
    weekPointsCache[week] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final String? teamId = widget.teamData['teamId'];

    if (teamId == null || teamId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Ingen lagdata")),
      );
    }

    final skierFuture = getSkierData(teamId, selectedWeek);
    final weekPointsFuture = getWeekPoints(teamId, selectedWeek);
    final screenSize = ScreenUtils.size(context);

    return buildScaffold(
      context,
      teamId,
      screenSize,
      skierFuture,
      weekPointsFuture,
    );
  }

  Widget buildScaffold(
    BuildContext context,
    String teamId,
    ScreenSize screenSize,
    Future<List<Map<String, dynamic>>> skierFuture,
    Future<int> weekPointsFuture,
  ) {
    double containerSize, nameSize, countrySize, containerHeightRatio;

    switch (screenSize) {
      case ScreenSize.sm:
        containerSize = 100.0;
        nameSize = 12.0;
        countrySize = 10.0;
        containerHeightRatio = 0.75;
        break;
      case ScreenSize.md:
        containerSize = 120.0;
        nameSize = 14.0;
        countrySize = 12.0;
        containerHeightRatio = 0.70;
        break;
      case ScreenSize.lg:
        containerSize = 140.0;
        nameSize = 16.0;
        countrySize = 14.0;
        containerHeightRatio = 0.55;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.teamData['teamName'] ?? "Okänt lag",
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: skierFuture,
        builder: (context, skierSnapshot) {
          if (skierSnapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          if (skierSnapshot.hasError ||
              !skierSnapshot.hasData ||
              skierSnapshot.data!.isEmpty) {
            return _buildNoDataScreen();
          }

          var skiers = skierSnapshot.data!;

          return Stack(
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: selectedWeek > 1
                            ? () => _changeWeek(selectedWeek - 1)
                            : null,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(
                        "Week $selectedWeek",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: selectedWeek <
                                context.read<TeamProvider>().currentWeek
                            ? () => _changeWeek(selectedWeek + 1)
                            : null,
                        icon: const Icon(Icons.arrow_forward,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildWeekPoints(context, weekPointsFuture),
                            const SizedBox(width: 16),
                            _buildTotalPointsBox(),
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

  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/background.jpg"),
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

  Widget _buildNoDataScreen() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/background.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: const Center(
        child: Text(
          'Inget lag hittades för denna vecka.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPointsBox() {
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
            Icons.emoji_events,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            "Total Points: ${widget.teamData['totalPoints'] ?? 0}",
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
  }

  Widget buildWeekPoints(BuildContext context, Future<int> weekPointsFuture) {
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
                "Week Points: ${snapshot.data ?? 0}",
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
}

// Widget buildWeekPoints(BuildContext context) {
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA000),
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
              style: const TextStyle(
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
