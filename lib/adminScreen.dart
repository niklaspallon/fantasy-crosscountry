// 🏁 Sportig & strukturerad Adminpanel med tydlig layout och visuella sektioner
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_fls/team_details_handler.dart';
import 'package:real_fls/week_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teamProvider.dart';
import 'updatePoints.dart';
import 'fetch_from_fis.dart';
import 'package:intl/intl.dart';

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
            const Text("Här kan du hantera tävlingar, poäng och veckodata",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            _adminCard(
              context,
              icon: Icons.flag,
              title: "Tävlingar & Resultat",
              child: AddCompetitionsResultsWidget(),
            ),
            _adminCard(
              context,
              icon: Icons.person,
              title: "Skidåkare",
              child: ElevatedButton(
                onPressed: () async {
                  await updateAllSkiersTotalPoints();
                  _snack(context, "✅ Skidåkares totalpoäng uppdaterade!");
                },
                child: const Text("Uppdatera åkares totalpoäng"),
              ),
            ),
            _adminCard(
              context,
              icon: Icons.groups,
              title: "Lag",
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700),
                    onPressed: () async {
                      final confirmed = await _confirmDangerousAction(context,
                          "Denna åtgärd uppdaterar lagens TOTALPOÄNG permanent. Är du säker?");
                      if (confirmed) {
                        await updateAllTeamsTotalPoints();
                        _snack(context, "✅ Lagens totalpoäng uppdaterade!");
                      }
                    },
                    child: const Text(
                        "❗ Uppdatera lagens totalpoäng (efter sista tävling)"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await updateAllTeamsWeeklyPoints();
                      _snack(context, "✅ Lagens veckopoäng uppdaterade!");
                    },
                    child: const Text("Uppdatera lagens veckopoäng"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await undoAllTeamsTotalPoints();
                      _snack(context,
                          "🗑️ Veckopoäng togs bort från lagens totalpoäng!");
                    },
                    child: const Text(
                        "Ångra lagens totalpoäng, med dess veckopoäng"),
                  ),
                ],
              ),
            ),
            _adminCard(
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
            _adminCard(
              context,
              icon: Icons.event,
              title: "Skapa ny spelvecka",
              child: NewWeekWidget(),
            ),
            _adminCard(
              context,
              icon: Icons.delete_forever,
              title: "Radera tävlingsresultat",
              child: RemoveCompAndPoints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(BuildContext context,
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            "Lägg till tävlingsresultat",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedCompetition,
            items: competitionOptions
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
            decoration: const InputDecoration(labelText: "Välj tävling"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _compURLController,
            decoration: const InputDecoration(
              labelText: "Länk till tävling (FIS)",
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
                await fetchAndSetCompetitionPoints(
                    selectedCompetition!, compURL);

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
        ],
      ),
    );
  }
}

class NewWeekWidget extends StatefulWidget {
  NewWeekWidget({super.key});

  @override
  State<NewWeekWidget> createState() => _NewWeekState();
}

class _NewWeekState extends State<NewWeekWidget> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime? selectedDeadline;

  String selectedGender = "Women";
  String selectedStyle = "Classic";
  String selectedType = "Sprint";

  List<String> competitions = [];

  final List<String> styles = ["Classic", "Free"];
  final List<String> genders = ["Women", "Men"];
  final List<String> raceTypes = [
    "Sprint",
    "10 KM Individual",
    "15 KM Individual",
    "20 KM Individual",
    "30 KM Mass start",
    "50 KM Mass start",
    "Skiathlon",
    "Teamsprint",
    "Pursuit",
    "Relay",
  ];

  /// 🔹 Datumväljare
  Future<void> _pickDeadline() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDeadline = pickedDate;
      });
    }
  }

  /// 🔹 Hämta tid från input
  DateTime? _getTimeFromInput() {
    if (_timeController.text.isEmpty || selectedDeadline == null) return null;

    try {
      final timeParts = _timeController.text.split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(
        selectedDeadline!.year,
        selectedDeadline!.month,
        selectedDeadline!.day,
        hour,
        minute,
      );
    } catch (e) {
      return null;
    }
  }

  void _addCompetition() {
    final String comp = "$selectedGender's $selectedType $selectedStyle";
    if (!competitions.contains(comp)) {
      setState(() {
        competitions.add(comp);
      });
    }
  }

  void _removeCompetition(String comp) {
    setState(() {
      competitions.remove(comp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🆕 Skapa ny spelvecka",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: "Tävlingsplats"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickDeadline,
            child: const Text("Välj deadline 📅"),
          ),
          if (selectedDeadline != null)
            Text(
              "Valt datum: ${DateFormat('yyyy-MM-dd').format(selectedDeadline!)}",
              style: const TextStyle(fontSize: 16),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _timeController,
            decoration: const InputDecoration(
              labelText: "Tid (HH:mm)",
              hintText: "Ex: 18:30",
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Text("📋 Lägg till tävling", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              DropdownButton<String>(
                value: selectedGender,
                items: genders
                    .map((gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) => setState(() => selectedGender = value!),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedStyle,
                items: styles
                    .map((style) =>
                        DropdownMenuItem(value: style, child: Text(style)))
                    .toList(),
                onChanged: (value) => setState(() => selectedStyle = value!),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: selectedType,
                items: raceTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => selectedType = value!),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addCompetition,
                child: const Text("➕ Lägg till"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: competitions
                .map((comp) => Chip(
                      label: Text(comp),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => _removeCompetition(comp),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              final location = _locationController.text.trim();
              final fullDeadline = _getTimeFromInput();

              if (location.isEmpty ||
                  fullDeadline == null ||
                  competitions.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text("❌ Fyll i plats, deadline, tid och tävlingar!")));
                return;
              }

              incrementWeek(context, location, fullDeadline, competitions);

              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Ny spelvecka skapad!")));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700),
            child: const Text("🚀 Skapa ny vecka"),
          ),
        ],
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
  final TextEditingController _compNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Column(
        children: [
          TextField(
            controller: _compNameController,
            decoration:
                InputDecoration(hintText: "Namn på tävlingen som ska tas bort"),
          ),
          ElevatedButton(
            onPressed: () async {
              String compName = _compNameController.text;
              if (compName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Fyll i tävlingsnamnet!")),
                );
                return;
              }

              await undoCompetitionPoints(compName);
            },
            child: const Text("Radera tävlingspoäng"),
          ),
        ],
      ),
    );
  }
}
