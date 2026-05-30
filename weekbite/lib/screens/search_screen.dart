import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart';
import 'recipe.dart'; 
import '../services/database_helper.dart'; // 📂 Importazione del Database
import 'dart:io';

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // 🧪 IMPOSTA A TRUE PER VEDERE LA FUNZIONE (Simula utente loggato)
  bool isUserLogged = true; 
  
  // Variabile per gestire la modalità di ricerca (Web vs Locale)
  bool searchLocal = false;

  final TextEditingController _searchController = TextEditingController();
  final translator = GoogleTranslator();

  bool isLoading = false;
  List<dynamic> searchResults = [];

  // ==========================================================
  // 🎛️ MAPPE DEI FILTRI (Solo per ricerca Web)
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
  // 🔍 GESTORE DELLA RICERCA (Smista tra Locale e Web)
  // ==========================================================
  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus(); 
    
    if (searchLocal) {
      await _performLocalSearch();
    } else {
      await _performApiSearch();
    }
  }

  // 💾 RICERCA LOCALE (Nel Database SQLite)
  Future<void> _performLocalSearch() async {
    setState(() {
      isLoading = true;
      searchResults = [];
    });

    try {
      final db = await DatabaseHelper.instance.database;
      String query = _searchController.text.trim();
      List<Map<String, dynamic>> res;

      if (query.isEmpty) {
        // Se la barra è vuota, mostra TUTTE le ricette salvate
        res = await db.query('saved_recipes');
      } else {
        // Cerca la parola chiave nel titolo
        res = await db.query(
          'saved_recipes', 
          where: 'title LIKE ?', 
          whereArgs: ['%$query%'] // Il % serve per dire "contiene questa parola"
        );
      }

      // Ricostruiamo la struttura JSON originale per darla in pasto alla griglia
      List<dynamic> parsedResults = res.map((row) {
        Map<String, dynamic> recipe = json.decode(row['recipe_json'] as String);
        recipe['personalNotes'] = row['personal_notes'];
        recipe['isDownloadedLocal'] = true;
        return recipe;
      }).toList();

      if (mounted) {
        setState(() {
          searchResults = parsedResults;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Errore Database Locale: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🌐 RICERCA WEB (Tramite Spoonacular API)
  Future<void> _performApiSearch() async {
    if (_searchController.text.trim().isEmpty && 
        selectedDiet == 'Qualsiasi Dieta' && 
        selectedType == 'Qualsiasi Pasto') {
      setState(() => searchResults = []);
      return;
    }

    setState(() {
      isLoading = true;
      searchResults = [];
    });

    try {
      String queryEn = "";
      if (_searchController.text.trim().isNotEmpty) {
        var tQuery = await translator.translate(_searchController.text.trim(), from: 'it', to: 'en');
        queryEn = tQuery.text;
      }

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

        await Future.wait(results.map((recipe) async {
          String originalTitle = recipe['title'] ?? '';
          if (originalTitle.isNotEmpty) {
            try {
              var translation = await translator.translate(originalTitle, from: 'en', to: 'it');
              recipe['title'] = translation.text; 
            } catch (e) {
              print("Errore traduzione: $e");
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
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          
          // ==========================================================
          // 🔘 TOGGLE: ESPLORA WEB / LE MIE RICETTE (Solo se loggato)
          // ==========================================================
          if (isUserLogged)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => searchLocal = false);
                          _performSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !searchLocal ? primaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: !searchLocal ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                          ),
                          child: Center(
                            child: Text(
                              "Esplora Web",
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: !searchLocal ? Colors.white : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => searchLocal = true);
                          _performSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: searchLocal ? primaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: searchLocal ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : [],
                          ),
                          child: Center(
                            child: Text(
                              "Le Mie Ricette",
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: searchLocal ? Colors.white : Colors.grey[600]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ==========================================================
          // BARRA DI RICERCA TESTUALE
          // ==========================================================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _performSearch(),
              style: GoogleFonts.montserrat(fontSize: 16),
              decoration: InputDecoration(
                hintText: searchLocal ? "Cerca tra le tue ricette salvate..." : "Cerca ricette o ingredienti...",
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

          // ==========================================================
          // FILTRI (Nascondiamo i filtri API se la ricerca è Locale)
          // ==========================================================
          if (!searchLocal)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
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
                          _performSearch(); 
                        },
                      ),
                    ),
                ],
              ),
            ),
          
          if (!searchLocal) const Divider(height: 30),

          // ==========================================================
          // RISULTATI DELLA GRIGLIA
          // ==========================================================
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: primaryGreen),
                        const SizedBox(height: 16),
                        Text(searchLocal ? "Ricerca nel dispositivo..." : "Ricerca e traduzione in corso...", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : searchResults.isEmpty
                    ? Center(
                        child: Text(
                          searchLocal 
                            ? "Nessuna ricetta salvata corrisponde alla ricerca." 
                            : "Cerca qualcosa di sfizioso!\n(es. Pasta, Torta, Insalata)",
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
                                      // 🔴 IMPORTANTE: Se sto cercando in locale, dico alla schermata che non è dall'API!
                                      isFromApi: !searchLocal, 
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Builder(
                                      builder: (context) {
                                        // 1. Estrai il path e pulisci eventuali "file://"
                                        String imgPath = recipe['image'] ?? '';
                                        imgPath = imgPath.replaceAll('file://', '');

                                        // 2. Widget condizionale sicuro
                                        Widget imageWidget;
                                        if (imgPath.startsWith('http')) {
                                          imageWidget = Image.network(
                                            imgPath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                                          );
                                        } else if (imgPath.isNotEmpty) {
                                          // Importa 'dart:io' in cima al file se non c'è
                                          imageWidget = Image.file(
                                            File(imgPath),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                                          );
                                        } else {
                                          imageWidget = Container(color: Colors.grey[200], child: const Icon(Icons.restaurant_menu, color: Colors.grey));
                                        }

                                        // 3. Ritorna l'immagine tagliata perfettamente
                                        return ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: imageWidget,
                                          ),
                                        );
                                      },
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