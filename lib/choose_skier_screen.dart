import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teamProvider.dart';
import 'skiers_provider.dart';
import 'screen_utils.dart';
import 'flags.dart';

class SkierScreen extends StatefulWidget {
  @override
  _ChooseSkierScreen createState() => _ChooseSkierScreen();
}

class _ChooseSkierScreen extends State<SkierScreen> {
  String selectedCountry = "All"; // Standard filter value
  bool sortAscending = false; // Sorting control

  @override
  void initState() {
    super.initState();
    context.read<SkiersProvider>().fetchSkiers(); // Hämta skidåkare
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ScreenUtils.size(context); // Hämta skärmstorlek

    return Scaffold(
      appBar: AppBar(title: const Text('Skidåkare')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Filter by country
                Row(
                  children: [
                    const Text("Filter by country: "),
                    DropdownButton<String>(
                      value: selectedCountry,
                      items: [
                        "All",
                        "sweden",
                        "norway",
                        "finland",
                        "usa",
                        "italy",
                        "france",
                        "uk"
                      ].map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(
                            country.substring(0, 1).toUpperCase() +
                                country.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountry = value!;
                        });
                      },
                    ),
                  ],
                ),

                // Sort by price button (visas endast på större skärmar)
                if (screenSize != ScreenSize.sm)
                  Row(
                    children: [
                      const Text("Sort by price"),
                      IconButton(
                        icon: Icon(
                          sortAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                        ),
                        onPressed: () {
                          setState(() {
                            sortAscending = !sortAscending;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(thickness: 2),

          // Skärmstorleksanpassad layout
          Expanded(
            child: screenSize == ScreenSize.sm
                ? skierListViewMobile(context) // 🔹 Mobil layout
                : skierListViewDesktop(context), // 🔹 Tablet / Desktop layout
          ),
        ],
      ),
    );
  }

  /// 🔹 Layout för mobil (Liten skärm)
  Widget skierListViewMobile(BuildContext context) {
    String genderFilter = "All"; // Standardvärde för könsfilter

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dropdown för att välja kön
                  Row(
                    children: [
                      const Text(
                        "Filter by gender: ",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<String>(
                        value: genderFilter,
                        items: ["All", "Male", "Female"].map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(
                              gender,
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            genderFilter = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<SkiersProvider>(
                builder: (context, skiersProvider, child) {
                  if (skiersProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Hämta och filtrera skidåkare
                  var skiers = filterAndSortSkiers(skiersProvider.locSkiers);

                  // Filtrera kön
                  if (genderFilter != "All") {
                    skiers = skiers
                        .where((skier) =>
                            skier['gender'].toString().toLowerCase() ==
                            genderFilter.toLowerCase())
                        .toList();
                  }

                  return ListView.builder(
                    itemCount: skiers.length,
                    itemBuilder: (context, index) {
                      var skierData = skiers[index];
                      String skierId = skierData['id'];
                      bool alreadyAdded = context
                          .watch<TeamProvider>()
                          .userTeam
                          .any((athlete) => athlete['id'] == skierId);

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          leading: flagWidget(skierData['country']),
                          title: Text(
                            skierData['name'] ?? "Unknown",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Pris ${skierData['price']} | ${skierData['country'].toUpperCase()}",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[700]),
                          ),
                          trailing: ElevatedButton(
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
                            child: Text(alreadyAdded ? "Remove" : "Add"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  alreadyAdded ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Layout för desktop / tablet (stor skärm)
  Widget skierListViewDesktop(BuildContext context) {
    return Consumer<SkiersProvider>(
      builder: (context, skiersProvider, child) {
        if (skiersProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var skiers = filterAndSortSkiers(skiersProvider.locSkiers);

        // Dela upp listan i män och kvinnor
        var maleSkiers = skiers
            .where(
                (skier) => skier['gender'].toString().toLowerCase() == 'male')
            .toList();
        var femaleSkiers = skiers
            .where(
                (skier) => skier['gender'].toString().toLowerCase() == 'female')
            .toList();

        return Row(
          children: [
            // Män
            Expanded(
              child: Column(
                children: [
                  const Text("Men",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: skierListView(maleSkiers)),
                ],
              ),
            ),
            const VerticalDivider(thickness: 2, width: 20),
            // Kvinnor
            Expanded(
              child: Column(
                children: [
                  const Text("Women",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: skierListView(femaleSkiers)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Gemensam funktion för att filtrera & sortera skidåkare
  List<Map<String, dynamic>> filterAndSortSkiers(
      List<Map<String, dynamic>> skiers) {
    // Filtrera efter land
    if (selectedCountry != "All") {
      skiers = skiers
          .where((skier) =>
              skier['country'].toString().toLowerCase() ==
              selectedCountry.toLowerCase())
          .toList();
    }

    // Sortera efter pris
    skiers.sort((a, b) {
      double priceA = (a['price'] ?? 0).toDouble();
      double priceB = (b['price'] ?? 0).toDouble();
      return sortAscending
          ? priceA.compareTo(priceB)
          : priceB.compareTo(priceA);
    });

    return skiers;
  }

  /// 🔹 Funktion för att bygga skidåkare-listan
  Widget skierListView(List<Map<String, dynamic>> skierList) {
    return ListView.builder(
      itemCount: skierList.length,
      itemBuilder: (context, index) {
        var skierData = skierList[index];
        String skierId = skierData['id'];
        bool alreadyAdded = context
            .watch<TeamProvider>()
            .userTeam
            .any((athlete) => athlete['id'] == skierId);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
          child: Row(
            children: [
              // 🔹 Flagga
              SizedBox(
                height: 40,
                width: 40,
                child: flagWidget(skierData['country']),
              ),
              const SizedBox(width: 10),

              // 🔹 Namn
              Expanded(
                flex: 2,
                child: Text(
                  skierData['name'] ?? "Unknown",
                  textAlign: TextAlign.left,
                ),
              ),

              // 🔹 Land
              Expanded(
                flex: 1,
                child: Text(
                  skierData['country'] ?? "Unknown",
                  textAlign: TextAlign.center,
                ),
              ),

              // 🔹 Pris
              Expanded(
                flex: 1,
                child: Text(
                  "💰 ${skierData['price'] ?? 'N/A'}",
                  textAlign: TextAlign.center,
                ),
              ),

              // 🔹 Add/Remove-knapp
              ElevatedButton(
                onPressed: alreadyAdded
                    ? () => context
                        .read<TeamProvider>()
                        .removeSkierFromTeam(skierId, context)
                    : () => context
                        .read<TeamProvider>()
                        .addSkierToTeam(skierId, context),
                child: Text(alreadyAdded ? "Remove" : "Add"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: alreadyAdded ? Colors.grey : Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}





/*
class TestList extends StatefulWidget {
  @override
  _TestListState createState() => _TestListState();
}

class _TestListState extends State<TestList> {
  String ownerId = "";
  String selectedCountry = "All"; // 🔹 Standardvärde för filtrering
  bool sortAscending = true; // 🔹 Kontroll för sorteringsordning

  @override
  void initState() {
    super.initState();
    ownerId = context.read<TeamProvider>().ownerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skidåkare')),
      body: Column(
        children: [
          // 🔹 Filter Dropdown & Sorteringsknapp
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 🔹 Filtrering på land
                Row(
                  children: [
                    const Text("Filter by country: "),
                    DropdownButton<String>(
                      value: selectedCountry,
                      items: [
                        "All",
                        "sweden",
                        "norway",
                        "finland",
                        "usa",
                        "italy",
                        "france",
                        "uk"
                      ].map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(
                            country.substring(0, 1).toUpperCase() +
                                country.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCountry = value!;
                        });
                      },
                    ),
                  ],
                ),

                // 🔹 Sorteringsknapp
                Row(
                  children: [
                    Text("Sort by price"),
                    IconButton(
                      icon: Icon(
                        sortAscending
                            ? Icons.arrow_upward // 🔼 Om stigande
                            : Icons.arrow_downward, // 🔽 Om fallande
                      ),
                      onPressed: () {
                        setState(() {
                          sortAscending =
                              !sortAscending; // Växla sorteringsordning
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(thickness: 2), // 🔹 Separator

          // 🔹 StreamBuilder för att hämta skidåkare
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('SkiersDb').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Något gick fel: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Inga åkare hittades!'));
                }

                var skiers = snapshot.data!.docs;

                // 🔹 Filtrera listan baserat på valt land
                if (selectedCountry != "All") {
                  skiers = skiers
                      .where((skier) =>
                          skier['country'].toString().toLowerCase() ==
                          selectedCountry.toLowerCase())
                      .toList();
                }

                // 🔹 Sortera på pris
                skiers.sort((a, b) {
                  double priceA = (a['price'] ?? 0).toDouble();
                  double priceB = (b['price'] ?? 0).toDouble();
                  return sortAscending
                      ? priceA.compareTo(priceB) // 🔼 Stigande ordning
                      : priceB.compareTo(priceA); // 🔽 Fallande ordning
                });

                // 🔹 Unik lista för skidåkare
                Set<String> uniqueMaleIds = {};
                Set<String> uniqueFemaleIds = {};

                var maleSkiers = skiers
                    .where((skier) =>
                        skier['gender'].toString().toLowerCase() == 'male' &&
                        uniqueMaleIds.add(skier.id))
                    .toList();

                var femaleSkiers = skiers
                    .where((skier) =>
                        skier['gender'].toString().toLowerCase() == 'female' &&
                        uniqueFemaleIds.add(skier.id))
                    .toList();

                return Row(
                  children: [
                    // 🔹 Herrar
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Men",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: skierListView(maleSkiers)),
                        ],
                      ),
                    ),
                    const VerticalDivider(
                        thickness: 2, width: 20), // 🔹 Separator
                    // 🔹 Damer
                    Expanded(
                      child: Column(
                        children: [
                          const Text("Women",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: skierListView(femaleSkiers)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Funktion som bygger listan över skidåkare
  Widget skierListView(List<DocumentSnapshot> skierList) {
    return ListView.builder(
      itemCount: skierList.length,
      itemBuilder: (context, index) {
        var skierData = skierList[index].data() as Map<String, dynamic>;
        String skierId = skierList[index].id;

        // Kontrollera om åkaren redan är i laget
        bool alreadyAdded = context
            .watch<TeamProvider>()
            .userTeam
            .any((athlete) => athlete['id'] == skierId);

        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
              child: Row(
                children: [
                  // 🔹 Flagga
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        "bilder/${skierData['country']}.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 🔹 Namn (Vänsterjusterat)
                  Expanded(
                    flex: 2,
                    child: Text(
                      skierData['name'] ?? "Unknown",
                      textAlign: TextAlign.left,
                    ),
                  ),

                  // 🔹 Land (Mittenjusterat)
                  Expanded(
                    flex: 1,
                    child: Text(
                      "${skierData['country']?.substring(0, 1).toUpperCase()}${skierData['country']?.substring(1).toLowerCase() ?? 'Unknown'}",
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // 🔹 Pris (Mittenjusterat)
                  Expanded(
                    flex: 1,
                    child: Text(
                      "💰 ${skierData['price'] ?? 'N/A'}",
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // 🔹 Add-knapp (Högerjusterad)
                  ElevatedButton(
                    onPressed: alreadyAdded
                        ? null
                        : () async {
                            try {
                              bool success = await context
                                  .read<TeamProvider>()
                                  .addSkierToTeam(skierId, context);

                              if (success) {
                                // 🟢 Bara poppa tillbaka om åkaren lades till
                                await context
                                    .read<TeamProvider>()
                                    .getUserTeam();
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              print("Fel vid tillägg: $e");
                            }
                          },
                    child: Text(alreadyAdded ? "Added" : "Add"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyAdded ? Colors.grey : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(), // 🔹 Linje under varje åkare
          ],
        );
      },
    );
  }
}
*/