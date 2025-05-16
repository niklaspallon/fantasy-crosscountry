import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teamProvider.dart';
import 'skiers_provider.dart';
import 'flags.dart';
import 'alertdialog_skier.dart';

class SkierListMobile extends StatelessWidget {
  final List<Map<String, dynamic>> skiers;

  const SkierListMobile({
    Key? key,
    required this.skiers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Skier List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: skiers.length,
            itemBuilder: (context, index) {
              var skierData = skiers[index];
              String skierId = skierData['id'];
              bool alreadyAdded = context
                  .watch<TeamProvider>()
                  .userTeam
                  .any((athlete) => athlete['id'] == skierId);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color:
                        alreadyAdded ? Colors.grey[800] : Colors.blueGrey[900],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: flagWidget(skierData['country']),
                        ),
                      ),
                      title: Text(
                        skierData['name'] ?? "Unknown",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        skierData['country']?.toUpperCase() ?? "Unknown",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: alreadyAdded
                                  ? Colors.grey[700]
                                  : Colors.amber[700],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${skierData['price']}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: alreadyAdded
                                ? () {
                                    context
                                        .read<TeamProvider>()
                                        .removeSkierFromTeam(skierId, context);
                                  }
                                : () {
                                    context
                                        .read<TeamProvider>()
                                        .addSkierToTeam(skierId, context);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  alreadyAdded ? Colors.red : Colors.green,
                              padding: const EdgeInsets.all(8),
                              minimumSize: const Size(40, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Icon(
                              alreadyAdded ? Icons.remove : Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
