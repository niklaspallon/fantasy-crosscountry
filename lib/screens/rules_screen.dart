import 'package:flutter/material.dart';
import 'package:real_fls/main.dart';
import '../designs/button_design.dart';
import '../designs/appbar_design.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: "Rules",
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A237E).withOpacity(0.95),
              Colors.blue[900]!.withOpacity(0.85),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle("1. Spelupplägg"),
            _sectionText(
              "lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            ),
            _sectionTitle("2. Poängsystem"),
            _sectionText(
              "lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            ),
            _sectionTitle("3. Byten"),
            _sectionText(
              "lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            ),
            _sectionTitle("4. Miniligor"),
            _sectionText(
              "Du kan skapa eller gå med i privata ligor där du tävlar mot vänner.",
            ),
            _sectionTitle("5. Fusk"),
            _sectionText(
              "Användning av flera konton eller manipulation av resultat leder till avstängning.",
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                "Version 1.0 – Fantasy Crosscountry 2025",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }
}
