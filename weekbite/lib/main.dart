import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dispensa.dart';
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
    Center(child: Text("Ricette", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87))),
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