import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'alertdialog_skier.dart';
import 'skiers_provider.dart';
import 'package:provider/provider.dart';
import 'week_handler.dart';

Future<void> createTeam(String teamName) async {
  try {
    FirebaseFirestore db = FirebaseFirestore.instance;
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    // 🔹 1️⃣ Hämta aktuell spelvecka från Firestore
    int currentWeek = await getCurrentWeek();

    // 🔹 2️⃣ Skapa team-dokumentet
    DocumentReference teamRef = await db.collection('teams').add({
      'teamName': teamName,
      'ownerId': uid,
      'budget': 100,
      'totalPoints': 0,
      'isAdmin': false,
    });

    String teamId = teamRef.id;

    // 🔹 3️⃣ Skapa veckostruktur för den aktuella veckan
    await db
        .collection('teams')
        .doc(teamId)
        .collection('weeklyTeams')
        .doc("week$currentWeek")
        .set({
      'weekNumber': currentWeek,
      'skiers': [],
      'weeklyPoints': 0,
      'captain': null
    });

    print(
        "✅ Lag skapat med ID: $teamId och första veckan ($currentWeek) sparad!");
  } catch (e) {
    print("❌ Fel vid skapande av lag: $e");
  }
}

class TeamProvider extends ChangeNotifier {
  String _captain = "";
  String get captain => _captain;

  List<Map<String, dynamic>> _userTeam = [];
  List<Map<String, dynamic>> get userTeam => _userTeam;

  bool _hasFetchedTeamName =
      false; // Flagga för att kolla om vi redan har hämtat teamName

  double _totalBudget = 0;
  double get totalBudget => _totalBudget;

  int _weekPoints = 0;
  int get weekPoints => _weekPoints;

  String _ownerId = "";
  String get ownerId => _ownerId;

  int _teamTotalPoints = 0;
  int get teamTotalPoints => _teamTotalPoints;

  int _currentWeek = 1;
  int get currentWeek => _currentWeek;

  DateTime? _weekDeadline;
  DateTime? get weekDeadline => _weekDeadline;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  String _teamName = "";
  String get teamName => _teamName;

  TeamProvider() {
    checkIfUserIsAdmin(); // Kolla om användaren är admin
    _initializeOwnerId();
    fetchTeamName();
    getUserTeam();
    getRemainingBudget();
    getTeamTotalPoints();
    fetchWeekData();
  }

  void setLocalCaptain(skierId) {
    _captain = skierId;
    print("$skierId, sattes som kapten");
    notifyListeners();
  }

  void _initializeOwnerId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _ownerId = currentUser.uid;
      notifyListeners();
      print("OwnerId initierat: $_ownerId");
    }
  }

  Future<void> checkIfUserIsAdmin() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String uid = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot teamSnapshot =
          await db.collection('teams').where('ownerId', isEqualTo: uid).get();

      if (teamSnapshot.docs.isNotEmpty) {
        _isAdmin = teamSnapshot.docs.first.get('isAdmin') ?? false;
      } else {
        _isAdmin = false;
      }

      notifyListeners();
    } catch (e) {
      print("❌ Fel vid hämtning av admin-status: $e");
      _isAdmin = false;
    }
  }

  Future<void> fetchWeekData() async {
    try {
      _currentWeek = await getCurrentWeek();
      _weekDeadline = await getCurrentDeadline();

      print("📅 Vecka: $_currentWeek, Deadline: $_weekDeadline");
      notifyListeners(); // 🔁 Uppdatera UI
    } catch (e) {
      print("❌ Fel vid fetchWeekData: $e");
    }
  }

  Future<void> fetchTeamName() async {
    if (_hasFetchedTeamName)
      return; // Om teamName redan hämtats, gör inget nytt anrop

    try {
      FirebaseFirestore db = FirebaseFirestore.instance;

      String uid = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot snapshot =
          await db.collection('teams').where('ownerId', isEqualTo: uid).get();

      if (snapshot.docs.isNotEmpty) {
        _teamName = snapshot.docs.first.get('teamName');
        _hasFetchedTeamName = true; // Markera att teamName har hämtats
        notifyListeners(); // Uppdatera UI med nytt teamName
        print("Team name fetched and set: $_teamName");
      }
    } catch (e) {
      print("❌ Error fetching team name: $e");
    }
  }

  Future<void> getUserTeam() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;

      // 🔹 Hämta lag-id för användaren
      QuerySnapshot teamSnapshot = await db
          .collection('teams')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (teamSnapshot.docs.isEmpty) {
        _userTeam = [];
        _weekPoints = 0;
        _captain = "";
        notifyListeners();
        return;
      }

      String teamId = teamSnapshot.docs.first.id;

      // 🔹 Hämta veckodokumentet för det laget
      DocumentSnapshot weeklyTeamDoc = await db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$_currentWeek")
          .get();

      if (!weeklyTeamDoc.exists) {
        _userTeam = [];
        _weekPoints = 0;
        _captain = "";
        notifyListeners();
        return;
      }

      final data = weeklyTeamDoc.data() as Map<String, dynamic>;

      // 🔹 Sätt kapten
      _captain = data['captain'] ?? '';

      // 🔹 Hämta åkardata direkt från dokumentet
      List<dynamic> skierRawList = data['skiers'] ?? [];
      if (skierRawList.isEmpty) {
        _userTeam = [];
        _weekPoints = 0;
        notifyListeners();
        return;
      }

      List<Map<String, dynamic>> fetchedTeam = [];
      int totalPoints = 0;

      for (var skierData in skierRawList) {
        final String skierId = skierData['skierId'];
        int points = skierData['totalWeeklyPoints'] ?? 0;
        double price = (skierData['price'] ?? 0).toDouble();

        if (skierId == _captain) {
          points *= 2;
        }

        fetchedTeam.add({
          'id': skierId,
          'name': skierData['name'],
          'country': skierData['country'],
          'points': points,
          'price': price, // 🔥 Lägg till priset här
        });

        totalPoints += points;
      }

      _userTeam = fetchedTeam;
      _weekPoints = totalPoints;

      print("✅ Lag för vecka $_currentWeek hämtat med poäng: $_weekPoints");
      getRemainingBudget();
      notifyListeners();
    } catch (e) {
      print("❌ Fel vid hämtning av lagets skidåkare: $e");
    }
  }

  Future<Map<String, int>> getAllSkiersPoints(
      List<String> skierIds, int weekNumber) async {
    Map<String, int> skierPointsMap = {};

    try {
      List<Future<DocumentSnapshot>> futures = skierIds.map((skierId) {
        return FirebaseFirestore.instance
            .collection('SkiersDb')
            .doc(skierId)
            .collection('weeklyResults')
            .doc("week$weekNumber")
            .get();
      }).toList();

      List<DocumentSnapshot> results =
          await Future.wait(futures); // 🔥 Batch-hämtning

      for (int i = 0; i < results.length; i++) {
        DocumentSnapshot weekDoc = results[i];

        int totalPoints = 0;
        if (weekDoc.exists && weekDoc.data() != null) {
          var data = weekDoc.data();
          if (data is Map<String, dynamic>) {
            totalPoints = (data['totalWeeklyPoints'] ?? 0) as int;
          }
        }

        skierPointsMap[skierIds[i]] = totalPoints;
      }
    } catch (e) {
      print("❌ Error fetching totalWeeklyPoints for skiers: $e");
    }

    return skierPointsMap;
  }

  void getRemainingBudget() {
    double playerCost = 0;
    for (var skier in _userTeam) {
      playerCost += (skier['price'] as num).toDouble();
    }
    _totalBudget = 100 - playerCost;
    notifyListeners();
  }

  Future<void> getTeamTotalPoints() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      //await fetchWeekData(); ta bort??

      QuerySnapshot teamSnapshot = await db
          .collection('teams')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (teamSnapshot.docs.isEmpty) return;

      _teamTotalPoints = teamSnapshot.docs.first.get('totalPoints') ?? 0;
      notifyListeners();
    } catch (e) {
      print("❌ Fel vid hämtning av lagets totalpoäng: $e");
    }
  }

  Future<void> removeSkierFromTeam(String skierId, BuildContext context) async {
    try {
      // 🚫 Kontrollera om deadline har passerat
      if (_weekDeadline != null && DateTime.now().isAfter(_weekDeadline!)) {
        showAlertDialog(context, "🚫 Deadline har passerat!",
            "Du kan inte ta bort åkare efter deadline.");
        return;
      }

      // Kontrollera om åkaren finns i laget
      var skierIndex = _userTeam.indexWhere((skier) => skier['id'] == skierId);

      if (skierIndex == -1) {
        showAlertDialog(context, "⚠️ Åkaren hittades inte!",
            "Den här åkaren finns inte i ditt lag.");
        return;
      }

      // Ta bort åkaren
      _userTeam.removeAt(skierIndex);
      print("✅ Åkare $skierId borttagen från det lokala laget!");

      // Uppdatera budgeten lokalt
      getRemainingBudget();

      // Uppdatera UI
      notifyListeners();
    } catch (e) {
      showAlertDialog(context, "❌ Fel vid borttagning av åkare!", "$e");
    }
  }

  Future<bool> addSkierToTeam(String skierId, BuildContext context) async {
    List<Map<String, dynamic>> locSkiers =
        context.read<SkiersProvider>().locSkiers;

    try {
      // Trigger feedback if context is valid
      if (context != null) {
        await Feedback.forTap(context); // Trigger platform feedback
      }

      // Kontrollera om deadline har passerat
      if (_weekDeadline != null && DateTime.now().isAfter(_weekDeadline!)) {
        showAlertDialog(context, "🚫 Deadline har passerat!",
            "Du kan inte byta åkare efter deadline.");
        return false;
      }

      // Kontrollera om åkaren redan finns i laget
      if (_userTeam.any((skier) => skier['id'] == skierId)) {
        showAlertDialog(context, "⚠️ Åkaren finns redan!",
            "Den här åkaren är redan med i ditt lag.");
        return false;
      }

      // Kontrollera om laget har plats för fler åkare (max 8 åkare)
      if (_userTeam.length >= 8) {
        showAlertDialog(
            context, "🚫 Fullt lag!", "Du kan bara ha 8 åkare i ditt lag.");
        return false;
      }

      // Hämta åkardata från den lokala listan
      Map<String, dynamic>? skierData = locSkiers.firstWhere(
        (skier) => skier['id'] == skierId,
        orElse: () => <String, dynamic>{}, // Returnera en tom Map istället
      );

      // Om åkaren inte hittas, visa felmeddelande
      if (skierData.isEmpty) {
        showAlertDialog(context, "❌ Åkaren hittades inte!",
            "Den valda åkaren kunde inte hittas i den lokala databasen.");
        return false;
      }

      String skierCountry = skierData['country'] ?? "Unknown";
      String skierGender = skierData['gender'] ?? "Unknown";
      double skierPrice = (skierData['price'] as num).toDouble();

      // 🔹 Kontrollera om budgeten räcker
      if (_totalBudget - skierPrice < 0) {
        showAlertDialog(context, "💰 Budget överskriden!",
            "Du har inte råd att lägga till denna åkare.");
        return false;
      }

      // Skapa räknare för kön och land i nuvarande lag
      Map<String, int> countryCount = {};
      Map<String, int> genderCount = {};

      for (var skier in _userTeam) {
        String country = skier['country'] ?? "Unknown";
        String gender = skier['gender'] ?? "Unknown";

        countryCount[country] = (countryCount[country] ?? 0) + 1;
        genderCount[gender] = (genderCount[gender] ?? 0) + 1;
      }

      // Kontrollera om laget har för många från samma land
      if ((countryCount[skierCountry] ?? 0) >= 3) {
        showAlertDialog(context, "🚫 För många från $skierCountry!",
            "Du kan max ha 3 åkare från detta land.");
        return false;
      }

      // Kontrollera om laget har för många av samma kön
      if ((genderCount[skierGender] ?? 0) >= 3) {
        showAlertDialog(context, "🚫 För många $skierGender!",
            "Du kan max ha 3 åkare av detta kön.");
        return false;
      }

      // Lägg till åkaren i det lokala laget
      _userTeam.add(skierData);
      print("$skierId, lades till");

      // 🔹 Uppdatera budgeten lokalt
      _totalBudget -= skierPrice;
      print("Ny budget: $_totalBudget");

      // 🔹 Uppdatera UI
      notifyListeners();

      return true; // Åkaren lades till korrekt
    } catch (e) {
      showAlertDialog(context, "❌ Fel vid tillägg av åkare!", "$e");
      return false;
    }
  }

  Future<void> saveTeamToFirebase(BuildContext context) async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;

      // Hämta lag-ID för nuvarande användare
      QuerySnapshot teamSnapshot = await db
          .collection('teams')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (teamSnapshot.docs.isEmpty) {
        showAlertDialog(context, "❌ Inget lag hittades!",
            "Ditt lag kunde inte hittas i databasen.");
        return;
      }

      String teamId = teamSnapshot.docs.first.id;
      DocumentReference weeklyTeamRef = db
          .collection('teams')
          .doc(teamId)
          .collection('weeklyTeams')
          .doc("week$_currentWeek");

      // Skapa lista med full åkardata (inklusive price!)
      List<Map<String, dynamic>> fullSkierData = _userTeam.map((skier) {
        return {
          'skierId': skier['id'],
          'name': skier['name'],
          'country': skier['country'],
          'totalWeeklyPoints': skier['points'],
          'isCaptain': skier['id'] == _captain,
          'price': skier['price'] ?? 0, // ✅ Lägg till priset här
        };
      }).toList();

      // 🔥 Uppdatera Firestore med lagets åkardata
      await weeklyTeamRef.set({
        'weekNumber': _currentWeek,
        'captain': _captain,
        'skiers': fullSkierData,
      }, SetOptions(merge: true));

      showSuccessDialog(
          context, "✅ Lag sparat!", "Ditt lag har sparats för $_currentWeek");

      print("✅ Lag + åkardata sparat till Firestore för vecka $_currentWeek!");
    } catch (e) {
      showAlertDialog(context, "❌ Fel vid sparande av lag!", "$e");
    }
  }
}
