import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dispensa.dart';
import 'screens/ricette.dart'; // Mantenuto se lo usi altrove
import 'screens/main_screen.dart';
import 'screens/mealplanner.dart'; // Mantenuto se lo usi altrove
import 'screens/createplanner.dart';
import 'screens/user_profile_screen.dart';
import 'screens/auth_screen.dart'; 
import 'package:shared_preferences/shared_preferences.dart';


// ==========================================================
// ⚙️ CONFIGURAZIONI GLOBALI
// ==========================================================

// COLORI
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Color.fromARGB(255, 241, 241, 241);
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

// TESTI E TITOLI
const String appTitle = 'weekBite';
const double appBarTitleSize = 22.0;
const double navBarTextSize = 12.0;

// ==========================================================
// 🚀 AVVIO APP
// ==========================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false, // Rimuove il banner DEBUG in alto a destra
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
  int _selectedIndex = 0;

  // 🔴 VARIABILE PER CONTROLLARE SE L'UTENTE È LOGGATO
  bool isUserLogged = false;

  @override
  void initState() {
    super.initState();
    _checkPersistentLogin(); // 🟢 Controlla subito se c'è una sessione salvata!
  }

  Future<void> _checkPersistentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? uid = prefs.getString('logged_in_uid');
      if (uid != null && uid.isNotEmpty) {
        setState(() {
          isUserLogged = true;
        });
      }
    } catch (e) {
      print("Errore caricamento sessione SharedPreferences: $e");
    }
  }

    // 🟢 ORDINE DELLE PAGINE CORRETTO (5 Pagine esatte, da indice 0 a indice 4)
    List<Widget> _getPages() {
      return [
        MainScreen(isLogged: isUserLogged), // 0: Home / MainScreen
        const MealPlanScreen(), // 1: Visualizza Planner
        Center(child: Text("Aggiungi", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))), // 2: Aggiungi
        const DispensaScreen(), // 3: Dispensa
        const UserProfileScreen(), // 4: Profilo Utente
      ];
    }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu, color: primaryGreen),
            SizedBox(width: 8),
            const Text(appTitle),
          ]
        ),
      ),
      
      // extendBody permette al contenuto di scorrere DIETRO la bottom bar fluttuante
      extendBody: true, 
      
      body: _getPages()[_selectedIndex],
      
      // BOTTOM BAR SUPER-MINIMALE
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 36, right: 36, bottom: 12), 
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_filled, 0),
              _buildNavItem(Icons.calendar_month, 1),
              _buildNavItem(Icons.add_box_outlined, 2, size: 28),
              _buildNavItem(Icons.kitchen, 3),
              _buildNavItem(Icons.person_outline, 4),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // WIDGET DI SUPPORTO
  // ==============================================================

  Widget _buildNavItem(IconData icon, int index, {double size = 26}) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTapDown: (details) async {

        // 📅 MENU CENTRATO SOPRA CALENDAR MONTH
        if (index == 1) {

          final result = await showMenu(
            context: context,

            position: RelativeRect.fromLTRB(
              details.globalPosition.dx - 70, // ← centra il menu
              details.globalPosition.dy - 90, // ← posizione sopra
              details.globalPosition.dx - 10,
              details.globalPosition.dy,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),

            elevation: 8,

            color: Colors.white,

            items: [
              PopupMenuItem(
                value: 'view_planner', // 🌟 NUOVA OPZIONE AGGIUNTA
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_view_week,
                      color: primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Visualizza Planner',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'create_planner',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      color: primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Crea Planner',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (!mounted) return;

          // 🚀 GESTIONE DELLA SCELTA DAL MENU
          if (result == 'view_planner') {
            setState(() {
              _selectedIndex = 1; // Cambia l'indice per mostrare la schermata del Meal Plan
            });
          } else if (result == 'create_planner') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateMealPlanScreen(),
              ),
            );
          }

          return;
        }

        // 🔴 CONTROLLO CRUCIALE: Logica di accesso (Auth) se clicca su Profilo
        if (index == 4 && !isUserLogged) {
          final hasLoggedIn = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );

          if (hasLoggedIn == true) {
            setState(() {
              isUserLogged = true;
              _selectedIndex = 4; // Portiamo l'utente direttamente sulla pagina del profilo
            });
          }
          return;
        }

        // comportamento originale per tutti gli altri tasti
        setState(() => _selectedIndex = index);
      },

      child: Icon(
        icon,
        size: size,
        color: isSelected
            ? primaryGreen
            : unselectedIconColor,
      ),
    );
  }
}