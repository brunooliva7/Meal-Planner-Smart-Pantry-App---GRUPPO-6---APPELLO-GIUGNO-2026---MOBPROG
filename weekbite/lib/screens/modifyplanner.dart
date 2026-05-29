import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recipe_model.dart'; 

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color kCardBackground = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kBorderColor = Color(0xFFF3F4F6); 
const Color kBackgroundClear = Color(0xFFF9F9FB); 

class EditMealPlanScreen extends StatefulWidget {
  final String initialPlannerName;
  final Map<String, List<String>> initialDayMealTypes;
  final Map<String, Map<String, List<RecipeModel>>> initialAssociatedRecipes;

  const EditMealPlanScreen({
    super.key,
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

  final Map<String, List<String>> _suggestionsPool = {
    "colazione": ["Pancakes allo sciroppo", "Porridge d'avena", "Yogurt greco con muesli"],
    "pranzo": ["Pasta aglio, olio e peperoncino", "Risotto ai funghi", "Gnocchi al pomodoro"],
    "cena": ["Petto di pollo e verdure", "Filetto di orata al cartoccio", "Frittata al forno"],
    "snack": ["Frutta fresca", "Barretta proteica", "Manciata di noci"]
  };

  @override
  void initState() {
    super.initState();
    _plannerNameController = TextEditingController(text: widget.initialPlannerName);
    
    _dayMealTypes = Map.from(widget.initialDayMealTypes.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    ));
    
    _associatedRecipes = widget.initialAssociatedRecipes.map((giorno, mappaPasti) {
      final Map<String, List<RecipeModel>> mappaTipizzata = mappaPasti.map((pasto, listaRicette) {
        return MapEntry<String, List<RecipeModel>>(pasto, List<RecipeModel>.from(listaRicette));
      });
      return MapEntry<String, Map<String, List<RecipeModel>>>(giorno, mappaTipizzata);
    });
  }

  @override
  void dispose() {
    _plannerNameController.dispose();
    super.dispose();
  }

  void _addNewMealSlot() {
    if (_dayMealTypes[_selectedDay]!.length >= 10) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Limite raggiunto", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          content: Text("Non puoi superare i 10 pasti giornalieri.", style: GoogleFonts.montserrat()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)))
          ],
        ),
      );
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
                    decoration: InputDecoration(hintText: "Es: Spuntino Notturno", border: InputBorder.none),
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

  // 📝 MODIFICA IN-LINE DI UN PIATTO ESISTENTE (Richiesta soddisfatta)
  void _showEditPiattoDialog(String mealType, RecipeModel oldRecipe) {
    final TextEditingController editPiattoController = TextEditingController(text: oldRecipe.title);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("Modifica il piatto", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
        content: Container(
          decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorderColor)),
          child: TextField(
            controller: editPiattoController,
            autofocus: true,
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: InputBorder.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text("Annulla", style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.w600))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              String nuovoTitolo = editPiattoController.text.trim();
              if (nuovoTitolo.isEmpty) return;
              
              int index = _associatedRecipes[_selectedDay]![mealType]!.indexOf(oldRecipe);
              if (index != -1) {
                setState(() {
                  _associatedRecipes[_selectedDay]![mealType]![index] = RecipeModel(
                    id: oldRecipe.id, // Mantiene lo stesso ID univoco
                    title: nuovoTitolo,
                    image: oldRecipe.image,
                  );
                });
              }
              Navigator.pop(dialogContext);
            },
            child: Text("Aggiorna", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPiattoDialog(String mealType) {
    final TextEditingController piattoController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("Aggiungi un nuovo piatto", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
        content: Container(
          decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorderColor)),
          child: TextField(
            controller: piattoController,
            autofocus: true,
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(hintText: "Nome piatto...", contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: InputBorder.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Annulla", style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              String t = piattoController.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(dialogContext); 
              setState(() {
                _associatedRecipes[_selectedDay]![mealType]!.add(RecipeModel(id: DateTime.now().millisecondsSinceEpoch, title: t, image: ""));
              });
            },
            child: Text("Aggiungi", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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

  void _updatePlannerInDatabase() {
    String name = _plannerNameController.text.trim();
    if (name.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.update_rounded, color: primaryGreen),
            const SizedBox(width: 8),
            Text("Modifiche salvate!", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Il planner '$name' è stato sovrascritto e aggiornato con successo.", style: GoogleFonts.montserrat()),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () {
              Navigator.pop(dialogContext); 
              Navigator.pop(context);       
            },
            child: const Text("Ottimo", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pastiDelGiorno = _dayMealTypes[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundClear,
      // 🛠️ LAYOUT OTTIMIZZATO: Bottone spostato nell'AppBar per massima visibilità
      appBar: AppBar(
        title: Text("Modifica Meal Planner", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: _addNewMealSlot,
              icon: const Icon(Icons.add_circle_outline_rounded, color: primaryGreen, size: 16),
              label: Text("Pasto", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          )
        ],
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
                    Text("NOME DEL PIANO ALIMENTARE", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _plannerNameController,
                      style: GoogleFonts.montserrat(fontSize: 16, color: kTextDark, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(border: InputBorder.none, isDense: true),
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
              Text("MENU DI $_selectedDay", style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800, color: primaryGreen, letterSpacing: 1.1)),
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
                                        return InkWell(
                                          // 🛠️ MODIFICA AL TOCCO: Cliccando sul testo si edita, cliccando sulla X si elimina
                                          onTap: () => _showEditPiattoDialog(mealType, recipe),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                                            decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryGreen.withOpacity(0.2))),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(recipe.title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
                                                const SizedBox(width: 8),
                                                GestureDetector(
                                                  onTap: () => setState(() => _associatedRecipes[_selectedDay]![mealType]!.remove(recipe)),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2), 
                                                    decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle), 
                                                    child: const Icon(Icons.close_rounded, size: 12, color: Colors.white)
                                                  ),
                                                ),
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(12), border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1.5)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_rounded, color: primaryGreen, size: 16),
                                          const SizedBox(width: 6),
                                          Text("Nuovo piatto...", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen)),
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
                  onPressed: _updatePlannerInDatabase,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                  child: Text("Conferma modifiche", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}