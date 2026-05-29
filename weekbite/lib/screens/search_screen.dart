import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart';
import 'recipe.dart'; 

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final translator = GoogleTranslator();

  bool isLoading = false;
  List<dynamic> searchResults = [];

  // ==========================================================
  // 🎛️ MAPPE DEI FILTRI
  // ==========================================================
  
  final Map<String, String> dietOptions = {
    'Qualsiasi Dieta': '',
    'Vegetariana': 'vegetarian',
    'Vegana': 'vegan',
    'Senza Glutine': 'gluten free',
    'Keto': 'ketogenic',
  };
  String selectedDiet = 'Qualsiasi Dieta';

  final Map<String, String> typeOptions = {
    'Qualsiasi Pasto': '',
    'Piatto Principale': 'main course',
    'Dolce / Dessert': 'dessert',
    'Antipasto': 'appetizer',
    'Colazione': 'breakfast',
    'Zuppa': 'soup',
  };
  String selectedType = 'Qualsiasi Pasto';

  // ==========================================================
  // 🔍 MOTORE DI RICERCA
  // ==========================================================
  Future<void> _performSearch() async {
    // Se tutto è vuoto/resettato, pulisci semplicemente la schermata
    if (_searchController.text.trim().isEmpty && 
        selectedDiet == 'Qualsiasi Dieta' && 
        selectedType == 'Qualsiasi Pasto') {
      setState(() {
        searchResults = [];
      });
      return;
    }

    FocusScope.of(context).unfocus(); 
    setState(() {
      isLoading = true;
      searchResults = [];
    });

    try {
      String queryEn = "";
      
      // 1. TRADUZIONE DELLA QUERY: Italiano -> Inglese
      if (_searchController.text.trim().isNotEmpty) {
        var tQuery = await translator.translate(_searchController.text.trim(), from: 'it', to: 'en');
        queryEn = tQuery.text;
      }

      // Parametri per l'API
      String dietParam = dietOptions[selectedDiet]!;
      String typeParam = typeOptions[selectedType]!;
      const apiKey = 'd94d3ad2ddaa4b9a8e6ae55f4e87b174'; 
      
      String url = 'https://api.spoonacular.com/recipes/complexSearch?apiKey=$apiKey&addRecipeInformation=true&fillIngredients=true&number=16';
      
      if (queryEn.isNotEmpty) url += '&query=$queryEn';
      if (dietParam.isNotEmpty) url += '&diet=$dietParam';
      if (typeParam.isNotEmpty) url += '&type=$typeParam';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List results = data['results'] ?? []; 

        // 2. TRADUZIONE DEI RISULTATI: Inglese -> Italiano
        await Future.wait(results.map((recipe) async {
          String originalTitle = recipe['title'] ?? '';
          if (originalTitle.isNotEmpty) {
            try {
              var translation = await translator.translate(originalTitle, from: 'en', to: 'it');
              recipe['title'] = translation.text; 
            } catch (e) {
              print("Errore traduzione titolo: $e");
            }
          }
        }));

        if (mounted) {
          setState(() {
            searchResults = results;
            isLoading = false;
          });
        }
      } else {
        print("Errore API: ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("Errore di rete: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Controllo per capire se c'è almeno un filtro attivo
    bool isAnyFilterActive = selectedDiet != 'Qualsiasi Dieta' || selectedType != 'Qualsiasi Pasto';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Ricerca Avanzata", style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // BARRA DI RICERCA TESTUALE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _performSearch(),
              style: GoogleFonts.montserrat(fontSize: 16),
              decoration: InputDecoration(
                hintText: "Cerca ricette o ingredienti...",
                hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.search, color: primaryGreen),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),

          // FILTRI A DISCESA ORIZZONTALI
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // DROPDOWN DIETA
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedDiet == 'Qualsiasi Dieta' ? Colors.grey[100] : primaryGreen.withOpacity(0.1),
                    border: Border.all(color: selectedDiet == 'Qualsiasi Dieta' ? Colors.grey[300]! : primaryGreen),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDiet,
                      icon: Icon(Icons.keyboard_arrow_down, color: selectedDiet == 'Qualsiasi Dieta' ? Colors.grey : primaryGreen),
                      style: GoogleFonts.montserrat(fontSize: 14, color: selectedDiet == 'Qualsiasi Dieta' ? Colors.black87 : primaryGreen, fontWeight: FontWeight.w600),
                      items: dietOptions.keys.map((String key) {
                        return DropdownMenuItem<String>(value: key, child: Text(key));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() => selectedDiet = newValue);
                        _performSearch();
                      },
                    ),
                  ),
                ),

                // DROPDOWN TIPO DI PASTO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedType == 'Qualsiasi Pasto' ? Colors.grey[100] : primaryGreen.withOpacity(0.1),
                    border: Border.all(color: selectedType == 'Qualsiasi Pasto' ? Colors.grey[300]! : primaryGreen),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      icon: Icon(Icons.keyboard_arrow_down, color: selectedType == 'Qualsiasi Pasto' ? Colors.grey : primaryGreen),
                      style: GoogleFonts.montserrat(fontSize: 14, color: selectedType == 'Qualsiasi Pasto' ? Colors.black87 : primaryGreen, fontWeight: FontWeight.w600),
                      items: typeOptions.keys.map((String key) {
                        return DropdownMenuItem<String>(value: key, child: Text(key));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) setState(() => selectedType = newValue);
                        _performSearch();
                      },
                    ),
                  ),
                ),

                // 🛑 TASTO RIMUOVI FILTRI (Visibile solo se un filtro è attivo)
                if (isAnyFilterActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ActionChip(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      avatar: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                      label: Text("Rimuovi", style: GoogleFonts.montserrat(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                      onPressed: () {
                        setState(() {
                          selectedDiet = 'Qualsiasi Dieta';
                          selectedType = 'Qualsiasi Pasto';
                        });
                        _performSearch(); // Riazzera i risultati
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 30),

          // RISULTATI DELLA GRIGLIA
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: primaryGreen),
                        const SizedBox(height: 16),
                        Text("Ricerca e traduzione in corso...", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : searchResults.isEmpty
                    ? Center(
                        child: Text(
                          "Cerca qualcosa di sfizioso!\n(es. Pasta, Torta, Insalata)",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        physics: const ClampingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final recipe = searchResults[index];
                          return Card(
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecipeDetailScreen(
                                      recipeData: recipe,
                                      isFromApi: true,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        image: DecorationImage(
                                          image: NetworkImage(recipe['image'] ?? 'https://via.placeholder.com/150'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      recipe['title'] ?? 'Senza Titolo',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}