import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart'; 
import '../database/database_helper.dart'; // 📂 Connessione al Database SQLite del gruppo

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
  // 🧪 IMPOSTATO A FALSE PER IL TUO TEST: l'app bloccherà le azioni mostrando l'avviso.
  bool isUserLogged = false; 

  bool isDownloaded = false;
  bool isFavorite = false;
  bool isEditing = false; // Gestisce l'abilitazione dei campi di testo inline
  
  late int servings;
  late int originalServings;
  bool isLocalLoading = false; 
  bool isTranslating = false;

  // Controller per la modifica in tempo reale dei testi
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<dynamic> ingredients = [];

  @override
  void initState() {
    super.initState();
    _initRecipeState();
  }

  // Inizializzazione controllando i dati persistenti dentro SQLite
  Future<void> _initRecipeState() async {
    int recipeId = widget.recipeData['id'] ?? 0;
    
    bool favStatus = await DatabaseHelper.instance.isFavorite(recipeId);
    bool downloadStatus = await DatabaseHelper.instance.isRecipeDownloaded(recipeId);
    
    Map<String, dynamic>? localData;
    if (downloadStatus) {
      localData = await DatabaseHelper.instance.getSavedRecipeWithNotes(recipeId);
    }

    setState(() {
      isFavorite = favStatus;
      isDownloaded = downloadStatus;
      
      servings = localData?['servings'] ?? widget.recipeData['servings'] ?? 2;
      originalServings = widget.recipeData['servings'] ?? servings;
      if (originalServings <= 0) originalServings = 2;

      ingredients = localData?['extendedIngredients'] ?? widget.recipeData['extendedIngredients'] ?? widget.recipeData['ingredients'] ?? [];
      
      _titleController.text = localData?['title'] ?? widget.recipeData['title'] ?? 'Senza Titolo';
      _notesController.text = localData?['personalNotes'] ?? widget.recipeData['personalNotes'] ?? "";
      
      // Estraiamo e puliamo il procedimento dai tag HTML di Spoonacular
      String rawInstructions = localData?['instructions'] ?? widget.recipeData['instructions'] ?? "Nessuna istruzione fornita per questa ricetta.";
      _instructionsController.text = _cleanHtml(rawInstructions);
    });

    if (widget.isFromApi && !downloadStatus) {
      _translateContent();
    }
  }

  // Funzione di supporto per ripulire le stringhe sporche di tag HTML (<ol>, <li>, ecc)
  String _cleanHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  // Traduttore automatico simultaneo per ricette API inglesi
  Future<void> _translateContent() async {
    setState(() => isTranslating = true);
    final translator = GoogleTranslator();

    try {
      var tTitle = await translator.translate(_titleController.text, from: 'en', to: 'it');
      _titleController.text = tTitle.text;

      String rawInst = widget.recipeData['instructions'] ?? '';
      if (rawInst.isNotEmpty) {
        var tInst = await translator.translate(_cleanHtml(rawInst), from: 'en', to: 'it');
        _instructionsController.text = tInst.text;
      }

      for (var ing in ingredients) {
        String originalName = ing['name'] ?? ing['originalName'] ?? "";
        if (originalName.isNotEmpty) {
          var tIng = await translator.translate(originalName, from: 'en', to: 'it');
          ing['translatedName'] = tIng.text;
        } else {
          ing['translatedName'] = "Ingrediente";
        }
      }
    } catch (e) {
      print("Errore traduzione: $e");
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
    if (u == 'tbsp' || u == 'tablespoon' || u == 'tablespoons') return 'cucchiai';
    if (u == 'tsp' || u == 'teaspoon' || u == 'teaspoons') return 'cucchiaini';
    if (u == 'cup' || u == 'cups' || u == 'c') return 'tazze';
    if (u == 'oz' || u == 'ounce' || u == 'ounces') return 'once';
    if (u == 'lb' || u == 'lbs' || u == 'pound' || u == 'pounds') return 'libbre';
    if (u == 'clove' || u == 'cloves') return 'spicchi';
    if (u == 'pinch' || u == 'pinches') return 'pizzico';
    if (u == 'handful' || u == 'handfuls') return 'manciata';
    if (u == 'slice' || u == 'slices') return 'fette';
    return unit; 
  }

  // MOSTRA IL MESSAGGIO BLOCCO UTENTE SE NON LOGGATO 
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

  // PRIMO SALVATAGGIO (DOWNLOAD STRUTTURA API IN SQLITE)
  Future<void> _downloadRecipeAction() async {
    setState(() => isLocalLoading = true);
    
    Map<String, dynamic> currentData = Map<String, dynamic>.from(widget.recipeData);
    currentData['title'] = _titleController.text;
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

  // SALVATAGGIO COMPLESSIVO DELLE MODIFICHE EFFETTUATE NEI CAMPI DI TESTO
  Future<void> _saveModifications() async {
    int recipeId = widget.recipeData['id'] ?? 0;
    
    Map<String, dynamic> updatedData = Map<String, dynamic>.from(widget.recipeData);
    updatedData['title'] = _titleController.text;
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
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // COPERTINA RICETTA
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
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.recipeData['image'] ?? 'https://via.placeholder.com/400x300',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, size: 50, color: unselectedIconColor))),
              ),
            ),
          ),

          // INFORMAZIONI CORPO SCHERMATA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✏️ EDITING INLINE DEL TITOLO
                  if (isTranslating)
                    Text("Traduzione in corso...", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold))
                  else if (isEditing)
                    TextField(
                      controller: _titleController,
                      style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
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

                  // BARRA STRUMENTI INTERATTIVI
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
                      
                      Row(
                        children: [
                          // CUORE PREFERITI PROTETTO DA BLOCCO LOGIN 🔒
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle, border: Border.all(color: Colors.grey[300]!)),
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

                          // TASTI SALVA / MODIFICA PROTETTI DA BLOCCO LOGIN 🔒
                          if (isLocalLoading)
                            const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2))
                          else if (isEditing)
                            ElevatedButton.icon(
                              onPressed: _saveModifications,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              icon: const Icon(Icons.check, size: 18),
                              label: Text("Salva", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                            )
                          else if (!isDownloaded)
                            ElevatedButton.icon(
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
                          else
                            OutlinedButton.icon(
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
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 48, color: Colors.black12),

                  // ==========================================================
                  // SEZIONE INGREDIENTI (EDITABILI INLINE)
                  // ==========================================================
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

                        // MODALITÀ INLINE EDITING ATTIVA PER GLI INGREDIENTI
                        if (isEditing) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: TextFormField(
                                    initialValue: currentAmount.toStringAsFixed(1),
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen),
                                    decoration: InputDecoration(
                                      suffixText: translatedUnit,
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryGreen)),
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
                                    decoration: InputDecoration(
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

                        // MODALITÀ LETTURA STANDARD
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(padding: EdgeInsets.only(top: 6.0), child: Icon(Icons.circle, size: 8, color: primaryGreen)),
                              const SizedBox(width: 16),
                              Expanded(child: Text(name[0].toUpperCase() + name.substring(1), style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500))),
                              Text(currentAmount > 0 ? "${currentAmount.toStringAsFixed(1)} $translatedUnit" : "", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: primaryGreen)),
                            ],
                          ),
                        );
                      },
                    ),

                  const Divider(height: 48, color: Colors.black12),

                  // ==========================================================
                  // SEZIONE PROCEDIMENTO (EDITABILE INLINE + ROTELLINA TRADUZIONE)
                  // ==========================================================
                  Text("Procedimento", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 12),
                  
                  // Aggiunto il controllo: mostra la rotellina se sta ancora traducendo!
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

                  // ==========================================================
                  // SEZIONE LE TUE NOTE
                  // ==========================================================
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
    );
  }
}