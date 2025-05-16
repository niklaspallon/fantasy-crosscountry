import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:real_fls/mini_league_details_screen.dart';

import 'teamProvider.dart';
import 'mini_league_handler.dart';
import 'button_design.dart';
import 'main.dart'; // för leaderboardWidget

class MiniLeagueScreen extends StatefulWidget {
  const MiniLeagueScreen({super.key});

  @override
  State<MiniLeagueScreen> createState() => _MiniLeagueScreenState();
}

class _MiniLeagueScreenState extends State<MiniLeagueScreen> {
  final TextEditingController leagueNameController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _leagues = [];

  @override
  void initState() {
    super.initState();
    fetchLeagues();
  }

  Future<void> fetchLeagues() async {
    final userId = context.read<TeamProvider>().ownerId;
    final leagues = await getLeaguesForUser(userId);
    setState(() {
      _leagues = leagues;
    });
  }

  Future<void> handleCreateLeague() async {
    final name = leagueNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❗ Ange ett namn för ligan")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final created = await createMiniLeagueWithAutoCode(
      leagueName: name,
      createdByUid: FirebaseAuth.instance.currentUser!.uid,
      createdAt: DateTime.now(),
    );

    if (created) {
      leagueNameController.clear();
      await fetchLeagues(); // Uppdatera UI med nya ligan
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ '$name' skapades!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Misslyckades att skapa liga")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String code = "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Miniligor"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("bilder/backgrund.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leaderboardWidget(context),
                  const SizedBox(height: 20),
                  const Text(
                    "Skapa en ny miniliga",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: leagueNameController,
                    decoration: const InputDecoration(
                      labelText: "Ligans namn",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : HoverButton(
                          onPressed: handleCreateLeague,
                          backgroundColor: Colors.green,
                          text: "Skapa Miniliga",
                        ),
                  const SizedBox(height: 30),
                  const Text(
                    "Dina miniligor",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._leagues.map((league) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MiniLeagueDetailScreen(
                                code: league['code'], // eller doc.id
                                leagueName: league['name'], // namn
                              ),
                            ),
                          );
                          print(league['id']);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              league['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text("${league['teamsCount']} lag"),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
