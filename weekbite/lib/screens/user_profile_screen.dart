import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stats_screen.dart';
import '../database/database_helper.dart'; // <-- IMPORT DEL DATABASE DEL TEAM

// COLORI UFFICIALI DEL GRUPPO
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Stati Utente
  String nickname = 'utente_misterioso';
  String nome = 'Nome non impostato';
  String peso = '';
  String altezza = '';
  String bio = '';
  bool isEditingStats = false;
  bool isLoading = true; // Mostra caricamento mentre legge la memoria

  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  List<dynamic> ricettePreferite = [];
  List<dynamic> ricettePersonali = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ==========================================================
  // 🧠 LOGICA DI LETTURA E SALVATAGGIO DATI
  // ==========================================================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Carica i dati del profilo
    setState(() {
      peso = prefs.getString('user_peso') ?? '';
      altezza = prefs.getString('user_altezza') ?? '';
      bio = prefs.getString('user_bio') ?? '';
      _pesoController.text = peso;
      _altezzaController.text = altezza;
      _bioController.text = bio;
    });

    // 2. Cerca le ricette preferite nel Database SQLite del team
    final List<Map<String, dynamic>> favs = await DatabaseHelper.instance.getAllFavorites();
    setState(() {
      ricettePreferite = favs;
    });

    // 3. Cerca eventuali ricette create dall'utente
    final String? personalRecipesStr = prefs.getString('personal_recipes');
    if (personalRecipesStr != null) {
      ricettePersonali = json.decode(personalRecipesStr);
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveProfileStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_peso', _pesoController.text);
    await prefs.setString('user_altezza', _altezzaController.text);
    setState(() {
      peso = _pesoController.text;
      altezza = _altezzaController.text;
      isEditingStats = false;
    });
  }

  Future<void> _saveBio(String newBio) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_bio', newBio);
    setState(() => bio = newBio);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryGreen));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================================
              // HEADER: Foto e Dati Utente
              // ==========================================================
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryGreen, width: 2),
                    ),
                    child: const Icon(Icons.person, size: 40, color: primaryGreen),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@$nickname',
                          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          nome,
                          style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),

                        // INSERIMENTO DATI FISICI MANUALE E PERSISTENTE
                        isEditingStats 
                          ? Row(
                              children: [
                                _buildMiniInput("Peso (kg)", _pesoController),
                                const SizedBox(width: 8),
                                _buildMiniInput("Alt (cm)", _altezzaController),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _saveProfileStats,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: primaryGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text("OK", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                )
                              ],
                            )
                          : GestureDetector(
                              onTap: () => setState(() => isEditingStats = true),
                              child: Row(
                                children: [
                                  Icon(peso.isEmpty ? Icons.add_circle_outline : Icons.edit, size: 16, color: primaryGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    peso.isNotEmpty && altezza.isNotEmpty 
                                      ? 'Peso: $peso kg | Alt: $altezza cm' 
                                      : 'Inserisci dati fisici',
                                    style: GoogleFonts.montserrat(color: peso.isEmpty ? primaryGreen : Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // ==========================================================
              // SEZIONE BIO
              // ==========================================================
              Text('Bio', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              TextField(
                controller: _bioController,
                onChanged: (value) => _saveBio(value),
                maxLines: 3,
                style: GoogleFonts.montserrat(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Scrivi qualcosa su di te e salverà in automatico...',
                  hintStyle: GoogleFonts.montserrat(color: unselectedIconColor),
                  filled: true,
                  fillColor: Colors.grey[50],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // ==========================================================
              // SEZIONE RICETTE PREFERITE (DATI VERI DA SQLITE)
              // ==========================================================
              Text('Ricette Preferite', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              ricettePreferite.isEmpty 
                  ? _buildEmptyList("Nessuna ricetta preferita salvata.")
                  : _buildHorizontalList(ricettePreferite),
              const SizedBox(height: 30),

              // ==========================================================
              // SEZIONE RICETTE PERSONALI
              // ==========================================================
              Text('Ricette Personali', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              ricettePersonali.isEmpty 
                  ? _buildEmptyList("Non hai ancora creato ricette.")
                  : _buildHorizontalList(ricettePersonali),
              const SizedBox(height: 40),

              // ==========================================================
              // BOTTONE STATISTICHE
              // ==========================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.bar_chart, color: Colors.white),
                  label: Text(
                    'Statistiche', 
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 100), // Spazio per la bottom bar
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // WIDGET DI SUPPORTO
  // ==============================================================

  Widget _buildMiniInput(String hint, TextEditingController controller) {
    return SizedBox(
      width: 70,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: GoogleFonts.montserrat(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryGreen),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyList(String messaggio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          messaggio,
          style: GoogleFonts.montserrat(color: unselectedIconColor, fontStyle: FontStyle.italic, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List recipes) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
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
                      image: DecorationImage(
                        image: NetworkImage(recipe['image'] ?? 'https://via.placeholder.com/150'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      recipe['title'] ?? 'Senza Titolo',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}