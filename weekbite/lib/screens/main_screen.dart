import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Gestione della persistenza locale
import 'package:translator/translator.dart'; // 🌍 Pacchetto per la traduzione automatica dei titoli
import 'search_screen.dart';
import 'recipe.dart'; // Importazione corretta per la schermata di dettaglio del tuo progetto

// COLORI UFFICIALI DEL GRUPPO EREDITATI DAL MAIN
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isUserLogged = false; // Se impostato su true, mostra le liste orizzontali in alto
  List recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // All'avvio controlla se esistono ricette salvate localmente per la giornata di oggi
    _loadLocalOrFetchViralRecipes();
  }

  // LOGICA DI CONTROLLO DEL CACHING LOCALE
  Future<void> _loadLocalOrFetchViralRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedRecipesStr = prefs.getString('cached_viral_recipes');
      final String? lastFetchDate = prefs.getString('last_viral_fetch_date');
      
      // Data odierna in formato YYYY-MM-DD
      String todayStr = DateTime.now().toString().split(' ')[0];

      if (cachedRecipesStr != null && lastFetchDate == todayStr) {
        // DATI PREGRESSI TROVATI: Carica istantaneamente dalla memoria (già tradotti in italiano!)
        if (mounted) {
          setState(() {
            recipes = json.decode(cachedRecipesStr);
            isLoading = false;
          });
        }
        print("🎉 Ricette di oggi caricate in italiano dalla cache (0 token consumati)");
      } else {
        // NESSUN DATO O CACHE SCADUTA: Effettua la richiesta API reale e la traduce
        _fetchViralRecipesAndCache(todayStr);
      }
    } catch (e) {
      String todayStr = DateTime.now().toString().split(' ')[0];
      _fetchViralRecipesAndCache(todayStr);
    }
  }

  // VERA CHIAMATA API DI RETE A SPOONACULAR + TRADUTTORE LIVE AUTOMATICO
  Future<void> _fetchViralRecipesAndCache(String todayDate) async {
    const apiKey = 'd94d3ad2ddaa4b9a8e6ae55f4e87b174'; 
    const url = 'https://api.spoonacular.com/recipes/random?number=30&tags=italian&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List fetchedRecipes = data['recipes'] ?? [];

        // 🌍 LOGICA DI TRADUZIONE SIMULTANEA DEI 30 TITOLI DELLE CARD
        final translator = GoogleTranslator();
        
        // Eseguiamo tutte le traduzioni in parallelo per non rallentare l'avvio
        await Future.wait(fetchedRecipes.map((recipe) async {
          String originalTitle = recipe['title'] ?? '';
          if (originalTitle.isNotEmpty) {
            try {
              var translation = await translator.translate(originalTitle, from: 'en', to: 'it');
              recipe['title'] = translation.text; // Sovrascriviamo il titolo inglese con quello italiano
            } catch (e) {
              print("Errore traduzione titolo singolo: $e");
              // In caso di micro-errore, mantiene il titolo originale senza bloccarsi
            }
          }
        }));

        // Scrittura dei dati già tradotti nella memoria permanente del dispositivo
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_viral_recipes', json.encode(fetchedRecipes));
        await prefs.setString('last_viral_fetch_date', todayDate);

        if (mounted) {
          setState(() {
            recipes = fetchedRecipes;
            isLoading = false;
          });
        }
        print("📡 Nuove ricette scaricate, TRADOTTE in italiano e salvate localmente!");
      } else {
        print("🔴 ERRORE RISPOSTA API: Codice ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("🔴 ECCEZIONE DURANTE LA RICHIESTA DI RETE: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold pulito che fa da Material Container integrato con il BaseLayout del main.dart
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. BARRA DI RICERCA FISSA IN ALTO
            _buildSearchBar(context),

            // 2. CORPO SCORREVOLE
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // SEZIONE UTENTE LOGGATO
                  if (isUserLogged) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text("I tuoi Preferiti", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildHorizontalList()), 
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text("In base alla tua Dispensa", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildHorizontalList()), 
                  ],

                  // TITOLO RICETTE VIRALI
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text("Esplora Ricette Virali", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // 3. LA GRIGLIA DELL'API (ORA COMPLETAMENTE TRADOTTA)
                  _buildApiSliverGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COSTRUTTORE DELLA BARRA DI RICERCA ---
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100], 
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: primaryGreen, size: 20), 
              const SizedBox(width: 12),
              Text('Cerca ricette o ingredienti...', style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // --- COSTRUTTORE DELLE LISTE ORIZZONTALI ---
  Widget _buildHorizontalList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          final mockLocalRecipe = {
            "title": "Ricetta Preferita #${index + 1}",
            "image": "https://via.placeholder.com/400x300",
            "readyInMinutes": 25,
            "servings": 4,
            "ingredients": [
              {"name": "ingrediente prova 1", "amount": 200.0, "unit": "g"}
            ],
            "isFavorite": true,
            "personalNotes": "Annotazione locale di prova."
          };
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12), 
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeData: mockLocalRecipe, isFromApi: false)));
              },
              child: Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 90,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                      child: Center(child: Icon(Icons.restaurant, color: primaryGreen.withOpacity(0.5))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(mockLocalRecipe["title"] as String, maxLines: 2, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- COSTRUTTORE DELLA GRIGLIA VERTICALE SLIVER ---
  Widget _buildApiSliverGrid() {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 50.0),
          child: Center(child: CircularProgressIndicator(color: primaryGreen)),
        ),
      );
    }

    if (recipes.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: Center(child: Text("Nessuna ricetta trovata.", style: GoogleFonts.montserrat())),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30), 
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = recipes[index];
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
          childCount: recipes.length, 
        ),
      ),
    );
  }
}