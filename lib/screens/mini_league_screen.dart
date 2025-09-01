import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_fls/screens/mini_league_details_screen.dart';
import '../providers/team_provider.dart';
import '../handlers/mini_league_handler.dart';
import '../designs/appbar_design.dart';

class MiniLeagueScreen extends StatefulWidget {
  const MiniLeagueScreen({super.key});

  @override
  State<MiniLeagueScreen> createState() => _MiniLeagueScreenState();
}

class _MiniLeagueScreenState extends State<MiniLeagueScreen> {
  // Håller koll på ligorna
  List<Map<String, dynamic>> joinedLeagues = [];

  @override
  void initState() {
    super.initState();
    _loadJoinedLeagues();
  }

  Future<void> _loadJoinedLeagues() async {
    final leagues =
        await fetchJoinedLeagues(context.read<TeamProvider>().ownerId!);
    setState(() {
      joinedLeagues = leagues;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StandardAppBar(
        title: 'Mini Leagues',
      ),
      body: Stack(
        children: [
          // Bakgrundsbild
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/skitracks_back.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 500,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // Lista med ligor
                    JoinedLeagues(
                      leagues: joinedLeagues, // Skickar in den lokala listan
                    ),
                    const SizedBox(height: 10),

                    JoinLeague(),
                    const SizedBox(height: 10),

                    // Skapa liga med callback
                    CreateMiniLeague(
                      onLeagueCreated: (newLeague) {
                        setState(() {
                          joinedLeagues.add(newLeague);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JoinLeague extends StatelessWidget {
  final TextEditingController controller = TextEditingController();

  JoinLeague({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = context.read<TeamProvider>().ownerId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E).withOpacity(0.9),
            Colors.blue[900]!.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Join League",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: "Enter league code",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.amber,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                controller.text.isNotEmpty && controller.text.length == 6
                    ? joinMiniLeague(
                        context: context,
                        leagueCode: controller.text,
                        userId: userId!)
                    : ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            controller.text.isEmpty
                                ? 'League code cannot be empty.'
                                : 'League code must be 6 characters.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Join League with code",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateMiniLeague extends StatelessWidget {
  final void Function(Map<String, dynamic> league) onLeagueCreated;

  CreateMiniLeague({super.key, required this.onLeagueCreated});

  final TextEditingController _leagueNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Create League Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E).withOpacity(0.9),
                Colors.blue[900]!.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create New League",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _leagueNameController,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: "Enter league name",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.amber,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = _leagueNameController.text;

                    if (name.isEmpty || name.length < 3 || name.length > 30) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            name.isEmpty
                                ? 'League name cannot be empty.'
                                : 'League name must be between 3 and 30 characters.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Skapa ligan och vänta på resultat
                    final newLeague = await createLeague(
                      leagueName: name,
                      userId: context.read<TeamProvider>().ownerId!,
                      context: context,
                    );

                    // Om ligan skapades, uppdatera UI med nya ligan
                    if (newLeague != null) {
                      onLeagueCreated(
                          newLeague); // <-- här måste du ha en callback som uppdaterar UI
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "CREATE LEAGUE",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class JoinedLeagues extends StatelessWidget {
  final List<Map<String, dynamic>> leagues;

  const JoinedLeagues({super.key, required this.leagues});

  @override
  Widget build(BuildContext context) {
    if (leagues.isEmpty) {
      return const Center(
        child: Text(
          'You are not part of any leagues yet.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E).withOpacity(0.9),
            Colors.blue[900]!.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "Mini Leagues",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leagues.length,
            itemBuilder: (context, index) {
              final league = leagues[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    league['name'] ?? "Unknown League",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    "${league['teamsCount']} teams",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      league['code'] ?? "",
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MiniLeagueDetailScreen(
                          code: league['code'],
                          leagueName: league['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
