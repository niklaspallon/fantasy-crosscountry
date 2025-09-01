import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_fls/handlers/team_details_handler.dart';
import 'package:real_fls/handlers/week_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/team_provider.dart';
import '../handlers/update_points.dart';
import '../services/fetch_from_fis.dart';
import 'package:intl/intl.dart';
import '../screens/admin_screen.dart';

class AdminNewWeekScreen extends StatelessWidget {
  const AdminNewWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          " Skapa ny spelvecka",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 2,
      ),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: NewWeekWidget(),
            ),
          ),
        ),
      ),
    );
  }
}

class NewWeekWidget extends StatefulWidget {
  NewWeekWidget({super.key});

  @override
  State<NewWeekWidget> createState() => _NewWeekState();
}

class _NewWeekState extends State<NewWeekWidget> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime? selectedDeadline;

  String selectedGender = "Women";
  String selectedStyle = "Classic";
  String selectedType = "Sprint";

  List<String> competitions = [];

  final List<String> styles = ["Classic", "Free"];
  final List<String> genders = ["Women", "Men"];
  final List<String> raceTypes = [
    "Sprint",
    "10 KM Individual",
    "15 KM Individual",
    "20 KM Individual",
    "30 KM Mass start",
    "50 KM Mass start",
    "Skiathlon",
    "Teamsprint",
    "Pursuit",
    "Relay",
  ];

  /// 🔹 Datumväljare
  Future<void> _pickDeadline() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDeadline = pickedDate;
      });
    }
  }

  /// 🔹 Hämta tid från input
  DateTime? _getTimeFromInput() {
    if (_timeController.text.isEmpty || selectedDeadline == null) return null;

    try {
      final timeParts = _timeController.text.split(':');
      if (timeParts.length != 2) return null;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      return DateTime(
        selectedDeadline!.year,
        selectedDeadline!.month,
        selectedDeadline!.day,
        hour,
        minute,
      );
    } catch (e) {
      return null;
    }
  }

  void _addCompetition() {
    final String location = _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Ange tävlingsplats först!")),
      );
      return;
    }
    final String comp =
        "$selectedGender's $selectedType $selectedStyle $location";
    if (!competitions.contains(comp)) {
      setState(() {
        competitions.add(comp);
      });
    }
  }

  void _removeCompetition(String comp) {
    setState(() {
      competitions.remove(comp);
    });
  }

  Future<bool> _showSummaryDialog(BuildContext context, String location,
      DateTime deadline, List<String> competitions) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.blue, size: 28),
                SizedBox(width: 8),
                Text("Sammanfattning"),
              ],
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                location,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.blue),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(deadline),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "🏁 Tävlingar:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: competitions
                          .map((c) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    const Icon(Icons.flag,
                                        size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Flexible(
                                        child: Text(c,
                                            style:
                                                const TextStyle(fontSize: 15))),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Avbryt"),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Bekräfta"),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.event, color: Colors.blue, size: 28),
                SizedBox(width: 10),
                Text(
                  "Ny spelvecka",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Tävlingsplats",
                prefixIcon: const Icon(Icons.location_on_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDeadline,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Välj deadline"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (selectedDeadline != null)
                  Text(
                    DateFormat('yyyy-MM-dd').format(selectedDeadline!),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: "Tid (HH:mm)",
                hintText: "Ex: 18:30",
                prefixIcon: const Icon(Icons.access_time),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.blue.shade50,
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 28),
            Divider(color: Colors.blue.shade100, thickness: 1.2),
            const SizedBox(height: 10),
            const Text(
              "📋 Lägg till tävling",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedGender,
                    items: genders
                        .map((gender) => DropdownMenuItem(
                            value: gender, child: Text(gender)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedGender = value!),
                    decoration: const InputDecoration(labelText: "Kön"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStyle,
                    items: styles
                        .map((style) =>
                            DropdownMenuItem(value: style, child: Text(style)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedStyle = value!),
                    decoration: const InputDecoration(labelText: "Stil"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedType,
              items: raceTypes
                  .map((type) =>
                      DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) => setState(() => selectedType = value!),
              decoration: const InputDecoration(labelText: "Gren"),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _addCompetition,
                icon: const Icon(Icons.add),
                label: const Text("Lägg till tävling"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (competitions.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: competitions
                    .map((comp) => Chip(
                          label: Text(comp),
                          backgroundColor: Colors.blue.shade100,
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => _removeCompetition(comp),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 28),
            Divider(color: Colors.blue.shade100, thickness: 1.2),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final location = _locationController.text.trim();
                  final fullDeadline = _getTimeFromInput();

                  if (location.isEmpty ||
                      fullDeadline == null ||
                      competitions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "❌ Fyll i plats, deadline, tid och tävlingar!")));
                    return;
                  }

                  final confirmed = await _showSummaryDialog(
                      context, location, fullDeadline, competitions);
                  if (!confirmed) return;

                  await incrementWeek(
                      context, location, fullDeadline, competitions);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text("Ny vecka skapad!, alla funktioner klara"),
                      duration: const Duration(days: 1),
                      action: SnackBarAction(
                        label: "Stäng",
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch),
                label: const Text("Skapa ny vecka"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
