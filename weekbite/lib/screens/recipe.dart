import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:translator/translator.dart'; // 🌍 Il pacchetto di traduzione

// ==========================================================
// ⚙️ STILE UFFICIALE
// ==========================================================
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
  // 🧪 LOGIN DI TEST (Metti false per provare gli avvisi)
  bool isUserLogged = false; 

  late bool isDownloaded;
  late bool isFavorite;
  late int servings;
  late int originalServings;
  
  bool isLocalLoading = false; 
  final TextEditingController _notesController = TextEditingController();
  List<dynamic> ingredients = [];

  // Variabili per la traduzione
  bool isTranslating = false;
  String translatedTitle = "";

  @override
  void initState() {
    super.initState();
    isDownloaded = !widget.isFromApi; 
    isFavorite = widget.recipeData['isFavorite'] ?? false;
    
    servings = widget.recipeData['servings'] ?? 2;
    originalServings = servings > 0 ? servings : 2;

    ingredients = widget.recipeData['extendedIngredients'] ?? widget.recipeData['ingredients'] ?? [];
    _notesController.text = widget.recipeData['personalNotes'] ?? "";
    
    translatedTitle = widget.recipeData['title'] ?? 'Senza Titolo';

    // Se la ricetta viene da internet, avviamo la traduzione automatica!
    if (widget.isFromApi) {
      _translateContent();
    } else {
      // Se è locale, diamo per scontato che sia già in italiano
      for (var ing in ingredients) {
        ing['translatedName'] = ing['name'] ?? ing['originalName'];
      }
    }
  }

  // ==========================================================
  // 🌍 TRADUTTORE LIVE (Titolo e Ingredienti)
  // ==========================================================
  Future<void> _translateContent() async {
    setState(() => isTranslating = true);
    final translator = GoogleTranslator();

    try {
      // 1. Traduce il titolo
      var tTitle = await translator.translate(widget.recipeData['title'] ?? '', from: 'en', to: 'it');
      translatedTitle = tTitle.text;

      // 2. Traduce ogni singolo ingrediente
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
      print("Errore di traduzione: $e");
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

  // ==========================================================
  // 📏 TRADUTTORE UNITA' DI MISURA
  // ==========================================================
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
    if (u == 'can' || u == 'cans') return 'lattine';
    if (u == 'servings' || u == 'serving') return 'porzioni';
    return unit; 
  }

  void _showLoginWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white),
            const SizedBox(width: 10),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _downloadRecipe() {
    setState(() => isLocalLoading = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          isLocalLoading = false;
          isDownloaded = true; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ricetta salvata in locale!", style: GoogleFonts.montserrat()),
            backgroundColor: primaryGreen,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, 
      body: CustomScrollView(
        slivers: [
          // IMMAGINE DI COPERTINA
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
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: unselectedIconColor)),
                ),
              ),
            ),
          ),

          // CORPO DELLA RICETTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITOLO (Con animazione di caricamento traduzione)
                  if (isTranslating)
                    Row(
                      children: [
                        const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2)),
                        const SizedBox(width: 12),
                        Text("Traduzione in corso...", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    )
                  else
                    Text(
                      translatedTitle,
                      style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                  
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.access_time, color: primaryGreen, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.recipeData['readyInMinutes'] ?? 30} min",
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 24),
                      Icon(
                        isDownloaded ? Icons.cloud_done : Icons.cloud_download_outlined,
                        color: isDownloaded ? primaryGreen : unselectedIconColor,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDownloaded ? "Salvato Locale" : "Solo Online",
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================================
                  // 🎛️ ZONA PULSANTI DI AZIONE - (Layout Semplificato per evitare Overflow)
                  // ==========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // SELETTORE PERSONE
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: primaryGreen, size: 20),
                              onPressed: servings > 1 ? () => setState(() => servings--) : null,
                            ),
                            Text(
                              "$servings persone",
                              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: primaryGreen, size: 20),
                              onPressed: () => setState(() => servings++),
                            ),
                          ],
                        ),
                      ),
                      
                      // AZIONI: CUORE + SALVA (Testo accorciato per entrare in una sola riga)
                      Row(
                        children: [
                          // TASTO PREFERITI
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? primaryGreen : unselectedIconColor,
                                size: 22,
                              ),
                              onPressed: () {
                                if (!isUserLogged) {
                                  _showLoginWarning();
                                } else {
                                  setState(() => isFavorite = !isFavorite);
                                }
                              },
                            ),
                          ),

                          // TASTO SALVA / MODIFICA
                          if (isLocalLoading)
                            ElevatedButton.icon(
                              onPressed: null, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2),
                              ),
                              label: Text("Salvataggio...", style: GoogleFonts.montserrat(color: Colors.grey)),
                            )
                          else if (!isDownloaded)
                            ElevatedButton.icon(
                              onPressed: () {
                                if (!isUserLogged) {
                                  _showLoginWarning();
                                } else {
                                  _downloadRecipe();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen, 
                                foregroundColor: backgroundColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.save_alt, size: 18),
                              label: Text("Salva", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)), // <-- TESTO ACCORCIATO!
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () {
                                if (!isUserLogged) {
                                  _showLoginWarning();
                                } else {
                                  // Azione di modifica
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: primaryGreen, width: 2),
                                foregroundColor: primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text("Modifica", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 48, color: Colors.black12),

                  // ==========================================================
                  // LISTA INGREDIENTI
                  // ==========================================================
                  Text(
                    "Ingredienti",
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  if (isTranslating)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: primaryGreen),
                      ),
                    )
                  else if (ingredients.isEmpty)
                    Text("Nessun ingrediente trovato.", style: GoogleFonts.montserrat(color: unselectedIconColor))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ing = ingredients[index];
                        
                        double originalAmount = 0.0;
                        String originalUnit = "";

                        // Sistema Metrico Europeo
                        if (ing['measures'] != null && ing['measures']['metric'] != null) {
                          originalAmount = ing['measures']['metric']['amount']?.toDouble() ?? 0.0;
                          originalUnit = ing['measures']['metric']['unitShort'] ?? "";
                        } else {
                          originalAmount = ing['amount']?.toDouble() ?? 0.0;
                          originalUnit = ing['unit'] ?? "";
                        }

                        String translatedUnit = _translateUnit(originalUnit);
                        double currentAmount = _getScaledAmount(originalAmount);
                        
                        // Prendiamo il nome tradotto da Google!
                        String name = ing['translatedName'] ?? "Ingrediente";

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6.0),
                                child: Icon(Icons.circle, size: 8, color: primaryGreen),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  name[0].toUpperCase() + name.substring(1),
                                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                currentAmount > 0 ? "${currentAmount.toStringAsFixed(1)} $translatedUnit" : "",
                                style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: primaryGreen),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // ==========================================================
                  // NOTE PERSONALI
                  // ==========================================================
                  if (isUserLogged && isDownloaded) ...[
                    const Divider(height: 48, color: Colors.black12),
                    Text(
                      "Le tue Note",
                      style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: GoogleFonts.montserrat(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Aggiungi varianti o annotazioni personali...",
                        hintStyle: GoogleFonts.montserrat(color: unselectedIconColor, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Note aggiornate!", style: GoogleFonts.montserrat()),
                              backgroundColor: primaryGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: backgroundColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text("Salva Note", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
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