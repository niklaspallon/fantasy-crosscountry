import 'package:flutter/material.dart';
import 'package:real_fls/authProvider.dart';
import 'package:real_fls/choose_skier_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'loginScreen.dart';
import 'teamProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leaderboard_screen.dart';
import 'alertdialog_skier.dart';
import 'adminScreen.dart';
import 'screen_utils.dart';
import 'skiers_provider.dart';
import 'flags.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart'; // 📅 För att formatera datum
import 'addSkierToFb.dart';
import 'button_design.dart';
import 'layout_tablet.dart';
import 'layout_desktop.dart';
import 'layout_mobile.dart';
import 'mini_league_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //clearSkiersDb();
  //addSkiersToFirestore();
  // Försök att auto-logga in
  User? user = FirebaseAuth.instance.currentUser;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthenticProvider>(
          create: (context) => AuthenticProvider(),
        ),
        ChangeNotifierProvider<TeamProvider>(
          create: (context) => TeamProvider(),
        ),
        ChangeNotifierProvider<SkiersProvider>(
          create: (context) => SkiersProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Fantasy Längdskidor',
        home: user != null ? const MyHome() : const LoginScreen(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FANTASY LÄNGDSKIDOR',
      home: MiniLeagueScreen(),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    String teamName = context.watch<TeamProvider>().teamName;
    int gameWeek = context.watch<TeamProvider>().currentWeek;
    DateTime? deadline = context.watch<TeamProvider>().weekDeadline;
    String formattedDeadline = deadline != null
        ? DateFormat('d/M, H:mm').format(deadline)
        : "Ingen deadline";
    bool isAdmin = context.watch<TeamProvider>().isAdmin;

    final size = ScreenUtils.size(context);

    switch (size) {
      case ScreenSize.sm:
        return LayoutMobile(
          teamName: teamName,
          gameWeek: gameWeek,
          deadline: formattedDeadline,
          isAdmin: isAdmin,
        );
      case ScreenSize.md:
        return LayoutTablet(
          teamName: teamName,
          gameWeek: gameWeek,
          deadline: formattedDeadline,
          isAdmin: isAdmin,
        );
      case ScreenSize.lg:
        return LayoutDesktop(
            teamName: teamName,
            gameWeek: gameWeek,
            deadline: formattedDeadline,
            isAdmin: isAdmin);
    }
  }
}

Widget skierContainer(BuildContext context, int index, double contSize,
    double nameSize, double countrySize, double priceSize) {
  final userTeam = context.watch<TeamProvider>().userTeam;
  final bool hasPlayer = index < userTeam.length;
  final skierId = hasPlayer ? userTeam[index]['id'] : null;
  String captainId = context.watch<TeamProvider>().captain;

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            hasPlayer
                ? Builder(builder: (context) {
                    return HoverContainer(
                      onTap: () {
                        final box = context.findRenderObject() as RenderBox;
                        final position = box.localToGlobal(
                            Offset(box.size.width / 2, box.size.height / 2));
                        showQuickActionOverlay(context, skierId, position);
                      },
                      child: Container(
                        height: contSize,
                        width: contSize,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: flagWidget(userTeam[index]["country"]),
                        ),
                      ),
                    );
                  })
                : HoverContainer(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SkierScreen()),
                      );
                    },
                    child: Container(
                      height: contSize,
                      width: contSize,
                      decoration: BoxDecoration(
                        color:
                            hasPlayer ? Colors.transparent : Colors.lightBlue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black),
                      ),
                      child: const Center(child: Icon(Icons.add, size: 27)),
                    ),
                  ),
            if (hasPlayer)
              captainId.toString() == skierId.toString()
                  ? Positioned(
                      bottom: 3,
                      left: 3,
                      child: Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Padding(
                          padding: EdgeInsets.all(0),
                          child: Center(
                            child: Text(
                              "C",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ))
                  : const Text(""),
          ],
        ),
        hasPlayer
            ? Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  height: contSize - 45,
                  width: contSize,
                  decoration: BoxDecoration(
                    color: Colors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AutoSizeText(
                        userTeam[index]["name"]
                            .split(" ")
                            .first
                            .toUpperCase(), // Tar endast efternamnet och gör det versalt
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        minFontSize: 8, // Minsta storleken
                        maxFontSize: nameSize, // Normala storleken
                        maxLines: 1, // Hindrar att namnet går ner på ny rad
                        overflow:
                            TextOverflow.ellipsis, // Klipper av om det behövs
                      ),
                      Text(
                        userTeam[index]["country"].toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: countrySize),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        "Price ${userTeam[index]["price"]}",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: priceSize),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: contSize - 45,
              ),
        hasPlayer
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber, // Färg för att poängen ska sticka ut
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "${userTeam[index]["points"]}",
                  style: TextStyle(
                      fontSize: countrySize, fontWeight: FontWeight.bold),
                ),
              )
            : const SizedBox(
                // för att kompensera för poängen så alla containrar hamnar på samma nivå
                height: 30,
              ),
      ],
    ),
  );
}

Widget budgetWidget(BuildContext context) {
  double totalBudget = context.watch<TeamProvider>().totalBudget;
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: Container(
      height: 50,
      width: 70,
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
                "Budget",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "$totalBudget",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget deadlineWidget(BuildContext context) {
  DateTime? deadline = context.watch<TeamProvider>().weekDeadline;
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: Container(
      height: 50,
      width: 170,
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
                "Deadline",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              deadline != null
                  ? "${DateFormat('yyyy-MM-dd HH:mm').format(deadline)}"
                  : "Ingen deadline vald",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget totalTeamPointsWidget(BuildContext context) {
  int teamTotalPoints = context.watch<TeamProvider>().teamTotalPoints;
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: Container(
      height: 50,
      width: 70,
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
                "Poäng",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "$teamTotalPoints",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget leaderboardWidget(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: HoverButton(
      text: "Leaderboard",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardScreen(),
          ),
        );
      },
    ),
  );
}

Widget saveTeam(BuildContext context) {
  String captain = context.watch<TeamProvider>().captain;
  return Padding(
    padding: const EdgeInsets.all(4),
    child: HoverButton(
      text: "Save team",
      onPressed: () {
        if (captain == null || captain == "") {
          showAlertDialog(context, "Ingen kapten vald",
              "Du måste väja en kapten för att spara lag");
        } else {
          context.read<TeamProvider>().saveTeamToFirebase(context);
        }
      },
    ),
  );
}

Widget logoutWidget(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(4),
    child: HoverButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(),
            ),
          );
        },
        text: "Log out"),
  );
}

Widget weekPoints(BuildContext context) {
  int weekPoints = context.watch<TeamProvider>().weekPoints;
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "$weekPoints",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}
