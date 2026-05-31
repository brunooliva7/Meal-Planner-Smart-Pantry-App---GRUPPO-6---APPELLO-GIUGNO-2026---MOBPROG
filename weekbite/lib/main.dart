import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/gestione_dispensa/dispensa.dart';
import 'screens/gestione_dispensa/lista_spesa.dart';
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
  int loggedUserId = 0; // Traccia l'ID utente per le tue pagine personali

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
      final int? uid = prefs.getInt('userId');
      
      // Se trova l'ID salvato sul telefono, l'utente entra direttamente!
      if (uid != null) {
        setState(() {
          isUserLogged = true;
          loggedUserId = uid; // Salva localmente l'ID per passarlo alla tua pagina
        });
      }
    } catch (e) {
      print("Errore caricamento sessione SharedPreferences: $e");
    }
  }
  
  List<Widget> _getPages() {
    return [
      MainScreen(isLogged: isUserLogged), 
      MealPlanScreen(key: _mealPlanKey, userId: loggedUserId), // Passa il valore alla tua pagina per non lasciarla a 0
      const ListaIngredientiScreen(), 
      const DispensaScreen(), 
      UserProfileScreen(
        onLogout: () {
          setState(() {
            isUserLogged = false;
            loggedUserId = 0; // Svuota al logout
            _selectedIndex = 0;
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
                final prefs = await SharedPreferences.getInstance();
                final int? uid = prefs.getInt('userId');
                
                setState(() {
                  isUserLogged = true;
                  if (uid != null) {
                    loggedUserId = uid; // 🟢 CORRETTO: Estrae immediatamente l'ID utente per evitare il valore 0
                  }
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
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), 
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
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
              _buildNavItem(Icons.playlist_add_check_outlined,"Lista", 2, size: 28),
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
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTapDown: (details) async {
          if (index == 1) {
            if (!isUserLogged) {
              _showRegistrationPopup();
            } else {
              // 🟢 SICUREZZA AGGIUNTIVA: Rilegge l'ID utente locale per garantire che non sia 0 al cambio di scheda
              final prefs = await SharedPreferences.getInstance();
              final int? uid = prefs.getInt('userId');
              setState(() {
                if (uid != null) loggedUserId = uid;
                _selectedIndex = 1;
              });
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
          if (index == 4) {
            if (!isUserLogged) {
              final hasLoggedIn = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );

              if (!mounted) return;

              if (hasLoggedIn == true) {
                final prefs = await SharedPreferences.getInstance();
                final int? uid = prefs.getInt('userId');
                
                setState(() {
                  isUserLogged = (uid != null);
                  if (uid != null) loggedUserId = uid; // Aggiorna l'ID dopo il login
                  _selectedIndex = 4; 
                });
              }
            } else {
              setState(() => _selectedIndex = index);
            }
            return;
          }

          setState(() => _selectedIndex = index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: size, 
              color: isSelected ? primaryGreen : Colors.grey, 
            ),
            const SizedBox(height: 4), 
            Flexible( 
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 10, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryGreen : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}