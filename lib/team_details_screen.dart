import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen_utils.dart';
import 'package:provider/provider.dart';
import 'teamProvider.dart';
import 'flags.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'team_details_handler.dart';
import 'alertdialog_skier.dart';

class TeamDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> teamData;
  final Future<List<Map<String, dynamic>>> skierFuture;
  final Future<int> weekPointsFuture;

  TeamDetailsScreen(this.teamData)
      : skierFuture = getTeamSkiersWithPoints(
          teamData['teamId'],
          _getInitialWeekToShow(teamData),
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
        appBar: AppBar(title: const Text("Okänt lag")),
        body: const Center(child: Text("⚠️ Lagdata saknas!")),
      );
    }

    final size = ScreenUtils.size(context);
    return buildScaffold(context, teamId, size);
  }

  Widget buildScaffold(
      BuildContext context, String teamId, ScreenSize screenSize) {
    double containerSize, nameSize, countrySize;

    switch (screenSize) {
      case ScreenSize.sm:
        containerSize = 60.0;
        nameSize = 12.0;
        countrySize = 10.0;
        break;
      case ScreenSize.md:
        containerSize = 100.0;
        nameSize = 14.0;
        countrySize = 12.0;
        break;
      case ScreenSize.lg:
        containerSize = 120.0;
        nameSize = 16.0;
        countrySize = 14.0;
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(teamData['teamName'] ?? "Okänt lag")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: skierFuture,
        builder: (context, skierSnapshot) {
          if (skierSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (skierSnapshot.hasError ||
              !skierSnapshot.hasData ||
              skierSnapshot.data!.isEmpty) {
            return const Center(child: Text('Inga skidåkare hittades!'));
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
                        buildWeekPoints(context),
                        const SizedBox(height: 10),
                        buildSkierGrid(
                            skiers, containerSize, nameSize, countrySize),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        int weekPoints = snapshot.data ?? 0;

        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            height: 50,
            width: 90,
            decoration: const BoxDecoration(
              color: Colors.lightBlue,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Text(
                      "Veckopoäng",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "$weekPoints",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSkierGrid(List<Map<String, dynamic>> skiers, double size,
      double nameSize, double countrySize) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: skiers.length,
      itemBuilder: (context, index) {
        return skierContainer(
            context, skiers[index], size, nameSize, countrySize);
      },
    );
  }

  Widget skierContainer(BuildContext context, Map<String, dynamic> skierData,
      double size, double nameSize, double countrySize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: flagWidget(skierData["country"]),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: ElevatedButton(
                onPressed: () {
                  showSkierInfo(context, skierData["skierId"].toString());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(0, 0),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.info, size: 16),
              ),
            ),
            skierData["isCaptain"] == true
                ? Positioned(
                    bottom: 5,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.yellow,
                          borderRadius: BorderRadius.circular(90)),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Text("C"),
                      ),
                    ),
                  )
                : const Text(""),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: size - 20,
          width: size,
          decoration: BoxDecoration(
            color: Colors.lightBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                skierData["name"].split(" ").first.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
                minFontSize: 8,
                maxFontSize: nameSize,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              AutoSizeText(
                skierData["country"].toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: countrySize),
                minFontSize: 6,
                maxFontSize: nameSize,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            skierData["isCaptain"] == true
                ? "${((skierData["points"] ?? 0) * 2)}"
                : "${skierData["points"] ?? 0}",
            style:
                TextStyle(fontSize: countrySize, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
