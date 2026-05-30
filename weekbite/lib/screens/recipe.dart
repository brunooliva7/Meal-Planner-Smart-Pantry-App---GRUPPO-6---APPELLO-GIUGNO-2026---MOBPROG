import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:translator/translator.dart'; 
import '../database/database_helper.dart';
import 'dart:io';  

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData; 
  final bool isFromApi;                 

  const RecipeDetailScreen({
    super.key,
    required this.recipeData,
    required this.isFromApi,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool isUserLogged = false; 

  bool isDownloaded = false;
  bool isFavorite = false;
  bool isEditing = false; 
  
  late int servings;
  late int originalServings;
  bool isLocalLoading = false; 
  bool isTranslating = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController(); 
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<dynamic> ingredients = [];

  @override
  void initState() {
    super.initState();
    _initRecipeState();
  }

  Future<void> _initRecipeState() async {
    int recipeId = widget.recipeData['id'] ?? 0;
    
    final prefs = await SharedPreferences.getInstance();
    final String? uid = prefs.getString('logged_in_uid');
    bool checkLogged = uid != null && uid.isNotEmpty;

    bool favStatus = await DatabaseHelper.instance.isFavorite(recipeId);
    bool downloadStatus = await DatabaseHelper.instance.isRecipeDownloaded(recipeId);
    
    Map<String, dynamic>? localData;
    if (downloadStatus) {
      localData = await DatabaseHelper.instance.getSavedRecipeWithNotes(recipeId);
    }

    setState(() {
      isUserLogged = checkLogged; 
      isFavorite = favStatus;
      isDownloaded = downloadStatus;
      
      servings = localData?['servings'] ?? widget.recipeData['servings'] ?? 2;
      originalServings = widget.recipeData['servings'] ?? servings;
      if (originalServings <= 0) originalServings = 2;

      ingredients = localData?['extendedIngredients'] ?? widget.recipeData['extendedIngredients'] ?? widget.recipeData['ingredients'] ?? [];
      
      _titleController.text = localData?['title'] ?? widget.recipeData['title'] ?? 'Senza Titolo';
      _notesController.text = localData?['personalNotes'] ?? widget.recipeData['personalNotes'] ?? "";
      
      String rawSummary = localData?['summary'] ?? widget.recipeData['summary'] ?? "Nessuna descrizione disponibile per questo piatto.";
      _summaryController.text = _cleanHtml(rawSummary);

      String rawInstructions = localData?['instructions'] ?? widget.recipeData['instructions'] ?? "Nessuna istruzione fornita per questa ricetta.";
      _instructionsController.text = _cleanHtml(rawInstructions);
    });

    if (widget.isFromApi && !downloadStatus) {
      _translateContent();
    }
  }

  String _cleanHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  Future<void> _translateContent() async {
    setState(() => isTranslating = true);
    final translator = GoogleTranslator();

    try {
      var tTitle = await translator.translate(_titleController.text, from: 'en', to: 'it');
      _titleController.text = tTitle.text;

      String rawSummary = widget.recipeData['summary'] ?? '';
      if (rawSummary.isNotEmpty) {
        var tSummary = await translator.translate(_cleanHtml(rawSummary), from: 'en', to: 'it');
        _summaryController.text = tSummary.text;
      }

      String rawInst = widget.recipeData['instructions'] ?? '';
      if (rawInst.isNotEmpty) {
        var tInst = await translator.translate(_cleanHtml(rawInst), from: 'en', to: 'it');
        _instructionsController.text = tInst.text;
      }

      for (var ing in ingredients) {
        String nameToTranslate = ing['nameClean'] ?? ing['name'] ?? ing['originalName'] ?? "";
        if (nameToTranslate.isNotEmpty) {
          try {
            var tIng = await translator.translate(nameToTranslate, from: 'en', to: 'it');
            ing['translatedName'] = tIng.text;
          } catch (e) {
            print("Errore traduzione ingrediente: $e");
            ing['translatedName'] = nameToTranslate;
          }
        } else {
          ing['translatedName'] = "Ingrediente";
        }
      }
    } catch (e) {
      print("Errore traduzione completa: $e");
      for (var ing in ingredients) {
        ing['translatedName'] = ing['name'];
      }
    }

    if (mounted) {
      setState(() => isTranslating = false);
    }
  }

  double _getScaledAmount(double? originalAmount) {
    if (originalAmount == null) return 0.0;
    return (originalAmount / originalServings) * servings;
  }

  String _translateUnit(String unit) {
    String u = unit.toLowerCase().trim();
    if (u == 'g' || u == 'gr' || u == 'grams' || u == 'gram') return 'g';
    if (u == 'kg' || u == 'kilogram' || u == 'kilograms') return 'kg';
    if (u == 'ml' || u == 'milliliter' || u == 'milliliters') return 'ml';
    if (u == 'l' || u == 'liter' || u == 'liters') return 'L';
    if (u == 'tbsp' || u == 'tablespoon' || u == 'tablespoons' || u == 'tbsps') return 'cucchiai';
    if (u == 'tsp' || u == 'teaspoon' || u == 'teaspoons' || u == 'tsps') return 'cucchiaini';
    if (u == 'cup' || u == 'cups' || u == 'c') return 'tazze';
    if (u == 'oz' || u == 'ounce' || u == 'ounces') return 'once';
    if (u == 'lb' || u == 'lbs' || u == 'pound' || u == 'pounds') return 'libbre';
    if (u == 'clove' || u == 'cloves') return 'spicchi';
    if (u == 'pinch' || u == 'pinches') return 'pizzico';
    if (u == 'handful' || u == 'handfuls') return 'manciata';
    if (u == 'slice' || u == 'slices') return 'fette';
    if (u == 'leaf' || u == 'leaves') return 'foglie';
    if (u == 'bunch' || u == 'bunches') return 'mazzetto';
    if (u == 'dash' || u == 'dashes') return 'goccia/e';
    if (u == 'sprig' || u == 'sprigs') return 'rametti';
    if (u == 'head' || u == 'heads') return 'cespi';
    if (u == 'serving' || u == 'servings') return 'porzioni';
    if (u == 'piece' || u == 'pieces') return 'pezzi';
    if (u == 'can' || u == 'cans') return 'lattine';
    if (u == 'package' || u == 'packages') return 'confezioni';
    return u; 
  }

  void _showLoginWarning() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Devi effettuare l'accesso per usare questa funzione!", 
                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadRecipeAction() async {
    setState(() => isLocalLoading = true);
    
    Map<String, dynamic> currentData = Map<String, dynamic>.from(widget.recipeData);
    currentData['title'] = _titleController.text;
    currentData['summary'] = _summaryController.text;
    currentData['instructions'] = _instructionsController.text;
    currentData['servings'] = servings;
    currentData['extendedIngredients'] = ingredients;

    await DatabaseHelper.instance.downloadRecipe(currentData);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          isLocalLoading = false;
          isDownloaded = true; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ricetta salvata nel Database SQLite locale!", style: GoogleFonts.montserrat()), backgroundColor: primaryGreen),
        );
      }
    });
  }

  Future<void> _saveModifications() async {
    int recipeId = widget.recipeData['id'] ?? 0;
    
    Map<String, dynamic> updatedData = Map<String, dynamic>.from(widget.recipeData);
    updatedData['title'] = _titleController.text;
    updatedData['summary'] = _summaryController.text; 
    updatedData['instructions'] = _instructionsController.text;
    updatedData['servings'] = servings;
    updatedData['extendedIngredients'] = ingredients;

    await DatabaseHelper.instance.downloadRecipe(updatedData);
    await DatabaseHelper.instance.updatePersonalNotes(recipeId, _notesController.text);

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Tutte le modifiche sono state salvate in SQLite!", style: GoogleFonts.montserrat()), backgroundColor: primaryGreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    int recipeId = widget.recipeData['id'] ?? 0;

    return Scaffold(
      backgroundColor: backgroundColor, 
      // 🟢 AGGIUNTA LA SCROLL CONFIGURATION PER DISATTIVARE L'OVERSCROLL (EFFETTO SLIME)
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(), // Si ferma di netto senza "rimbalzi" o deformazioni
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              elevation: 0,
              backgroundColor: backgroundColor, 
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: backgroundColor.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: backgroundColor.withOpacity(0.9),
                    child: IconButton(
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? primaryGreen : unselectedIconColor, size: 22),
                      onPressed: () async {
                        if (!isUserLogged) {
                          _showLoginWarning(); 
                        } else {
                          if (isFavorite) {
                            await DatabaseHelper.instance.removeFavorite(recipeId);
                          } else {
                            await DatabaseHelper.instance.addFavorite(recipeId, _titleController.text, widget.recipeData['image'] ?? '');
                          }
                          setState(() => isFavorite = !isFavorite);
                        }
                      },
                    ),
                  ),
                ),
              ],
             flexibleSpace: FlexibleSpaceBar(
              background: Builder(
                builder: (context) {
                  String imgPath = widget.recipeData['image'] ?? '';
                  
                  Widget imageWidget;
                  // Se inizia con http, è di Spoonacular (internet)
                  if (imgPath.startsWith('http')) {
                    imageWidget = Image.network(
                      imgPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 50, color: unselectedIconColor))),
                    );
                  } 
                  // Se inizia con / o c:, è un percorso locale (creata da te)
                  else if (imgPath.isNotEmpty) {// Assicurati di aggiungere import 'dart:io'; in cima al file recipe.dart
                    imageWidget = Image.file(
                      File(imgPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 50, color: unselectedIconColor))),
                    );
                  } 
                  // Fallback se non c'è nessuna immagine
                  else {
                    imageWidget = Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.restaurant, size: 50, color: unselectedIconColor)));
                  }

                  return imageWidget;
                },
              ),
            ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTranslating)
                      Text("Traduzione in corso...", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold))
                    else if (isEditing)
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800),
                        decoration: const InputDecoration(
                          labelText: "Nome della Ricetta",
                          labelStyle: TextStyle(color: primaryGreen),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen, width: 2)),
                        ),
                      )
                    else
                      Text(_titleController.text, style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
                    
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(Icons.access_time, color: primaryGreen, size: 20),
                        const SizedBox(width: 6),
                        Text("${widget.recipeData['readyInMinutes'] ?? 30} min", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                        const SizedBox(width: 24),
                        Icon(isDownloaded ? Icons.cloud_done : Icons.cloud_download_outlined, color: isDownloaded ? primaryGreen : unselectedIconColor, size: 20),
                        const SizedBox(width: 6),
                        Text(isDownloaded ? "Salvato nel DB" : "Solo Online", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey[300]!)),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: primaryGreen, size: 20),
                                onPressed: servings > 1 && !isEditing ? () => setState(() => servings--) : null,
                              ),
                              Text("$servings persone", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add, color: primaryGreen, size: 20),
                                onPressed: !isEditing ? () => setState(() => servings++) : null,
                              ),
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: isLocalLoading
                                  ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2))
                                  : isEditing
                                      ? ElevatedButton.icon(
                                          onPressed: _saveModifications,
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                          icon: const Icon(Icons.check, size: 18),
                                          label: Text("Salva", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                                        )
                                      : !isDownloaded
                                          ? ElevatedButton.icon(
                                              onPressed: () {
                                                if (!isUserLogged) {
                                                  _showLoginWarning(); 
                                                } else {
                                                  _downloadRecipeAction();
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, foregroundColor: backgroundColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                              icon: const Icon(Icons.save_alt, size: 18),
                                              label: Text("Salva", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                                            )
                                          : OutlinedButton.icon(
                                              onPressed: () {
                                                if (!isUserLogged) {
                                                  _showLoginWarning(); 
                                                } else {
                                                  setState(() => isEditing = true); 
                                                }
                                              },
                                              style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryGreen, width: 2), foregroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                              icon: const Icon(Icons.edit, size: 18),
                                              label: Text("Modifica", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                                            ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: Colors.black12),

                    Text("Descrizione", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),
                    
                    if (isTranslating)
                      const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: primaryGreen)))
                    else if (isEditing)
                      TextField(
                        controller: _summaryController,
                        maxLines: null, 
                        style: GoogleFonts.montserrat(fontSize: 14, height: 1.5),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 2)),
                        ),
                      )
                    else
                      Text(
                        _summaryController.text,
                        style: GoogleFonts.montserrat(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),

                    const Divider(height: 32, color: Colors.black12),

                    Text("Ingredienti", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 16),
                    
                    if (isTranslating)
                      const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: primaryGreen)))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ingredients.length,
                        itemBuilder: (context, index) {
                          final ing = ingredients[index];
                          double originalAmount = 0.0;
                          String originalUnit = "";

                          if (ing['measures'] != null && ing['measures']['metric'] != null) {
                            originalAmount = ing['measures']['metric']['amount']?.toDouble() ?? 0.0;
                            originalUnit = ing['measures']['metric']['unitShort'] ?? "";
                          } else {
                            originalAmount = ing['amount']?.toDouble() ?? 0.0;
                            originalUnit = ing['unit'] ?? "";
                          }

                          String translatedUnit = _translateUnit(originalUnit);
                          double currentAmount = _getScaledAmount(originalAmount);
                          String name = ing['translatedName'] ?? ing['name'] ?? "Ingrediente";

                          String formattedAmount = currentAmount % 1 == 0 
                              ? currentAmount.toInt().toString() 
                              : currentAmount.toStringAsFixed(1).replaceAll('.0', '');

                          if (isEditing) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: TextFormField(
                                      initialValue: formattedAmount,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen),
                                      decoration: InputDecoration(
                                        suffixText: translatedUnit,
                                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen)),
                                      ),
                                      onChanged: (val) {
                                        double? parsed = double.tryParse(val);
                                        if (parsed != null) {
                                          if (ing['measures'] != null && ing['measures']['metric'] != null) {
                                            ing['measures']['metric']['amount'] = parsed;
                                          } else {
                                            ing['amount'] = parsed;
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: name,
                                      style: GoogleFonts.montserrat(fontSize: 14),
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen)),
                                      ),
                                      onChanged: (val) {
                                        ing['translatedName'] = val;
                                        ing['name'] = val;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(padding: EdgeInsets.only(top: 6.0), child: Icon(Icons.circle, size: 8, color: primaryGreen)),
                                const SizedBox(width: 16),
                                Expanded(child: Text(name[0].toUpperCase() + name.substring(1), style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500))),
                                Text(currentAmount > 0 ? "$formattedAmount $translatedUnit" : "", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: primaryGreen)),
                              ],
                            ),
                          );
                        },
                      ),

                    const Divider(height: 48, color: Colors.black12),

                    Text("Procedimento", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),
                    
                    if (isTranslating)
                      const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: primaryGreen)))
                    else if (isEditing)
                      TextField(
                        controller: _instructionsController,
                        maxLines: null, 
                        style: GoogleFonts.montserrat(fontSize: 15, height: 1.5),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGreen, width: 2)),
                        ),
                      )
                    else
                      Text(
                        _instructionsController.text,
                        style: GoogleFonts.montserrat(fontSize: 15, height: 1.6, color: Colors.black87),
                      ),

                    if (isUserLogged && isDownloaded) ...[
                      const Divider(height: 48, color: Colors.black12),
                      Text("Le tue Note", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        enabled: isEditing, 
                        style: GoogleFonts.montserrat(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Clicca su 'Modifica' in alto per sbloccare e inserire le tue annotazioni...",
                          hintStyle: GoogleFonts.montserrat(color: unselectedIconColor, fontSize: 14),
                          filled: true,
                          fillColor: isEditing ? Colors.grey[50] : Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}