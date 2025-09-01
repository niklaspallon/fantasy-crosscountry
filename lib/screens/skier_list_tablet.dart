import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/team_provider.dart';
import '../designs/flags.dart';
import '../designs/alertdialog_skier.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
            .userTeam!
            .any((athlete) => athlete['id'] == skierId);

        return Container(
          constraints: BoxConstraints(maxHeight: 60),
          margin: const EdgeInsets.only(bottom: 2),
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
            child: GestureDetector(
              onTap: () {
                showSkierInfo(context, skierId);
              },
              child: ListTile(
                contentPadding: const EdgeInsets.all(3),
                visualDensity: const VisualDensity(
                  vertical: -4,
                  horizontal: -4,
                ),
                leading: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                    borderRadius: BorderRadius.circular(10),
                    child: flagWidget(skierData['country']),
                  ),
                ),
                title: Text(
                  skierData['name'] ?? "Unknown",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
                      constraints:
                          const BoxConstraints(minWidth: 65, maxWidth: 65),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            alreadyAdded
                                ? Colors.grey[700]!
                                : Colors.amber[700]!,
                            alreadyAdded
                                ? Colors.grey[800]!
                                : Colors.amber[800]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "${skierData['price']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
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
                            alreadyAdded
                                ? Colors.red[600]!
                                : Colors.green[600]!,
                            alreadyAdded
                                ? Colors.red[900]!
                                : Colors.green[900]!,
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
                                Navigator.pop(context);
                              }
                            : () {
                                context
                                    .read<TeamProvider>()
                                    .addSkierToTeam(skierId, context);
                                Navigator.pop(context);
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
          ),
        );
      },
    );
  }
}
