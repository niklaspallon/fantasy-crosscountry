import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../handlers/week_handler.dart';
import '../handlers/update_points.dart';

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';

Future<List<String>> sprintfetchAndSetCompetitionPoints(
    String compName, String compURL) async {
  final response = await http.get(Uri.parse(compURL));

  if (response.statusCode == 200) {
    final document = parser.parse(response.body);
    final rows = document.querySelectorAll('div.g-row.container');

    Map<String, Map<String, dynamic>> skierResultsByName = {};
    int added = 0;
    Set<String> seenNames = {};

    for (var row in rows) {
      final placementElement = row.querySelector('div.g-lg-1.bold');
      final nameElement = row.querySelector('div.g-lg-14.bold');
      final countryElement = row.querySelector('span.country__name-short');

      if (placementElement != null && nameElement != null) {
        final name = nameElement.text.trim();
        final placement = int.tryParse(placementElement.text.trim());

        if (placement != null &&
            placement > 0 &&
            name.isNotEmpty &&
            !seenNames.contains(name)) {
          int points = getPoints(placement);

          skierResultsByName[name] = {
            'points': points,
            'placement': placement,
            'country': countryElement?.text.trim().toLowerCase() ?? 'unknown',
          };

          seenNames.add(name);
          added++;
        }
      }
    }

    if (skierResultsByName.isNotEmpty) {
      final addMsg = await addPointsFromCompToWeeklySkierPoints(
          compName, skierResultsByName);

      return addMsg;
    } else {
      print("⚠️ Inga åkare hittades i HTML. Möjligen fel selectors.");
      final preview = document.body?.outerHtml.substring(0, 1000) ?? '';
      return [];
    }
  } else {
    print(
        '❌ Kunde inte hämta data från FIS-ski (status: ${response.statusCode}).');
    return [];
  }
}

/// 🔹 Funktion för att hämta resultat & uppdatera poäng från FIS
Future<List<String>> fetchAndSetCompetitionPoints(
    String compName, String compURL) async {
  final response = await http.get(Uri.parse(compURL));

  if (response.statusCode == 200) {
    final document = parser.parse(response.body);
    final rows = document.querySelectorAll('div.g-row');

    Map<String, Map<String, dynamic>> skierResultsByName = {};
    int added = 0;
    Set<String> seenNames = {};

    for (var row in rows) {
      final placementElement = row.querySelector('div.g-lg-1.bold');
      final nameElement = row.querySelector('div.g-lg-12.bold');

      if (placementElement != null && nameElement != null) {
        final name = nameElement.text.trim();
        final placement = int.tryParse(placementElement.text.trim());

        if (placement != null &&
            placement > 0 &&
            name.isNotEmpty &&
            !seenNames.contains(name)) {
          int points = getPoints(placement);
          skierResultsByName[name] = {
            'points': points,
            'placement': placement,
          };
          seenNames.add(name);
          added++;
        }
      }
    }

    if (skierResultsByName.isNotEmpty) {
      final addMsg = await addPointsFromCompToWeeklySkierPoints(
          compName, skierResultsByName);
      print(
          "✅ $added åkare hittades och poäng har lagts till för \"$compName\".\n$addMsg");

      return addMsg;
    } else {
      print("⚠️ Inga åkare hittades i HTML. Möjligen fel selectors.");
      final preview = document.body?.outerHtml.substring(0, 1000) ?? '';
      return [];
    }
  } else {
    print(
        '❌ Kunde inte hämta data från FIS-ski (status: ${response.statusCode}).');
    return [];
  }
}

Future<List<String>> addPointsFromCompToWeeklySkierPoints(
  String competitionId,
  Map<String, Map<String, dynamic>> skierResultsByName,
) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    int currentWeek = await getCurrentWeek();

    QuerySnapshot skiersSnapshot = await db.collection('SkiersDb').get();

    Map<String, String> skierNameToId = {};
    Map<String, DocumentSnapshot> skierNameToDoc = {};

    for (var doc in skiersSnapshot.docs) {
      final name = doc.get('name');
      skierNameToId[name] = doc.id;
      skierNameToDoc[name] = doc;
    }

    List<String> results = [];

    skierResultsByName.forEach((name, data) {
      if (skierNameToId.containsKey(name)) {
        results.add(
            "${name}: Placering ${data['placement']}, ${data['points']} poäng");
      } else {
        results.add("$name: Hittades EJ i databasen!");
      }
    });

    // Sätt poäng endast för de som finns i DB
    Map<String, Map<String, dynamic>> validSkiers = {
      for (var entry in skierResultsByName.entries)
        if (skierNameToId.containsKey(entry.key)) entry.key: entry.value
    };

    WriteBatch skierBatch = db.batch();

    for (var entry in validSkiers.entries) {
      final skierName = entry.key;
      final skierId = skierNameToId[skierName]!;
      final skierDoc = skierNameToDoc[skierName]!;

      final int points = entry.value['points'];
      final int placement = entry.value['placement'];

      final weekRef = db
          .collection('SkiersDb')
          .doc(skierId)
          .collection('weeklyResults')
          .doc("week$currentWeek");

      final weekSnap = await weekRef.get();
      final Map<String, dynamic> data =
          weekSnap.exists ? (weekSnap.data() as Map<String, dynamic>) : {};

      final Map<String, dynamic> competitions =
          Map<String, dynamic>.from(data['competitions'] ?? {});
      final List<dynamic> counted =
          List<dynamic>.from(data['countedCompetitions'] ?? []);
      final int currentTotal = data['totalWeeklyPoints'] ?? 0;

      if (counted.contains(competitionId)) {
        continue;
      }

      competitions[competitionId] = {
        'points': points,
        'placement': placement,
      };
      counted.add(competitionId);
      final int newTotal = currentTotal + points;

      skierBatch.set(
        weekRef,
        {
          'competitions': competitions,
          'countedCompetitions': counted,
          'totalWeeklyPoints': newTotal,
        },
        SetOptions(merge: true),
      );

      // Uppdatera recentPlacements
      List<dynamic> recentPlacements =
          List.from(skierDoc.get('recentPlacements') ?? []);
      recentPlacements.insert(0, placement);
      if (recentPlacements.length > 5) {
        recentPlacements = recentPlacements.sublist(0, 5);
      }

      final skierRef = db.collection('SkiersDb').doc(skierId);
      skierBatch.update(skierRef, {
        'recentPlacements': recentPlacements,
      });
    }

    await skierBatch.commit();

    return results;
  } catch (e) {
    print("❌ Fel i addPointsFromCompToWeeklySkierPoints: $e");
    return <String>[]; // Returnera en tom lista vid fel
  }
}

int getPoints(int placement) {
  if (placement == 1) return 100;
  if (placement == 2) return 80;
  if (placement == 3) return 60;
  if (placement == 4) return 50;
  if (placement == 5) return 45;
  if (placement == 6) return 40;
  if (placement == 7) return 35;
  if (placement == 8) return 30;
  if (placement == 9) return 25;
  if (placement == 10) return 20;
  if (placement >= 11 && placement <= 30) return 30 - placement + 1;
  return 0;
}
