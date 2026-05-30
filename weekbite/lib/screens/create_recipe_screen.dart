import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';

// Manteniamo le costanti grafiche definite nel tuo tema principale
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
  // 🟢 PATTERN: Chiave globale per identificare e convalidare il Form dello Stato (Slide 04-input-in-ui)
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _timeController = TextEditingController(text: '30');
  
  int _servings = 2;
  File? _selectedImage;
  final List<IngredientItem> _ingredients = [IngredientItem()]; 

  // 🟢 PATTERN: Rilascio delle risorse per prevenire Memory Leaks (Slide 04-input-in-ui)
  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _instructionsController.dispose();
    _timeController.dispose();
    
    // Distrugge in ciclo tutti i controller creati dinamicamente nella lista degli ingredienti
    for (var ingredient in _ingredients) {
      ingredient.amountCtrl.dispose();
      ingredient.unitCtrl.dispose();
      ingredient.nameCtrl.dispose();
    }
    super.dispose();
  }

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
      // Prima di rimuovere l'elemento dall'array, distruggiamo i suoi controller per sicurezza
      _ingredients[index].amountCtrl.dispose();
      _ingredients[index].unitCtrl.dispose();
      _ingredients[index].nameCtrl.dispose();
      
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    // 🟢 PATTERN: Validazione sicura del modulo tramite lo stato corrente della FormKey
    if (!_formKey.currentState!.validate()) {
      // Se un validatore fallisce, la funzione si interrompe e gli errori compaiono nell'interfaccia grafica
      return;
    }

    // Costruiamo la lista degli ingredienti formattata accuratamente per il database
    List<Map<String, dynamic>> extIngredients = _ingredients.map((ing) {
      return {
        'name': ing.nameCtrl.text.trim(),
        'amount': double.tryParse(ing.amountCtrl.text) ?? 1.0,
        'unit': ing.unitCtrl.text.trim(),
        'translatedName': ing.nameCtrl.text.trim(),
      };
    }).toList();

    int customId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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

    // Inserimento nei database SQLite locali strutturati coerentemente
    await DatabaseHelper.instance.downloadRecipe(customRecipe);
    await DatabaseHelper.instance.addFavorite(customId, customRecipe['title'], imagePath);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ricetta creata e aggiunta ai Preferiti!', style: GoogleFonts.montserrat()), 
          backgroundColor: primaryGreen
        ),
      );
      Navigator.pop(context); 
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
      // 🟢 PATTERN: Introduzione del widget Form all'inizio dell'albero dell'input utente
      body: Form(
        key: _formKey,
        child: ScrollConfiguration(
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

                // 📝 TITOLO DELLA RICETTA
                _buildFormField(
                  controller: _titleController, 
                  hint: "Nome del piatto", 
                  icon: Icons.restaurant_menu,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il nome della ricetta';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // TEMPO E PORZIONI
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _timeController, 
                        hint: "Minuti", 
                        icon: Icons.timer, 
                        isNumber: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Inserisci i minuti';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Usa un numero intero';
                          }
                          return null;
                        },
                      ),
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
                _buildFormField(
                  controller: _summaryController, 
                  hint: "Un breve riassunto del piatto...", 
                  icon: null,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // 🥦 INGREDIENTI DINAMICI
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quantità
                          SizedBox(
                            width: 65, 
                            child: _buildFormField(
                              controller: _ingredients[index].amountCtrl, 
                              hint: "Qta", 
                              icon: null,
                              isNumber: true,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return '!';
                                if (double.tryParse(value) == null) return '?';
                                return null;
                              },
                            )
                          ),
                          const SizedBox(width: 8),
                          // Unità di Misura
                          SizedBox(
                            width: 65, 
                            child: _buildFormField(
                              controller: _ingredients[index].unitCtrl, 
                              hint: "Mis.", 
                              icon: null,
                            )
                          ),
                          const SizedBox(width: 8),
                          // Nome Ingrediente
                          Expanded(
                            child: _buildFormField(
                              controller: _ingredients[index].nameCtrl, 
                              hint: "Ingrediente", 
                              icon: null,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Inserisci ingrediente';
                                }
                                return null;
                              },
                            )
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), 
                              onPressed: _ingredients.length > 1 ? () => _removeIngredient(index) : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 🍳 PROCEDIMENTO
                Text("Procedimento", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildFormField(
                  controller: _instructionsController, 
                  hint: "Descrivi i passaggi da seguire...", 
                  icon: null,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Spiega come preparare il piatto!';
                    }
                    return null;
                  },
                ),
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
      ),
    );
  }

  // 🟢 COERENZA DEI PATTERN: Funzione helper rifattorizzata che implementa correttamente TextFormField e validazioni
  Widget _buildFormField({
    required TextEditingController controller, 
    required String hint, 
    required IconData? icon, 
    int maxLines = 1, 
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator, // Nativamente gestito dal modulo globale
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: GoogleFonts.montserrat(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(color: Colors.grey[400]),
        prefixIcon: icon != null ? Icon(icon, color: primaryGreen) : null,
        filled: true,
        fillColor: Colors.white,
        errorStyle: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.0)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }
}