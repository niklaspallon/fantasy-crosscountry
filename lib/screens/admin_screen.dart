import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_fls/designs/button_design.dart';
import 'package:real_fls/handlers/team_details_handler.dart';
import 'package:real_fls/handlers/week_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_fls/screens/admin_new_week_screen.dart';
import 'package:real_fls/screens/admin_remove_data.dart';
import '../providers/team_provider.dart';
import '../handlers/update_points.dart';
import '../services/fetch_from_fis.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../handlers/leaderboard_handler.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isAdmin = context.watch<TeamProvider>().isAdmin;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Åtkomst nekad")),
        body: const Center(
            child: Text("🚫 Du har inte behörighet att se denna sida.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("🏁 Adminpanel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Adminpanel",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                HoverButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminNewWeekScreen()),
                    );
                  },
                  text: "Skapa Ny Tävlingsvecka",
                ),
                SizedBox(
                  width: 10,
                ),
                HoverButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AdminRemoveData()),
                    );
                  },
                  text: "Återställ Poäng",
                ),
              ],
            ),
            const SizedBox(height: 20),
            adminCard(
              context,
              icon: Icons.flag,
              title: "Distans - Tävlingar & Resultat",
              child: const AddCompetitionsResultsWidget(),
            ),
            adminCard(
              context,
              icon: Icons.flag,
              title: "SPRINT Tävlingar & Resultat",
              child: const AddSprintResultsWidget(),
            ),
            adminCard(
              context,
              icon: Icons.groups,
              title: "Lag",
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow.shade700),
                    onPressed: () async {
                      final confirmed = await _confirmDangerousAction(context,
                          "Denna åtgärd uppdaterar lagens TOTALPOÄNG.");
                      if (confirmed) {
                        List<String> feedback =
                            await updateAllTeamsTotalPoints();

                        await showPointsFeedback(
                          context,
                          title: "Uppdatering av totalpoäng",
                          messages: feedback,
                        );
                        _snack(context, "✅ Lagens totalpoäng uppdaterade!");
                      }
                    },
                    child: const Text(" Uppdatera lagens totalpoäng"),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                      " Bäst att uppdatera totalpoängen en stund efter fis-resultaten är typ helt klara \n"
                      "så ingen blir diskad eller liknande. Måste man ändå ångra lagens total poäng så går det men enklast att undvika \n"
                      "för att minska risken för bugg, dock ska det fungera till 100% så var inte rädd att göra det."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await updateAllTeamsWeeklyPoints(true);
                      _snack(context, "✅ Lagens veckopoäng uppdaterade!");
                    },
                    child: const Text("Uppdatera lagens veckopoäng"),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            adminCard(
              context,
              icon: Icons.leaderboard,
              title: "Leaderboard Cache",
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await cacheTemporaryLeaderboard();
                      _snack(context, "💾 Temporär leaderboard cachad!");
                    },
                    child: const Text("TEMP Cachea leaderboard"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final confirmed = await _confirmDangerousAction(context,
                          "Denna åtgärd sparar den totala leaderboarden för hela veckan");
                      if (confirmed) {
                        await finalizeLeaderboardCache();
                        _snack(context, "📌 Permanent leaderboard sparad!");
                      }
                    },
                    child: const Text("CACHEA slutgiltig leaderboard"),
                  ),
                ],
              ),
            ),
            adminCard(
              context,
              icon: Icons.person,
              title: "Skidåkare",
              child: ElevatedButton(
                onPressed: () async {
                  await updateAllSkiersTotalPoints();
                  _snack(context, "✅ Skidåkares totalpoäng uppdaterade!");
                },
                child: const Text(
                    "Uppdatera åkares totalpoäng - körs automatiskt när du lägger till ett resultat"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AddCompetitionsResultsWidget extends StatefulWidget {
  const AddCompetitionsResultsWidget({super.key});

  @override
  State<AddCompetitionsResultsWidget> createState() =>
      _AddCompetitionsResultsState();
}

class _AddCompetitionsResultsState extends State<AddCompetitionsResultsWidget> {
  final TextEditingController _compURLController = TextEditingController();
  List<String> competitionOptions = [];
  String? selectedCompetition;

  @override
  void initState() {
    super.initState();
    fetchDefinedCompetitions();
  }

  Future<void> fetchDefinedCompetitions() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      int currentWeek = await getCurrentWeek();

      DocumentSnapshot doc =
          await db.collection('gameData').doc('currentWeek').get();

      if (doc.exists &&
          (doc.data() as Map<String, dynamic>).containsKey('competitions')) {
        List<dynamic> comps = doc.get('competitions');
        setState(() {
          competitionOptions = comps.cast<String>();
        });
      } else {
        print("⚠️ Inga tävlingar definierade för aktuell vecka.");
      }
    } catch (e) {
      print("❌ Fel vid hämtning av competitions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lägg till distans-tävlingsresultat",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedCompetition,
            items: competitionOptions
                .where((comp) => !comp
                    .toLowerCase()
                    .contains('sprint')) // <-- filtrera bort sprint
                .map((comp) => DropdownMenuItem(
                      value: comp,
                      child: Text(comp),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCompetition = value;
              });
            },
            decoration:
                const InputDecoration(labelText: "Välj distans-tävling"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _compURLController,
            decoration: const InputDecoration(
              labelText: "Länk till distans-tävling (FIS)",
              hintText: "https://www.fis-ski.com/...",
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              String compURL = _compURLController.text.trim();

              if (selectedCompetition == null || compURL.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Välj tävling och fyll i länk!"),
                  ),
                );
                return;
              }

              try {
                // Hämta resultatet från fetchAndSetCompetitionPoints
                final result = await fetchAndSetCompetitionPoints(
                    selectedCompetition!, compURL);
// Dela strängen på radbrytningar för att få en lista av strängar
                final List<String> resultLines = result;

// Skicka listan till dialogen
                showResultsDialog(context, resultLines);

                await syncSkierPointsToWeeklyTeams();
                await updateAllSkiersTotalPoints();
                await updateAllTeamsWeeklyPoints(true);
                await updateAllTeamsTotalPoints();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Alla Funktioner har körts"),
                    duration: const Duration(days: 1),
                    action: SnackBarAction(
                      label: "Stäng",
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Fel: $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Uppdatera tävlingspoäng"),
          ),
          ElevatedButton(
              onPressed: () {
                syncSkierPointsToWeeklyTeams();
              },
              child: Text(
                  "synka med lagens map poäng - denna körs automatiskt när du lägger till distansresultat"))
        ],
      ),
    );
  }
}

class AddSprintResultsWidget extends StatefulWidget {
  const AddSprintResultsWidget({super.key});

  @override
  State<AddSprintResultsWidget> createState() => _AddSprintResultsState();
}

class _AddSprintResultsState extends State<AddSprintResultsWidget> {
  final TextEditingController _compURLController = TextEditingController();
  List<String> competitionOptions = [];
  String? selectedCompetition;

  @override
  void initState() {
    super.initState();
    fetchDefinedCompetitions();
  }

  Future<void> fetchDefinedCompetitions() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      int currentWeek = await getCurrentWeek();

      DocumentSnapshot doc =
          await db.collection('gameData').doc('currentWeek').get();

      if (doc.exists &&
          (doc.data() as Map<String, dynamic>).containsKey('competitions')) {
        List<dynamic> comps = doc.get('competitions');
        setState(() {
          competitionOptions = comps.cast<String>();
        });
      } else {
        print("⚠️ Inga tävlingar definierade för aktuell vecka.");
      }
    } catch (e) {
      print("❌ Fel vid hämtning av competitions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lägg till sprint-tävlingsresultat",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedCompetition,
            items: competitionOptions
                .where((comp) => comp
                    .toLowerCase()
                    .contains('sprint')) // <-- filtrera bort sprint
                .map((comp) => DropdownMenuItem(
                      value: comp,
                      child: Text(comp),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCompetition = value;
              });
            },
            decoration: const InputDecoration(labelText: "Välj sprint-tävling"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _compURLController,
            decoration: const InputDecoration(
              labelText: "Länk till sprinttävling (FIS)",
              hintText: "https://www.fis-ski.com/...",
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              String compURL = _compURLController.text.trim();

              if (selectedCompetition == null || compURL.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Välj sprinttävling och fyll i länk!"),
                  ),
                );
                return;
              }

              try {
                final result = await sprintfetchAndSetCompetitionPoints(
                    selectedCompetition!, compURL);
// Dela strängen på radbrytningar för att få en lista av strängar
                final List<String> resultLines = result;

// Skicka listan till dialogen
                showResultsDialog(context, resultLines);
                await updateAllTeamsWeeklyPoints(true);
                await syncSkierPointsToWeeklyTeams();
                await updateAllSkiersTotalPoints();
                await updateAllTeamsWeeklyPoints(true);
                await updateAllTeamsTotalPoints();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Tävlingspoäng uppdaterade!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Fel: $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Uppdatera tävlingspoäng"),
          ),
          ElevatedButton(
              onPressed: () {
                syncSkierPointsToWeeklyTeams();
              },
              child: const Text(
                  "synka med lagens map poäng - denna körs automatiskt när du lägger till sprintresultat"))
        ],
      ),
    );
  }
}

Widget adminCard(BuildContext context,
    {required IconData icon, required String title, required Widget child}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700),
              const SizedBox(width: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirmDangerousAction(
    BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("⚠️ Bekräfta åtgärd"),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Avbryt")),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Jag är säker")),
          ],
        ),
      ) ??
      false;
}

void showResultsDialog(BuildContext context, List<String> results) {
  // Separera på hittade vs ej hittade
  final found = results.where((r) => !r.contains("Hittades EJ")).toList();
  final notFound = results.where((r) => r.contains("Hittades EJ")).toList();

  // Slå ihop så att hittade först
  final sortedResults = [...found, ...notFound];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Resultat från poänguppdatering"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.separated(
          itemCount: sortedResults.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final line = sortedResults[index];
            final isNotFound = line.contains("Hittades EJ");

            return Text(
              line,
              style: TextStyle(
                color: isNotFound ? Colors.red : Colors.black,
                fontWeight: isNotFound ? FontWeight.bold : FontWeight.normal,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Stäng"),
        ),
      ],
    ),
  );
}

Future<void> showPointsFeedback(
  BuildContext context, {
  required String title,
  required List<String> messages,
}) async {
  // Visa dialogen
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(messages[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Stäng"),
          ),
        ],
      );
    },
  );
}
