import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teamProvider.dart';
import 'flags.dart';
import 'alertdialog_skier.dart';

class SkierListDesktop extends StatelessWidget {
  final List<Map<String, dynamic>> skiers;

  const SkierListDesktop({
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A237E).withOpacity(0.9),
                      Colors.blue[900]!.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Men",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A237E).withOpacity(0.9),
                      Colors.blue[900]!.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Women",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                alreadyAdded
                    ? Colors.grey[800]!.withOpacity(0.9)
                    : const Color(0xFF1A237E).withOpacity(0.9),
                alreadyAdded
                    ? Colors.grey[900]!.withOpacity(0.8)
                    : Colors.blue[900]!.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
                  letterSpacing: 0.5,
                ),
              ),
              subtitle: Text(
                skierData['country']?.toUpperCase() ?? "Unknown",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  letterSpacing: 0.5,
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          alreadyAdded ? Colors.grey[700]! : Colors.amber[700]!,
                          alreadyAdded ? Colors.grey[800]! : Colors.amber[800]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      "${skierData['price']} M",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          alreadyAdded ? Colors.red[600]! : Colors.green[600]!,
                          alreadyAdded ? Colors.red[900]! : Colors.green[900]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
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
                      icon: Icon(
                        alreadyAdded ? Icons.remove : Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
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
