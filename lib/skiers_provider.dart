import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'week_handler.dart';

class SkiersProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _locSkiers = [];
  bool _isLoading = true;
  bool _isFetched = false;
  int _latestWeek = 0;

  List<Map<String, dynamic>> get locSkiers => _locSkiers;
  bool get isLoading => _isLoading;

  late Future<void> _initialLoad;

  SkiersProvider() {
    _initialLoad = _initialize();
  }

  Future<void> _initialize() async {
    _latestWeek = await getCurrentWeek();
    await fetchSkiers();
  }

  Future<void> fetchSkiers() async {
    if (_isFetched) return;

    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot snapshot = await _db.collection('SkiersDb').get();
      List<String> skierIds = snapshot.docs.map((doc) => doc.id).toList();

      Map<String, int> skierPointsMap =
          await getAllSkiersPoints(skierIds, _latestWeek);

      List<Map<String, dynamic>> fetchedSkiers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String skierId = doc.id;

        return {
          ...data,
          'id': skierId,
          'points': skierPointsMap[skierId] ?? 0,
        };
      }).toList();

      _locSkiers = fetchedSkiers;
      _isFetched = true;
    } catch (e) {
      print("❌ Error fetching skiers: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, int>> getAllSkiersPoints(
      List<String> skierIds, int weekNumber) async {
    Map<String, int> skierPointsMap = {};

    try {
      List<Future<QuerySnapshot>> futures = skierIds.map((skierId) {
        return _db
            .collection('SkiersDb')
            .doc(skierId)
            .collection('weeklyPoints')
            .doc("week$weekNumber")
            .collection('competitions')
            .get();
      }).toList();

      List<QuerySnapshot> results = await Future.wait(futures);

      for (int i = 0; i < results.length; i++) {
        int totalPoints = results[i].docs.fold<int>(
              0,
              (sum, doc) => sum + ((doc.get('points') ?? 0) as num).toInt(),
            );
        skierPointsMap[skierIds[i]] = totalPoints;
      }
    } catch (e) {
      print("❌ Error fetching batch skier points: $e");
    }

    return skierPointsMap;
  }

  Future<void> get initialLoad => _initialLoad;
}
