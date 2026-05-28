import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================================
// ⚙️ CONFIGURAZIONI GLOBALI (Le tue impostazioni weekBite)
// ==========================================================

// COLORI
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

// COSTANTI DI DESIGN AGGIUNTIVE ANTI-DEPRECATION
const Color kCardBackground = Colors.white;
const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kBorderColor = Color(0xFFF3F4F6); 
const Color kBackgroundClear = Color(0xFFF9F9FB); 

// TESTI E TITOLI
const String appTitle = 'weekBite';
const double appBarTitleSize = 22.0;
const double navBarTextSize = 12.0;

// ==========================================================
// 📦 MODELLI DATI (Mappatura dell'API Spoonacular)
// ==========================================================
class Ingredient {
  final int id;
  final String name;
  final double amount;
  final String unit;
  final String original;

  const Ingredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.original,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      original: json['original'] ?? '',
    );
  }
}

class RecipeModel {
  final int id;
  final String title;
  final int readyInMinutes;
  final int servings;
  final String image;
  final String summary;
  final String instructions;
  final List<Ingredient> extendedIngredients;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.readyInMinutes,
    required this.servings,
    required this.image,
    required this.summary,
    required this.instructions,
    required this.extendedIngredients,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    var list = json['extendedIngredients'] as List? ?? [];
    List<Ingredient> ingredientsList = list.map((i) => Ingredient.fromJson(i)).toList();

    return RecipeModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Nessun Titolo',
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 0,
      image: json['image'] ?? '',
      summary: json['summary'] ?? '',
      instructions: json['instructions'] ?? 'Nessuna istruzione.',
      extendedIngredients: ingredientsList,
    );
  }
}

class MealSlot {
  final String type; 
  final String emoji;
  final RecipeModel? recipe; 

  const MealSlot({
    required this.type,
    required this.emoji,
    this.recipe,
  });
}

// ==========================================================
// 🗓️ DATI MOCK DI TEST (Il tuo Planner Settimanale)
// ==========================================================
final RecipeModel mockPastaRecipe = RecipeModel.fromJson({
  "id": 716429,
  "title": "Pasta with Garlic, Scallions, and Butter",
  "readyInMinutes": 45,
  "servings": 2,
  "image": "https://spoonacular.com/recipeImages/716429-556x370.jpg",
  "summary": "Pasta with Garlic...",
  "instructions": "Cook...",
  "extendedIngredients": [{"id": 20420, "name": "pasta", "amount": 8.0, "unit": "oz", "original": "8 oz pasta"}]
});

final Map<String, List<MealSlot>> mockWeeklyPlanner = {
  "Lunedì": [
    MealSlot(type: "COLAZIONE", emoji: "🥞", recipe: null), 
    MealSlot(type: "SPUNTINO", emoji: "🍏", recipe: null),
    MealSlot(type: "PRANZO", emoji: "🍝", recipe: mockPastaRecipe), 
    MealSlot(type: "MERENDA", emoji: "🧃", recipe: null),
    MealSlot(type: "CENA", emoji: "🥩", recipe: null),
  ],
  "Martedì": [
    MealSlot(type: "COLAZIONE", emoji: "🥞"),
    MealSlot(type: "SPUNTINO", emoji: "🍏"),
    MealSlot(type: "PRANZO", emoji: "🍝"),
    MealSlot(type: "MERENDA", emoji: "🧃"),
    MealSlot(type: "CENA", emoji: "🥩", recipe: mockPastaRecipe),
  ],
  "Mercoledì": [MealSlot(type: "COLAZIONE", emoji: "🥞"), MealSlot(type: "SPUNTINO", emoji: "🍏"), MealSlot(type: "PRANZO", emoji: "🍝"), MealSlot(type: "MERENDA", emoji: "🧃"), MealSlot(type: "CENA", emoji: "🥩")],
  "Giovedì": [MealSlot(type: "COLAZIONE", emoji: "🥞"), MealSlot(type: "SPUNTINO", emoji: "🍏"), MealSlot(type: "PRANZO", emoji: "🍝"), MealSlot(type: "MERENDA", emoji: "🧃"), MealSlot(type: "CENA", emoji: "🥩")],
  "Venerdì": [MealSlot(type: "COLAZIONE", emoji: "🥞"), MealSlot(type: "SPUNTINO", emoji: "🍏"), MealSlot(type: "PRANZO", emoji: "🍝"), MealSlot(type: "MERENDA", emoji: "🧃"), MealSlot(type: "CENA", emoji: "🥩")],
  "Sabato": [MealSlot(type: "COLAZIONE", emoji: "🥞"), MealSlot(type: "SPUNTINO", emoji: "🍏"), MealSlot(type: "PRANZO", emoji: "🍝"), MealSlot(type: "MERENDA", emoji: "🧃"), MealSlot(type: "CENA", emoji: "🥩")],
  "Domenica": [MealSlot(type: "COLAZIONE", emoji: "🥞"), MealSlot(type: "SPUNTINO", emoji: "🍏"), MealSlot(type: "PRANZO", emoji: "🍝"), MealSlot(type: "MERENDA", emoji: "🧃"), MealSlot(type: "CENA", emoji: "🥩")],
};

// ==========================================================
// 🚀 AVVIO APP
// ==========================================================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          surface: backgroundColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: primaryGreen,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.montserrat(
            fontSize: appBarTitleSize,
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
        useMaterial3: true,
      ),
      home: const BaseLayout(),
    );
  }
}

class BaseLayout extends StatefulWidget {
  const BaseLayout({super.key});

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  int _selectedIndex = 1; // Impostato di default a 1 per mostrare subito il Meal Plan al lancio

  // ==========================================================
  // 📄 LE SCHERMATE INTEGRATE (Incluso il nuovo MealPlanScreen)
  // ==========================================================
  static final List<Widget> _pages = <Widget>[
    Center(child: Text("Ricette", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
    
    const MealPlanScreen(), 
    
    Center(child: Text("Aggiungi", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
    Center(child: Text("Dispensa", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))), // Sostituisci pure con const DispensaScreen() se il file è importato correttamente
    Center(child: Text("Utente", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        selectedLabelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: navBarTextSize),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ricette'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), activeIcon: Icon(Icons.add_circle, size: 32), label: 'Aggiungi'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen_outlined), activeIcon: Icon(Icons.kitchen), label: 'Dispensa'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), activeIcon: Icon(Icons.account_circle), label: 'Utente'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryGreen,
        unselectedItemColor: unselectedIconColor,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ==========================================================
//  SCHERMATA MEAL PLAN (VERSIONE TOTALMENTE RESPONSIVE)
// ==========================================================
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final List<String> _days = [
    "Lunedì", "Martedì", "Mercoledì", "Giovedì", "Venerdì", "Sabato", "Domenica"
  ];
  int _currentDayIndex = 0;

  void _nextDay() {
    if (_currentDayIndex < _days.length - 1) {
      setState(() => _currentDayIndex++);
    }
  }

  void _previousDay() {
    if (_currentDayIndex > 0) {
      setState(() => _currentDayIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentDay = _days[_currentDayIndex];
    final List<MealSlot> currentMeals = mockWeeklyPlanner[currentDay] ?? [];

    return Scaffold(
      backgroundColor: kBackgroundClear,
      body: SafeArea(
        child: Column(
          children: [
            // NAVBAR SUPERIORE 
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0),
              child: Row(
                children: [
                  // 1. Bottone Matita (Modifica/Configurazione)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_note_rounded, size: 28, color: primaryGreen),
                      onPressed: () {
                        // TODO: Collegamento alla tua schermata form di inserimento/modifica planner
                      },
                    ),
                  ),
                  
                  // 2. Selettore Centrale Flessibile del Giorno
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 28),
                          color: _currentDayIndex == 0 ? Colors.grey.shade300 : primaryGreen,
                          onPressed: _previousDay,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              currentDay,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kTextDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 28),
                          color: _currentDayIndex == _days.length - 1 ? Colors.grey.shade300 : primaryGreen,
                          onPressed: _nextDay,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  // 3. Clone Invisibile di bilanciamento per centrare al millimetro il testo del giorno
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(Icons.edit_note_rounded, size: 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // LISTA DELLE CARD DEI PASTI
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: currentMeals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _MealCard(slot: currentMeals[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// 📇 COMPONENTE CARD FLUIDO PER SMARTPHONE
// ==========================================================
class _MealCard extends StatelessWidget {
  final MealSlot slot;

  const _MealCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final hasRecipe = slot.recipe != null;

    return Container(
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: kBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6), 
          ),
          if (hasRecipe)
            BoxShadow(
              color: primaryGreen.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20), 
          onTap: () {
            if (hasRecipe) {
              // 🚀 TODO: Inserisci il push alla tua schermata delle ricette
              // Esempio: Navigator.push(context, MaterialPageRoute(builder: (_) => SchermataDettaglio(recipe: slot.recipe!)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nessun piano per ${slot.type.toLowerCase()}. Usa la matita in alto.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: kTextDark,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Contenitore circolare per l'Emoji
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: kBackgroundClear,
                    shape: BoxShape.circle,
                  ),
                  child: Text(slot.emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                
                // Area Testi della card (Protetta da overflow tramite Expanded e Flexible)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            slot.type,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: primaryGreen,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Badge dello stato corrente del pasto
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasRecipe 
                                  ? primaryGreen.withValues(alpha: 0.1) 
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hasRecipe ? 'Pianificato' : 'Vuoto',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: hasRecipe ? primaryGreen : kTextMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasRecipe ? slot.recipe!.title : 'Cosa si mangia oggi?',
                        style: GoogleFonts.montserrat(
                          textStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: hasRecipe ? kTextDark : kTextMuted.withValues(alpha: 0.8),
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Tronca i titoli troppo lunghi sui telefoni stretti
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded, 
                  size: 22, 
                  color: hasRecipe ? primaryGreen : Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}