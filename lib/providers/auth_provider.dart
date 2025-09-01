import 'package:real_fls/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_provider.dart';
import 'package:provider/provider.dart';

class AuthenticProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("Hämtar teamdata efter inloggning...");
      await context.read<TeamProvider>().getLoginData();

      // Navigera till debug screen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyHome()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    await _auth.signOut();
    context.read<TeamProvider>().clearLoginData();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(), // ✅ Rätt sätt att hämta e-post
        password: passwordController.text.trim(), // Lägg även till trim här
      );

      // Vid lyckad registrering, navigera till HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHome()),
      );
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'email-already-in-use') {
        message = 'Emailen används redan.';
      } else if (e.code == 'weak-password') {
        message = 'Lösenordet är för svagt.';
      } else if (e.code == 'invalid-email') {
        message = 'Ogiltig email.';
      } else {
        message = 'Error: ${e.message}';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
