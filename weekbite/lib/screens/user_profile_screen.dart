import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // 🟢 Import per la galleria
import 'stats_screen.dart';
import '../database/database_helper.dart';

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
  bool isUserLogged = false; // 🟢 Controlla se è Guest o Loggato
  bool isEditingProfile = false; // 🟢 Sostituisce isEditingStats per gestire TUTTO
  bool isLoading = true; 

  String nickname = 'utente_guest';
  String nome = 'Ospite';
  String peso = '';
  String altezza = '';
  String bio = '';
  String imagePath = ''; // 🟢 Percorso della foto profilo locale

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
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
    
    // 1. Controllo se l'utente è loggato
    final String? uid = prefs.getString('logged_in_uid');
    bool checkLogged = uid != null && uid.isNotEmpty;

    // 2. Carica i dati del profilo
    setState(() {
      isUserLogged = checkLogged;

      if (isUserLogged) {
        nickname = prefs.getString('user_nickname') ?? 'nuovo_utente';
        nome = prefs.getString('user_nome') ?? 'Nome non impostato';
        peso = prefs.getString('user_peso') ?? '';
        altezza = prefs.getString('user_altezza') ?? '';
        bio = prefs.getString('user_bio') ?? '';
        imagePath = prefs.getString('user_pic') ?? '';
      } else {
        // Valori di default per i Guest
        nickname = 'ospite_curioso';
        nome = 'Utente Non Registrato';
        peso = ''; altezza = ''; bio = ''; imagePath = '';
      }

      _nicknameController.text = nickname;
      _nomeController.text = nome;
      _pesoController.text = peso;
      _altezzaController.text = altezza;
      _bioController.text = bio;
    });

    // 3. Cerca le ricette preferite nel Database
    if (isUserLogged) {
      final List<Map<String, dynamic>> favs = await DatabaseHelper.instance.getAllFavorites();
      setState(() {
        ricettePreferite = favs;
      });

      final String? personalRecipesStr = prefs.getString('personal_recipes');
      if (personalRecipesStr != null) {
        ricettePersonali = json.decode(personalRecipesStr);
      }
    }

    setState(() => isLoading = false);
  }

  // 🟢 SALVA TUTTE LE MODIFICHE DEL PROFILO
  Future<void> _saveFullProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nickname', _nicknameController.text.trim());
    await prefs.setString('user_nome', _nomeController.text.trim());
    await prefs.setString('user_peso', _pesoController.text.trim());
    await prefs.setString('user_altezza', _altezzaController.text.trim());
    await prefs.setString('user_bio', _bioController.text.trim());
    await prefs.setString('user_pic', imagePath);

    setState(() {
      nickname = _nicknameController.text.trim();
      nome = _nomeController.text.trim();
      peso = _pesoController.text.trim();
      altezza = _altezzaController.text.trim();
      bio = _bioController.text.trim();
      isEditingProfile = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profilo aggiornato!", style: GoogleFonts.montserrat()), backgroundColor: primaryGreen),
      );
    }
  }

  // 🟢 SELEZIONA FOTO DALLA GALLERIA
  Future<void> _pickImage() async {
    if (!isUserLogged || !isEditingProfile) return;

    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
    }
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
              // PULSANTE MODIFICA IN ALTO (Solo se loggato)
              // ==========================================================
              if (isUserLogged)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      if (isEditingProfile) {
                        _saveFullProfile(); // Salva se stava modificando
                      } else {
                        setState(() => isEditingProfile = true); // Entra in modalità modifica
                      }
                    },
                    icon: Icon(isEditingProfile ? Icons.check : Icons.edit, color: primaryGreen, size: 18),
                    label: Text(
                      isEditingProfile ? "Salva Profilo" : "Modifica Profilo",
                      style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // ==========================================================
              // HEADER: Foto e Dati Utente
              // ==========================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟢 FOTO PROFILO CLICCABILE
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryGreen, width: 2),
                            image: imagePath.isNotEmpty 
                                ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover)
                                : null,
                          ),
                          child: imagePath.isEmpty ? const Icon(Icons.person, size: 40, color: primaryGreen) : null,
                        ),
                        if (isEditingProfile)
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: primaryGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // 🟢 DATI ANAGRAFICI
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isEditingProfile
                            ? TextField(
                                controller: _nicknameController,
                                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(bottom: 4), hintText: "Nickname"),
                              )
                            : Text(
                                '@$nickname',
                                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                        
                        const SizedBox(height: 4),
                        
                        isEditingProfile
                            ? TextField(
                                controller: _nomeController,
                                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[700]),
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(bottom: 4), hintText: "Nome e Cognome"),
                              )
                            : Text(
                                nome,
                                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.grey[600]),
                              ),
                        
                        const SizedBox(height: 12),

                        // DATI FISICI
                        isEditingProfile 
                          ? Row(
                              children: [
                                _buildMiniInput("Peso (kg)", _pesoController),
                                const SizedBox(width: 8),
                                _buildMiniInput("Alt (cm)", _altezzaController),
                              ],
                            )
                          : Row(
                              children: [
                                Icon(Icons.fitness_center, size: 16, color: primaryGreen),
                                const SizedBox(width: 6),
                                Text(
                                  peso.isNotEmpty && altezza.isNotEmpty 
                                    ? '$peso kg • $altezza cm' 
                                    : (isUserLogged ? 'Dati fisici non impostati' : 'Guest'),
                                  style: GoogleFonts.montserrat(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
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
                maxLines: 3,
                enabled: isEditingProfile, // Scrivibile solo se in modalità modifica
                style: GoogleFonts.montserrat(fontSize: 14),
                decoration: InputDecoration(
                  hintText: isUserLogged ? (isEditingProfile ? 'Scrivi qualcosa su di te...' : 'Nessuna bio inserita.') : 'Iscriviti per aggiungere una bio.',
                  hintStyle: GoogleFonts.montserrat(color: unselectedIconColor),
                  filled: true,
                  fillColor: isEditingProfile ? Colors.white : Colors.grey[50],
                  disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
                ),
              ),
              const SizedBox(height: 30),

              // ==========================================================
              // SEZIONE RICETTE PREFERITE
              // ==========================================================
              Text('Ricette Preferite', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              !isUserLogged 
                ? _buildEmptyList("Accedi per salvare i tuoi piatti preferiti.")
                : (ricettePreferite.isEmpty ? _buildEmptyList("Nessuna ricetta preferita salvata.") : _buildHorizontalList(ricettePreferite)),
              const SizedBox(height: 30),

              // ==========================================================
              // SEZIONE RICETTE PERSONALI
              // ==========================================================
              Text('Ricette Personali', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 10),
              !isUserLogged 
                ? _buildEmptyList("Accedi per creare le tue ricette personali.")
                : (ricettePersonali.isEmpty ? _buildEmptyList("Non hai ancora creato ricette.") : _buildHorizontalList(ricettePersonali)),
              const SizedBox(height: 40),

              // ==========================================================
              // BOTTONE STATISTICHE (BLOCCATO PER I GUEST)
              // ==========================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!isUserLogged) {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Iscriviti o accedi per vedere le tue statistiche!", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen()));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUserLogged ? primaryGreen : Colors.grey[400], // Grigio se bloccato
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
      width: 75,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryGreen)),
        ),
      ),
    );
  }

  Widget _buildEmptyList(String messaggio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
      ),
      child: Center(
        child: Text(
          messaggio,
          textAlign: TextAlign.center,
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
          String imgPath = recipe['image'] ?? '';

          Widget imageWidget;
          if (imgPath.startsWith('http')) {
            imageWidget = Image.network(imgPath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)));
          } else if (imgPath.isNotEmpty) {
            imageWidget = Image.file(File(imgPath), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)));
          } else {
            imageWidget = Container(color: Colors.grey[200], child: const Icon(Icons.restaurant_menu, color: Colors.grey));
          }

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
                    decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                    child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: imageWidget),
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