import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Import del font ufficiale
import 'search_screen.dart';

// COLORI UFFICIALI DEL GRUPPO
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  // STATO DEL LOGIN:
  // - Se metti 'true': vedi le liste orizzontali in alto e la Griglia sotto.
  // - Se metti 'false': le liste orizzontali spariscono e la Griglia sale in cima.
  bool isUserLogged = false; 

  List recipes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchViralRecipes();
  }

  // Connessione API a Spoonacular
  Future<void> _fetchViralRecipes() async {
    const apiKey = 'd94d3ad2ddaa4b9a8e6ae55f4e87b174'; 
    const url = 'https://api.spoonacular.com/recipes/random?number=30&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recipes = data['recipes'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Sfondo bianco ufficiale
      
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
                        child: Text("I tuoi Preferiti", 
                          // FONT AGGIORNATO
                          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildHorizontalList()), 
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text("In base alla tua Dispensa", 
                          // FONT AGGIORNATO
                          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _buildHorizontalList()), 
                  ],

                  // TITOLO RICETTE VIRALI 
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text("Esplora Ricette Virali", 
                        // FONT AGGIORNATO
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),

                  // 3. LA GRIGLIA API 
                  _buildApiSliverGrid(),
                ],
              ),
            ),
          ],
        ),
      ),

      // BOTTOM BAR SUPER-MINIMALE
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 36, right: 36, bottom: 12), 
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_filled, 0),
              _buildNavItem(Icons.kitchen, 1),
              _buildNavItem(Icons.add_box_outlined, 2, size: 28),
              _buildNavItem(Icons.calendar_month, 3),
              _buildNavItem(Icons.person_outline, 4),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // WIDGET DI SUPPORTO
  // ==============================================================

  Widget _buildNavItem(IconData icon, int index, {double size = 26}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque, 
      child: Icon(
        icon,
        size: size,
        // COLORE AGGIORNATO (Verde primario o grigio disattivo)
        color: isSelected ? primaryGreen : unselectedIconColor,
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
            color: Colors.grey[100], // Leggermente grigio per staccare dal fondo bianco
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: primaryGreen, size: 20), // Icona verde
              const SizedBox(width: 12),
              // FONT AGGIORNATO
              Text('Cerca ricette o ingredienti...', 
                style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 15)
              ),
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
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12), 
            child: Card(
              color: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(child: Icon(Icons.restaurant, color: primaryGreen.withOpacity(0.5))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Ricetta #${index + 1}",
                      maxLines: 2,
                      // FONT AGGIORNATO
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApiSliverGrid() {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 50.0),
          // CARICAMENTO VERDE
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
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100), 
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
                      // FONT AGGIORNATO
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: recipes.length, 
        ),
      ),
    );
  }
}