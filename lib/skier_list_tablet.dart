import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teamProvider.dart';
import 'flags.dart';

class SkierListTablet extends StatelessWidget {
  final List<Map<String, dynamic>> skiers;

  const SkierListTablet({
    Key? key,
    required this.skiers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dela upp listan i män och kvinnor
    var maleSkiers = skiers
        .where((skier) => skier['gender'].toString().toLowerCase() == 'male')
        .toList();
    var femaleSkiers = skiers
        .where((skier) => skier['gender'].toString().toLowerCase() == 'female')
        .toList();

    return Row(
      children: [
        // Män
        Expanded(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "Men",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(child: _buildSkierList(context, maleSkiers)),
            ],
          ),
        ),
        Container(
          width: 2,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: Colors.grey[700],
        ),
        // Kvinnor
        Expanded(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "Women",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(child: _buildSkierList(context, femaleSkiers)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkierList(
      BuildContext context, List<Map<String, dynamic>> skierList) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: skierList.length,
      itemBuilder: (context, index) {
        var skierData = skierList[index];
        String skierId = skierData['id'];
        bool alreadyAdded = context
            .watch<TeamProvider>()
            .userTeam
            .any((athlete) => athlete['id'] == skierId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: alreadyAdded ? Colors.grey[800] : Colors.blueGrey[900],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
                      color:
                          alreadyAdded ? Colors.grey[700] : Colors.amber[700],
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
                      backgroundColor: alreadyAdded ? Colors.red : Colors.green,
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
        );
      },
    );
  }
}
