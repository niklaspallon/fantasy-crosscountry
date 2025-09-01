import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aktivitetsloggar"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("priceUpdateLogs")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Inga loggar sparade ännu.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final logDoc = logs[index];
              final week = logDoc['week'] ?? "-";
              final entries = List<String>.from(logDoc['entries'] ?? []);
              final timestamp = (logDoc['timestamp'] as Timestamp?)?.toDate();

              return ExpansionTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: Text("Vecka $week"),
                subtitle: timestamp != null
                    ? Text("${timestamp.toLocal()}")
                    : const Text("Okänd tid"),
                children: [
                  if (entries.isEmpty)
                    const ListTile(
                      title: Text(
                        "Ingen aktivitet registrerad.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...entries.map(
                      (entry) => ListTile(
                        leading:
                            const Icon(Icons.bolt, color: Colors.orangeAccent),
                        title: Text(entry),
                      ),
                    )
                ],
              );
            },
          );
        },
      ),
    );
  }
}
