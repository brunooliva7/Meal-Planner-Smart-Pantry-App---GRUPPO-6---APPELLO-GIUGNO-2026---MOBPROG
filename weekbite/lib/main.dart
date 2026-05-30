
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dispensa.dart';
import 'screens/ricette.dart'; 
import 'screens/main_screen.dart';
import 'screens/mealplanner.dart'; 
import 'screens/createplanner.dart';
import 'screens/user_profile_screen.dart';
import 'screens/auth_screen.dart'; // 🔴 IMPORTAZIONE DELLA SCHERMATA DI LOGIN

// ==========================================================
// ⚙️ CONFIGURAZIONI GLOBALI
// ==========================================================
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Color.fromARGB(255, 241, 241, 241);
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

const String appTitle = 'weekBite';
const double appBarTitleSize = 22.0;
const double navBarTextSize = 12.0;

// Definizione colore locale di supporto mancante nel file originale
const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);

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
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          surface: backgroundColor,
        ),
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.montserratTextTheme(Theme.of(context).textTheme),
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

  List<Widget> _getPages() {
    return [
      MainScreen(isLogged: isUserLogged), 
      const MealPlanScreen(), 
      Center(child: Text("Aggiungi", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))), 
      const DispensaScreen(), 
      const UserProfileScreen(), 
    ];
  }

  // 🌟 FUNZIONE SUPPORTO: Mostra il Popup di avviso registrazione se non loggato
  void _showRegistrationPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Accesso Richiesto", style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: kTextDark)),
        content: Text("Per poter pianificare i tuoi pasti e utilizzare il Meal Planner devi far parte della community di weekBite!", style: GoogleFonts.montserrat(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Annulla", style: GoogleFonts.montserrat(color: kTextMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              Navigator.pop(ctx);
              final hasLoggedIn = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
              
              // 🟢 CONTROL MOUNTED: Sicurezza post-navigazione asincrona (Indice 1 fall-back)
              if (!mounted) return;

              if (hasLoggedIn == true) {
                setState(() {
                  isUserLogged = true;
                  _selectedIndex = 1; // Naviga direttamente sul planner dopo il login
                });
              }
            },
            child: Text("Accedi / Registrati", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
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
      extendBody: true, 
      body: _getPages()[_selectedIndex],
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

  Widget _buildNavItem(IconData icon, int index, {double size = 26}) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) async {
        
        // 📅 AZIONE SUL BOTTONE CALENDARIO
        if (index == 1) {
          if (!isUserLogged) {
            _showRegistrationPopup();
          } else {
            setState(() => _selectedIndex = 1);
          }
          return;
        }

        // ➕ AZIONE SUL BOTTONE AGGIUNGI (MENU A COMPARSA)
        if (index == 2) {
          if (!isUserLogged) {
            _showRegistrationPopup();
            return;
          }

          final result = await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              details.globalPosition.dx - 60,
              details.globalPosition.dy - 80,
              details.globalPosition.dx,
              details.globalPosition.dy,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 8,
            color: Colors.white,
            items: [
              PopupMenuItem(
                value: 'create_planner',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, color: primaryGreen, size: 20),
                    const SizedBox(width: 10),
                    Text('Crea Nuovo Planner', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ],
          );

          // 🟢 CONTROL MOUNTED: Sicurezza post chiusura showMenu (Indice 2)
          if (!mounted) return;

          if (result == 'create_planner') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMealPlanScreen()),
            );
          }
          return;
        }

        // 🔴 CONTROLLO CRUCIALE: Logica Profilo
        if (index == 4 && !isUserLogged) {
          final hasLoggedIn = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );

          if (!mounted) return;

          if (hasLoggedIn == true) {
            setState(() {
              isUserLogged = true;
              _selectedIndex = 4; 
            });
          }
          return;
        }

        setState(() => _selectedIndex = index);
      },
      child: Icon(
        icon,
        size: size,
        color: isSelected ? primaryGreen : unselectedIconColor,
      ),
    );
  }
}