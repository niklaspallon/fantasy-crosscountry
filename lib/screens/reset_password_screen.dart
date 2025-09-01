import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../designs/button_design.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticProvider>(context);
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
                    "Reset Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

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
                  Container(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: HoverButton(
                      onPressed: () async {
                        final email = authProvider.emailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Email")),
                          );
                          return;
                        }

                        try {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: email);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Reset link sent to your email")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("⚠️ Fel: ${e.toString()}")),
                          );
                        }
                      },
                      child: const Text(
                        'Send Reset Link',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
