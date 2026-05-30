import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Color.fromARGB(255, 241, 241, 241);

class IngredientItem {
  TextEditingController amountCtrl = TextEditingController(text: '1');
  TextEditingController unitCtrl = TextEditingController(text: 'g');
  TextEditingController nameCtrl = TextEditingController();
}

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _timeController = TextEditingController(text: '30');
  
  int _servings = 2;
  File? _selectedImage;
  final List<IngredientItem> _ingredients = [IngredientItem()]; 

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(IngredientItem());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci almeno il titolo della ricetta!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Costruiamo la lista degli ingredienti formattata ESATTAMENTE come l'API
    List<Map<String, dynamic>> extIngredients = _ingredients.map((ing) {
      return {
        'name': ing.nameCtrl.text.trim().isEmpty ? 'Ingrediente' : ing.nameCtrl.text.trim(),
        'amount': double.tryParse(ing.amountCtrl.text) ?? 1.0,
        'unit': ing.unitCtrl.text.trim(),
        'translatedName': ing.nameCtrl.text.trim().isEmpty ? 'Ingrediente' : ing.nameCtrl.text.trim(),
      };
    }).toList();

    // Creiamo un ID univoco basato sul momento esatto in cui premi "Salva"
    int customId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Assicuriamoci che l'immagine ci sia, sennò usiamo una stringa vuota
    String imagePath = _selectedImage?.path ?? '';

    Map<String, dynamic> customRecipe = {
      'id': customId,
      'title': _titleController.text.trim(),
      'image': imagePath, 
      'readyInMinutes': int.tryParse(_timeController.text) ?? 30,
      'servings': _servings,
      'summary': _summaryController.text.trim(),
      'instructions': _instructionsController.text.trim(),
      'extendedIngredients': extIngredients,
      'personalNotes': '', 
    };

    // 🟢 1. SALVATAGGIO NEL DATABASE PRINCIPALE (La tua vera cassaforte locale)
    await DatabaseHelper.instance.downloadRecipe(customRecipe);

    // 🟢 2. INSERIMENTO NEI PREFERITI (Fondamentale per farla apparire sulla Home)
    await DatabaseHelper.instance.addFavorite(
      customId, 
      customRecipe['title'], 
      imagePath
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ricetta creata e aggiunta ai Preferiti!', style: GoogleFonts.montserrat()), 
          backgroundColor: primaryGreen
        ),
      );
      Navigator.pop(context); // Torna alla Home in automatico
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Crea Ricetta", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📷 SEZIONE IMMAGINE
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo, size: 40, color: primaryGreen),
                            const SizedBox(height: 8),
                            Text("Aggiungi una foto", style: GoogleFonts.montserrat(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // 📝 TITOLO E TEMPO
              _buildTextField(_titleController, "Nome del piatto", Icons.restaurant_menu, maxLines: 1),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_timeController, "Minuti", Icons.timer, isNumber: true),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: primaryGreen),
                        IconButton(icon: const Icon(Icons.remove, color: primaryGreen, size: 20), onPressed: () => setState(() => _servings > 1 ? _servings-- : null)),
                        Text("$_servings", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(icon: const Icon(Icons.add, color: primaryGreen, size: 20), onPressed: () => setState(() => _servings++)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 📖 DESCRIZIONE
              Text("Descrizione (Opzionale)", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildTextField(_summaryController, "Un breve riassunto del piatto...", null, maxLines: 3),
              const SizedBox(height: 24),

              // 🥦 INGREDIENTI (Dinamici)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ingredienti", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add_circle, color: primaryGreen),
                    label: Text("Aggiungi", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 8),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 60, child: _buildTextField(_ingredients[index].amountCtrl, "Qta", null, isNumber: true)),
                        const SizedBox(width: 8),
                        SizedBox(width: 60, child: _buildTextField(_ingredients[index].unitCtrl, "Mis.", null)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_ingredients[index].nameCtrl, "Ingrediente", null)),
                        IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () => _removeIngredient(index)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 🍳 PROCEDIMENTO
              Text("Procedimento", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildTextField(_instructionsController, "Descrivi i passaggi da seguire...", null, maxLines: 5),
              const SizedBox(height: 40),

              // 💾 BOTTONE SALVA
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text("Salva nel Ricettario", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData? icon, {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
        prefixIcon: icon != null ? Icon(icon, color: primaryGreen) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
      ),
    );
  }
}