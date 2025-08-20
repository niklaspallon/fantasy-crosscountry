import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../designs/alertdialog_skier.dart';
import 'skiers_provider.dart';
import 'package:provider/provider.dart';
import '../handlers/week_handler.dart';
import 'dart:math';

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
      'freeTransfers': 0,
      'createdGw': currentWeek,
      'isFullTeam': false,
      'unlimitedTransfers':
          true, // Sätter till true för att börja med oändliga byten
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
      'captain': null,
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

  List<Map<String, dynamic>> _lastSavedTeam = [];
  List<Map<String, dynamic>> get lastSavedTeam => _lastSavedTeam;

  bool _hasTeamChanged = false;
  bool get hasTeamChanged => _hasTeamChanged;

  bool _hasFetchedTeamName =
      false; // Flagga för att kolla om vi redan har hämtat teamName

  double _totalBudget = 0;
  double get totalBudget => _totalBudget;

  double _firebaseBudget = 0;
  double get firebaseBudget => _firebaseBudget;

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

  int _freeTransfers = 1;
  int get freeTransfers => _freeTransfers;

  bool _unlimitedTransfers = true;
  bool get unlimitedTransfers => _unlimitedTransfers;

  double _delta = 0;
  double get delta => _delta;

  int _createdGw = 1;
  int get createdGw => _createdGw;

  bool _isFullTeam = false;
  bool get isFullTeam => _isFullTeam;

  List<String> _upcomingEvents = [];
  List<String> get upcomingEvents => _upcomingEvents;

  int _numberOfChanges = 0;
  int get numberOfChanges => _numberOfChanges;

  TeamProvider() {
    fetchWeekData();

    checkIfUserIsAdmin(); // Kolla om användaren är admin
    _initializeOwnerId();
    fetchTeamName();
    getUserTeam();
    getReaminingBudgetFromFb();
    getRemainingBudget();
    getTeamTotalPoints();
    updateUpcomingEvents();
  }
  int get paidTransfers {
    final transfers = _numberOfChanges - _freeTransfers;
    return transfers > 0 ? transfers : 0;
  }

  int get visibleFreeTransfers {
    final remaining = _freeTransfers - _numberOfChanges;
    return remaining > 0 ? remaining : 0;
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

  Future<void> fetchFreeTransfers() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String uid = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot teamSnapshot =
          await db.collection('teams').where('ownerId', isEqualTo: uid).get();

      if (teamSnapshot.docs.isNotEmpty) {
        _createdGw = teamSnapshot.docs.first.get('createdGw') ?? 1;
        _freeTransfers = teamSnapshot.docs.first.get('freeTransfers') ?? 1;
        _isFullTeam = teamSnapshot.docs.first.get('isFullTeam') ?? true;
        if (_isFullTeam == true && _createdGw != _currentWeek) {
          _unlimitedTransfers = false;
        }

        notifyListeners();
      }
    } catch (e) {
      print("❌ Fel vid hämtning av freeTransfers: $e");
    }
  }

  Future<void> decreaseFreeTransfersFb(int numberOfChanges) async {
    try {
      final db = FirebaseFirestore.instance;
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      final teamSnapshot =
          await db.collection('teams').where('ownerId', isEqualTo: uid).get();

      if (teamSnapshot.docs.isEmpty) {
        print("❌ Inget lag hittades för användaren.");
        return;
      }

      final teamDoc = teamSnapshot.docs.first;
      final teamId = teamDoc.id;
      final teamData = teamDoc.data() as Map<String, dynamic>;
      final int currentFreeTransfers = teamData['freeTransfers'] ?? 0;

      if (currentFreeTransfers <= 0) {
        print("⚠️ Inga fria transfers kvar att minska.");
        return;
      }

      final int newFreeTransfers =
          (currentFreeTransfers - numberOfChanges).clamp(0, 99);

      await db
          .collection('teams')
          .doc(teamId)
          .update({'freeTransfers': newFreeTransfers});

      print("✅ Free transfers updated till: $newFreeTransfers");
    } catch (e) {
      print("❌ Fel vid minskning av freeTransfers: $e");
    }
  }

  Future<void> setFullTeam() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String uid = FirebaseAuth.instance.currentUser!.uid;

      QuerySnapshot teamSnapshot =
          await db.collection('teams').where('ownerId', isEqualTo: uid).get();
      if (teamSnapshot.docs.isNotEmpty) {
        _createdGw = teamSnapshot.docs.first.get('createdGw') ?? 1;
        _isFullTeam = teamSnapshot.docs.first.get('isFullTeam') ?? false;
        if (_createdGw != _currentWeek && isFullTeam == true) {
          _isFullTeam = false;
          await db.collection('teams').doc(teamSnapshot.docs.first.id).update({
            'isFullTeam': true,
          });
          notifyListeners();
          print("Laget är inte fullt längre");
        }
      }
    } catch (e) {
      print("❌ Fel vid hämtning av isFullTeam: $e");
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
        _lastSavedTeam = [];
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
        _lastSavedTeam = [];
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
        _lastSavedTeam = [];
        _weekPoints = 0;
        notifyListeners();
        return;
      }

      List<Map<String, dynamic>> fetchedTeam = [];
      int totalPoints = 0;

      for (var skierData in skierRawList) {
        final String skierId = skierData['skierId'];
        int totalWeeklyPoints = skierData['totalWeeklyPoints'] ?? 0;
        double price = (skierData['price'] ?? 0).toDouble();

        if (skierId == _captain) {
          totalWeeklyPoints *= 2;
        }
        final marketPrice = skierData.containsKey('marketPrice')
            ? skierData['marketPrice']
            : null;

        fetchedTeam.add({
          'id': skierId,
          'name': skierData['name'],
          'country': skierData['country'],
          'totalWeeklyPoints': totalWeeklyPoints,
          'price': price, // 🔥 Lägg till priset här
          'gender': skierData['gender'],
          'marketPrice': marketPrice
        });

        totalPoints += totalWeeklyPoints;
      }

      _userTeam = fetchedTeam;
      _lastSavedTeam =
          fetchedTeam.map((skier) => Map<String, dynamic>.from(skier)).toList();
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

        int totalWeeklyPoints = 0;

        if (weekDoc.exists && weekDoc.data() != null) {
          var data = weekDoc.data();
          if (data is Map<String, dynamic>) {
            totalWeeklyPoints = (data['totalWeeklyPoints'] ?? 0) as int;
          }
        }

        skierPointsMap[skierIds[i]] = totalWeeklyPoints;
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
    _totalBudget = _firebaseBudget - playerCost;

    notifyListeners();
  }

  void applyBudgetDeltaLocally(double delta) {
    _delta = delta;
    _firebaseBudget += delta;
    print("loklt budget uppdaterad: $_firebaseBudget");
    getRemainingBudget(); // Uppdaterar _totalBudget = _firebaseBudget - alla åkares pris
  }

  Future<void> getReaminingBudgetFromFb() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;

      QuerySnapshot teamSnapshot = await db
          .collection('teams')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (teamSnapshot.docs.isEmpty) return;

      _firebaseBudget = teamSnapshot.docs.first.get('budget') ?? 0;
      _totalBudget = _firebaseBudget;
      print("Firebase budget: $_firebaseBudget");
      notifyListeners();
    } catch (e) {
      print("❌ Fel vid hämtning av lagets budget: $e");
    }
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

  void updateTeamChangeStatus() {
    final currentIds = _userTeam.map((s) => s['id'] as String).toSet();
    final savedIds = _lastSavedTeam.map((s) => s['id'] as String).toSet();

    final removed = savedIds.difference(currentIds).length;
    final added = currentIds.difference(savedIds).length;

    final changes = min(removed, added);

    _numberOfChanges = changes;
    _hasTeamChanged = changes > 0;

    notifyListeners();
  }

  Future<void> removeSkierFromTeam(String skierId, BuildContext context) async {
    try {
      print("kördes");
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
      final skier = _userTeam[skierIndex];
      final double buyPrice = (skier['price'] as num).toDouble();
      final double marketPrice = (skier['marketPrice'] ?? buyPrice) is num
          ? (skier['marketPrice'] ?? buyPrice).toDouble()
          : double.tryParse(skier['marketPrice'].toString()) ?? buyPrice;

      final double delta = marketPrice - buyPrice;
      print(
          "Skidåkare: ${skier['name']}, buyPrice: $buyPrice, marketPrice: $marketPrice, delta: $delta");

      // Om åkaren är kapten, ta bort kaptenstatus
      if (skierId == _captain) {
        _captain = "";

        // Uppdatera kapten i Firebase
        FirebaseFirestore db = FirebaseFirestore.instance;
        QuerySnapshot teamSnapshot = await db
            .collection('teams')
            .where('ownerId', isEqualTo: ownerId)
            .get();

        if (teamSnapshot.docs.isNotEmpty) {
          String teamId = teamSnapshot.docs.first.id;
          await db
              .collection('teams')
              .doc(teamId)
              .collection('weeklyTeams')
              .doc("week$_currentWeek")
              .update({
            'captain': null,
          });
        } else {
          print("inga kaptener i laget");
        }
      }

      // Ta bort åkaren
      _userTeam.removeAt(skierIndex);

      applyBudgetDeltaLocally(delta);
      getRemainingBudget();
      await adjustTeamBudgetFB(delta);

      // Kontrollera om laget har ändrats
      updateTeamChangeStatus();

      notifyListeners();

      // Uppdatera UI
      notifyListeners();
    } catch (e) {
      showAlertDialog(context, "❌ Fel vid borttagning av åkare!", "$e");
    }
  }

  Future<void> adjustTeamBudgetFB(double delta) async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;

      // 🔍 Hämta lagdokument baserat på ownerId
      final teamSnapshot = await db
          .collection('teams')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (teamSnapshot.docs.isEmpty) {
        print("❌ Inget lag hittades för användaren.");
        return;
      }

      final docRef = teamSnapshot.docs.first.reference;
      final docData = teamSnapshot.docs.first.data();

      // ✅ Casta till double säkert
      final double currentBudget = (docData['budget'] is num)
          ? (docData['budget'] as num).toDouble()
          : 100.0;

      final double newBudget = (currentBudget + delta).clamp(0.0, 200.0);

      await docRef.update({'budget': newBudget});
      _firebaseBudget = newBudget;

      print("💰 Budget justerad: $currentBudget ➜ $newBudget (delta: $delta)");

      notifyListeners();
    } catch (e) {
      print("❌ Fel vid justering av budget: $e");
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
      if (_userTeam.length >= 6) {
        showAlertDialog(
            context, "🚫 Fullt lag!", "Du kan bara ha 6 åkare i ditt lag.");
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
      updateTeamChangeStatus();

      // 🔹 Uppdatera budgeten lokalt
      _totalBudget -= skierPrice;

      // Kontrollera om laget har ändrats

      // 🔹 Uppdatera UI
      notifyListeners();

      return true; // Åkaren lades till korrekt
    } catch (e) {
      showAlertDialog(context, "❌ Fel vid tillägg av åkare!", "$e");
      return false;
    }
  }

  Future<bool> canMakeTransfers() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;

      // Hämta team-dokumentet
      QuerySnapshot teamSnapshot = await db
          .collection('teams')
          .where('ownerId', isEqualTo: ownerId)
          .get();

      if (teamSnapshot.docs.isEmpty) {
        print("❌ Inget team hittades i Firestore (ownerId: $ownerId)");
        return false;
      }

      final teamData = teamSnapshot.docs.first.data() as Map<String, dynamic>;

      // Kolla om användaren har oändliga byten
      bool hasUnlimitedTransfers = teamData['unlimitedTransfers'] ?? false;

      if (hasUnlimitedTransfers) return true;
      if (!hasTeamChanged) {
        print("Spelaren har inte gjort några byten denna vecka");
        return true;
      }

      if (freeTransfers >= numberOfChanges && _userTeam.length >= 6) {
        print(
            "Anävndaren gör $numberOfChanges och har  $_freeTransfers fria byten kvar");
        return true;
      } else if (_teamTotalPoints >= 40 && _userTeam.length >= 6) {
        print(
            "Användaren har tillräckligt med poäng för att betala för ett byte, antal ponäg : $_teamTotalPoints");
        return true;
      }

      return false;
    } catch (e) {
      print("❌ Fel vid kontroll av transfers: $e");
      return false;
    }
  }

  Future<void> saveTeamToFirebase(BuildContext context) async {
    try {
      // Kolla först om användaren kan göra transfers

      bool canMakeTransfer = await canMakeTransfers();

      if (!canMakeTransfer) {
        print(freeTransfers);
        showAlertDialog(context, "Inga transfers kvar",
            "Du har inga transfers kvar denna vecka. Vänta till nästa vecka för att göra ändringar.");
        return;
      }
      if (_userTeam.length < 6) {
        showAlertDialog(context, "För få åkare",
            "Du behöver 6 åkare i ditt lag för att spara det.");
        return;
      }

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
          'price': skier['price'] ?? 0,
          'gender': skier['gender'],
          'marketPrice': skier['marketPrice'] ?? skier['price'],
        };
      }).toList();

      // 🔥 Uppdatera Firestore med lagets åkardata
      await weeklyTeamRef.set({
        'weekNumber': _currentWeek,
        'captain': _captain,
        'skiers': fullSkierData,
      }, SetOptions(merge: true));
      if (_userTeam.length == 6) {
        await db.collection('teams').doc(teamId).update({
          'isFullTeam': true,
        });
      }
      if (hasTeamChanged && unlimitedTransfers == false) {
        decreaseFreeTransfersFb(numberOfChanges);

        if (paidTransfers > 0) {
          await payForTransferFB();
          print("✅ Betalda transfers: $paidTransfers");
        }
      }

      showSuccessDialog(
          context, "✅ Lag sparat!", "Ditt lag har sparats för $_currentWeek");

      markTeamAsSaved();

      print("✅ Lag + åkardata sparat till Firestore för vecka $_currentWeek!");
    } catch (e) {
      showAlertDialog(context, "❌ Fel vid sparande av lag!", "$e");
    }
  }

  Future<void> updateUpcomingEvents() async {
    _upcomingEvents = await fetchUpcomingEvents();
    notifyListeners();
  }

  void markTeamAsSaved() {
    // Markera laget som sparat vilket behövs för att uppdatera mapen när man trycker på "save team"
    _lastSavedTeam =
        _userTeam.map((skier) => Map<String, dynamic>.from(skier)).toList();
    _hasTeamChanged = false;
    notifyListeners();
  }

  void decreaseFreeTransfers() {
    if (freeTransfers > 0) {
      _freeTransfers -= numberOfChanges;
      print("Free transfers decreased by number of changes: $numberOfChanges");

      notifyListeners();
    } else {
      print("No free transfers left to decrease");
    }
  }

  void addFreeTransfers() {
    if (freeTransfers > 0) {
      _freeTransfers -= numberOfChanges;
      print("Free transfers decreased by number of changes: $numberOfChanges");

      notifyListeners();
    } else {
      print("No free transfers left to decrease");
    }
  }

  Future<void> payForTransferFB() async {
    try {
      final db = FirebaseFirestore.instance;
      final uid = ownerId;

      final teamSnapshot =
          await db.collection('teams').where('ownerId', isEqualTo: uid).get();

      if (teamSnapshot.docs.isNotEmpty && paidTransfers > 0) {
        final teamId = teamSnapshot.docs.first.id;
        final int pointsToDeduct = paidTransfers * 40;

        await db.collection('teams').doc(teamId).update({
          'totalPoints': FieldValue.increment(-pointsToDeduct),
        });

        _teamTotalPoints -= pointsToDeduct;
        notifyListeners();

        print("✅ Total points decreased by $pointsToDeduct");
      } else {
        print("ℹ️ Inga betalda transfers, inga poäng att dra av.");
      }
    } catch (e) {
      print("❌ Error decreasing total points: $e");
    }
  }
}
