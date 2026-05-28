import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================================
// ⚙️ STILE UFFICIALE EREDITATO DAL MAIN
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
  // STATO LOGIN
  bool isUserLogged = true; 

  late bool isDownloaded;
  late bool isFavorite;
  late int servings;
  late int originalServings;
  
  bool isLocalLoading = false; 
  final TextEditingController _notesController = TextEditingController();
  List<dynamic> ingredients = [];

  @override
  void initState() {
    super.initState();
    isDownloaded = !widget.isFromApi; 
    isFavorite = widget.recipeData['isFavorite'] ?? false;
    
    servings = widget.recipeData['servings'] ?? 2;
    originalServings = servings > 0 ? servings : 2;

    ingredients = widget.recipeData['extendedIngredients'] ?? widget.recipeData['ingredients'] ?? [];
    _notesController.text = widget.recipeData['personalNotes'] ?? "";
  }

  double _getScaledAmount(double? originalAmount) {
    if (originalAmount == null) return 0.0;
    return (originalAmount / originalServings) * servings;
  }

  void _downloadRecipe() {
    setState(() {
      isLocalLoading = true; 
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          isLocalLoading = false;
          isDownloaded = true; 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ricetta salvata nella tua dispensa!", style: GoogleFonts.montserrat()),
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
          // ==========================================================
          // IMMAGINE DI COPERTINA (PULITA)
          // ==========================================================
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

          // ==========================================================
          // CORPO DELLA RICETTA
          // ==========================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipeData['title'] ?? 'Ricetta Senza Titolo',
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
                        isDownloaded ? "Offline" : "Solo Online",
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================================
                  // 🎛️ ZONA PULSANTI DI AZIONE UNIFICATI
                  // ==========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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

                      Row(
                        children: [
                          if (isUserLogged)
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
                                onPressed: () => setState(() => isFavorite = !isFavorite),
                              ),
                            ),

                          if (!isUserLogged)
                            Text(
                              "Accedi per salvare", 
                              style: GoogleFonts.montserrat(color: unselectedIconColor, fontSize: 12, fontWeight: FontWeight.w600)
                            )
                          else if (isLocalLoading)
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
                              label: Text("Scaricamento...", style: GoogleFonts.montserrat(color: Colors.grey)),
                            )
                          else if (!isDownloaded)
                            ElevatedButton.icon(
                              onPressed: _downloadRecipe,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen, 
                                foregroundColor: backgroundColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              icon: const Icon(Icons.download, size: 18),
                              label: Text("Scarica", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () {},
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
                  // LISTA INGREDIENTI CON CONVERSIONE IN SISTEMA METRICO EUROPEO
                  // ==========================================================
                  Text(
                    "Ingredienti",
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  
                  if (ingredients.isEmpty)
                    Text("Nessun ingrediente trovato.", style: GoogleFonts.montserrat(color: unselectedIconColor))
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ingredients.length,
                      itemBuilder: (context, index) {
                        final ing = ingredients[index];
                        
                        // 🌍 LOGICA PER MISURAZIONI EUROPEE
                        double originalAmount = 0.0;
                        String unit = "";

                        // Se l'API ci fornisce i dati metrici (Grammi, ml, cucchiai standard europei) li usiamo
                        if (ing['measures'] != null && ing['measures']['metric'] != null) {
                          originalAmount = ing['measures']['metric']['amount']?.toDouble() ?? 0.0;
                          unit = ing['measures']['metric']['unitShort'] ?? "";
                        } else {
                          // Se la ricetta è locale o non ha dati metrici, usiamo quelli di base
                          originalAmount = ing['amount']?.toDouble() ?? 0.0;
                          unit = ing['unit'] ?? "";
                        }

                        // Applichiamo il ricalcolo per il numero di persone
                        double currentAmount = _getScaledAmount(originalAmount);
                        String name = ing['name'] ?? ing['originalName'] ?? "Ingrediente";

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
                                currentAmount > 0 ? "${currentAmount.toStringAsFixed(1)} $unit" : "",
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