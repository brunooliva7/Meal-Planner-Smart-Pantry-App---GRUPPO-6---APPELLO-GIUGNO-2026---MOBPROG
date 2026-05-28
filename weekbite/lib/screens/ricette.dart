import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
// import 'search_screen.dart'; // Decommenta se ti serve

class RicetteScreen extends StatefulWidget {
  const RicetteScreen({super.key});

  @override
  State<RicetteScreen> createState() => _RicetteScreenState();
}

class _RicetteScreenState extends State<RicetteScreen> {
  // STATO DEL LOGIN
  bool isUserLogged = false; 

  List recipes = [];
  bool isLoading = true;
  
  // Ripreso dalle tue config globali
  final Color primaryGreen = const Color.fromARGB(255, 75, 187, 120); 

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
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // 1. BARRA DI RICERCA 
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
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildHorizontalList()), 
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text("In base alla tua Dispensa", 
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
    );
  }

  // ==============================================================
  // WIDGET INTERNI
  // ==============================================================

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
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
              Icon(Icons.search, color: primaryGreen, size: 20),
              const SizedBox(width: 12),
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
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0),
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
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16), 
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