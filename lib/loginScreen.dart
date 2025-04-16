import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_fls/registrationScreen.dart';
import 'authProvider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Bakgrundsbild med overlay
          /*Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'assets/login_background.jpg'), // Lägg till en snygg bild i assets
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
          // 🔹 Inloggningsformulär i en centrerad kolumn
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔹 App-logga eller ikon
                  const Icon(
                    Icons
                        .sports_martial_arts, // Exempelikon, byt ut till din logotyp
                    color: Colors.white,
                    size: 80,
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Välkomsttext
                  const Text(
                    "Välkommen tillbaka!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    "Logga in för att fortsätta",
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
                  const SizedBox(height: 20),

                  // 🔹 Logga in knapp med animation
                  authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => authProvider.login(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Logga in',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                  const SizedBox(height: 10),

                  // 🔹 Skapa konto knapp
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegistrationScreen()),
                      );
                    },
                    child: const Text(
                      'Skapa konto',
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
