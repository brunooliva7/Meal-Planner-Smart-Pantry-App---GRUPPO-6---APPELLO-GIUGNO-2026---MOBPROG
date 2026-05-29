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
    "colazione": ["Pancakes allo sciroppo", "Porridge d'avena", "Yogurt greco con muesli", "Toast con avocado"],
    "pranzo": ["Pasta aglio, olio", "Risotto ai funghi", "Gnocchi al pomodoro", "Insalata di quinoa"],
    "cena": ["Petto di pollo", "Filetto di orata", "Frittata al forno", "Vellutata di zucca"],
    "snack": ["Frutta fresca", "Barretta proteica", "Manciata di noci", "Gallette di riso"]
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text(message, style: GoogleFonts.montserrat()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)))
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
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(dialogContext);
              }, 
              child: Text("Annulla", style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.w600))
            ),
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

                if (mounted) {
                  setState(() {
                    _dayMealTypes[_selectedDay]!.add(finalMealName);
                    _associatedRecipes[_selectedDay]![finalMealName] = [];
                  });
                }
                FocusScope.of(context).unfocus();
                Navigator.pop(dialogContext);
              },
              child: Text("Aggiungi", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    ).then((_) => customNameController.dispose()); // Chiude in modo sicuro dopo la fine del ciclo del dialogo
  }

  void _removeMealSlot(String mealType) {
    setState(() {
      _dayMealTypes[_selectedDay]!.remove(mealType);
      _associatedRecipes[_selectedDay]!.remove(mealType);
    });
  }

  void _showAddPiatoDialog(String mealType) async {
    List<Map<String, dynamic>> savedRecipesDB = [];
    try {
      savedRecipesDB = await DatabaseHelper.instance.getAllFavorites(); 
    } catch (_) {}

    if (!mounted) return;
    final TextEditingController piattoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.75, 
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text("Aggiungi a $mealType", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 20),
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
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16)),
                  onPressed: () {
                    String t = piattoController.text.trim();
                    if (t.isEmpty) return;
                    
                    if (mounted) {
                      setState(() {
                        _associatedRecipes[_selectedDay]![mealType]!.add(
                          RecipeModel(id: -DateTime.now().millisecondsSinceEpoch, title: t, image: "")
                        );
                      });
                    }
                    FocusScope.of(context).unfocus(); // Rimuove la tastiera
                    Navigator.pop(bottomSheetContext); 
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text("Scegli dalle tue Ricette...", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: kTextMuted)),
            const SizedBox(height: 12),
            Expanded(
              child: savedRecipesDB.isEmpty
                ? Center(child: Text("Nessuna ricetta salvata localmente.", style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 13)))
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
                          title: Text(recipe['title'] ?? 'Senza Titolo', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold, color: kTextDark)),
                          trailing: const Icon(Icons.add_circle, color: primaryGreen),
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _associatedRecipes[_selectedDay]![mealType]!.add(
                                  RecipeModel(id: recipe['id'], title: recipe['title'], image: recipe['image'] ?? "")
                                );
                              });
                            }
                            FocusScope.of(context).unfocus();
                            Navigator.pop(bottomSheetContext);
                          },
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    ).then((_) => piattoController.dispose()); // Il dispose avviene in modo protetto solo alla fine di tutta l'animazione
  }

  void _suggestRecipeFromApi(String mealType) {
    String baseType = mealType.split(' ')[0].toLowerCase();
    String poolKey = (baseType == "colazione" || baseType == "pranzo" || baseType == "cena") ? baseType : "snack";
    List<String> opzioni = _suggestionsPool[poolKey]!;
    String piattoScelto = opzioni[Random().nextInt(opzioni.length)];

    setState(() {
      _associatedRecipes[_selectedDay]![mealType]!.add(RecipeModel(id: -DateTime.now().microsecondsSinceEpoch, title: piattoScelto, image: ""));
    });
  }

  Future<void> _savePlannerToDatabase() async {
    String name = _plannerNameController.text.trim();
    if (name.isEmpty) {
      _showErrorDialog("Attenzione", "Devi inserire un nome per il tuo piano alimentare!");
      return;
    }

    try {
      List<String> existingNames = await DatabaseHelper.instance.getAllPlannerNames();
      if (existingNames.any((n) => n.toLowerCase() == name.toLowerCase())) {
        _showErrorDialog("Nome Duplicato", "Esiste già un planner chiamato '$name'.");
        return;
      }

      await DatabaseHelper.instance.saveFullPlanner(name, _dayMealTypes, _associatedRecipes);

      if (!mounted) return;
      Navigator.pop(context, true); 
    } catch (e) {
      _showErrorDialog("Errore", "Impossibile salvare il planner: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pastiDelGiorno = _dayMealTypes[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundClear,
      appBar: AppBar(
        title: Text("Nuovo Meal Planner", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NOME DEL PIANO ALIMENTARE *", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _plannerNameController,
                      style: GoogleFonts.montserrat(fontSize: 16, color: kTextDark, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: isSelected ? primaryGreen : Colors.white, borderRadius: BorderRadius.circular(25)),
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
                  Text("MENU DI ${_selectedDay.toUpperCase()}", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: primaryGreen)),
                  TextButton.icon(
                    onPressed: _addNewMealSlot,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: primaryGreen, size: 16),
                    label: Text("Pasto", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Column(
                children: pastiDelGiorno.map((mealType) {
                  final listRecipes = _associatedRecipes[_selectedDay]![mealType] ?? [];
                  final baseType = mealType.split(' ')[0];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: kBorderColor)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Text(_mealEmojis[baseType] ?? "🍲", style: const TextStyle(fontSize: 22)),
                          title: Text(mealType, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 20), onPressed: () => _suggestRecipeFromApi(mealType)),
                              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => _removeMealSlot(mealType)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (listRecipes.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: listRecipes.map((recipe) {
                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Bloccato l'overflow orizzontale su smartphone stretti
                                          Flexible(child: Text(recipe.title, style: GoogleFonts.montserrat(fontSize: 12, color: kTextDark), overflow: TextOverflow.ellipsis)),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () => setState(() => _associatedRecipes[_selectedDay]![mealType]!.remove(recipe)),
                                            child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                          )
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              InkWell(
                                onTap: () => _showAddPiatoDialog(mealType),
                                child: Container(
                                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12)),
                                  child: Center(child: Text("+ Aggiungi piatto", style: GoogleFonts.montserrat(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.bold))),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _savePlannerToDatabase,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
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