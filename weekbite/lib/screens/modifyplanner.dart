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

class EditMealPlanScreen extends StatefulWidget {
  final int plannerId; 
  final String initialPlannerName;
  final Map<String, List<String>> initialDayMealTypes;
  final Map<String, Map<String, List<RecipeModel>>> initialAssociatedRecipes;

  const EditMealPlanScreen({
    super.key,
    required this.plannerId,
    required this.initialPlannerName,
    required this.initialDayMealTypes,
    required this.initialAssociatedRecipes,
  });

  @override
  State<EditMealPlanScreen> createState() => _EditMealPlanScreenState();
}

class _EditMealPlanScreenState extends State<EditMealPlanScreen> {
  late TextEditingController _plannerNameController;
  final List<String> _days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"];
  String _selectedDay = "Lunedì";

  late Map<String, List<String>> _dayMealTypes;
  late Map<String, Map<String, List<RecipeModel>>> _associatedRecipes;

  final Map<String, String> _mealEmojis = {
    "COLAZIONE": "🥞", "PRANZO": "🍝", "SPUNTINO": "🍏", "MERENDA": "🧃", "CENA": "🥩", "ALTRO": "🍲"
  };

  @override
  void initState() {
    super.initState();
    _plannerNameController = TextEditingController(text: widget.initialPlannerName);
    _dayMealTypes = Map.from(widget.initialDayMealTypes.map((k, v) => MapEntry(k, List<String>.from(v))));
    _associatedRecipes = widget.initialAssociatedRecipes.map((g, mP) => MapEntry(g, mP.map((p, lR) => MapEntry(p, List<RecipeModel>.from(lR)))));
  }

  @override
  void dispose() {
    _plannerNameController.dispose();
    super.dispose();
  }

  void _showEditPiattoDialog(String mealType, RecipeModel oldRecipe) {
    final TextEditingController editPiattoController = TextEditingController(text: oldRecipe.title);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Modifica piatto", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(controller: editPiattoController, autofocus: true),
        actions: [
          TextButton(
            onPressed: () {
              editPiattoController.dispose();
              Navigator.pop(dialogContext);
            }, 
            child: const Text("Annulla")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () {
              if (editPiattoController.text.trim().isEmpty) return;
              int idx = _associatedRecipes[_selectedDay]![mealType]!.indexOf(oldRecipe);
              if (idx != -1) {
                setState(() {
                  _associatedRecipes[_selectedDay]![mealType]![idx] = RecipeModel(
                    id: oldRecipe.id < 0 ? -DateTime.now().millisecondsSinceEpoch : oldRecipe.id,
                    title: editPiattoController.text.trim(),
                    image: oldRecipe.image,
                  );
                });
              }
              editPiattoController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text("Aggiorna", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showAddPiattoDialog(String mealType) async {
    List<Map<String, dynamic>> savedRecipesDB = [];
    try { savedRecipesDB = await DatabaseHelper.instance.getAllFavorites(); } catch (_) {}

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
            TextField(controller: piattoController, decoration: const InputDecoration(hintText: "Nome piatto personalizzato...")),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: () {
                if (piattoController.text.trim().isEmpty) return;
                setState(() {
                  _associatedRecipes[_selectedDay]![mealType]!.add(RecipeModel(id: -DateTime.now().millisecondsSinceEpoch, title: piattoController.text.trim(), image: ""));
                });
                piattoController.dispose();
                Navigator.pop(bottomSheetContext);
              },
              child: const Text("Aggiungi a mano libera", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: savedRecipesDB.length,
                itemBuilder: (context, idx) {
                  final rec = savedRecipesDB[idx];
                  return ListTile(
                    title: Text(rec['title'] ?? ''),
                    onTap: () {
                      setState(() {
                        _associatedRecipes[_selectedDay]![mealType]!.add(RecipeModel(id: rec['id'], title: rec['title'], image: rec['image'] ?? ""));
                      });
                      piattoController.dispose();
                      Navigator.pop(bottomSheetContext);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _updatePlannerInDatabase() async {
    String name = _plannerNameController.text.trim();
    if (name.isEmpty) return;

    try {
      await DatabaseHelper.instance.updatePlanner(widget.plannerId, name, _associatedRecipes);
      if (!mounted) return;
      Navigator.pop(context, true); 
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pastiDelGiorno = _dayMealTypes[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundClear,
      appBar: AppBar(
        title: Text("Modifica Meal Planner", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 20), onPressed: () => Navigator.pop(context, false)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: TextField(controller: _plannerNameController, style: GoogleFonts.montserrat(fontSize: 16, color: kTextDark, fontWeight: FontWeight.w600), decoration: const InputDecoration(border: InputBorder.none, isDense: true)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, itemCount: _days.length,
                  itemBuilder: (context, idx) {
                    final day = _days[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDay = day),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: day == _selectedDay ? primaryGreen : Colors.white, borderRadius: BorderRadius.circular(25)),
                          child: Center(child: Text(day, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: day == _selectedDay ? Colors.white : kTextDark))),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Column(
                children: pastiDelGiorno.map((mealType) {
                  final listRecipes = _associatedRecipes[_selectedDay]![mealType] ?? [];
                  final baseType = mealType.split(' ')[0];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 18.0),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: kBorderColor)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Text(_mealEmojis[baseType] ?? "🍲", style: const TextStyle(fontSize: 22)),
                          title: Flexible(child: Text(mealType, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark), overflow: TextOverflow.ellipsis)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (listRecipes.isNotEmpty) ...[
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: listRecipes.map((recipe) {
                                    return InkWell(
                                      onTap: () => _showEditPiattoDialog(mealType, recipe),
                                      child: Container(
                                        padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(child: Text(recipe.title, style: GoogleFonts.montserrat(fontSize: 13, color: kTextDark), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 8),
                                            GestureDetector(onTap: () => setState(() => _associatedRecipes[_selectedDay]![mealType]!.remove(recipe)), child: const Icon(Icons.close, size: 14))
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              InkWell(
                                onTap: () => _showAddPiattoDialog(mealType),
                                child: Container(
                                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12)),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add, color: primaryGreen, size: 16), Text(" Aggiungi piatto...", style: GoogleFonts.montserrat(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.bold))]),
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
                child: ElevatedButton(onPressed: _updatePlannerInDatabase, style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))), child: Text("Conferma modifiche", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
              )
            ],
          ),
        ),
      ),
    );
  }
}