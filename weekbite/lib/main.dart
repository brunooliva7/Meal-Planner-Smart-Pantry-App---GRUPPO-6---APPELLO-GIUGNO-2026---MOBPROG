import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dispensa.dart';
import 'screens/lista_spesa.dart';
import 'screens/ricette.dart'; 
import 'screens/main_screen.dart';
import 'screens/mealplanner.dart'; 
import 'screens/createplanner.dart';
import 'screens/user_profile_screen.dart';
import 'screens/auth_screen.dart'; 
import 'screens/create_recipe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weekbite/services/notification_service.dart'; 


// ==========================================================
// ⚙️ CONFIGURAZIONI GLOBALI
// ==========================================================
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Color.fromARGB(255, 241, 241, 241);
const Color unselectedIconColor = Color.fromARGB(255, 158, 158, 158);

const String appTitle = 'weekBite';
const double appBarTitleSize = 22.0;
const double navBarTextSize = 12.0;

const Color kTextDark = Color(0xFF1A1A2E); 
const Color kTextMuted = Color(0xFF9CA3AF);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
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
  bool isUserLogged = false; 

  // Usiamo una GlobalKey per notificare e forzare il refresh di MealPlanScreen quando torniamo dal Crea Planner
  final GlobalKey<MealPlanScreenState> _mealPlanKey = GlobalKey<MealPlanScreenState>();

  @override
  void initState() {
    super.initState();
    _checkPersistentLogin(); // Controlla la memoria appena si apre l'app!
  }

  Future<void> _checkPersistentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? uid = prefs.getString('logged_in_uid');
      
      // Se trova l'ID salvato sul telefono, l'utente entra direttamente!
      if (uid != null && uid.isNotEmpty) {
        setState(() {
          isUserLogged = true;
        });
      }
    } catch (e) {
      print("Errore caricamento sessione SharedPreferences: $e");
    }
  }
  
  List<Widget> _getPages() {
    return [
      MainScreen(isLogged: isUserLogged), 
      MealPlanScreen(key: _mealPlanKey), 
      const ListaIngredientiScreen(), 
      const DispensaScreen(), 
      UserProfileScreen(
        onLogout: () {
          setState(() {
            isUserLogged = false;
          });
        },
      ), 
    ];
  }

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
              
              if (!mounted) return;

              if (hasLoggedIn == true) {
                setState(() {
                  isUserLogged = true;
                  _selectedIndex = 1; 
                });
              }
            },
            child: Text("Accedi / Registrati", style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Text(appTitle)),
      extendBody: true, 
      body: _getPages()[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12), 
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), 
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_filled,"Home", 0),
              _buildNavItem(Icons.calendar_month,"Piani", 1),
              _buildNavItem(Icons.checklist_rtl_rounded,"Lista", 2, size: 28),
              _buildNavItem(Icons.kitchen,"Dispensa", 3),
              _buildNavItem(Icons.person_outline,"Account", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon,String label, int index, {double size = 26}) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTapDown: (details) async {
        if (index == 1) {
          if (!isUserLogged) {
            _showRegistrationPopup();
          } else {
            setState(() => _selectedIndex = 1);
          }
          return;
        }
        if (index == 2) {
          if (!isUserLogged) {
            _showRegistrationPopup();
          } else {
            setState(() => _selectedIndex = 2);
          }
          return;
        }
        if (index == 3) {
          if (!isUserLogged) {
            _showRegistrationPopup();
          } else {
            setState(() => _selectedIndex = 3);
          }
          return;
        }
/*
        if (index == 2) {
          if (!isUserLogged) {
            _showRegistrationPopup();
            return;
          }

          final result = await showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx - 60, details.globalPosition.dy - 80, details.globalPosition.dx, details.globalPosition.dy),
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
              PopupMenuItem(
                value: 'create_recipe', // 🌟 NUOVA OPZIONE
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restaurant_menu, color: primaryGreen, size: 20),
                    const SizedBox(width: 10),
                    Text('Crea Ricetta', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ],
          );

          if (!mounted) return;

          if (result == 'create_planner') {
            // 🌟 ABBIAMO MESSO UN AWAIT: Cattura il "true" quando salvi il planner
            final bool? rinfrescaTutto = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const CreateMealPlanScreen()),
            );

            if (rinfrescaTutto == true && mounted) {
              setState(() {
                _selectedIndex = 1; // Sposta la visualizzazione sulla tab del planner
              });
              // Chiama il metodo pubblico della chiave per ricaricare il Dropdown dal DB!
              _mealPlanKey.currentState?.forceReloadFromDb();
            }
          }else if (result == 'create_recipe') {
             if (!isUserLogged) {
                // Rimanda al login se necessario, o aprilo direttamente
             } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
                );
             }
          }
          return;
        }
*/
        if (index == 4) {
          if (!isUserLogged) {
            // Se non è loggato, lo mandiamo alla pagina di autenticazione
            final hasLoggedIn = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );

            if (!mounted) return;

            if (hasLoggedIn == true) {
              // Controlliamo se SharedPreferences si è aggiornato correttamente
              final prefs = await SharedPreferences.getInstance();
              final uid = prefs.getString('logged_in_uid');
              
              setState(() {
                isUserLogged = (uid != null && uid.isNotEmpty && uid != 'null');
                _selectedIndex = 4; // Ci sposta sulla pagina del profilo appena loggato
              });
            }
          } else {
            // Se è già loggato, mostra semplicemente la scheda del profilo
            setState(() => _selectedIndex = index);
          }
          return;
        }

        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fondamentale per non far esplodere la BottomBar in altezza
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            size: size, 
            color: isSelected ? primaryGreen : Colors.grey, // Colore dinamico
          ),
          const SizedBox(height: 4), // Piccolo spazio tra icona e scritta
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10, // Testo piccolino ed elegante
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? primaryGreen : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
