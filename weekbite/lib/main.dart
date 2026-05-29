import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dispensa.dart';
import 'screens/ricette.dart';
import 'screens/main_screen.dart';

// ==========================================================
// ⚙️ CONFIGURAZIONI GLOBALI
// ==========================================================

// COLORI
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;
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

  // ==========================================================
  // 📄 LE TUE SCHERMATE (QUI SOSTITUIRAI CON I TUOI FILE)
  // ==========================================================
  static final List<Widget> _pages = <Widget>[
    const MainScreen(),
    Center(child: Text("Meal Plan", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
    Center(child: Text("Aggiungi", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
    const DispensaScreen(),
    //Center(child: Text("Dispensa", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
    Center(child: Text("Utente", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(appTitle),
      ),
      
      // extendBody permette al contenuto di scorrere DIETRO la bottom bar fluttuante
      extendBody: true, 
      
      body: _pages[_selectedIndex],
      
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
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque, 
      child: Icon(
        icon,
        size: size,
        // COLORE AGGIORNATO (Verde primario o grigio disattivo)
        color: isSelected ? primaryGreen : unselectedIconColor,
      ),
    );
  }
}