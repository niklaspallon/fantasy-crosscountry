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
      title: 'FANTASY CROSS COUNTRY',
      home: MyHome(),
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

  if (userTeam.isNotEmpty) {}

  // Filtrera åkare baserat på gender (uppdaterad logik)
  final femaleSkiers = userTeam
      .where((skier) =>
          skier['gender']?.toString().toLowerCase() == 'female' ||
          skier['gender']?.toString().toLowerCase() == 'kvinna')
      .toList();

  final maleSkiers = userTeam
      .where((skier) =>
          skier['gender']?.toString().toLowerCase() == 'male' ||
          skier['gender']?.toString().toLowerCase() == 'man')
      .toList();

  // Välj rätt lista och index baserat på position
  final List<Map<String, dynamic>> filteredTeam =
      index < 3 ? femaleSkiers : maleSkiers;
  final int adjustedIndex = index < 3 ? index : index - 3;

  final bool hasPlayer = adjustedIndex < filteredTeam.length;
  final skierId = hasPlayer ? filteredTeam[adjustedIndex]['id'] : null;
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
                        showQuickActionOverlay(
                            context, skierId, position, contSize);
                      },
                      containerSize: contSize,
                      child: Container(
                        height: contSize,
                        width: contSize,
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
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: flagWidget(
                                    filteredTeam[adjustedIndex]["country"]),
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
                    );
                  })
                : HoverContainer(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SkierScreen()),
                      );
                    },
                    containerSize: contSize,
                    child: Container(
                      height: contSize,
                      width: contSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A237E),
                            Colors.blue[900]!,
                            Colors.blue[800]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
            if (hasPlayer)
              captainId.toString() == skierId.toString()
                  ? Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
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
                        child: const Center(
                          child: Text(
                            "C",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ))
                  : const Text(""),
          ],
        ),
        const SizedBox(height: 8),
        hasPlayer
            ? Container(
                height: contSize * 0.6,
                width: contSize * 0.7,
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
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasPlayer) ...[
                      AutoSizeText(
                        filteredTeam[adjustedIndex]["name"]
                            .split(" ")
                            .first
                            .toUpperCase(),
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
                        filteredTeam[adjustedIndex]["country"].toUpperCase(),
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
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber[700]!,
                              Colors.amber[900]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          "${filteredTeam[adjustedIndex]["price"]}M",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: priceSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : SizedBox(height: contSize * 0.6),
      ],
    ),
  );
}

Widget budgetWidget(BuildContext context) {
  double totalBudget = context.watch<TeamProvider>().totalBudget;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 70,
      width: 100,
      decoration: reusableBoxDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Budget",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$totalBudget M",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget totalTeamPointsWidget(BuildContext context) {
  int teamTotalPoints = context.watch<TeamProvider>().teamTotalPoints;
  return Padding(
    padding: const EdgeInsets.all(10.0),
    child: Container(
      height: 70,
      width: 100,
      decoration: reusableBoxDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Points",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$teamTotalPoints",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget leaderboardWidget(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: HoverButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeaderboardScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFF1A237E),
      child: const Text(
        "Leaderboard",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}

Widget saveTeam(BuildContext context) {
  String captain = context.watch<TeamProvider>().captain;
  DateTime? deadline = context.watch<TeamProvider>().weekDeadline;
  bool hasDeadlinePassed = false;
  bool hasTeamChanged = context.watch<TeamProvider>().hasTeamChanged;

  if (deadline != null) {
    if (deadline.isBefore(DateTime.now())) {
      hasDeadlinePassed = true;
    }
  }

  return hasDeadlinePassed
      ? Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            height: 50,
            width: 150,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Deadline passed",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        )
      : Padding(
          padding: const EdgeInsets.all(4.0),
          child: HoverButton(
            onPressed: () {
              if (captain.isEmpty) {
                showAlertDialog(context, "Ingen kapten vald",
                    "Du måste väja en kapten för att spara lag");
              } else {
                context.read<TeamProvider>().saveTeamToFirebase(context);
              }
            },
            backgroundColor: hasTeamChanged ? Colors.red : Color(0xFF1A237E),
            child: Text(
              "Save Team",
              style: TextStyle(
                color: hasTeamChanged ? Colors.red : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
}

Widget logoutWidget(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: HoverButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFF1A237E),
      child: const Text(
        "Logga ut",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}

Widget weekPoints(BuildContext context) {
  int weekPoints = context.watch<TeamProvider>().weekPoints;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 70,
      width: 100,
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Weekly Points",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$weekPoints",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget showUpcomingEvents(BuildContext context) {
  List<String> upcomingEvents = context.watch<TeamProvider>().upcomingEvents;
  int currentWeek = context.watch<TeamProvider>().currentWeek;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 200,
      width: 300, // Fixed height for the container
      decoration: reusableBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Competitions GW $currentWeek',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12),
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  upcomingEvents[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget miniLeague(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: HoverButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MiniLeagueScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFF1A237E),
      child: const Text(
        "Mini League",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}

Widget adminWidget(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: HoverButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFF1A237E),
      child: const Text(
        "Admin",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );
}

Widget sidebar(BuildContext context) {
  bool isAdmin = context.watch<TeamProvider>().isAdmin;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: reusableBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Menu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          logoutWidget(context),
          leaderboardWidget(context),
          miniLeague(context),
          isAdmin ? adminWidget(context) : const SizedBox.shrink(),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
