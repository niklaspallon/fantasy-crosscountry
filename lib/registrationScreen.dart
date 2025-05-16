import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'authProvider.dart';
import 'teamProvider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticProvider>(context);
    final TextEditingController teamNameController = TextEditingController();

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Bakgrundsbild med overlay
          /* Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/registration_background.jpg'), // Lägg till en snygg bild
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 🔹 Mörk overlay för bättre läsbarhet
         */
          Container(
            color: Colors.black
                .withOpacity(0.6), // Svart overlay med 60% transparens
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
                    "Skapa ditt konto",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "Ange dina uppgifter nedan",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // 🔹 Email TextField
                  TextField(
                    controller: authProvider.emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.email, color: Colors.white70),
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Lösenord TextField
                  TextField(
                    controller: authProvider.passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      labelText: 'Lösenord',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🔹 Lagnamn TextField
                  TextField(
                    controller: teamNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.group, color: Colors.white70),
                      labelText: 'Lagnamn',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Skapa konto knapp med animation
                  authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              await authProvider.register(context);
                              if (FirebaseAuth.instance.currentUser != null &&
                                  teamNameController.text.isNotEmpty) {
                                await createTeam(teamNameController.text);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Skapa konto',
                              style: TextStyle(fontSize: 18),
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
                      'Har du redan ett konto? Logga in',
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
