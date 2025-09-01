import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_fls/screens/login_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticProvider>(context);
    final TextEditingController teamNameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white), // så back-pilen syns
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/skitracks_back.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: Colors.black
                .withOpacity(0.5), // Svart overlay med 60% transparens
          ),
          // 🔹 Formulär i en centrerad kolumn
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔹 Ikon eller logotyp
                  const Icon(
                    Icons.sports_martial_arts,
                    color: Colors.white,
                    size: 80,
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Titel
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Email TextField
                  Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: TextField(
                      controller: authProvider.emailController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.email, color: Colors.white70),
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Lösenord TextField
                  Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: TextField(
                      controller: authProvider.passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.white70),
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Lagnamn TextField
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextField(
                      controller: teamNameController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      maxLength: 26, // Max 26 tecken

                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.group, color: Colors.white70),
                        labelText: 'Team Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        counterStyle: const TextStyle(
                            color: Colors.white70), // Gör räknaren vit
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Skapa konto knapp med animation
                  authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              final email =
                                  authProvider.emailController.text.trim();
                              final teamName = teamNameController.text.trim();

                              if (email.isEmpty || teamName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please fill in all fields')),
                                );
                                return;
                              }
                              final confirm = await showDialog<bool>(
                                context: context,
                                useRootNavigator: true,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    backgroundColor:
                                        const Color(0xFF1A237E), // Deep indigo
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Column(
                                      children: [
                                        const Text(
                                          "Confirm Team Creation",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 2,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.blue,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: SizedBox(
                                      width: 300,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 10),
                                          Text(
                                            "Email: $email",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Team Name: $teamName",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.close,
                                                  size: 20,
                                                  color: Colors.white70),
                                              label: const Text(
                                                "Cancel",
                                                style: TextStyle(
                                                    color: Colors.white70),
                                              ),
                                              style: TextButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(dialogContext)
                                                      .pop(false),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.check,
                                                  size: 20,
                                                  color: Colors.white),
                                              label: const Text(
                                                "Confirm",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                elevation: 5,
                                              ),
                                              onPressed: () =>
                                                  Navigator.of(dialogContext)
                                                      .pop(true),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                bool success =
                                    await authProvider.register(context);
                                if (success) {
                                  await createTeam(teamName);

                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 10),

                  // 🔹 Tillbaka till login
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
