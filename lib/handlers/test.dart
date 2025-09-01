import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> generateTestTeams(int numberOfTeams) async {
  final db = FirebaseFirestore.instance;
  final random = Random();

  // 🔹 Hämta alla existerande skidåkare
  final skiersSnapshot = await db.collection('SkiersDb').get();
  final skiers = skiersSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'id': doc.id,
      'name': data['name'] ?? 'Unknown',
      'gender': data['gender'] ?? 'male',
      'country': (data['country'] ?? 'unknown').toString().toUpperCase(),
      'marketPrice': (data['marketPrice'] ?? 5.0).toDouble(),
    };
  }).toList();

  // Dela upp skidåkarna efter kön
  final maleSkiers = skiers.where((s) => s['gender'] == 'male').toList();
  final femaleSkiers = skiers.where((s) => s['gender'] == 'female').toList();

  for (int i = 0; i < numberOfTeams; i++) {
    final teamSkiers = <Map<String, dynamic>>[];
    final countryCount = <String, int>{};

    // 🔹 Funktion för att välja unika skidåkare med max 3 från samma land
    Map<String, dynamic> pickSkier(List<Map<String, dynamic>> pool) {
      Map<String, dynamic> chosen;
      int attempts = 0;
      do {
        chosen = pool[random.nextInt(pool.length)];
        final count = countryCount[chosen['country']] ?? 0;
        attempts++;
        if (attempts > 50) break;
      } while ((countryCount[chosen['country']] ?? 0) >= 3 ||
          teamSkiers.any((s) => s['skierId'] == chosen['id']));
      countryCount[chosen['country']] =
          (countryCount[chosen['country']] ?? 0) + 1;
      return chosen;
    }

    // 🔹 Välj 3 män
    for (int j = 0; j < 3; j++) {
      final skier = pickSkier(maleSkiers);
      teamSkiers.add({
        'skierId': skier['id'],
        'name': skier['name'],
        'country': skier['country'],
        'gender': skier['gender'],
        'isCaptain': j == 0, // första mannen blir kapten
        'marketPrice': skier['marketPrice'],
        'price': (5 + random.nextDouble() * 5).toStringAsFixed(1), // slumppris
        'totalWeeklyPoints': 0,
      });
    }

    // 🔹 Välj 3 kvinnor
    for (int j = 0; j < 3; j++) {
      final skier = pickSkier(femaleSkiers);
      teamSkiers.add({
        'skierId': skier['id'],
        'name': skier['name'],
        'country': skier['country'],
        'gender': skier['gender'],
        'isCaptain': false,
        'marketPrice': skier['marketPrice'],
        'price': (5 + random.nextDouble() * 5).toStringAsFixed(1),
        'totalWeeklyPoints': 0,
      });
    }

    // 🔹 Skapa lag i teams
    final teamRef = await db.collection('teams').add({
      'teamName': 'TestTeam$i',
      'ownerId': 'testOwner$i',
      'totalPoints': 0,
      'weeklyPoints': 0,
      'budget': 100,
      'freeTransfers': 0,
      'isAdmin': false,
      'isFullTeam': true,
      'unlimitedTransfers': true,
      'createdGw': 1,
    });

    // 🔹 Lägg till skidåkarna i weeklyTeams/week1
    await teamRef.collection('weeklyTeams').doc('week1').set({
      'weekNumber': 1,
      'weeklyPoints': 0,
      'skiers': teamSkiers,
    });
  }

  print(
      "✅ $numberOfTeams testlag skapade i teams med 6 skidåkare vardera (3 män, 3 kvinnor), max 3 från samma land.");
}



///////-------------------------------------------------------
// debug för inlogg, den under fungerar, behåller lite ifall den vanliga börjar krångla

// class DebugHomeScreen extends StatelessWidget { 
//   const DebugHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final ownerId = context.watch<TeamProvider>().ownerId;
//     final teamName = context.watch<TeamProvider>().teamName;
//     final gameWeek = context.watch<TeamProvider>().currentWeek;
//     final totalTeampoints = context.watch<TeamProvider>().teamTotalPoints;
//     final budget = context.watch<TeamProvider>().totalBudget;
//     final isAdmin = context.watch<TeamProvider>().isAdmin;
//     final userTeam = context.watch<TeamProvider>().userTeam;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Debug Home")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Owner ID: $ownerId"),
//             const SizedBox(height: 10),
//             Text("Team Name: $teamName"),
//             const SizedBox(height: 10),
//             Text("Current Game Week: $gameWeek"),
//             const SizedBox(height: 10),
//             Text("Team Total Points: $totalTeampoints"),
//             const SizedBox(height: 10),
//             Text("Total Budget: $budget"),
//             const SizedBox(height: 10),
//             Text("Is Admin: $isAdmin"),
//             const SizedBox(height: 10),
//             Text("User Team: ${userTeam?.join(', ') ?? 'Ingen userTeam'}"),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: () async {
//                 await context.read<AuthenticProvider>().logout(context);
//               },
//               child: const Text("Logga ut"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Fantasy Längdskidor',
//       home: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }

//           if (snapshot.hasData && snapshot.data != null) {
//             // 🔹 Visa debug-skärmen istället för MyHome
//             return const DebugHomeScreen();
//           } else {
//             return const LoginScreen();
//           }
//         },
//       ),
//     );
//   }
// }
// fortsättnign från ovan med auth: 
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:real_fls/main.dart';
// import 'package:real_fls/providers/team_provider.dart';
// import '../screens/login_screen.dart';
// import 'package:provider/provider.dart';

// class AuthenticProvider extends ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Controllers som hanteras av providern
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   Future<void> login(BuildContext context) async {
//     print("🚀 Startar login...");
//     _isLoading = true;
//     notifyListeners();
//     print("🔄 _isLoading satt till true och notifyListeners kallad");

//     try {
//       String email = emailController.text.trim();
//       String password = passwordController.text.trim();
//       print("📧 Email från controller: '$email'");
//       print(
//           "🔑 Lösenord från controller: '${'*' * password.length}'"); // maskerat

//       print("⏳ Försöker logga in med FirebaseAuth...");
//       UserCredential cred = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       print("✅ Inloggning lyckades!");
//       print("User UID: ${cred.user?.uid}");
//       print("User Email: ${cred.user?.email}");
//       print("User displayName: ${cred.user?.displayName}");
//       print("User isAnonymous: ${cred.user?.isAnonymous}");
//       print("User emailVerified: ${cred.user?.emailVerified}");
//       // Skapa en metod som rensar teamet

//       // Tvinga reload på user (för säkerhets skull)
//       await FirebaseAuth.instance.currentUser?.reload();
//       print("🔄 FirebaseAuth currentUser reloadad");

//       if (context.mounted) {
//         await context.read<TeamProvider>().getLoginData();
//       }

//       // Navigera direkt till MyHome
//       print("🎉 Navigerar till MyHome...");
//       if (context.mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (_) => const MyHome()),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = '';
//       print("⚠️ FirebaseAuthException fångad!");
//       print("Error code: ${e.code}");
//       print("Error message: ${e.message}");

//       if (e.code == 'user-not-found') {
//         message = 'Användare hittades inte.';
//       } else if (e.code == 'wrong-password') {
//         message = 'Fel lösenord.';
//       } else if (e.code == 'invalid-email') {
//         message = 'Ogiltig e-postadress.';
//       } else if (e.code == 'user-disabled') {
//         message = 'Konto inaktiverat.';
//       } else {
//         message = 'Error: ${e.message}';
//       }

//       print("📢 Visar felmeddelande: $message");
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(message)));
//     } catch (e) {
//       print("❌ Okänt fel vid login: $e");
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//       print("🔄 _isLoading satt till false och notifyListeners kallad");
//       print("🔹 Login-metoden avslutad");
//     }
//   }

//   Future<void> logout(BuildContext context) async {
//     try {
//       await _auth.signOut();
//       context.read<TeamProvider>().clearLoginData();
//       // StreamBuilder tar hand om att visa LoginScreen
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error logging out: $e')));
//     }
//   }

//   Future<void> register(BuildContext context) async {
//     _isLoading = true;
//     notifyListeners();

//     try {
//       await _auth.createUserWithEmailAndPassword(
//         email: emailController.text.trim(), // ✅ Rätt sätt att hämta e-post
//         password: passwordController.text.trim(), // Lägg även till trim här
//       );

//       // Vid lyckad registrering, navigera till HomeScreen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const MyHome()),
//       );
//     } on FirebaseAuthException catch (e) {
//       String message = '';
//       if (e.code == 'email-already-in-use') {
//         message = 'Emailen används redan.';
//       } else if (e.code == 'weak-password') {
//         message = 'Lösenordet är för svagt.';
//       } else if (e.code == 'invalid-email') {
//         message = 'Ogiltig email.';
//       } else {
//         message = 'Error: ${e.message}';
//       }
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(message)));
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }
// }

// auth_provider.dart
// -------------------------------------------------------