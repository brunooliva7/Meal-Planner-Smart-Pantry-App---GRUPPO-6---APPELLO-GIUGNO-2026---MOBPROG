import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart'; 
import 'search_screen.dart';
import 'recipe.dart'; 
import '../database/database_helper.dart'; // 📂 Importazione del nuovo Database SQLite

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isUserLogged = false; 
  List recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalOrFetchViralRecipes();
  }

  // LOGICA DI CONTROLLO TRAMITE DATABASE SQLITE
  Future<void> _loadLocalOrFetchViralRecipes() async {
    try {
      String todayStr = DateTime.now().toString().split(' ')[0];
      
      // Cerchiamo la cache all'interno della tabella SQLite
      List<dynamic> cachedRecipes = await DatabaseHelper.instance.getViralCache(todayStr);

      if (cachedRecipes.isNotEmpty) {
        // Cache valida trovata nel DB
        if (mounted) {
          setState(() {
            recipes = cachedRecipes;
            isLoading = false;
          });
        }
        print("🎉 Ricette virali caricate dal Database SQLite locale (0 token consumati)");
      } else {
        // Tabella vuota o data scaduta: scarica nuove ricette
        _fetchViralRecipesAndCache(todayStr);
      }
    } catch (e) {
      String todayStr = DateTime.now().toString().split(' ')[0];
      _fetchViralRecipesAndCache(todayStr);
    }
  }

  Future<void> _fetchViralRecipesAndCache(String todayDate) async {
    const apiKey = 'd94d3ad2ddaa4b9a8e6ae55f4e87b174'; 
    const url = 'https://api.spoonacular.com/recipes/random?number=30&tags=italian&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List fetchedRecipes = data['recipes'] ?? [];

        final translator = GoogleTranslator();
        
        await Future.wait(fetchedRecipes.map((recipe) async {
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

        // SALVATAGGIO NELLA TABELLA SQLITE CACHE
        await DatabaseHelper.instance.saveViralCache(fetchedRecipes, todayDate);

        if (mounted) {
          setState(() {
            recipes = fetchedRecipes;
            isLoading = false;
          });
        }
        print("📡 Nuove ricette salvate nella cache SQLite con successo!");
      } else {
        print("🔴 Errore risposta API: ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("🔴 Eccezione di rete: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text("Esplora Ricette Virali", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _buildApiSliverGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildHorizontalList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, 
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          final mockLocalRecipe = {
            "id": 999 + index,
            "title": "Ricetta Preferita #${index + 1}",
            "image": "https://via.placeholder.com/400x300",
            "readyInMinutes": 25,
            "servings": 4,
            "extendedIngredients": [
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

  Widget _buildApiSliverGrid() {
    if (isLoading) {
      return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 50.0), child: Center(child: CircularProgressIndicator(color: primaryGreen))));
    }
    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30), 
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipeData: recipe, isFromApi: true)));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          image: DecorationImage(image: NetworkImage(recipe['image'] ?? 'https://via.placeholder.com/150'), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(recipe['title'] ?? 'Senza Titolo', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold)),
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