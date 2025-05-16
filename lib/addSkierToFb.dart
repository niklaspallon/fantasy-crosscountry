import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addSkiersToFirestore() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  WriteBatch batch = db.batch(); // Batchar för att effektivisera skrivningar

  // 🔹 Lista med skidåkare att lägga till
  final List<Map<String, dynamic>> skiersList = [
    {
      "name": "KLAEBO Johannes Hoesflot",
      "country": "norway",
      "gender": "male",
      "price": 14
    },
    {
      "name": "KRUEGER Simen Hegstad",
      "country": "norway",
      "gender": "male",
      "price": 14
    },
    {
      "name": "LIEFARI Emil",
      "country": "finland",
      "gender": "male",
      "price": 5
    },
    {"name": "ROSJOE Eric", "country": "sweden", "gender": "male", "price": 5},
    {"name": "WIIG Sivert", "country": "norway", "gender": "male", "price": 5},
    {
      "name": "DIGGINS Jessie",
      "country": "united states",
      "gender": "female",
      "price": 14
    },
    {
      "name": "CARL Victoria",
      "country": "germany",
      "gender": "female",
      "price": 14
    },
    {
      "name": "SLIND Astrid Oeyre",
      "country": "norway",
      "gender": "female",
      "price": 14
    },
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

Future<void> deleteEmptySkierDocuments() async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    QuerySnapshot skierSnapshot = await db.collection('SkiersDb').get();

    for (var skierDoc in skierSnapshot.docs) {
      String skierId = skierDoc.id;
      Map<String, dynamic>? data = skierDoc.data() as Map<String, dynamic>?;

      // 🔹 Kontrollera om dokumentet är tomt (inga fält)
      if (data == null || data.isEmpty) {
        print("🚀 Hittade tomt dokument: $skierId, försöker radera...");

        // 🔥 Radera ALLA underliggande veckor i `weeklyPoints`
        await deleteAllWeeklyPoints(db, skierId);

        // 🔥 När alla subcollections är borta, radera huvuddokumentet
        await db.collection('SkiersDb').doc(skierId).delete();

        print("✅ Raderade skidåkardokument: $skierId");
      }
    }

    print(
        "🎉 Alla tomma skidåkardokument och deras subcollections har raderats!");
  } catch (e) {
    print("❌ Fel vid radering av tomma skidåkardokument: $e");
  }
}

// 🔹 Hjälpfunktion för att radera ALLA veckor i `weeklyPoints`
Future<void> deleteAllWeeklyPoints(FirebaseFirestore db, String skierId) async {
  try {
    CollectionReference weeklyPointsRef =
        db.collection('SkiersDb').doc(skierId).collection('weeklyPoints');

    QuerySnapshot weeklyPointsSnapshot = await weeklyPointsRef.get();

    for (var weekDoc in weeklyPointsSnapshot.docs) {
      String weekId = weekDoc.id;

      // 🔥 Först radera tävlingspoäng i varje vecka
      await deleteSubcollection(
          db, skierId, "weeklyPoints", weekId, "competitions");

      // 🔥 Radera själva veckodokumentet
      await weeklyPointsRef.doc(weekId).delete();
      print("🗑 Raderade vecka $weekId för skidåkare $skierId");
    }
  } catch (e) {
    print("❌ Fel vid radering av veckopoäng i weeklyPoints: $e");
  }
}

// 🔹 Hjälpfunktion för att radera ALLA tävlingar i en vecka
Future<void> deleteSubcollection(FirebaseFirestore db, String skierId,
    String parentCollection, String parentId, String subcollection) async {
  try {
    QuerySnapshot subcollectionSnapshot = await db
        .collection('SkiersDb')
        .doc(skierId)
        .collection(parentCollection)
        .doc(parentId)
        .collection(subcollection)
        .get();

    for (var doc in subcollectionSnapshot.docs) {
      await db
          .collection('SkiersDb')
          .doc(skierId)
          .collection(parentCollection)
          .doc(parentId)
          .collection(subcollection)
          .doc(doc.id)
          .delete();
      print(
          "🗑 Raderade $subcollection/${doc.id} för vecka $parentId i $parentCollection för skidåkare $skierId");
    }
  } catch (e) {
    print("❌ Fel vid radering av subcollection $subcollection: $e");
  }
}

/*
[
    {
      "name": "KLAEBO Johannes Hoesflot",
      "country": "norway",
      "gender": "male",
      "price": 14
    },
    {"name": "ANGER Edvin", "country": "sweden", "gender": "male", "price": 14},
    {
      "name": "AMUNDSEN Harald Oestberg",
      "country": "norway",
      "gender": "male",
      "price": 14
    },
    {
      "name": "LAPALUS Hugo",
      "country": "france",
      "gender": "male",
      "price": 14
    },
    {
      "name": "KRUEGER Simen Hegstad",
      "country": "norway",
      "gender": "male",
      "price": 14
    },
    {"name": "VALNES Erik", "country": "norway", "gender": "male", "price": 14},
    {
      "name": "PELLEGRINO Federico",
      "country": "italy",
      "gender": "male",
      "price": 14
    },
    {
      "name": "REE Andreas Fjorden",
      "country": "norway",
      "gender": "male",
      "price": 14
    },
    {
      "name": "VERMEULEN Mika",
      "country": "austria",
      "gender": "male",
      "price": 14
    },
    {
      "name": "DESLOGES Mathis",
      "country": "france",
      "gender": "male",
      "price": 14
    },
    {
      "name": "NYENGET Martin Loewstroem",
      "country": "norway",
      "gender": "male",
      "price": 12
    },
    {
      "name": "OGDEN Ben",
      "country": "united states",
      "gender": "male",
      "price": 12
    },
    {
      "name": "MOCH Friedrich",
      "country": "germany",
      "gender": "male",
      "price": 12
    },
    {
      "name": "POROMAA William",
      "country": "sweden",
      "gender": "male",
      "price": 12
    },
    {
      "name": "NISKANEN Iivo",
      "country": "finland",
      "gender": "male",
      "price": 12
    },
    {
      "name": "GOLBERG Paal",
      "country": "norway",
      "gender": "male",
      "price": 12
    },
    {
      "name": "ANDERSEN Iver Tildheim",
      "country": "norway",
      "gender": "male",
      "price": 12
    },
    {
      "name": "SCHUMACHER Gus",
      "country": "united states",
      "gender": "male",
      "price": 12
    },
    {
      "name": "JENSSEN Jan Thomas",
      "country": "norway",
      "gender": "male",
      "price": 12
    },
    {
      "name": "CHANAVAT Lucas",
      "country": "france",
      "gender": "male",
      "price": 12
    },
    {
      "name": "MUSGRAVE Andrew",
      "country": "united kingdom",
      "gender": "male",
      "price": 10
    },
    {
      "name": "VUORINEN Lauri",
      "country": "finland",
      "gender": "male",
      "price": 10
    },
    {
      "name": "RUUSKANEN Arsi",
      "country": "finland",
      "gender": "male",
      "price": 10
    },
    {
      "name": "NORTHUG Even",
      "country": "norway",
      "gender": "male",
      "price": 10
    },
    {
      "name": "NOVAK Michal",
      "country": "czech republic",
      "gender": "male",
      "price": 10
    },
    {
      "name": "JOUVE Richard",
      "country": "france",
      "gender": "male",
      "price": 10
    },
    {
      "name": "MOSEBY Haavard",
      "country": "norway",
      "gender": "male",
      "price": 10
    },
    {
      "name": "ESTEVE ALTIMIRAS Ireneu",
      "country": "andorra",
      "gender": "male",
      "price": 10
    },
    {"name": "BURMAN Jens", "country": "sweden", "gender": "male", "price": 10},
    {
      "name": "MCMULLEN Zanden",
      "country": "united states",
      "gender": "male",
      "price": 10
    },
    {"name": "BARP Elia", "country": "italy", "gender": "male", "price": 10},
    {
      "name": "GROND Valerio",
      "country": "switzerland",
      "gender": "male",
      "price": 10
    },
    {"name": "GRAZ Davide", "country": "italy", "gender": "male", "price": 10},
    {
      "name": "SCHOONMAKER JC",
      "country": "united states",
      "gender": "male",
      "price": 10
    },
    {"name": "BABA Naoto", "country": "japan", "gender": "male", "price": 8},
    {"name": "CYR Antoine", "country": "canada", "gender": "male", "price": 8},
    {
      "name": "VIKE Oskar Opstad",
      "country": "norway",
      "gender": "male",
      "price": 8
    },
    {
      "name": "HALFVARSSON Calle",
      "country": "sweden",
      "gender": "male",
      "price": 8
    },
    {
      "name": "ALEV Alvar Johannes",
      "country": "estonia",
      "gender": "male",
      "price": 8
    },
    {
      "name": "LEVEILLE Olivier",
      "country": "canada",
      "gender": "male",
      "price": 8
    },
    {
      "name": "CHAPPAZ Jules",
      "country": "france",
      "gender": "male",
      "price": 8
    },
    {
      "name": "TAUGBOEL Haavard Solaas",
      "country": "norway",
      "gender": "male",
      "price": 8
    },
    {
      "name": "MOSER Benjamin",
      "country": "austria",
      "gender": "male",
      "price": 8
    },
    {
      "name": "STOELBEN Jan",
      "country": "germany",
      "gender": "male",
      "price": 8
    },
    {
      "name": "LAPIERRE Jules",
      "country": "france",
      "gender": "male",
      "price": 8
    },
    {
      "name": "SVENSSON Oskar",
      "country": "sweden",
      "gender": "male",
      "price": 6
    },
    {
      "name": "PARISSE Clement",
      "country": "france",
      "gender": "male",
      "price": 6
    },
    {"name": "GRATE Marcus", "country": "sweden", "gender": "male", "price": 6},
    {"name": "MAKI Joni", "country": "finland", "gender": "male", "price": 6},
    {"name": "PUEYO Jaume", "country": "spain", "gender": "male", "price": 6},
    {
      "name": "BERGLUND Gustaf",
      "country": "sweden",
      "gender": "male",
      "price": 6
    },
    {
      "name": "HOLMBOE Aleksander Elde",
      "country": "norway",
      "gender": "male",
      "price": 6
    },
    {
      "name": "DAVIES Joe",
      "country": "united kingdom",
      "gender": "male",
      "price": 6
    },
    {
      "name": "SIMENC Miha",
      "country": "slovenia",
      "gender": "male",
      "price": 6
    },
    {
      "name": "LIEFARI Emil",
      "country": "finland",
      "gender": "male",
      "price": 5
    },
    {"name": "ROSJOE Eric", "country": "sweden", "gender": "male", "price": 5},
    {"name": "WIIG Sivert", "country": "norway", "gender": "male", "price": 5},
    {
      "name": "DIGGINS Jessie",
      "country": "united states",
      "gender": "female",
      "price": 14
    },
    {
      "name": "CARL Victoria",
      "country": "germany",
      "gender": "female",
      "price": 14
    },
    {
      "name": "SLIND Astrid Oeyre",
      "country": "norway",
      "gender": "female",
      "price": 14
    },
    {
      "name": "NISKANEN Kerttu",
      "country": "finland",
      "gender": "female",
      "price": 14
    },
    {
      "name": "JOHAUG Therese",
      "country": "norway",
      "gender": "female",
      "price": 14
    },
    {
      "name": "WENG Heidi",
      "country": "norway",
      "gender": "female",
      "price": 14
    },
    {
      "name": "ANDERSSON Ebba",
      "country": "sweden",
      "gender": "female",
      "price": 14
    },
    {
      "name": "JANATOVA Katerina",
      "country": "czech republic",
      "gender": "female",
      "price": 14
    },
    {
      "name": "STADLOBER Teresa",
      "country": "austria",
      "gender": "female",
      "price": 14
    },
    {
      "name": "JOENSUU Jasmi",
      "country": "finland",
      "gender": "female",
      "price": 14
    },
    {"name": "ILAR Moa", "country": "sweden", "gender": "female", "price": 12},
    {
      "name": "PARMAKOSKI Krista",
      "country": "finland",
      "gender": "female",
      "price": 12
    },
    {
      "name": "FOSNAES Kristin Austgulen",
      "country": "norway",
      "gender": "female",
      "price": 12
    },
    {"name": "FINK Pia", "country": "germany", "gender": "female", "price": 12},
    {
      "name": "SUNDLING Jonna",
      "country": "sweden",
      "gender": "female",
      "price": 12
    },
    {
      "name": "SANNESS Nora",
      "country": "norway",
      "gender": "female",
      "price": 12
    },
    {
      "name": "FAEHNDRICH Nadine",
      "country": "switzerland",
      "gender": "female",
      "price": 12
    },
    {
      "name": "HENNIG Katharina",
      "country": "germany",
      "gender": "female",
      "price": 12
    },
    {
      "name": "WENG Lotta Udnes",
      "country": "norway",
      "gender": "female",
      "price": 12
    },
    {
      "name": "GIMMLER Laura",
      "country": "germany",
      "gender": "female",
      "price": 12
    },
    {
      "name": "KERN Julia",
      "country": "united states",
      "gender": "female",
      "price": 10
    },
    {
      "name": "THEODORSEN Silje",
      "country": "norway",
      "gender": "female",
      "price": 10
    },
    {
      "name": "DAHLQVIST Maja",
      "country": "sweden",
      "gender": "female",
      "price": 10
    },
    {
      "name": "WEBER Anja",
      "country": "switzerland",
      "gender": "female",
      "price": 10
    },
    {
      "name": "LAUKLI Sophia",
      "country": "united states",
      "gender": "female",
      "price": 10
    },
    {
      "name": "GANZ Caterina",
      "country": "italy",
      "gender": "female",
      "price": 10
    },
    {
      "name": "SVAHN Linn",
      "country": "sweden",
      "gender": "female",
      "price": 10
    },
    {
      "name": "DOLCI Flora",
      "country": "france",
      "gender": "female",
      "price": 10
    },
    {
      "name": "STEWART-JONES Katherine",
      "country": "canada",
      "gender": "female",
      "price": 10
    },
    {
      "name": "HOFFMANN Helen",
      "country": "germany",
      "gender": "female",
      "price": 10
    },
    {"name": "RIBOM Emma", "country": "sweden", "gender": "female", "price": 8},
    {
      "name": "KAHARA Jasmin",
      "country": "finland",
      "gender": "female",
      "price": 8
    },
    {
      "name": "RYDZEK Coletta",
      "country": "germany",
      "gender": "female",
      "price": 8
    },
    {
      "name": "BRENNAN Rosie",
      "country": "united states",
      "gender": "female",
      "price": 8
    },
    {
      "name": "KARLSSON Frida",
      "country": "sweden",
      "gender": "female",
      "price": 8
    },
    {
      "name": "KREHL Sofie",
      "country": "germany",
      "gender": "female",
      "price": 8
    },
    {
      "name": "MYHRE Julie",
      "country": "norway",
      "gender": "female",
      "price": 8
    },
    {
      "name": "FOSSESHOLM Helene Marie",
      "country": "norway",
      "gender": "female",
      "price": 8
    },
    {
      "name": "GAGNON Liliane",
      "country": "canada",
      "gender": "female",
      "price": 8
    },
    {
      "name": "HAGSTROEM Johanna",
      "country": "sweden",
      "gender": "female",
      "price": 8
    },
    {
      "name": "STENSETH Ane Appelkvist",
      "country": "norway",
      "gender": "female",
      "price": 8
    },
    {
      "name": "MATINTALO Johanna",
      "country": "finland",
      "gender": "female",
      "price": 8
    },
    {
      "name": "AMUNDSEN Hedda Oestberg",
      "country": "norway",
      "gender": "female",
      "price": 8
    },
    {
      "name": "GAL Melissa",
      "country": "france",
      "gender": "female",
      "price": 6
    },
    {
      "name": "SONNESYN Alayna",
      "country": "united states",
      "gender": "female",
      "price": 6
    },
    {
      "name": "KYLLONEN Anne",
      "country": "finland",
      "gender": "female",
      "price": 6
    },
    {
      "name": "RYYTTY Vilma",
      "country": "finland",
      "gender": "female",
      "price": 6
    },
    {
      "name": "CASSOL Federica",
      "country": "italy",
      "gender": "female",
      "price": 6
    },
    {
      "name": "LUNDGREN Moa",
      "country": "sweden",
      "gender": "female",
      "price": 6
    },
    {
      "name": "MYHRVOLD Mathilde",
      "country": "norway",
      "gender": "female",
      "price": 6
    },
    {
      "name": "GIMMONDI Maria",
      "country": "italy",
      "gender": "female",
      "price": 6
    },
    {
      "name": "SKISTAD Kristine Stavaas",
      "country": "norway",
      "gender": "female",
      "price": 6
    },
    {
      "name": "JOHNSEN Elena Rise",
      "country": "norway",
      "gender": "female",
      "price": 6
    },
    {
      "name": "DUCORDEAU Juliette",
      "country": "france",
      "gender": "female",
      "price": 6
    },
    {
      "name": "STENMAN Ebba",
      "country": "sweden",
      "gender": "female",
      "price": 5
    },
    {
      "name": "HANSSON Moa",
      "country": "sweden",
      "gender": "female",
      "price": 5
    },
    {
      "name": "FISCHER Lea",
      "country": "switzerland",
      "gender": "female",
      "price": 5
    },

    */