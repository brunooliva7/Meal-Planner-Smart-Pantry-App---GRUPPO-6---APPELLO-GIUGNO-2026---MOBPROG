import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recipe.dart'; 
import 'modifyplanner.dart'; 
import 'recipe_model.dart'; 

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MealPlanScreen(),
  ));
}

const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color kCardBackground = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kBorderColor = Color(0xFFF3F4F6); 
const Color kBackgroundClear = Color(0xFFF9F9FB); 

class MealSlot {
  final String id;    
  final String type;  
  final String emoji;
  final List<RecipeModel> recipes; 

  const MealSlot({
    required this.id,
    required this.type,
    required this.emoji,
    required this.recipes,
  });
}

final Map<String, List<MealSlot>> mockWeeklyPlanner = {
  "Lunedì": [
    const MealSlot(id: "1", type: "COLAZIONE", emoji: "🥞", recipes: []),
    MealSlot(id: "2", type: "PRANZO", emoji: "🍝", recipes: [
      const RecipeModel(id: 716429, title: "Pasta with Garlic", image: ""),
      const RecipeModel(id: 637999, title: "Grilled Chicken Breast", image: ""), 
    ]),
    const MealSlot(id: "3", type: "SPUNTINO 1", emoji: "🍏", recipes: []),
    const MealSlot(id: "4", type: "SPUNTINO 2", emoji: "🔋", recipes: []), 
    const MealSlot(id: "5", type: "CENA", emoji: "🥩", recipes: []),
  ],
  "Martedì": [
    const MealSlot(id: "1", type: "COLAZIONE", emoji: "🥞", recipes: []),
    const MealSlot(id: "2", type: "PRANZO", emoji: "🍝", recipes: []),
    const MealSlot(id: "3", type: "CENA", emoji: "🥩", recipes: []),
  ],
  "Mercoledì": [], "Giovedì": [], "Venerdì": [], "Sabato": [], "Domenica": []
};

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final List<String> _days = ["Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"];
  int _currentDayIndex = 0;

  void _nextDay() => _currentDayIndex < _days.length - 1 ? setState(() => _currentDayIndex++) : null;
  void _previousDay() => _currentDayIndex > 0 ? setState(() => _currentDayIndex--) : null;

  @override
  Widget build(BuildContext context) {
    final String currentDay = _days[_currentDayIndex];
    final List<MealSlot> currentMeals = mockWeeklyPlanner[currentDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundClear,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.edit_note_rounded, size: 28, color: primaryGreen),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditMealPlanScreen(
                              initialPlannerName: "Dieta Definizione Estate 🏋️", 
                              initialDayMealTypes: const {
                                "Lunedì": ["COLAZIONE", "SPUNTINO 1", "PRANZO", "SPUNTINO 2", "CENA"],
                                "Martedì": ["COLAZIONE", "PRANZO", "CENA"],
                                "Mercoledì": ["COLAZIONE", "PRANZO", "CENA"],
                                "Giovedì": ["COLAZIONE", "PRANZO", "CENA"],
                                "Venerdì": ["COLAZIONE", "PRANZO", "CENA"],
                                "Sabato": ["COLAZIONE", "PRANZO", "CENA"],
                                "Domenica": ["COLAZIONE", "PRANZO", "CENA"],
                              },
                              initialAssociatedRecipes: const {
                                "Lunedì": {
                                  "COLAZIONE": [],
                                  "SPUNTINO 1": [],
                                  "PRANZO": [
                                    RecipeModel(id: 716429, title: "Pasta with Garlic", image: ""),
                                    RecipeModel(id: 637999, title: "Grilled Chicken Breast", image: ""),
                                  ],
                                  "SPUNTINO 2": [],
                                  "CENA": [],
                                },
                                "Martedì": {"COLAZIONE": [], "PRANZO": [], "CENA": []},
                                "Mercoledì": {}, "Giovedì": {}, "Venerdì": {}, "Sabato": {}, "Domenica": {}
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 28),
                          color: _currentDayIndex == 0 ? Colors.grey.shade300 : primaryGreen,
                          onPressed: _previousDay,
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                            child: Text(currentDay, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 28),
                          color: _currentDayIndex == _days.length - 1 ? Colors.grey.shade300 : primaryGreen,
                          onPressed: _nextDay,
                        ),
                      ],
                    ),
                  ),
                  const IgnorePointer(child: Opacity(opacity: 0, child: Icon(Icons.edit_note_rounded, size: 28))),
                ],
              ),
            ),
            Expanded(
              child: currentMeals.isEmpty 
                ? Center(child: Text("Nessun pasto pianificato", style: GoogleFonts.montserrat(color: kTextMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: currentMeals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => _MealCard(slot: currentMeals[index]),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealSlot slot;
  const _MealCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final hasRecipes = slot.recipes.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: kBackgroundClear, shape: BoxShape.circle),
              child: Text(slot.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(slot.type, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w800, color: primaryGreen, letterSpacing: 1.2)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasRecipes ? primaryGreen.withOpacity(0.1) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(hasRecipes ? '${slot.recipes.length} Piatti' : 'Vuoto', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: hasRecipes ? primaryGreen : kTextMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (!hasRecipes)
                    Text('Cosa si mangia oggi?', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: kTextMuted.withOpacity(0.8)))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slot.recipes.map((recipe) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailScreen(recipeData: recipe.toMap(), isFromApi: true),
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
            ),
          ],
        ),
      ),
    );
  }
}