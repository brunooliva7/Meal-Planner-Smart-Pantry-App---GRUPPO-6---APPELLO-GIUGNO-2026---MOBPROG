import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weekbite/services/database_helper.dart'; 
import 'package:weekbite/screens/ingredienti_model.dart'; 
import 'package:weekbite/screens/dispensa.dart'; 
import 'package:weekbite/main.dart';

class SearchDispensaScreen extends StatefulWidget {
  const SearchDispensaScreen({super.key});

  @override
  State<SearchDispensaScreen> createState() => _SearchDispensaScreenState();
}

class _SearchDispensaScreenState extends State<SearchDispensaScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool isLoading = false;
  List<Ingredienti> searchResults = [];

  final List<String> categorieOptions = [
    'Tutte le categorie',
    ...categoriaM.keys,
  ];
  String selectedCategoria = 'Tutte le categorie';

  final List<String> scadenzaOptions = [
    'Tutte le scadenze',
    'Scaduti',
    'In scadenza (7 gg)',
    'Validi'
  ];
  String selectedScadenza = 'Tutte le scadenze';

  @override
  void initState() {
    super.initState();
    _performLocalSearch();
  }

  Future<void> _performLocalSearch() async {  
    setState(() {
      isLoading = true;
    });
    String queryTesto = _searchController.text.trim();

    if (queryTesto.isEmpty && selectedCategoria == 'Tutte le categorie' && selectedScadenza == 'Tutte le scadenze') {
      if (mounted) {
        setState(() {
          searchResults = []; 
          isLoading = false;
        });
      }
      return; 
    }

    try {
      final db = await DatabaseHelper.instance.database;
      List<Map<String, dynamic>> res;
      if (queryTesto.isEmpty && selectedCategoria != 'Tutte le categorie') {
        res = await db.query('dispensa', where: 'categoria = ?', whereArgs: [selectedCategoria]);
      } else if (queryTesto.isNotEmpty && selectedCategoria == 'Tutte le categorie') {
        res = await db.query('dispensa', where: 'nome LIKE ?', whereArgs: ['%$queryTesto%']);
      } else {
        res = await db.query(
          'dispensa', 
          where: 'nome LIKE ? AND categoria = ?', 
          whereArgs: ['%$queryTesto%', selectedCategoria]
        );
      }

      List<Ingredienti> parsedResults = res.map((row) => Ingredienti.fromMap(row)).toList();

      if (selectedScadenza != 'Tutte le scadenze') {
        DateTime oggi = DateTime.now();
        // Rimuoviamo le ore e i minuti, ci interessano solo i giorni!
        DateTime soloOggi = DateTime(oggi.year, oggi.month, oggi.day);

        parsedResults = parsedResults.where((ing) {
          DateTime dataIng = DateTime(ing.dataScadenza.year, ing.dataScadenza.month, ing.dataScadenza.day);
          
          if (selectedScadenza == 'Scaduti') {
            return dataIng.isBefore(soloOggi); // Scadenza precedente a oggi
          } else if (selectedScadenza == 'In scadenza (7 gg)') {
            // Tra oggi e i prossimi 7 giorni compresi
            return (dataIng.isAtSameMomentAs(soloOggi) || dataIng.isAfter(soloOggi)) && 
                   dataIng.isBefore(soloOggi.add(const Duration(days: 8)));
          } else if (selectedScadenza == 'Validi') {
            return dataIng.isAfter(soloOggi.add(const Duration(days: 7))); // Oltre i 7 giorni
          }
          return true;
        }).toList();
      }


      if (mounted) {
        setState(() {
          searchResults = parsedResults;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Errore Ricerca Dispensa: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFilterActive = selectedCategoria != 'Tutte le categorie' && selectedScadenza != 'Tutte le scadenze';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Cerca in dispensa", style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 245, 245, 245),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const[
                  BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                ],
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  _performLocalSearch();
                },
                style: GoogleFonts.montserrat(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Cerca un ingrediente (es. Pollo)...",
                  hintStyle: GoogleFonts.montserrat(color: Colors.grey),
                  
                  border: InputBorder.none, 
                  
                  prefixIcon: const Icon(Icons.search, color: primaryGreen),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus(); 
                      _searchController.clear();
                      _performLocalSearch();
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedCategoria == 'Tutte le categorie' ? Colors.grey[100] : primaryGreen.withOpacity(0.1),
                    border: Border.all(color: selectedCategoria == 'Tutte le categorie' ? Colors.grey[300]! : primaryGreen),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategoria,
                      icon: Icon(Icons.keyboard_arrow_down, color: selectedCategoria == 'Tutte le categorie' ? Colors.grey : primaryGreen),
                      style: GoogleFonts.montserrat(fontSize: 14, color: selectedCategoria == 'Tutte le categorie' ? Colors.black87 : primaryGreen, fontWeight: FontWeight.w600),
                      items: categorieOptions.map((String cat) {
                        return DropdownMenuItem<String>(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => selectedCategoria = newValue);
                          _performLocalSearch(); 
                        }
                      },
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedScadenza == 'Tutte le scadenze' ? Colors.grey[100] : primaryGreen.withOpacity(0.1),
                    border: Border.all(color: selectedScadenza == 'Tutte le scadenze' ? Colors.grey[300]! : primaryGreen),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedScadenza,
                      icon: Icon(Icons.keyboard_arrow_down, color: selectedScadenza == 'Tutte le scadenze' ? Colors.grey : primaryGreen),
                      style: GoogleFonts.montserrat(fontSize: 14, color: selectedScadenza == 'Tutte le scadenze' ? Colors.black87 : primaryGreen, fontWeight: FontWeight.w600),
                      items: scadenzaOptions.map((String val) {
                        return DropdownMenuItem<String>(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => selectedScadenza = newValue);
                          _performLocalSearch(); 
                        }
                      },
                    ),
                  ),
                ),

                if (isFilterActive)
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: ActionChip(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14), 
                      backgroundColor: Colors.red.withOpacity(0.1),
                      side: const BorderSide(color: Colors.red, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      avatar: const Icon(Icons.close, color: Colors.red, size: 16),
                      label: Text("Rimuovi filtro", style: GoogleFonts.montserrat(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 13)),
                      onPressed: () {
                        setState(() {
                          selectedCategoria = 'Tutte le categorie';
                        });
                        _performLocalSearch(); 
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 30),
          
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                : searchResults.isEmpty
                    ? Center(
                        child: Text(
                          "Nessun ingrediente trovato\ncon questi criteri.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: searchResults.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ingrediente = searchResults[index];
                          return IngredientiCard(
                            ingrediente: ingrediente,
                            onTap: () {
                            },
                            onElimina: () async {
                              await DatabaseHelper.instance.deleteIngrediente('dispensa', ingrediente.id!);
                              setState(() {
                                searchResults.removeWhere((item) => item.id == ingrediente.id);
                                dispensa.removeWhere((item) => item.id == ingrediente.id);
                              });
                            },
                            onModifica: () async {
                              final ingredienteModificato = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FormIngredientiScreen(ingredienteEsistente: ingrediente),
                                ),
                              );

                              if (ingredienteModificato != null && ingredienteModificato is Ingredienti) {
                                await DatabaseHelper.instance.updateIngrediente('dispensa', ingredienteModificato);
                                setState(() {
                                  int indexRicerca = searchResults.indexWhere((item) => item.id == ingrediente.id);
                                  if (indexRicerca != -1) {
                                    searchResults[indexRicerca] = ingredienteModificato;
                                  }

                                  int indexGlobale = dispensa.indexWhere((item) => item.id == ingrediente.id);
                                  if (indexGlobale != -1) {
                                    dispensa[indexGlobale] = ingredienteModificato;
                                  }
                                });
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}