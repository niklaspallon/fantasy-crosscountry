import 'package:cloud_firestore/cloud_firestore.dart';

typedef BatchOperation = void Function(WriteBatch batch);

Future<void> commitInBatches(
    FirebaseFirestore db, List<BatchOperation> operations) async {
  const int batchLimit = 500;
  int counter = 0;
  int batchNumber = 1; // 👈 Håller reda på vilken batch vi är på
  WriteBatch batch = db.batch();

  for (var op in operations) {
    op(batch);
    counter++;

    if (counter >= batchLimit) {
      print("✅ Commitar batch $batchNumber med $counter operationer...");
      await batch.commit();
      batch = db.batch();
      counter = 0;
      batchNumber++;
    }
  }

  if (counter > 0) {
    print("✅ Commitar batch $batchNumber med $counter operationer...");
    await batch.commit();
  }
}
