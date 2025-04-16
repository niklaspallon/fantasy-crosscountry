import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teamProvider.dart';
import 'package:provider/provider.dart';

void showSkierInfo(BuildContext context, String skierId) async {
  final provider = Provider.of<TeamProvider>(context, listen: false);
  final captain = provider.captain;
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;

    // 🔹 Hämta åkarens information
    final skierDoc = await db.collection('SkiersDb').doc(skierId).get();

    if (!skierDoc.exists) {
      showAlertDialog(
          context, "Fel", "Skidåkaren med ID $skierId hittades inte.");
      return;
    }

    final skierName = skierDoc.get('name') ?? 'Okänd';
    final country = skierDoc.get('country') ?? 'Okänd';
    final totalPoints = skierDoc.get('totalPoints') ?? 0;

    print("⛷ Hämta veckodata för skierId: $skierId");
    final weeklyResultsSnapshot = await db
        .collection('SkiersDb')
        .doc(skierId)
        .collection('weeklyResults')
        .get();
    print("✅ weeklyResults hämtade!");
    print("🔢 Antal veckodokument: ${weeklyResultsSnapshot.docs.length}");

    List<Widget> competitionsList = [];

    for (var weekDoc in weeklyResultsSnapshot.docs) {
      final weekId = weekDoc.id.replaceAll('week', '');
      final totalWeeklyPoints = weekDoc.get('totalWeeklyPoints') ?? 0;

      competitionsList.add(
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            "📅 Vecka $weekId - Totalt: $totalWeeklyPoints poäng",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blue,
            ),
          ),
        ),
      );

      final competitions =
          weekDoc.get('competitions') as Map<String, dynamic>? ?? {};
      if (competitions.isNotEmpty) {
        competitions.forEach((name, points) {
          competitionsList.add(Text("🏆 $name: $points poäng"));
        });
      } else {
        competitionsList.add(const Text("Inga tävlingsresultat denna vecka."));
      }
    }

    // 🔹 Visa dialogen
    showDialog(
      context: context,
      useRootNavigator: true, // 🛡 Viktigt vid användning av Overlay etc.
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(skierName),
          content: SizedBox(
            height: 250,
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🏅 Totala poäng: $totalPoints"),
                  const SizedBox(height: 10),
                  const Text(
                    "📊 Tävlingshistorik:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ...competitionsList,
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                skierId != captain
                    ? TextButton(
                        style:
                            TextButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          provider.setLocalCaptain(skierId);
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text("Make Captain",
                            style: TextStyle(color: Colors.white)),
                      )
                    : TextButton(
                        style:
                            TextButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          provider.setLocalCaptain("");
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text("Remove Captaincy",
                            style: TextStyle(color: Colors.white)),
                      ),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Stäng",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  } catch (e) {
    print("❌ Fel vid hämtning av skidåkarens info: $e");
    showAlertDialog(context, "Fel", "Kunde inte hämta skidåkarens info.");
  }
}

void showAlertDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    useRootNavigator: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

/// 🔹 Visar en AlertDialog för bekräftelsemeddelanden
void showSuccessDialog(BuildContext context, String title, String message) {
  showDialog(
    context: Navigator.of(context, rootNavigator: true).context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}
