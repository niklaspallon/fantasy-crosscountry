import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addSkiersToFirestore() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  WriteBatch batch = db.batch(); // Batchar för att effektivisera skrivningar

  // Lista med skidåkare att lägga till
  final List<Map<String, dynamic>> skiersList = [
    {
      "name": "DIGGINS Jessie",
      "country": "USA",
      "gender": "female",
      "price": 32.0,
      "recentPlacements": [1, 1, 2]
    },
    {
      "name": "CARL Victoria",
      "country": "Germany",
      "gender": "female",
      "price": 27.5,
      "recentPlacements": [7, 6, 8]
    },
    {
      "name": "NISKANEN Kerttu",
      "country": "Finland",
      "gender": "female",
      "price": 26.5,
      "recentPlacements": [10, 11, 9]
    },
    {
      "name": "SLIND Astrid Oeyre",
      "country": "Norway",
      "gender": "female",
      "price": 26.0,
      "recentPlacements": [11, 10, 12]
    },
    {
      "name": "JOHAUG Therese",
      "country": "Norway",
      "gender": "female",
      "price": 29.0,
      "recentPlacements": [3, 2, 4]
    },
    {
      "name": "JANATOVA Katerina",
      "country": "Czech Republic",
      "gender": "female",
      "price": 24.5,
      "recentPlacements": [14, 13, 15]
    },
    {
      "name": "ANDERSSON Ebba",
      "country": "Sweden",
      "gender": "female",
      "price": 27.0,
      "recentPlacements": [8, 7, 9]
    },
    {
      "name": "WENG Heidi",
      "country": "Norway",
      "gender": "female",
      "price": 23.0,
      "recentPlacements": [17, 16, 18]
    },
    {
      "name": "JOENSUU Jasmi",
      "country": "Finland",
      "gender": "female",
      "price": 22.5,
      "recentPlacements": [18, 19, 17]
    },
    {
      "name": "STADLOBER Teresa",
      "country": "Austria",
      "gender": "female",
      "price": 22.0,
      "recentPlacements": [19, 20, 18]
    },
    {
      "name": "FAEHNDRICH Nadine",
      "country": "Switzerland",
      "gender": "female",
      "price": 21.5,
      "recentPlacements": [20, 21, 19]
    },
    {
      "name": "ILAR Moa",
      "country": "Sweden",
      "gender": "female",
      "price": 20.5,
      "recentPlacements": [21, 22, 20]
    },
    {
      "name": "FOSNAES Kristin",
      "country": "Norway",
      "gender": "female",
      "price": 20.0,
      "recentPlacements": [22, 23, 21]
    },
    {
      "name": "SANNESS Nora",
      "country": "Norway",
      "gender": "female",
      "price": 19.5,
      "recentPlacements": [23, 24, 22]
    },
    {
      "name": "FINK Pia",
      "country": "Germany",
      "gender": "female",
      "price": 19.0,
      "recentPlacements": [24, 25, 23]
    },
    {
      "name": "PARMAKOSKI Krista",
      "country": "Finland",
      "gender": "female",
      "price": 18.5,
      "recentPlacements": [25, 26, 24]
    },
    {
      "name": "SUNDLING Jonna",
      "country": "Sweden",
      "gender": "female",
      "price": 20.5,
      "recentPlacements": [21, 20, 19]
    },
    {
      "name": "HENNIG Katharina",
      "country": "Germany",
      "gender": "female",
      "price": 19.0,
      "recentPlacements": [24, 23, 22]
    },
    {
      "name": "KERN Julia",
      "country": "USA",
      "gender": "female",
      "price": 16.5,
      "recentPlacements": [28, 29, 27]
    },
    {
      "name": "DAHLQVIST Maja",
      "country": "Sweden",
      "gender": "female",
      "price": 16.0,
      "recentPlacements": [29, 30, 28]
    },
    {
      "name": "GIMMLER Laura",
      "country": "Germany",
      "gender": "female",
      "price": 15.5,
      "recentPlacements": [30, 31, 29]
    },
    {
      "name": "WENG Lotta Udnes",
      "country": "Norway",
      "gender": "female",
      "price": 15.0,
      "recentPlacements": [31, 32, 30]
    },
    {
      "name": "WEBER Anja",
      "country": "Switzerland",
      "gender": "female",
      "price": 14.5,
      "recentPlacements": [32, 33, 31]
    },
    {
      "name": "THEODORSEN Silje",
      "country": "Norway",
      "gender": "female",
      "price": 14.0,
      "recentPlacements": [33, 34, 32]
    },
    {
      "name": "GANZ Caterina",
      "country": "Italy",
      "gender": "female",
      "price": 13.5,
      "recentPlacements": [34, 35, 33]
    },
    {
      "name": "RIBOM Emma",
      "country": "Sweden",
      "gender": "female",
      "price": 13.0,
      "recentPlacements": [35, 36, 34]
    },
    {
      "name": "DOLCI Flora",
      "country": "France",
      "gender": "female",
      "price": 12.5,
      "recentPlacements": [36, 37, 35]
    },
    {
      "name": "RYDZEK Coletta",
      "country": "Germany",
      "gender": "female",
      "price": 12.0,
      "recentPlacements": [37, 38, 36]
    },
    {
      "name": "LAUKLI Sophia",
      "country": "USA",
      "gender": "female",
      "price": 11.5,
      "recentPlacements": [38, 39, 37]
    },
    {
      "name": "SVAHN Linn",
      "country": "Sweden",
      "gender": "female",
      "price": 17.0,
      "recentPlacements": [26, 25, 27]
    },
    {
      "name": "STEWART-JONES Katherine",
      "country": "Canada",
      "gender": "female",
      "price": 11.0,
      "recentPlacements": [39, 40, 38]
    },
    {
      "name": "KAHARA Jasmin",
      "country": "Finland",
      "gender": "female",
      "price": 10.5,
      "recentPlacements": [40, 41, 39]
    },
    {
      "name": "HAGSTROEM Johanna",
      "country": "Sweden",
      "gender": "female",
      "price": 9.5,
      "recentPlacements": [41, 42, 40]
    },
    {
      "name": "HOFFMANN Helen",
      "country": "Germany",
      "gender": "female",
      "price": 9.5,
      "recentPlacements": [41, 42, 40]
    },
    {
      "name": "MYHRE Julie",
      "country": "Norway",
      "gender": "female",
      "price": 9.5,
      "recentPlacements": [41, 42, 40]
    },
    {
      "name": "SKISTAD Kristine Stavaas",
      "country": "Norway",
      "gender": "female",
      "price": 9.0,
      "recentPlacements": [43, 44, 42]
    },
    {
      "name": "KREHL Sofie",
      "country": "Germany",
      "gender": "female",
      "price": 8.5,
      "recentPlacements": [44, 45, 43]
    },
    {
      "name": "GAGNON Liliane",
      "country": "Canada",
      "gender": "female",
      "price": 8.5,
      "recentPlacements": [44, 45, 43]
    },
    {
      "name": "ROSENBERG Maerta",
      "country": "Sweden",
      "gender": "female",
      "price": 8.0,
      "recentPlacements": [45, 46, 44]
    },
    {
      "name": "BRENNAN Rosie",
      "country": "USA",
      "gender": "female",
      "price": 9.5,
      "recentPlacements": [41, 42, 43]
    },
    {
      "name": "KARLSSON Frida",
      "country": "Sweden",
      "gender": "female",
      "price": 22.0,
      "recentPlacements": [5, 4, 6]
    },
    {
      "name": "FOSSESHOLM Helene",
      "country": "Norway",
      "gender": "female",
      "price": 7.0,
      "recentPlacements": [46, 47, 45]
    },
    {
      "name": "AMUNDSEN Hedda",
      "country": "Norway",
      "gender": "female",
      "price": 6.5,
      "recentPlacements": [47, 48, 46]
    },
    {
      "name": "MYHRVOLD Mathilde",
      "country": "Norway",
      "gender": "female",
      "price": 6.0,
      "recentPlacements": [48, 49, 47]
    },
    {
      "name": "JOHNSEN Elena",
      "country": "Norway",
      "gender": "female",
      "price": 6.0,
      "recentPlacements": [48, 49, 47]
    },
    {
      "name": "MANDELJC Anja",
      "country": "Slovenia",
      "gender": "female",
      "price": 6.0,
      "recentPlacements": [48, 49, 50]
    },
    {
      "name": "QUINTIN Lena",
      "country": "France",
      "gender": "female",
      "price": 5.5,
      "recentPlacements": [50, 51, 49]
    },
    {
      "name": "STENSETH Ane",
      "country": "Norway",
      "gender": "female",
      "price": 5.5,
      "recentPlacements": [50, 51, 49]
    },
    {
      "name": "LUNDGREN Moa",
      "country": "Sweden",
      "gender": "female",
      "price": 5.5,
      "recentPlacements": [50, 51, 49]
    },
    {
      "name": "COMARELLA Anna",
      "country": "Italy",
      "gender": "female",
      "price": 5.0,
      "recentPlacements": [52, 53, 51]
    },
    {
      "name": "SAUERBREY Katherine",
      "country": "Germany",
      "gender": "female",
      "price": 5.0,
      "recentPlacements": [52, 53, 51]
    },
    {
      "name": "MATINTALO Johanna",
      "country": "Finland",
      "gender": "female",
      "price": 5.0,
      "recentPlacements": [52, 53, 51]
    },
    {
      "name": "KAELIN Nadja",
      "country": "Switzerland",
      "gender": "female",
      "price": 4.5,
      "recentPlacements": [54, 55, 52]
    },
    {
      "name": "CASSOL Federica",
      "country": "Italy",
      "gender": "female",
      "price": 4.5,
      "recentPlacements": [54, 55, 52]
    },
    {
      "name": "LYLYNPERA Katri",
      "country": "Finland",
      "gender": "female",
      "price": 4.5,
      "recentPlacements": [54, 55, 52]
    },
    {
      "name": "GAL Melissa",
      "country": "France",
      "gender": "female",
      "price": 4.5,
      "recentPlacements": [54, 55, 52]
    },
    {
      "name": "HAVLICKOVA Barbora",
      "country": "Czech Republic",
      "gender": "female",
      "price": 4.0,
      "recentPlacements": [56, 57, 55]
    },
    {
      "name": "SONNESYN Alayna",
      "country": "USA",
      "gender": "female",
      "price": 4.0,
      "recentPlacements": [56, 57, 55]
    },
    {
      "name": "KALVAA Anne Kjersti",
      "country": "Norway",
      "gender": "female",
      "price": 4.0,
      "recentPlacements": [56, 57, 55]
    },
    {
      "name": "PIERREL Julie",
      "country": "France",
      "gender": "female",
      "price": 4.0,
      "recentPlacements": [56, 57, 55]
    },
    //killar

    {
      "name": "KLAEBO Johannes Hoesflot",
      "country": "Norway",
      "gender": "male",
      "price": 32.0,
      "recentPlacements": [1, 1, 2]
    },
    {
      "name": "ANGER Edvin",
      "country": "Sweden",
      "gender": "male",
      "price": 27.0,
      "recentPlacements": [6, 5, 7]
    },
    {
      "name": "VALNES Erik",
      "country": "Norway",
      "gender": "male",
      "price": 26.0,
      "recentPlacements": [8, 7, 9]
    },
    {
      "name": "PELLEGRINO Federico",
      "country": "Italy",
      "gender": "male",
      "price": 25.5,
      "recentPlacements": [9, 10, 8]
    },
    {
      "name": "AMUNDSEN Harald Oestberg",
      "country": "Norway",
      "gender": "male",
      "price": 24.0,
      "recentPlacements": [3, 4, 5]
    },
    {
      "name": "KRUEGER Simen Hegstad",
      "country": "Norway",
      "gender": "male",
      "price": 24.5,
      "recentPlacements": [1, 2, 3]
    },
    {
      "name": "LAPALUS Hugo",
      "country": "France",
      "gender": "male",
      "price": 23.0,
      "recentPlacements": [3, 2, 4]
    },
    {
      "name": "REE Andreas Fjorden",
      "country": "Norway",
      "gender": "male",
      "price": 22.0,
      "recentPlacements": [5, 6, 4]
    },
    {
      "name": "NYENGET Martin Loewstroem",
      "country": "Norway",
      "gender": "male",
      "price": 21.5,
      "recentPlacements": [2, 3, 1]
    },
    {
      "name": "OGDEN Ben",
      "country": "USA",
      "gender": "male",
      "price": 20.0,
      "recentPlacements": [10, 8, 12]
    },
    {
      "name": "VERMEULEN Mika",
      "country": "Austria",
      "gender": "male",
      "price": 19.5,
      "recentPlacements": [9, 10, 11]
    },
    {
      "name": "MOCH Friedrich",
      "country": "Germany",
      "gender": "male",
      "price": 19.0,
      "recentPlacements": [11, 12, 10]
    },
    {
      "name": "DESLOGES Mathis",
      "country": "France",
      "gender": "male",
      "price": 18.5,
      "recentPlacements": [12, 13, 11]
    },
    {
      "name": "SCHUMACHER Gus",
      "country": "USA",
      "gender": "male",
      "price": 18.0,
      "recentPlacements": [14, 13, 15]
    },
    {
      "name": "POROMAA William",
      "country": "Sweden",
      "gender": "male",
      "price": 17.5,
      "recentPlacements": [10, 11, 12]
    },
    {
      "name": "NISKANEN Iivo",
      "country": "Finland",
      "gender": "male",
      "price": 17.0,
      "recentPlacements": [7, 6, 8]
    },
    {
      "name": "GOLBERG Paal",
      "country": "Norway",
      "gender": "male",
      "price": 16.5,
      "recentPlacements": [8, 9, 7]
    },
    {
      "name": "ANDERSEN Iver Tildheim",
      "country": "Norway",
      "gender": "male",
      "price": 16.0,
      "recentPlacements": [15, 14, 16]
    },
    {
      "name": "CHANAVAT Lucas",
      "country": "France",
      "gender": "male",
      "price": 15.5,
      "recentPlacements": [19, 18, 20]
    },
    {
      "name": "VUORINEN Lauri",
      "country": "Finland",
      "gender": "male",
      "price": 15.0,
      "recentPlacements": [57, 58, 56]
    },
    {
      "name": "NORTHUG Even",
      "country": "Norway",
      "gender": "male",
      "price": 14.5,
      "recentPlacements": [5, 4, 6]
    },
    {
      "name": "MUSGRAVE Andrew",
      "country": "United Kingdom",
      "gender": "male",
      "price": 14.0,
      "recentPlacements": [18, 19, 17]
    },
    {
      "name": "JENSSEN Jan Thomas",
      "country": "Norway",
      "gender": "male",
      "price": 13.5,
      "recentPlacements": [20, 21, 19]
    },
    {
      "name": "RUUSKANEN Arsi",
      "country": "Finland",
      "gender": "male",
      "price": 13.0,
      "recentPlacements": [19, 20, 21]
    },
    {
      "name": "NOVAK Michal",
      "country": "Czech Republic",
      "gender": "male",
      "price": 12.5,
      "recentPlacements": [28, 29, 27]
    },
    {
      "name": "CHAPPAZ Jules",
      "country": "France",
      "gender": "male",
      "price": 12.0,
      "recentPlacements": [66, 67, 65]
    },
    {
      "name": "JOUVE Richard",
      "country": "France",
      "gender": "male",
      "price": 11.5,
      "recentPlacements": [67, 68, 66]
    },
    {
      "name": "GROND Valerio",
      "country": "Switzerland",
      "gender": "male",
      "price": 11.0,
      "recentPlacements": [89, 90, 88]
    },
    {
      "name": "SCHOONMAKER JC",
      "country": "USA",
      "gender": "male",
      "price": 10.5,
      "recentPlacements": [83, 84, 82]
    },
    {
      "name": "MALONEY WESTGAARD Thomas",
      "country": "Ireland",
      "gender": "male",
      "price": 10.0,
      "recentPlacements": [21, 22, 20]
    },
    {
      "name": "BOURDIN Remi",
      "country": "France",
      "gender": "male",
      "price": 9.5,
      "recentPlacements": [39, 40, 38]
    },
    {
      "name": "MOSEBY Haavard",
      "country": "Norway",
      "gender": "male",
      "price": 9.0,
      "recentPlacements": [53, 54, 52]
    },
    {
      "name": "ESTEVE ALTIMIRAS Ireneu",
      "country": "Andorra",
      "gender": "male",
      "price": 8.5,
      "recentPlacements": [26, 27, 25]
    },
    {
      "name": "BURMAN Jens",
      "country": "Sweden",
      "gender": "male",
      "price": 8.0,
      "recentPlacements": [23, 24, 22]
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
