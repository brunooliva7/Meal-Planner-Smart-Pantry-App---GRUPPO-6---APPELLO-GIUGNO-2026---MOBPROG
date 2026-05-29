import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recipe_model.dart'; 
import '../database/database_helper.dart'; 

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color kCardBackground = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kBorderColor = Color(0xFFF3F4F6); 
const Color kBackgroundClear = Color(0xFFF9F9FB); 

class CreateMealPlanScreen extends StatefulWidget {
  const CreateMealPlanScreen({super.key});
  @override
  State<CreateMealPlanScreen> createState() => _CreateMealPlanScreenState();
}

class _CreateMealPlanScreenState extends State<CreateMealPlanScreen> {
  final TextEditingController _plannerNameController = TextEditingController();
  final List<String> _days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"];
  String _selectedDay = "Lunedì";

  final Map<String, List<String>> _dayMealTypes = {};
  final Map<String, Map<String, List<RecipeModel>>> _associatedRecipes = {};

  final Map<String, String> _mealEmojis = {
    "COLAZIONE": "🥞", "PRANZO": "🍝", "SPUNTINO": "🍏", "MERENDA": "🧃", "CENA": "🥩", "ALTRO": "🍲"
  };

  final Map<String, List<String>> _suggestionsPool = {
    "colazione": ["Pancakes allo sciroppo", "Porridge d'avena", "Yogurt greco con muesli"],
    "pranzo": ["Pasta aglio, olio e peperoncino", "Risotto ai funghi", "Gnocchi al pomodoro"],
    "cena": ["Petto di pollo e verdure", "Filetto di orata al cartoccio", "Frittata al forno"],
    "snack": ["Frutta fresca", "Barretta proteica", "Manciata di noci"]
  };

  @override
  void initState() {
    super.initState();
    for (var day in _days) {
      _dayMealTypes[day] = ["COLAZIONE", "SPUNTINO", "PRANZO", "MERENDA", "CENA"];
      _associatedRecipes[day] = {};
      
      for (var meal in _dayMealTypes[day]!) {
        _associatedRecipes[day]![meal] = [];
      }
    }
  }

  @override
  void dispose() {
    _plannerNameController.dispose();
    super.dispose();
  }

  // Mostra popup di errore personalizzato
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Ho capito", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))
          )
        ],
      ),
    );
  }

  void _addNewMealSlot() {
    if (_dayMealTypes[_selectedDay]!.length >= 10) {
      _showErrorDialog("Limite raggiunto", "Non puoi aggiungere più di 10 pasti in un singolo giorno.");
      return;
    }

    String selectedType = "SPUNTINO";
    final TextEditingController customNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Aggiungi un nuovo pasto", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: kTextDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: GoogleFonts.montserrat(color: kTextDark, fontWeight: FontWeight.w600),
                    items: ["SPUNTINO", "MERENDA", "ALTRO"].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedType = val!),
                  ),
                ),
              ),
              if (selectedType == "ALTRO") ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
                  child: TextField(
                    controller: customNameController,
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(hintText: "Es: Snack Notturno", border: InputBorder.none),
                  ),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Annulla", style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.w600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                String finalMealName = "";
                if (selectedType == "ALTRO") {
                  String customText = customNameController.text.trim();
                  finalMealName = customText.isNotEmpty ? customText.toUpperCase() : "ALTRO PASTO";
                } else {
                  int count = _dayMealTypes[_selectedDay]!.where((m) => m.startsWith(selectedType)).length + 1;
                  finalMealName = "$selectedType $count";
                }

                setState(() {
                  _dayMealTypes[_selectedDay]!.add(finalMealName);
                  _associatedRecipes[_selectedDay]![finalMealName] = [];
                });
                customNameController.dispose();
                Navigator.pop(dialogContext);
              },
              child: Text("Aggiungi", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _removeMealSlot(String mealType) {
    setState(() {
      _dayMealTypes[_selectedDay]!.remove(mealType);
      _associatedRecipes[_selectedDay]!.remove(mealType);
    });
  }

  // ==========================================================
  // 🍽️ BOTTOM SHEET PER AGGIUNGERE RICETTE (MANUALI O SALVATE)
  // ==========================================================
  void _showAddPiatoDialog(String mealType) async {
    // 1. Recuperiamo prima le ricette salvate nel database
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> savedRecipesDB = await db.query('saved_recipes');

    if (!mounted) return;

    final TextEditingController piattoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.75, // Occupa il 75% dello schermo
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          top: 24, left: 24, right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24, // Gestisce l'altezza della tastiera
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text("Aggiungi a $mealType", style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 20),
            
            // OPZIONE 1: Inserimento Manuale
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorderColor)),
                    child: TextField(
                      controller: piattoController,
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(hintText: "Scrivi un piatto personalizzato...", contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: InputBorder.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    String t = piattoController.text.trim();
                    if (t.isEmpty) return;
                    Navigator.pop(bottomSheetContext); 
                    setState(() {
                      _associatedRecipes[_selectedDay]![mealType]!.add(
                        RecipeModel(id: DateTime.now().millisecondsSinceEpoch, title: t, image: "")
                      );
                    });
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            Text("Oppure scegli dalle tue Ricette Salvate:", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: kTextMuted)),
            const SizedBox(height: 12),

            // OPZIONE 2: Scelta dal Database SQLite
            Expanded(
              child: savedRecipesDB.isEmpty
                ? Center(
                    child: Text("Non hai ancora salvato nessuna ricetta.\nEsplora l'app per salvarne qualcuna!", textAlign: TextAlign.center, style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 14)),
                  )
                : ListView.builder(
                    itemCount: savedRecipesDB.length,
                    itemBuilder: (context, index) {
                      final recipe = savedRecipesDB[index];
                      return Card(
                        elevation: 0,
                        color: kBackgroundClear,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kBorderColor)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              recipe['image'] != null && recipe['image'].toString().isNotEmpty 
                                  ? recipe['image'] 
                                  : 'https://via.placeholder.com/150',
                              width: 50, height: 50, fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(recipe['title'] ?? 'Senza Titolo', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
                          trailing: const Icon(Icons.add_circle, color: primaryGreen),
                          onTap: () {
                            Navigator.pop(bottomSheetContext);
                            setState(() {
                              _associatedRecipes[_selectedDay]![mealType]!.add(
                                RecipeModel(
                                  id: recipe['id'], 
                                  title: recipe['title'], 
                                  image: recipe['image'] ?? ""
                                )
                              );
                            });
                          },
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _suggestRecipeFromApi(String mealType) {
    String baseType = mealType.split(' ')[0].toLowerCase();
    String poolKey = (baseType == "colazione" || baseType == "pranzo" || baseType == "cena") ? baseType : "snack";
    List<String> opzioni = _suggestionsPool[poolKey]!;
    String piattoScelto = opzioni[Random().nextInt(opzioni.length)];

    setState(() {
      _associatedRecipes[_selectedDay]![mealType]!.add(RecipeModel(id: DateTime.now().microsecondsSinceEpoch, title: piattoScelto, image: ""));
    });
  }

  // ==========================================================
  // 💾 SALVATAGGIO DEL PLANNER E VALIDAZIONI
  // ==========================================================
  Future<void> _savePlannerToDatabase() async {
    String name = _plannerNameController.text.trim();
    
    // 1. Controllo validità: Nome inserito?
    if (name.isEmpty) {
      _showErrorDialog("Attenzione", "Devi inserire un nome per il tuo piano alimentare! (es. Dieta Estiva)");
      return;
    }

    // 2. Controllo univocità: Esiste già nel database?
    List<String> existingNames = await DatabaseHelper.instance.getAllPlannerNames();
    bool isDuplicate = existingNames.any((n) => n.toLowerCase() == name.toLowerCase());
    
    if (isDuplicate) {
      _showErrorDialog("Nome Duplicato", "Esiste già un planner chiamato '$name'. Scegli un nome diverso per evitare sovrascritture accidentali.");
      return;
    }

    // 3. Esecuzione salvataggio
    try {
      await DatabaseHelper.instance.saveFullPlanner(name, _dayMealTypes, _associatedRecipes);

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: primaryGreen),
              const SizedBox(width: 8),
              Text("Salvato!", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Il planner '$name' è stato registrato con successo nel Database locale.", style: GoogleFonts.montserrat()),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: () {
                Navigator.pop(dialogContext); // Chiudi il popup
                Navigator.pop(context); // Torna alla schermata precedente (es. la lista dei planner)
              },
              child: const Text("Ottimo", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog("Errore di Salvataggio", "Si è verificato un problema nel salvare il planner: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastiDelGiorno = _dayMealTypes[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundClear,
      appBar: AppBar(
        title: Text("Nuovo Meal Planner", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: kTextDark)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NOME DEL PIANO ALIMENTARE *", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _plannerNameController,
                      style: GoogleFonts.montserrat(fontSize: 16, color: kTextDark, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(hintText: "Es: Dieta Definizione Estate 🏋️", hintStyle: GoogleFonts.montserrat(color: kTextMuted, fontSize: 14), border: InputBorder.none, isDense: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = day == _selectedDay;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDay = day),
                        borderRadius: BorderRadius.circular(25),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryGreen : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: isSelected ? Colors.transparent : kBorderColor),
                            boxShadow: isSelected ? [BoxShadow(color: primaryGreen.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))] : [],
                          ),
                          child: Center(child: Text(day, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : kTextDark))),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("MENU DI ${_selectedDay.toUpperCase()} (${pastiDelGiorno.length}/10)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: primaryGreen, letterSpacing: 1.1)),
                  TextButton.icon(
                    onPressed: _addNewMealSlot,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: primaryGreen, size: 18),
                    label: Text("Aggiungi Pasto", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey<String>(_selectedDay),
                  children: pastiDelGiorno.map((mealType) {
                    final listRecipes = _associatedRecipes[_selectedDay]![mealType] ?? [];
                    final baseType = mealType.split(' ')[0];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: kBorderColor, width: 1)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                              child: Row(
                                children: [
                                  Text(_mealEmojis[baseType] ?? "🍲", style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Text(mealType, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark)),
                                  const Spacer(),
                                  IconButton(icon: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 20), onPressed: () => _suggestRecipeFromApi(mealType)),
                                  IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => _removeMealSlot(mealType)),
                                ],
                              ),
                            ),
                            const Divider(color: kBorderColor, height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (listRecipes.isNotEmpty) ...[
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: listRecipes.map((recipe) {
                                        return Container(
                                          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                                          decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryGreen.withOpacity(0.2))),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(recipe.title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => setState(() => _associatedRecipes[_selectedDay]![mealType]!.remove(recipe)),
                                                child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 12, color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  InkWell(
                                    onTap: () => _showAddPiatoDialog(mealType),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1.5)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_rounded, color: primaryGreen, size: 18),
                                          const SizedBox(width: 6),
                                          Text("Aggiungi piatto...", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))]),
                child: ElevatedButton(
                  onPressed: _savePlannerToDatabase,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: Text("Salva planner", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}