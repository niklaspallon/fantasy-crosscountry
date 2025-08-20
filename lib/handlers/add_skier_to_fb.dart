import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addSkiersToFirestore() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  WriteBatch batch = db.batch(); // Batchar för att effektivisera skrivningar

  // 🔹 Lista med skidåkare att lägga till
  final List<Map<String, dynamic>> skiersList = [
    {
      "name": "DIGGINS Jessie",
      "country": "united states",
      "gender": "female",
      "recentPlacements": [1, 1, 5],
      "price": 30.0
    },
    {
      "name": "SVAHN Linn",
      "country": "sweden",
      "gender": "female",
      "recentPlacements": [2, 8, 1],
      "price": 29.0
    },
    {
      "name": "KARLSSON Frida",
      "country": "sweden",
      "gender": "female",
      "recentPlacements": [3, 5, 7],
      "price": 28.5
    },
    {
      "name": "CARL Victoria",
      "country": "germany",
      "gender": "female",
      "recentPlacements": [4, 2, 16],
      "price": 27.5
    },
    {
      "name": "JOUVE Richard",
      "country": "france",
      "gender": "male",
      "recentPlacements": [25, 40, 14],
      "price": 10.5
    },
    {
      "name": "NORTHUG Even",
      "country": "norway",
      "gender": "male",
      "recentPlacements": [26, null, 6],
      "price": 9.5
    },
    {
      "name": "GROND Valerio",
      "country": "switzerland",
      "gender": "male",
      "recentPlacements": [27, 102, 7],
      "price": 9.0
    },
    {
      "name": "LAPIERRE Jules",
      "country": "france",
      "gender": "male",
      "recentPlacements": [28, 21, null],
      "price": 8.0
    },
    {
      "name": "NISKANEN Iivo",
      "country": "finland",
      "gender": "male",
      "recentPlacements": [29, 15, 55],
      "price": 7.5
    },
    {
      "name": "JENSSEN Jan Thomas",
      "country": "norway",
      "gender": "male",
      "recentPlacements": [30, 20, 115],
      "price": 6.5
    }
  ];

  QuerySnapshot existingSkiersSnapshot = await db.collection('SkiersDb').get();

  // 🔹 Skapa en set med alla existerande namn för snabb lookup
  Set<String> existingSkierNames = existingSkiersSnapshot.docs
      .map((doc) => doc.get('name') as String? ?? '')
      .where((name) => name.isNotEmpty)
      .toSet();

  int addedCount = 0;

  for (var skier in skiersList) {
    String skierName = skier["name"];

    if (existingSkierNames.contains(skierName)) {
      print(
          "⚠️ Skidåkare '$skierName' finns redan i databasen och läggs **inte** till.");
      continue; // 🛑 Hoppa över skidåkare som redan finns
    }

    // 🔹 Skapa en ny skidåkare i `SkiersDb`
    DocumentReference skierRef = db.collection('SkiersDb').doc();
    batch.set(skierRef, {
      "name": skier["name"],
      "country": skier["country"],
      "gender": skier["gender"],
      "price": skier["price"],
      "recentPlacements":
          skier["recentPlacements"], // Placeringar i senaste tävlingar
      "totalPoints": 0, // Ackumulerad totalpoäng för alla veckor
    });

    // 🔹 Lägg till `weeklyResults` subcollection med "week1" som start
    DocumentReference week1Ref =
        skierRef.collection('weeklyResults').doc("week1");
    batch.set(week1Ref, {
      "totalWeeklyPoints": 0, // Summerad poäng från tävlingar denna vecka
      "competitions": {}, // Skapa en tom mapp för tävlingsresultat
    });

    addedCount++;
  }

  // 🔥 Om vi har nya skidåkare att lägga till, skriv till Firestore
  if (addedCount > 0) {
    await batch.commit();
    print("✅ $addedCount nya skidåkare har lagts till i Firestore!");
  } else {
    print(
        "⚠️ Inga nya skidåkare lades till eftersom alla redan fanns i databasen.");
  }
}

/// 🔹 Radera alla skidåkare från `SkiersDb`
Future<void> clearSkiersDb() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  try {
    QuerySnapshot snapshot = await db.collection('SkiersDb').get();
    WriteBatch batch = db.batch();

    for (DocumentSnapshot doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    print("✅ Alla skidåkare har raderats från SkiersDb.");
  } catch (e) {
    print("❌ Fel vid radering av skidåkare: $e");
  }
}
