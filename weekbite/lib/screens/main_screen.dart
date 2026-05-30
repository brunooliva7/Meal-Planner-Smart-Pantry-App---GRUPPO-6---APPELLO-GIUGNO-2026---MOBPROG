import 'dart:io'; 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart'; 
import 'search_screen.dart';
import 'recipe.dart'; 
import '../database/database_helper.dart';

class MainScreen extends StatefulWidget {
  final bool isLogged;

  const MainScreen({super.key, this.isLogged = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List viralRecipes = [];
  List favoriteRecipes = [];
  List pantryRecipes = [];
  
  bool isLoadingViral = true;
  bool isLoadingPantry = true;
  bool isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  Future<void> _refreshAllData() async {
    await _loadViralRecipes();
    if (widget.isLogged) {
      await _loadUserFavorites();
      await _loadPantryBasedRecipes();
    }
  }

  Future<void> _loadUserFavorites() async {
    setState(() => isLoadingFavorites = true);
    try {
      final allFavs = await DatabaseHelper.instance.getAllFavorites();
      if (mounted) {
        setState(() {
          favoriteRecipes = allFavs.take(5).toList();
          isLoadingFavorites = false;
        });
      }
    } catch (e) {
      print("Errore preferiti: $e");
      if (mounted) setState(() => isLoadingFavorites = false);
    }
  }

  Future<void> _loadPantryBasedRecipes() async {
    setState(() => isLoadingPantry = true);
    String todayStr = DateTime.now().toString().split(' ')[0];

    try {
      List<dynamic> cachedPantry = await DatabaseHelper.instance.getPantryCache(todayStr);

      if (cachedPantry.isNotEmpty) {
        if (mounted) {
          setState(() {
            pantryRecipes = cachedPantry;
            isLoadingPantry = false;
          });
        }
        return;
      }

      // 🟢 1. COLLEGAMENTO REALE AL DATABASE DEL TUO COMPAGNO
      List<String> allMyIngredients = await DatabaseHelper.instance.getDispensaIngredients();

      if (allMyIngredients.isEmpty) {
        if (mounted) setState(() => isLoadingPantry = false);
        return; // La dispensa è vuota, mostriamo "Ancora nulla qui..."
      }

      // 🟢 2. OTTIMIZZAZIONE: Prendiamo solo i primi 5 ingredienti!
      // Se mandiamo 50 ingredienti all'API, non troverà ricette e bloccherà il traduttore.
      List<String> myIngredientsItalian = allMyIngredients.take(5).toList();

      final translator = GoogleTranslator();
      List<String> englishIngredients = [];
      
      // Traduzione in Inglese
      for (String ing in myIngredientsItalian) {
        var t = await translator.translate(ing, from: 'it', to: 'en');
        englishIngredients.add(t.text.toLowerCase());
      }

      // Chiamata API Spoonacular
      final ingredientsQuery = englishIngredients.join(',+');
      const apiKey = 'd94d3ad2ddaa4b9a8e6ae55f4e87b174';
      final url = 'https://api.spoonacular.com/recipes/findByIngredients?ingredients=$ingredientsQuery&number=5&apiKey=$apiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        
        // Traduzione dei Titoli in Italiano
        for (var recipe in data) {
          String originalTitle = recipe['title'] ?? '';
          if (originalTitle.isNotEmpty) {
            try {
              var translation = await translator.translate(originalTitle, from: 'en', to: 'it');
              recipe['title'] = translation.text;
            } catch (e) {
              print("Errore traduzione titolo: $e");
            }
          }
        }

        // Salvataggio per evitare sprechi di API oggi
        await DatabaseHelper.instance.savePantryCache(data, todayStr);

        if (mounted) {
          setState(() {
            pantryRecipes = data;
            isLoadingPantry = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingPantry = false);
      }
    } catch (e) {
      print("Errore API Dispensa: $e");
      if (mounted) setState(() => isLoadingPantry = false);
    }
  }

  Future<void> _loadViralRecipes() async {
    String todayStr = DateTime.now().toString().split(' ')[0];
    List<dynamic> cached = await DatabaseHelper.instance.getViralCache(todayStr);

    if (cached.isNotEmpty) {
      setState(() {
        viralRecipes = cached;
        isLoadingViral = false;
      });
    } else {
      _fetchViralFromApi(todayStr);
    }
  }

  Future<void> _fetchViralFromApi(String date) async {
    const apiKey = 'd94d3ad2ddaa4b9a8e6ae55f4e87b174';
    final url = 'https://api.spoonacular.com/recipes/random?number=30&tags=italian&apiKey=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List fetched = data['recipes'] ?? [];
        
        final translator = GoogleTranslator();
        for (var r in fetched) {
          String originalTitle = r['title'] ?? '';
          if (originalTitle.isNotEmpty) {
            try {
              var trans = await translator.translate(originalTitle, from: 'en', to: 'it');
              r['title'] = trans.text;
            } catch (e) {
              print("Errore traduzione Virali: $e");
            }
          }
        }

        await DatabaseHelper.instance.saveViralCache(fetched, date);
        if (mounted) setState(() { viralRecipes = fetched; isLoadingViral = false; });
      }
    } catch (e) {
       if (mounted) setState(() => isLoadingViral = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(context, theme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAllData,
                color: theme.colorScheme.primary,
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), 
                    slivers: [
                      if (widget.isLogged) ...[
                        _buildSectionHeader("I tuoi Preferiti", theme),
                        SliverToBoxAdapter(
                          child: isLoadingFavorites 
                            ? const Center(child: CircularProgressIndicator()) 
                            : _buildHorizontalList(favoriteRecipes, false),
                        ),

                        _buildSectionHeader("In base alla tua Dispensa", theme),
                        SliverToBoxAdapter(
                          child: isLoadingPantry 
                            ? const Center(child: CircularProgressIndicator()) 
                            : _buildHorizontalList(pantryRecipes, true),
                        ),
                      ],

                      _buildSectionHeader("Esplora Ricette Virali", theme, isLarge: true),
                      _buildApiSliverGrid(theme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, {bool isLarge = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isLarge ? 24 : 16, 16, 12),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: isLarge ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Text('Cerca ricette o ingredienti...', 
                style: GoogleFonts.montserrat(color: Colors.grey[600], fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List list, bool isFromApi) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Ancora nulla qui...", style: GoogleFonts.montserrat(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 170,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(), 
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final recipe = list[index];
            String imgPath = recipe['image'] ?? '';

            Widget imageWidget;
            if (imgPath.startsWith('http')) {
              imageWidget = Image.network(
                imgPath, height: 100, width: 150, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(height: 100, width: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey, size: 30)),
              );
            } else if (imgPath.isNotEmpty) {
              imageWidget = Image.file(
                File(imgPath), height: 100, width: 150, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(height: 100, width: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey, size: 30)),
              );
            } else {
              imageWidget = Container(height: 100, width: 150, color: Colors.grey[200], child: const Icon(Icons.restaurant_menu, color: Colors.grey, size: 30));
            }

            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RecipeDetailScreen(recipeData: recipe, isFromApi: isFromApi))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: imageWidget, 
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recipe['title'] ?? 'Senza titolo',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildApiSliverGrid(ThemeData theme) {
    if (isLoadingViral) {
      return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.75),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = viralRecipes[index];
            String imgPath = recipe['image'] ?? '';

            Widget imageWidget;
            if (imgPath.startsWith('http')) {
              imageWidget = Image.network(
                imgPath, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey))),
              );
            } else if (imgPath.isNotEmpty) {
              imageWidget = Image.file(
                File(imgPath), fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey))),
              );
            } else {
              imageWidget = Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.restaurant_menu, size: 40, color: Colors.grey)));
            }

            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipeData: recipe, isFromApi: true))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: imageWidget, 
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(recipe['title'] ?? 'Senza titolo', maxLines: 2, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            );
          },
          childCount: viralRecipes.length,
        ),
      ),
    );
  }
}