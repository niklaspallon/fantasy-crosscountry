import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teamProvider.dart';
import 'skiers_provider.dart';
import 'screen_utils.dart';
import 'skier_list_mobile.dart';
import 'skier_list_desktop.dart';
import 'skier_list_tablet.dart';
import 'flags.dart';

class SkierScreen extends StatefulWidget {
  @override
  _ChooseSkierScreen createState() => _ChooseSkierScreen();
}

class _ChooseSkierScreen extends State<SkierScreen> {
  String selectedCountry = "All";
  String genderFilter = "All";
  bool sortAscending = false;
  String selectedPriceRange = "All";
  final TextEditingController _searchController = TextEditingController();

  final List<String> countries = [
    "All",
    "sweden",
    "norway",
    "finland",
    "usa",
    "italy",
    "france",
    "uk"
  ];

  final List<Map<String, dynamic>> priceRanges = [
    {"label": "All", "max": 100},
    {"label": "Only Affordable", "max": -1},
    {"label": "Up to 7M", "max": 7},
    {"label": "Up to 10M", "max": 10},
    {"label": "Up to 13M", "max": 13},
    {"label": "Up to 16M", "max": 16},
  ];

  @override
  void initState() {
    super.initState();
    context.read<SkiersProvider>().fetchSkiers();
    context.read<TeamProvider>().fetchFreeTransfers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
  }

  List<Map<String, dynamic>> filterAndSortSkiers(
      List<Map<String, dynamic>> skiers) {
    var filteredSkiers = skiers;

    // Filtrera efter söktext
    if (_searchController.text.isNotEmpty) {
      final searchText = _searchController.text.toLowerCase();
      filteredSkiers = filteredSkiers.where((skier) {
        final name = skier['name']?.toString().toLowerCase() ?? '';
        return name.contains(searchText);
      }).toList();
    }

    // Filtrera efter land
    if (selectedCountry != "All") {
      filteredSkiers = filteredSkiers
          .where((skier) =>
              skier['country'].toString().toLowerCase() ==
              selectedCountry.toLowerCase())
          .toList();
    }

    // Filtrera efter kön
    if (genderFilter != "All") {
      filteredSkiers = filteredSkiers
          .where((skier) =>
              skier['gender'].toString().toLowerCase() ==
              genderFilter.toLowerCase())
          .toList();
    }

    // Filtrera efter pris
    if (selectedPriceRange != "All") {
      final selectedRange = priceRanges.firstWhere(
        (range) => range['label'] == selectedPriceRange,
      );

      if (selectedRange['label'] == "Only Affordable") {
        final remainingBudget = context.read<TeamProvider>().totalBudget;
        filteredSkiers = filteredSkiers.where((skier) {
          double price = (skier['price'] ?? 0).toDouble();
          return price <= remainingBudget;
        }).toList();
      } else {
        filteredSkiers = filteredSkiers.where((skier) {
          double price = (skier['price'] ?? 0).toDouble();
          return price <= selectedRange['max'];
        }).toList();
      }
    }

    // Sortera efter pris
    filteredSkiers.sort((a, b) {
      double priceA = (a['price'] ?? 0).toDouble();
      double priceB = (b['price'] ?? 0).toDouble();
      return sortAscending
          ? priceA.compareTo(priceB)
          : priceB.compareTo(priceA);
    });

    return filteredSkiers;
  }

  Widget _buildCountrySearch(BuildContext context) {
    return SearchAnchor(
      viewHintText: "Search country...",
      viewLeading: const Icon(
        Icons.search,
        color: Colors.white70,
      ),
      viewTrailing: [
        IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white70,
          ),
          onPressed: () {
            setState(() {
              selectedCountry = "All";
              Navigator.pop(context);
            });
          },
        ),
      ],
      viewBackgroundColor: const Color(0xFF1A237E),
      viewElevation: 10,
      viewShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      builder: (BuildContext context, SearchController controller) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          child: Row(
            children: [
              selectedCountry == "All"
                  ? const Icon(
                      Icons.public,
                      color: Colors.white70,
                      size: 20,
                    )
                  : SizedBox(
                      width: 30,
                      height: 20,
                      child: flagWidget(selectedCountry),
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    controller.openView();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      selectedCountry.substring(0, 1).toUpperCase() +
                          selectedCountry.substring(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white70),
                onPressed: () {
                  controller.openView();
                },
              ),
            ],
          ),
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        final keyword = controller.text.toLowerCase();
        return countries
            .where((country) =>
                country.toLowerCase().contains(keyword) || keyword.isEmpty)
            .map((country) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: Colors.transparent,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: country == "All"
                          ? const Icon(
                              Icons.public,
                              color: Colors.white70,
                              size: 20,
                            )
                          : SizedBox(
                              width: 30,
                              height: 20,
                              child: flagWidget(country),
                            ),
                      title: Text(
                        country.substring(0, 1).toUpperCase() +
                            country.substring(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      tileColor: Colors.transparent,
                      hoverColor: Colors.white.withOpacity(0.1),
                      selectedTileColor: Colors.white.withOpacity(0.2),
                      selected: country == selectedCountry,
                      onTap: () {
                        setState(() {
                          selectedCountry = country;
                        });
                        controller.closeView(country);
                      },
                    ),
                  ),
                ))
            .toList();
      },
    );
  }

  Widget _buildShowBudget(BuildContext context) {
    return Container(
      height: 50,
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Row(
        children: [
          const Icon(
            Icons.euro,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            "${context.read<TeamProvider>().totalBudget}M",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Row(
        children: [
          const Icon(
            Icons.people,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: const Color(0xFF1A237E),
                popupMenuTheme: PopupMenuThemeData(
                  color: const Color(0xFF1A237E),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              child: PopupMenuButton<String>(
                initialValue: genderFilter,
                onSelected: (String value) {
                  setState(() {
                    genderFilter = value;
                  });
                },
                position: PopupMenuPosition.under,
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 250,
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  for (String gender in ["All", "Male", "Female"])
                    PopupMenuItem<String>(
                      value: gender,
                      child: Container(
                        decoration: BoxDecoration(
                          color: gender == genderFilter
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        child: Row(
                          children: [
                            Icon(
                              gender == "Male"
                                  ? Icons.male
                                  : gender == "Female"
                                      ? Icons.female
                                      : Icons.people,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gender,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        genderFilter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: Row(
        children: [
          const Icon(
            Icons.euro,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: const Color(0xFF1A237E),
              popupMenuTheme: PopupMenuThemeData(
                color: const Color(0xFF1A237E),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              initialValue: selectedPriceRange,
              onSelected: (String value) {
                setState(() {
                  selectedPriceRange = value;
                });
              },
              itemBuilder: (BuildContext context) => priceRanges.map((range) {
                return PopupMenuItem<String>(
                  value: range['label'],
                  child: Container(
                    decoration: BoxDecoration(
                      color: range['label'] == selectedPriceRange
                          ? Colors.white.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.euro,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          range['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedPriceRange,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ScreenUtils.size(context);
    final freeTransfers = context.watch<TeamProvider>().freeTransfers;
    final unlimitedTransfers = context.watch<TeamProvider>().unlimitedTransfers;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Choose Skiers',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A237E),
              Colors.blue[900]!,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A237E).withOpacity(0.9),
                    Colors.blue[900]!.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                child: screenSize == ScreenSize.sm
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildCountrySearch(context),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: SearchSkierWidget(
                                  searchController: _searchController,
                                  onSearchChanged: _onSearchChanged,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 2),
                              Expanded(child: _buildShowBudget(context)),
                              const SizedBox(width: 2),
                              Expanded(
                                child: _buildGenderFilter(context),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: _buildPriceFilter(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSortButton(),
                              _buildResetButton(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      unlimitedTransfers
                                          ? Colors.green[600]!
                                          : Colors.amber[600]!,
                                      unlimitedTransfers
                                          ? Colors.green[900]!
                                          : Colors.amber[900]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Transfers: ${unlimitedTransfers ? '∞' : freeTransfers.toString()}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : screenSize == ScreenSize.md
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCountrySearch(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SearchSkierWidget(
                                      searchController: _searchController,
                                      onSearchChanged: _onSearchChanged,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildGenderFilter(context),
                                  ),
                                  Expanded(
                                    child: _buildPriceFilter(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSortButton(),
                                  _buildResetButton(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          unlimitedTransfers
                                              ? Colors.green[600]!
                                              : Colors.amber[600]!,
                                          unlimitedTransfers
                                              ? Colors.green[900]!
                                              : Colors.amber[900]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.swap_horiz,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Transfers: ${unlimitedTransfers ? '∞' : freeTransfers.toString()}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildCountrySearch(context),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SearchSkierWidget(
                                        searchController: _searchController,
                                        onSearchChanged: _onSearchChanged,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 200,
                                      child: _buildGenderFilter(context),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 200,
                                      child: _buildPriceFilter(context),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildSortButton(),
                                    const SizedBox(width: 16),
                                    _buildResetButton(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      unlimitedTransfers
                                          ? Colors.green[600]!
                                          : Colors.amber[600]!,
                                      unlimitedTransfers
                                          ? Colors.green[900]!
                                          : Colors.amber[900]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.swap_horiz,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "Free Transfers",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          unlimitedTransfers
                                              ? "Unlimited"
                                              : freeTransfers.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: Consumer<SkiersProvider>(
                builder: (context, skiersProvider, child) {
                  if (skiersProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }

                  final filteredSkiers =
                      filterAndSortSkiers(skiersProvider.locSkiers);

                  if (screenSize == ScreenSize.sm) {
                    return SkierListMobile(skiers: filteredSkiers);
                  } else if (screenSize == ScreenSize.md) {
                    return SkierListTablet(skiers: filteredSkiers);
                  } else {
                    return SkierListDesktop(skiers: filteredSkiers);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: InkWell(
        onTap: () {
          setState(() {
            sortAscending = !sortAscending;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              "Price",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCountry = "All";
            genderFilter = "All";
            selectedPriceRange = "All";
            sortAscending = false;
            _searchController.clear();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: const Row(
          children: [
            Icon(
              Icons.refresh,
              color: Colors.white70,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              "Reset",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchSkierWidget extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const SearchSkierWidget({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search skier...',
          hintStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
