import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_fls/designs/button_design.dart';
import 'package:real_fls/handlers/team_details_handler.dart';
import 'package:real_fls/handlers/week_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_fls/screens/admin_new_week_screen.dart';
import '../providers/team_provider.dart';
import '../handlers/update_points.dart';
import '../services/fetch_from_fis.dart';
import 'package:intl/intl.dart';
import 'admin_screen.dart';

class AdminRemoveData extends StatelessWidget {
  const AdminRemoveData({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🗑️ Återställ & Radera Data"),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: const Column(
                children: [
                  RemoveCompAndPoints(),
                  SizedBox(height: 24),
                  ResetThisWeekCompsToZero(),
                  SizedBox(height: 24),
                  RemoveTeamTotalPointsWithWeekly(),
                  SizedBox(height: 24),
                  RestorePointsFromCachedLeaderboard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RemoveCompAndPoints extends StatefulWidget {
  const RemoveCompAndPoints({super.key});

  @override
  State<RemoveCompAndPoints> createState() => _RemoveFromCompState();
}

class _RemoveFromCompState extends State<RemoveCompAndPoints> {
  int? selectedWeek;
  int? currentWeek;
  String? selectedCompetition;
  List<String> competitions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initCurrentWeek();
  }

  Future<void> _initCurrentWeek() async {
    final week = await getCurrentWeek();
    setState(() {
      currentWeek = week;
      selectedWeek = week;
    });
    await _fetchCompetitions(week);
  }

  Future<void> _fetchCompetitions(int week) async {
    setState(() {
      isLoading = true;
      competitions = [];
      selectedCompetition = null;
    });
    // Byt ut denna mot din egen funktion som hämtar tävlingar för en vecka:
    final comps = await fetchCompetitionsForWeek(
        week); // Exempel: ["Falun Sprint", "Falun 10km"]
    setState(() {
      competitions = comps;
      selectedCompetition = comps.isNotEmpty ? comps.first : null;
      isLoading = false;
    });
  }

  Future<void> _tryRemoveCompetition() async {
    print("Trying to remove competition körs..");
    if (selectedCompetition == null) return;

    bool warnOtherWeek = selectedWeek != null &&
        currentWeek != null &&
        selectedWeek != currentWeek;
    bool proceed = true;

    if (warnOtherWeek) {
      proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("⚠️ Varning"),
              content: Text(
                  "Du är på väg att ta bort en tävling från vecka $selectedWeek, men nuvarande vecka är $currentWeek. Är du säker?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Avbryt"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Fortsätt"),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (!proceed) return;

    final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Bekräfta borttagning"),
            content: Text(
                "Vill du verkligen ta bort poängen för tävlingen \"$selectedCompetition\" från vecka $selectedWeek?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Avbryt"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Ta bort"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;
    await undoCompetitionPoints(selectedCompetition!);
    await syncSkierPointsToWeeklyTeams(null);
    await updateAllTeamsWeeklyPoints(true);
    await totalPointsSyncDecrease();

    final resultMsg = await undoCompetitionPoints(selectedCompetition!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(resultMsg)),
    );
    // Uppdatera listan efter borttagning
    await _fetchCompetitions(selectedWeek!);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  "Radera tävlingspoäng",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentWeek != null
                  ? "Nuvarande vecka: $currentWeek, \n"
                      "- Tar bort poäng för tävlingen för allt, inkl totalpoäng för skidåkaren \n"
                      "- Även poäng i skiersDb och lagens map \n"
                      "- Tar bort poängen från veckopoängen för alla lag.\n"
                      "- Fixar även lagens totalpoängen \n"
                      "- Tar helt enkelt bort allt du behöver\n"
                  : "Nuvarande vecka: ...",
              style: const TextStyle(
                  color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: selectedCompetition,
                    items: competitions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedCompetition = val),
                    decoration: const InputDecoration(
                      labelText: "Tävling",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    selectedCompetition == null ? null : _tryRemoveCompetition,
                icon: const Icon(Icons.delete),
                label: const Text("Radera tävlingspoäng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetThisWeekCompsToZero extends StatelessWidget {
  const ResetThisWeekCompsToZero({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.red.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text(
                  "Rensa veckodata",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Denna åtgärd raderar alla skidåkares veckodata och lagens veckopoäng för denna vecka \n"
              "även totalpoängen för skidåkare nollställs ",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  int currentWeek = await getCurrentWeek();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("⚠️ Bekräfta radering"),
                      content: Text(
                          "Är du säker på att du vill radera data för vecka $currentWeek?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Avbryt")),
                        TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Radera")),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final msg = await resetWeekPointsData(true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
                icon: const Icon(Icons.delete_sweep),
                label: const Text("Radera veckodata"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RestorePointsFromCachedLeaderboard extends StatefulWidget {
  const RestorePointsFromCachedLeaderboard({super.key});

  @override
  State<RestorePointsFromCachedLeaderboard> createState() =>
      _RestorePointsFromCachedLeaderboardState();
}

class _RestorePointsFromCachedLeaderboardState
    extends State<RestorePointsFromCachedLeaderboard> {
  final TextEditingController _weekController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.yellow.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: const [
                Icon(Icons.refresh, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text(
                  "Återställ poäng från cachad leaderboard",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Denna åtgärd återställer lagens poäng baserat på den valfri cachade leaderboarden. Totalpoäng och veckopoäng för lag kommer att återställas.\n"
              "Även skidåkarna och deras poäng i skiersdb återställs\n",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _weekController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Vecka",
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final week = int.tryParse(_weekController.text.trim());
                  if (week == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("❌ Ange ett giltigt veckonummer!")),
                    );
                    return;
                  }
                  await restoreTeamPointsFromCachedLeaderboard(week);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Poäng återställda!")),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Återställ poäng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<String>> fetchCompetitionsForWeek(int week) async {
  final snap = await FirebaseFirestore.instance
      .collection('gameData')
      .where('weekNumber', isEqualTo: week)
      .limit(1)
      .get();

  if (snap.docs.isEmpty) return [];

  final data = snap.docs.first.data();
  final competitions = data['competitions'];
  if (competitions is List) {
    return competitions.map((e) => e.toString()).toList();
  }
  return [];
}

class RemoveTeamTotalPointsWithWeekly extends StatelessWidget {
  const RemoveTeamTotalPointsWithWeekly({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.yellow.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: const [
                Icon(Icons.refresh,
                    color: Color.fromARGB(255, 197, 58, 134), size: 28),
                SizedBox(width: 8),
                Text(
                  "Subbtrahera lagens totalpoäng med veckopoäng\n"
                  "Borde ej köras läs nedan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Funktionen tar bort veckopoängen från totalpoängen. Det återställer countinTotal i lagen. \n"
              "Men inte weeklypoints, vilket betyder att om man sedan uppdatear veckopoängen så kommer den att adderas igen.\n"
              "Använd Främst vid testning. ",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Bekräfta åtgärd"),
                      content: const Text(
                          "Är du säker på att du vill subtrahera lagens totalpoäng med veckopoängen?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Avbryt"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final feedback =
                                await undoAllTeamsTotalPointsWithWeekly();
                            await showPointsFeedback(
                              context,
                              title: "Borttagning av totalpoäng",
                              messages: feedback,
                            );
                          },
                          child: const Text("Subtrahera"),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Återställ poäng"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 197, 58, 134),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
