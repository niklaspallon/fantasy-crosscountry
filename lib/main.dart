import 'package:flutter/material.dart';
import 'package:real_fls/providers/auth_provider.dart';
import 'package:real_fls/screens/choose_skier_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'providers/team_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/leaderboard_screen.dart';
import 'designs/alertdialog_skier.dart';
import 'screens/admin_screen.dart';
import 'utils/screen_utils.dart';
import 'providers/skiers_provider.dart';
import 'designs/flags.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'designs/button_design.dart';
import 'screens/layout_tablet.dart';
import 'screens/layout_desktop.dart';
import 'screens/layout_mobile.dart';
import 'screens/mini_league_screen.dart';
import 'screens/rules_screen.dart';
import 'handlers/add_skier_to_fb.dart';
import 'handlers/test.dart';
import 'screens/activity_log_screen.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🚀 Startar appen och initierar Firebase...");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("✅ Firebase initierad");
  //addSkiersToFirestore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => SkiersProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fantasy Längdskidor',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const MyHome();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      String? teamName = context.watch<TeamProvider>().teamName;
      int? gameWeek = context.watch<TeamProvider>().currentWeek;
      DateTime? deadline = context.watch<TeamProvider>().weekDeadline;
      String formattedDeadline = deadline != null
          ? DateFormat('d/M, H:mm').format(deadline)
          : "Ingen deadline";
      bool? isAdmin = context.watch<TeamProvider>().isAdmin;

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
            isAdmin: isAdmin,
          );
      }
    } catch (e) {
      print("❌ Fel i MyHome build: $e");
    }

    return const Scaffold(
      body: Center(child: Text("Fel vid bygg av MyHome")),
    );
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
  final weeklySkierPoints =
      hasPlayer ? filteredTeam[adjustedIndex]["totalWeeklyPoints"] ?? 0 : 0;
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
                height: contSize * 0.7,
                width: contSize * 0.8,
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
                            horizontal: 6, vertical: 4),
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
                          "${filteredTeam[adjustedIndex]["marketPrice"] ?? filteredTeam[adjustedIndex]["price"]} M",
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
        hasPlayer
            ? Padding(
                padding: const EdgeInsets.all(
                    3.0), //KAN BLI GEL MED PADDINGEN, TA BORT OM OK
                child: Container(
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
                    height: 25,
                    width: 35,
                    child: Center(
                      child: Text(
                        weeklySkierPoints.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              )
            : const Text(
                "",
              )
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
            "${totalBudget.toStringAsFixed(1)} M",
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
  bool hasCaptainChanged = context.watch<TeamProvider>().hasCaptainChanged;

  if (deadline != null) {
    if (deadline.isBefore(DateTime.now())) {
      hasDeadlinePassed = true;
    }
  }

  return hasDeadlinePassed
      ? Padding(
          padding: const EdgeInsets.all(3.0),
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
            onPressed: () async {
              if (captain.isEmpty) {
                showAlertDialog(context, "Ingen kapten vald",
                    "Du måste välja en kapten för att spara lag");
              } else {
                //context.read<TeamProvider>().saveTeamToFirebase(context);
                await showConfirmAndSaveTeamDialog(
                    context, context.read<TeamProvider>());
              }
            },
            backgroundColor: hasTeamChanged || hasCaptainChanged
                ? Colors.red
                : Color(0xFF1A237E),
            child: Text(
              "Save Team",
              style: TextStyle(
                color: hasTeamChanged || hasCaptainChanged
                    ? Colors.red
                    : Colors.white,
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
      onPressed: () async {
        await context.read<AuthenticProvider>().logout(context);
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

Widget rulesWidget(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(4.0),
    child: HoverButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RulesScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFF1A237E),
      child: const Text(
        "Rules",
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

Widget showUpcomingEvents(BuildContext context, double maxWidth) {
  List<String> upcomingEvents = context.watch<TeamProvider>().upcomingEvents;
  int currentWeek = context.watch<TeamProvider>().currentWeek;
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      height: 200,
      width: maxWidth, // Fixed height for the container
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
          Row(
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.close, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          logoutWidget(context),
          leaderboardWidget(context),
          miniLeague(context),
          rulesWidget(context),
          isAdmin ? adminWidget(context) : const SizedBox.shrink(),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
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
              icon: Icons.emoji_events,
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
              icon: Icons.group,
              text: "Mini Leagues",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MiniLeagueScreen()));
              },
            ),
            _divider(),
            _drawerItem(
              context,
              icon: Icons.rule,
              text: "Rules",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RulesScreen()));
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
              _divider(),
              _drawerItem(
                context,
                icon: Icons.logout,
                text: "Activity Log",
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => ActivityLogScreen()));
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

class TransferSummaryContent extends StatelessWidget {
  final List<Map<String, dynamic>> currentTeam;
  final List<Map<String, dynamic>> lastSavedTeam;
  final int freeTransfers;
  final int numberOfChanges;
  final int paidTransfers;
  final int pointsPerPaidTransfer;

  const TransferSummaryContent({
    required this.currentTeam,
    required this.lastSavedTeam,
    required this.freeTransfers,
    required this.numberOfChanges,
    required this.paidTransfers,
    this.pointsPerPaidTransfer = 40,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    bool unlimitedTransfers = context.watch<TeamProvider>().unlimitedTransfers;

    final currentIds = currentTeam.map((s) => s['id']).toSet();
    final savedIds = lastSavedTeam.map((s) => s['id']).toSet();

    final added =
        currentTeam.where((s) => !savedIds.contains(s['id'])).toList();
    final removed =
        lastSavedTeam.where((s) => !currentIds.contains(s['id'])).toList();
    final usedFreeTransfers = numberOfChanges - paidTransfers;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Transfer Summary",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (added.isNotEmpty) ...[
            const Text("➕ New Skiers:",
                style: TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...added.map(
              (s) => _transferCard(
                name: s['name'],
                country: s['country'],
                color: Colors.green[700]!,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (removed.isNotEmpty) ...[
            const Text("➖ Removed Skiers:",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...removed.map(
              (s) => _transferCard(
                name: s['name'],
                country: s['country'],
                color: Colors.red[700]!,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _summaryRow(Icons.swap_horiz, "Total Transfers", "$numberOfChanges"),
          _summaryRow(Icons.card_giftcard, "Free Transfers",
              unlimitedTransfers ? "∞" : "$usedFreeTransfers"),
          _summaryRow(Icons.monetization_on, "Payed Transfers",
              unlimitedTransfers ? "0" : "$paidTransfers"),
          if (paidTransfers > 0)
            _summaryRow(
                Icons.warning_amber_rounded,
                "Cost",
                unlimitedTransfers
                    ? "0"
                    : "${paidTransfers * pointsPerPaidTransfer} Points",
                color: unlimitedTransfers ? Colors.white : Colors.redAccent),
        ],
      ),
    );
  }

  Widget _transferCard({
    required String name,
    required String country,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                flagWidget(country),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color ?? Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showConfirmAndSaveTeamDialog(
    BuildContext context, TeamProvider teamProvider) async {
  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A237E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(20),
      content: TransferSummaryContent(
        currentTeam: teamProvider.userTeam,
        lastSavedTeam: teamProvider.lastSavedTeam,
        freeTransfers: teamProvider.freeTransfers,
        numberOfChanges: teamProvider.numberOfChanges,
        paidTransfers: teamProvider.paidTransfers,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            "Cancel",
            style: TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Confirm and Save"),
        ),
      ],
    ),
  );

  if (shouldSave == true) {
    final deadline = teamProvider.weekDeadline;
    if (deadline != null && deadline.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Deadline has passed. Cannot save team."),
        ),
      );
      return;
    }
    await teamProvider.saveTeamToFirebase(context);
  }
}
