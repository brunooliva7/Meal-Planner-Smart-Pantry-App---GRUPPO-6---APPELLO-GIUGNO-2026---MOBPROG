import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; 
import 'stats_screen.dart';
import 'recipe.dart'; 
import 'package:sqflite/sqflite.dart'; 
import '../services/database_helper.dart'; // Assicurati che il path sia giusto (../services/ o ../database/)
import 'package:google_sign_in/google_sign_in.dart';

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class UserProfileScreen extends StatefulWidget {
  
  final VoidCallback? onLogout;

  const UserProfileScreen({super.key, this.onLogout});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isUserLogged = false; 
  bool isEditingProfile = false; 
  bool isLoading = true; 

  String nickname = 'utente_guest';
  String nome = 'Ospite';
  String peso = '';
  String altezza = '';
  String bio = '';
  String imagePath = ''; 

  List<dynamic> favoriteRecipes = [];
  List<dynamic> myCreatedRecipes = [];
  List<dynamic> savedOfflineRecipes = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 🟢 FIX 1: Lascia che la pagina si disegni prima fluidamente, POI carica i dati
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileAndData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _pesoController.dispose();
    _altezzaController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    
    // 🟢 FIX 1: Cerchiamo 'userId' come Numero (esattamente come nel main e nel login)
    final int? userId = prefs.getInt('userId');

    if (userId != null) {
      isUserLogged = true;
      final db = await DatabaseHelper.instance.database;

      // CHIAMATE PARALLELE
      final results = await Future.wait([
        db.query('users', where: 'id = ?', whereArgs: [userId]),
        db.query('user_profiles', where: 'user_id = ?', whereArgs: [userId]),
        db.query('favorites'), 
        db.query('saved_recipes', columns: ['id', 'title', 'image']) 
      ]);

      final userQuery = results[0];
      final profileQuery = results[1];
      final favQuery = results[2];
      final savedQuery = results[3];

      if (userQuery.isNotEmpty) {
        nome = userQuery.first['name']?.toString() ?? 'Utente Registrato';
        nickname = userQuery.first['nickname']?.toString() ?? userQuery.first['email']?.toString().split('@')[0] ?? 'utente';
      }

      if (profileQuery.isNotEmpty) {
        final data = profileQuery.first;
        peso = data['peso']?.toString() ?? '';
        altezza = data['altezza']?.toString() ?? '';
        bio = data['bio']?.toString() ?? '';
        imagePath = data['image_path']?.toString() ?? '';
      }

      _nameController.text = nome;
      _nicknameController.text = nickname;
      _pesoController.text = peso;
      _altezzaController.text = altezza;
      _bioController.text = bio;

      favoriteRecipes = favQuery.toList();

      List<dynamic> mine = [];
      List<dynamic> saved = [];

      for (var row in savedQuery) {
        int rId = row['id'] as int;
        Map<String, dynamic> minimalRecipe = {
          'id': rId,
          'title': row['title'],
          'image': row['image'],
        };
        if (rId > 1600000000 || rId < 0) {
          mine.add(minimalRecipe);
        } else {
          saved.add(minimalRecipe);
        }
      }
      myCreatedRecipes = mine;
      savedOfflineRecipes = saved;
    } else {
      isUserLogged = false;
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

 // 🟢 LOGOUT SINCRONIZZATO CON LA HOME
 Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); 

      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        await googleSignIn.disconnect(); 
      }
    } catch (e) {
      print("Errore durante la disconnessione Google nativa: $e");
    }

    if (mounted) {
      // 🟢 1. AVVISA LA HOME CHE L'UTENTE È USCITO
      widget.onLogout?.call();

      // 🟢 2. AZZERA LA SCHERMATA GRAFICA
      setState(() {
        isUserLogged = false;
        nome = 'Ospite';
        nickname = 'utente_guest';
        peso = '';
        altezza = '';
        bio = '';
        imagePath = '';
        favoriteRecipes = [];
        myCreatedRecipes = [];
        savedOfflineRecipes = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sessione chiusa. Cambiamento profilo effettuato!', style: GoogleFonts.montserrat()), 
          backgroundColor: Colors.orangeAccent
        ),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
      _saveProfileToDb();
    }
  }

  Future<void> _saveProfileToDb() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    
    // 🟢 FIX 2: Usiamo sempre 'userId' come numero
    final int? userId = prefs.getInt('userId');
    if (userId == null) return;

    final db = await DatabaseHelper.instance.database;

    await db.update(
      'users',
      {
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    await db.insert(
      'user_profiles',
      {
        'user_id': userId,
        'peso': double.tryParse(_pesoController.text) ?? 0.0,
        'altezza': double.tryParse(_altezzaController.text) ?? 0.0,
        'bio': _bioController.text.trim(),
        'image_path': imagePath,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    setState(() {
      nome = _nameController.text.trim();
      nickname = _nicknameController.text.trim();
      peso = _pesoController.text;
      altezza = _altezzaController.text;
      bio = _bioController.text.trim();
      isEditingProfile = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profilo salvato e sincronizzato!', style: GoogleFonts.montserrat()), backgroundColor: primaryGreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: backgroundColor, body: Center(child: CircularProgressIndicator(color: primaryGreen)));
    }

    if (!isUserLogged) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Text(
            "Accedi per visualizzare e\ngestire il tuo profilo personale.",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 16, color: unselectedIconColor, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text("Il tuo Profilo", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: primaryGreen),
            tooltip: "Vedi statistiche",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Sconnetti account",
            onPressed: _handleLogout,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeaderAvatar(),
                const SizedBox(height: 24),
                
                isEditingProfile ? _buildEditFormFields() : _buildProfileStatsCard(),
                const SizedBox(height: 24),

                _buildSectionTitle("I tuoi Preferiti ❤️"),
                _buildHorizontalRecipesList(favoriteRecipes, isFromApi: true),

                _buildSectionTitle("Le mie Ricette 🍳"),
                _buildHorizontalRecipesList(myCreatedRecipes, isFromApi: false),

                _buildSectionTitle("Ricette Salvate Offline 💾"),
                _buildHorizontalRecipesList(savedOfflineRecipes, isFromApi: false),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfileImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[200],
                  // 🟢 FIX 3: Rimpiccioliamo a 300 pixel l'immagine scattata con la fotocamera! Salva un sacco di RAM.
                  backgroundImage: imagePath.isNotEmpty ? ResizeImage(FileImage(File(imagePath)), width: 300) : null,
                  child: imagePath.isEmpty ? const Icon(Icons.person, size: 55, color: unselectedIconColor) : null,
                ),
                Positioned(
                  bottom: 0, right: 4,
                  child: CircleAvatar(
                    radius: 16, backgroundColor: primaryGreen,
                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(nome, style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text("@$nickname", style: GoogleFonts.montserrat(fontSize: 14, color: unselectedIconColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProfileStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Informazioni Fisiche", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: primaryGreen)),
              IconButton(
                icon: const Icon(Icons.edit, color: primaryGreen, size: 20),
                onPressed: () => setState(() => isEditingProfile = true),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBubble("Altezza", altezza.isEmpty ? "--" : "$altezza cm", Icons.straighten),
              const SizedBox(width: 16),
              _buildStatBubble("Peso", peso.isEmpty ? "--" : "$peso kg", Icons.scale),
            ],
          ),
          const SizedBox(height: 16),
          Text("Biografia", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 6),
          Text(
            bio.isEmpty ? "Nessuna biografia inserita. Raccontaci qualcosa sui tuoi gusti culinari!" : bio,
            style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          children: [
            Icon(icon, color: primaryGreen, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.montserrat(fontSize: 11, color: unselectedIconColor, fontWeight: FontWeight.w600)),
                Text(value, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEditFormFields() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          _buildTextFormField(_nameController, "Nome e Cognome", Icons.person, (v) => v == null || v.trim().isEmpty ? 'Inserisci il nome' : null),
          const SizedBox(height: 12),
          _buildTextFormField(_nicknameController, "Nickname", Icons.alternate_email, (v) => v == null || v.trim().isEmpty ? 'Inserisci un nickname' : null),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextFormField(_altezzaController, "Altezza (cm)", Icons.straighten, (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Errore' : null, isNum: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextFormField(_pesoController, "Peso (kg)", Icons.scale, (v) => v != null && v.isNotEmpty && double.tryParse(v) == null ? 'Errore' : null, isNum: true)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextFormField(_bioController, "Racconta qualcosa di te...", Icons.book, null, lines: 3),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => setState(() => isEditingProfile = false), child: Text("Annulla", style: GoogleFonts.montserrat(color: Colors.grey))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveProfileToDb,
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text("Salva", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController ctrl, String hint, IconData icon, String? Function(String?)? val, {bool isNum = false, int lines = 1}) {
    return TextFormField(
      controller: ctrl, validator: val, maxLines: lines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        labelText: hint, labelStyle: GoogleFonts.montserrat(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: primaryGreen), filled: true, fillColor: Colors.grey[50],
        errorStyle: GoogleFonts.montserrat(fontSize: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Text(title, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildHorizontalRecipesList(List<dynamic> list, {required bool isFromApi}) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text("Nessuna ricetta presente in questa sezione.", style: GoogleFonts.montserrat(fontSize: 13, color: unselectedIconColor, fontStyle: FontStyle.italic)),
      );
    }

    return SizedBox(
      height: 165,
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false), 
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(), 
          itemCount: list.length,
          itemBuilder: (context, index) {
            final recipe = list[index];
            String imgPath = recipe['image']?.toString() ?? '';
            imgPath = imgPath.replaceAll('file://', ''); 

            Widget imageWidget;
            if (imgPath.startsWith('http')) {
              imageWidget = Image.network(
                imgPath, fit: BoxFit.cover, cacheWidth: 200, 
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
              );
            } else if (imgPath.isNotEmpty) {
              imageWidget = Image.file(
                File(imgPath), fit: BoxFit.cover, cacheWidth: 200, 
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
              );
            } else {
              imageWidget = Container(color: Colors.grey[200], child: const Icon(Icons.restaurant_menu, color: Colors.grey));
            }

            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 14, bottom: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipeData: recipe, isFromApi: isFromApi)),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(width: double.infinity, child: imageWidget),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recipe['title'] ?? 'Senza Titolo',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}