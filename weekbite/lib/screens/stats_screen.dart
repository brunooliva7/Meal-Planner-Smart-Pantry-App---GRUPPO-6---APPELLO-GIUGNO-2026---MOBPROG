import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart'; // <-- IMPORT DEL DATABASE DEL TEAM

// COLORI UFFICIALI
const Color primaryGreen = Color.fromARGB(255, 75, 187, 120);
const Color backgroundColor = Colors.white;

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool isLoading = true;

  // Variabili per i dati reali
  int totalePreferite = 0;
  int tempoMedioMinuti = 0;
  
  List<Map<String, dynamic>> categorieFrequenti = [];
  List<Map<String, dynamic>> prodottiScadenza = [];

  @override
  void initState() {
    super.initState();
    _calcolaStatisticheReali();
  }

  // ==========================================================
  // 🧠 MOTORE DI CALCOLO STATISTICHE (SQLite Integration)
  // ==========================================================
  Future<void> _calcolaStatisticheReali() async {
    final db = await DatabaseHelper.instance.database;

    // 1. RECUPERO ID PREFERITI DA SQLITE
    final List<Map<String, dynamic>> favs = await DatabaseHelper.instance.getAllFavorites();
    int counterPreferite = favs.length;
    int sommaTempo = 0;
    Map<String, int> contatoreCategorie = {};

    if (counterPreferite > 0) {
      // Estraiamo tutti gli ID salvati come preferiti
      List<int> favoriteIds = favs.map((f) => f['id'] as int).toList();

      // Recuperiamo l'intera cache delle ricette virali dal DB per estrarre i dettagli (tempi e categorie)
      final List<Map<String, dynamic>> cacheRows = await db.query('viral_recipes_cache');
      
      for (var row in cacheRows) {
        int recipeId = row['id'] as int;
        
        // Se la ricetta della cache è tra i preferiti dell'utente, facciamo i calcoli
        if (favoriteIds.contains(recipeId)) {
          Map<String, dynamic> recipeJson = json.decode(row['recipe_json'] as String);
          
          // Somma tempo medio
          sommaTempo += (recipeJson['readyInMinutes'] as int? ?? 0);

          // Filtro categorie
          List types = recipeJson['dishTypes'] ?? [];
          if (types.isEmpty) types = ['Generico'];
          
          for (var tipo in types) {
            String catName = tipo.toString();
            catName = "${catName[0].toUpperCase()}${catName.substring(1)}"; 
            contatoreCategorie[catName] = (contatoreCategorie[catName] ?? 0) + 1;
          }
        }
      }

      tempoMedioMinuti = sommaTempo ~/ counterPreferite;
    }

    // 2. PREPARAZIONE DATI PER IL GRAFICO A BARRE
    var categorieOrdinate = contatoreCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> finalCats = [];
    List<Color> coloriGrafico = [primaryGreen, const Color(0xFFA8C0A3), const Color(0xFFC3D4BF)];
    int totalTags = contatoreCategorie.values.fold(0, (sum, val) => sum + val);

    for (int i = 0; i < categorieOrdinate.length && i < 3; i++) {
      finalCats.add({
        'nome': categorieOrdinate[i].key,
        'percentuale': totalTags > 0 ? (categorieOrdinate[i].value / totalTags) : 0.0,
        'colore': coloriGrafico[i % coloriGrafico.length],
      });
    }

    // ==========================================================
    // 🥫 INTERCETTAZIONE DISPENSA VERA (DA SQLITE)
    // ==========================================================
    List<Map<String, dynamic>> prodottiInScadenzaReali = [];
    
    try {
      // Peschiamo la dispensa reale dal database del team
      final ingredientiDispensa = await DatabaseHelper.instance.getIngredienti('dispensa');
      final DateTime oggi = DateTime.now();

      for (var ing in ingredientiDispensa) {
        // Calcoliamo la differenza in giorni tra la scadenza e oggi
        int giorniRimanenti = ing.dataScadenza.difference(oggi).inDays;

        // Selezioniamo solo i prodotti che scadono tra meno di 7 giorni (o già scaduti)
        if (giorniRimanenti <= 7) {
          prodottiInScadenzaReali.add({
            'nome': ing.nome,
            'giorni': giorniRimanenti < 0 ? "Scaduto da ${giorniRimanenti.abs()} gg" : "Tra $giorniRimanenti gg",
            'critico': giorniRimanenti <= 2, // Rosso se mancano meno di 3 giorni
          });
        }
      }

      // Ordiniamo la lista mettendo prima quelli più critici/scaduti
      prodottiInScadenzaReali.sort((a, b) {
        bool criticoA = a['critico'] as bool;
        bool criticoB = b['critico'] as bool;
        if (criticoA && !criticoB) return -1;
        if (!criticoA && criticoB) return 1;
        return 0;
      });

    } catch (e) {
      print("Errore lettura dispensa per statistiche: $e");
    }

    // Aggiorna l'interfaccia con tutti i dati raccolti
    if (mounted) {
      setState(() {
        totalePreferite = counterPreferite;
        categorieFrequenti = finalCats;
        prodottiScadenza = prodottiInScadenzaReali;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    final statsGenerali = [
      {'label': 'Ricette Salvate', 'valore': '$totalePreferite', 'icon': Icons.favorite},
      {'label': 'Tempo Medio', 'valore': '${tempoMedioMinuti}m', 'icon': Icons.access_time},
      {'label': 'Nel Frigo', 'valore': '${prodottiScadenza.length}', 'icon': Icons.kitchen},
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Statistiche & Riepilogo',
          style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GRID DELLE STATISTICHE VELOCI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: statsGenerali.map((stat) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.28,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Icon(stat['icon'] as IconData, color: primaryGreen, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        stat['valore'] as String,
                        style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stat['label'] as String,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // SEZIONE GRAFICO GUSTI
            Text('I tuoi gusti (Dai Preferiti)', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: categorieFrequenti.isEmpty
                ? Center(
                    child: Text(
                      "Salva qualche ricetta tra i preferiti per generare il grafico!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                : Column(
                    children: categorieFrequenti.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat['nome'] as String, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                                Text("${((cat['percentuale'] as double) * 100).toInt()}%", style: GoogleFonts.montserrat(color: primaryGreen, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Stack(
                              children: [
                                Container(height: 10, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(5))),
                                FractionallySizedBox(
                                  widthFactor: cat['percentuale'] as double,
                                  child: Container(height: 10, decoration: BoxDecoration(color: cat['colore'] as Color, borderRadius: BorderRadius.circular(5))),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            ),
            const SizedBox(height: 30),

            // SEZIONE SCADENZE DISPENSA
            Text('In scadenza (Dispensa)', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: prodottiScadenza.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "La tua dispensa è al sicuro.\nNessun prodotto in scadenza a breve.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  )
                : Column(
                    children: prodottiScadenza.map((prod) {
                      bool critico = prod['critico'] as bool;
                      return ListTile(
                        leading: Icon(critico ? Icons.error_outline : Icons.warning_amber_rounded, color: critico ? Colors.red[400] : Colors.orange[400]),
                        title: Text(prod['nome'] as String, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                        trailing: Text(
                          prod['giorni'] as String,
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: critico ? Colors.red[400] : Colors.grey[600]),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        dense: true,
                      );
                    }).toList(),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}