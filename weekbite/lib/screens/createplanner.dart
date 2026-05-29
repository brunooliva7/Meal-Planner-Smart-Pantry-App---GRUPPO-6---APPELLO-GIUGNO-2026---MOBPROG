import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CreateMealPlanScreen(),
  ));
}

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color kCardBackground = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kBorderColor = Color(0xFFF3F4F6); 
const Color kBackgroundClear = Color(0xFFF9F9FB); 

class RecipeModel {
  final int id;
  final String title;
  final String image;
  const RecipeModel({required this.id, required this.title, required this.image});
  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'image': image};
}

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

  // Database finto differenziato per suggerimenti casuali reali
  final Map<String, List<String>> _suggestionsPool = {
    "colazione": [
      "Pancakes allo sciroppo d'acero",
      "Porridge d'avena con frutti di bosco",
      "Yogurt greco con muesli e miele",
      "Toast con avocado e uovo in camicia"
    ],
    "pranzo": [
      "Pasta aglio, olio e peperoncino",
      "Risotto ai funghi porcini",
      "Gnocchi di patate al pomodoro e basilico",
      "Insalata di riso venere con salmone"
    ],
    "cena": [
      "Petto di pollo alla griglia con verdure",
      "Filetto di orata al cartoccio",
      "Frittata al forno con spinaci",
      "Hamburger di scottona con patate dolci"
    ],
    "snack": [
      "Frutta fresca di stagione",
      "Barretta proteica ai cereali",
      "Manciata di mandorle e noci",
      "Gallette di riso con burro d'arachidi"
    ]
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

  // ➕ AGGIUNGI INTERO SLOT PASTO EXTRA CON SUPPORTO AI NOMI PERSONALIZZATI
  void _addNewMealSlot() {
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
                    onChanged: (val) {
                      setDialogState(() {
                        selectedType = val!;
                      });
                    },
                  ),
                ),
              ),
              // Mostra il campo di testo libero solo se selezioni "ALTRO"
              if (selectedType == "ALTRO") ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderColor)),
                  child: TextField(
                    controller: customNameController,
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: "Es: Pre-Workout, Snack Notturno",
                      hintStyle: GoogleFonts.montserrat(color: kTextMuted, fontSize: 13),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ]
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Annulla", style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.w600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  // 🗑️ ELIMINA INTERO SLOT PASTO
  void _removeMealSlot(String mealType) {
    setState(() {
      _dayMealTypes[_selectedDay]!.remove(mealType);
      _associatedRecipes[_selectedDay]!.remove(mealType);
    });
  }

  // 🔤 ➕ DIALOG PER AGGIUNGERE UN PIATTO MANUALE ISTANTANEO
  void _showAddPiatoDialog(String mealType) {
    final TextEditingController piattoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text("Cosa inseriamo in $mealType?", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark)),
        content: Container(
          decoration: BoxDecoration(color: kBackgroundClear, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorderColor)),
          child: TextField(
            controller: piattoController,
            autofocus: true,
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Es: Pasta al pomodoro, bresaola...",
              hintStyle: GoogleFonts.montserrat(color: kTextMuted, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Annulla", style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.w600))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              String t = piattoController.text.trim();
              if (t.isEmpty) return;

              Navigator.pop(dialogContext); 

              setState(() {
                _associatedRecipes[_selectedDay]![mealType]!.add(
                  RecipeModel(id: DateTime.now().millisecondsSinceEpoch, title: t, image: "")
                );
              });
            },
            child: Text("Aggiungi", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 💡 SUGGERISCI UN PIATTO IN AUTOMATICO CASUALE E DIFFERENZIATO
  void _suggestRecipeFromApi(String mealType) {
    String baseType = mealType.split(' ')[0].toLowerCase();
    
    // Identifica la categoria adatta per pescare dal pool dei suggerimenti
    String poolKey = "snack";
    if (baseType == "colazione" || baseType == "pranzo" || baseType == "cena") {
      poolKey = baseType;
    }

    List<String> opzioni = _suggestionsPool[poolKey] ?? _suggestionsPool["snack"]!;
    
    // Sceglie un piatto a caso dalla lista corrispondente
    final random = Random();
    String piattoScelto = opzioni[random.nextInt(opzioni.length)];

    setState(() {
      _associatedRecipes[_selectedDay]![mealType]!.add(
        RecipeModel(id: DateTime.now().microsecondsSinceEpoch, title: piattoScelto, image: "")
      );
    });
  }

  void _savePlannerToDatabase() {
    if (_plannerNameController.text.trim().isEmpty) return;
    Navigator.pop(context);
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
              // 1. CARD NOME PLANNER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NOME DEL PIANO ALIMENTARE", style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _plannerNameController,
                      style: GoogleFonts.montserrat(fontSize: 16, color: kTextDark, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: "Es: Dieta Definizione Estate 🏋️",
                        hintStyle: GoogleFonts.montserrat(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 2. SELETTORE GIORNI ORIZZONTALE
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
                            boxShadow: isSelected ? [BoxShadow(color: primaryGreen.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))] : [],
                          ),
                          child: Center(
                            child: Text(day, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : kTextDark)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // INTESTAZIONE SEZIONE DEI PASTI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("MENU DI $_selectedDay", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: primaryGreen, letterSpacing: 1.1)),
                  TextButton.icon(
                    onPressed: _addNewMealSlot,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: primaryGreen, size: 18),
                    label: Text("Aggiungi Pasto", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. CONTENITORI PASTI
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 16, offset: const Offset(0, 4))],
                          border: Border.all(color: kBorderColor, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header del Pasto
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                              child: Row(
                                children: [
                                  Text(_mealEmojis[baseType] ?? "🍲", style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Text(mealType, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 20),
                                    onPressed: () => _suggestRecipeFromApi(mealType),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _removeMealSlot(mealType),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                  ),
                                ],
                              ),
                            ),
                            
                            const Divider(color: kBorderColor, height: 1),

                            // Corpo del pasto: mostra i Piatti correnti + il tasto "+"
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
                                          decoration: BoxDecoration(
                                            color: kBackgroundClear,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(recipe.title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _associatedRecipes[_selectedDay]![mealType]!.remove(recipe);
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                                                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // ➕ BOTTONE PIATTO DINAMICO
                                  InkWell(
                                    onTap: () => _showAddPiatoDialog(mealType),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: kBackgroundClear,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: primaryGreen.withValues(alpha: 0.3), width: 1.5),
                                      ),
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
              
              // 4. BOTTONE SALVA NEL DB
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: primaryGreen.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
                ),
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