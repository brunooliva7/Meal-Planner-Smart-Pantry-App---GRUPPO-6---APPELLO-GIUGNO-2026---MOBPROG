import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recipe.dart'; 
import 'modifyplanner.dart'; 
import 'package:translator/translator.dart';
import 'recipe_model.dart'; 
import '../services/database_helper.dart'; 

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color kCardBackground = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kBorderColor = Color(0xFFF3F4F6); 
const Color kBackgroundClear = Color(0xFFF9F9FB); 

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});
  @override
  State<MealPlanScreen> createState() => MealPlanScreenState();
}

class MealPlanScreenState extends State<MealPlanScreen> {
  final List<String> _days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"];
  String _selectedDay = "Lunedì";

  List<String> _allPlannerNames = [];
  String? _selectedPlannerName;
  Map<String, List<String>> _dayMealTypes = {};
  Map<String, Map<String, List<RecipeModel>>> _associatedRecipes = {};
  int _currentPlannerId = 0;
  bool _isLoading = true;

  final Map<String, String> _mealEmojis = {
    "COLAZIONE": "🥞", "PRANZO": "🍝", "SPUNTINO": "🍏", "MERENDA": "🧃", "CENA": "🥩", "ALTRO": "🍲"
  };

  @override
  void initState() {
    super.initState();
    _setTodayDay();
    _loadPlannerData();
  }
  void _setTodayDay() {
    int weekday = DateTime.now().weekday; 
    setState(() {
      _selectedDay = _days[weekday - 1];
    });
  }
  
  void forceReloadFromDb() {
    _selectedPlannerName = null; 
    _loadPlannerData();
  }

  Future<void> _loadPlannerData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final names = await DatabaseHelper.instance.getAllPlannerNames();
      
      if (names.isNotEmpty) {
        _allPlannerNames = names;
        
        if (_selectedPlannerName == null || !_allPlannerNames.contains(_selectedPlannerName)) {
          _selectedPlannerName = _allPlannerNames.first;
        }

        final completeData = await DatabaseHelper.instance.getPlannerComplete(_selectedPlannerName!);
        if (completeData != null) {
          _currentPlannerId = completeData['id'] ?? 0; 
          _dayMealTypes = completeData['dayMealTypes'] as Map<String, List<String>>;
          _associatedRecipes = completeData['associatedRecipes'] as Map<String, Map<String, List<RecipeModel>>>;
        }
      } else {
        _allPlannerNames = [];
        _selectedPlannerName = null;
        _dayMealTypes = {};
        _associatedRecipes = {};
        _currentPlannerId = 0;
      }
    } catch (e) {
      print("Errore nel caricamento del meal planner: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCurrentPlanner() async {
    if (_selectedPlannerName == null) return;
    
    final data = await DatabaseHelper.instance.getPlannerComplete(_selectedPlannerName!);
    if (data != null && data['id'] != null) {
      await DatabaseHelper.instance.deletePlanner(data['id'] as int);
      _selectedPlannerName = null; 
      _loadPlannerData(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackgroundClear,
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (_selectedPlannerName == null || _allPlannerNames.isEmpty) {
      return Scaffold(
        backgroundColor: kBackgroundClear,
        appBar: AppBar(
          title: Text("Il tuo Meal Planner", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: kTextDark)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("🗓️", style: TextStyle(fontSize: 50)),
                const SizedBox(height: 16),
                Text(
                  "Nessun piano alimentare salvato",
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
                ),
                const SizedBox(height: 8),
                Text(
                  "Clicca sul pulsante '+' nella barra in basso e seleziona 'Crea Planner' per comporre il tuo primo menu settimanale!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 13, color: kTextMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pastiDelGiorno = _dayMealTypes[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundClear,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(color: kBackgroundClear, shape: BoxShape.circle),
            child: IconButton(
              icon: const Icon(Icons.edit_note_rounded, size: 22, color: primaryGreen),
              padding: EdgeInsets.zero,
              onPressed: () async {
                if (_currentPlannerId == 0) return;

                final bool? rinfrescaDati = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditMealPlanScreen(
                      plannerId: _currentPlannerId,
                      initialPlannerName: _selectedPlannerName!,
                      initialDayMealTypes: _dayMealTypes,
                      initialAssociatedRecipes: _associatedRecipes,
                    ),
                  ),
                );

                if (rinfrescaDati == true) {
                  _loadPlannerData();
                }
              },
            ),
          ),
        ),
        // 🟢 EVITIAMO OVERFLOW NELL'APPBAR: Sfruttiamo una Row con Expanded per scalare dinamicamente il dropdown
        title: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPlannerName,
                  isExpanded: true, // Occupa in sicurezza lo spazio orizzontale rimanente
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryGreen),
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color: kTextDark),
                  dropdownColor: Colors.white,
                  items: _allPlannerNames.map((String name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis, // Gestisce nomi planner lunghissimi troncandoli con i tre puntini
                      ),
                    );
                  }).toList(),
                  onChanged: (newName) {
                    if (newName != null) {
                      setState(() {
                        _selectedPlannerName = newName;
                        _loadPlannerData();
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Elimina Piano"),
                  content: Text("Sei sicuro di voler eliminare definitivamente il piano '$_selectedPlannerName'?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteCurrentPlanner();
                      }, 
                      child: const Text("Elimina", style: TextStyle(color: Colors.redAccent))
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final isSelected = day == _selectedDay;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: InkWell(
                      onTap: () => setState(() => _selectedDay = day),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryGreen : kBackgroundClear,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : kTextDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Expanded(
              child: pastiDelGiorno.isEmpty
                  ? Center(child: Text("Nessun pasto configurato per oggi.", style: GoogleFonts.montserrat(color: kTextMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pastiDelGiorno.length,
                      itemBuilder: (context, index) {
                        final mealType = pastiDelGiorno[index];
                        final baseType = mealType.split(' ')[0].toUpperCase();
                        final listRecipes = _associatedRecipes[_selectedDay]?[mealType] ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: kBorderColor),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              leading: Text(_mealEmojis[baseType] ?? "🍲", style: const TextStyle(fontSize: 22)),
                              // 🟢 PREVENZIONE OVERFLOW TITOLO PASTO: Avvolto in Row ed Expanded per nomi custom lunghi
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mealType, 
                                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: kTextDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (listRecipes.isEmpty)
                                        Text(
                                          "Nessun piatto inserito",
                                          style: GoogleFonts.montserrat(fontSize: 13, fontStyle: FontStyle.italic, color: kTextMuted),
                                        )
                                      else
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: listRecipes.map((recipe) {
                                            return InkWell(
                                              onTap: () async {
                                                String searchTitle = recipe.title;

                                                if (recipe.id < 0) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(" ricerca della ricetta affine per '$searchTitle'...", style: GoogleFonts.montserrat()),
                                                      duration: const Duration(milliseconds: 800),
                                                      backgroundColor: primaryGreen,
                                                    ),
                                                  );

                                                  try {
                                                    final translator = GoogleTranslator();
                                                    var translation = await translator.translate(recipe.title, from: 'auto', to: 'en');
                                                    searchTitle = translation.text;
                                                  } catch (e) {
                                                    print("Errore pre-traduzione query: $e");
                                                  }
                                                }

                                                if (!mounted) return;

                                                final Map<String, dynamic> passedData = recipe.id < 0 
                                                  ? { 'id': recipe.id, 'title': searchTitle, 'image': '', 'originalTitleIt': recipe.title }
                                                  : recipe.toMap();

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => RecipeDetailScreen(
                                                      recipeData: passedData,
                                                      isFromApi: recipe.id < 0, 
                                                    ),
                                                  ),
                                                );
                                              },                                     
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: kBackgroundClear,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: primaryGreen.withOpacity(0.2)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        recipe.title,
                                                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.restaurant_menu_rounded, size: 14, color: primaryGreen),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                    ],
                                  ),
                                )
                              ],
                            ),
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
} 