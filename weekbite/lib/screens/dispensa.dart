import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weekbite/main.dart';

class Ingredienti{
  final String nome; //nome del prodotto
  final double quantita; //quantità nominale del prodotto
  final String unitaMisura; //unità di misura del prodotto
  int pezzi; //pezzi del prodotto

  Ingredienti({
    required this.nome, 
    required this.quantita,
    required this.unitaMisura,
    required this.pezzi,
  });
}

class DispensaScreen extends StatefulWidget{
  const DispensaScreen({super.key});

  @override
  State<DispensaScreen> createState() => _DispensaScreenState();
}

class _DispensaScreenState extends State<DispensaScreen>{
  List<Ingredienti> dispensa = [
    Ingredienti(nome: "Totti", quantita: 500, unitaMisura: "g", pezzi: 1),
    Ingredienti(nome: "Passata di pomodoro", quantita: 1, unitaMisura: "bottiglia", pezzi: 3),
  ];

  @override 
  Widget build(BuildContext context){
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              "La mia Dispensa",
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold, color:Colors.black,),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: (){
                      //funzione di ricerca
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 245, 245, 245),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const[
                          BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color:primaryGreen, size:20),
                          const SizedBox(width: 12), 
                          Text(
                            "Cerca ingredienti...",
                            style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 15)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 245, 245),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const[
                      BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                    ],
                  ),
                  child: IconButton(
                    onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Sostituisci "FormIngredientiScreen" con il nome reale della tua classe
                          builder: (context) => const ListaIngredientiScreen(), 
                        ),
                      );
                    },
                    icon: const Icon(Icons.playlist_add_rounded, color: primaryGreen),
                  ),
                ),
              ],
            ), 
          ),
          SizedBox(width: 12),
          Padding( 
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Ingredienti nella dispensa: ${dispensa.length}",
              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color:Colors.grey),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: dispensa.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final dispensa_ing = dispensa[i];
                return _IngredientiCard(
                  ingrediente: dispensa_ing,
                  onTap: () {
                    // Navigator.push = equivalente di navigation.navigate('Study', ...)
                    
                  },
                );
              },
            ),
          )
        ],
      )
    );
  }
}

class _IngredientiCard extends StatelessWidget {
  final Ingredienti ingrediente;
  final VoidCallback onTap;

  const _IngredientiCard({required this.ingrediente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingrediente.nome,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryGreen,
                    ),
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

class ListaIngredientiScreen extends StatefulWidget{
  const ListaIngredientiScreen({super.key});

  @override
  State <ListaIngredientiScreen> createState() => _ListaIngredientiScreen();
}

class _ListaIngredientiScreen extends State<ListaIngredientiScreen>{ 
  List<Ingredienti> lista = [];
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context, false), 
        ),
        title: Text("Lista della spesa", style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding( 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                "Ingredienti nella lista spesa: ${lista.length}",
               style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.bold, color:Colors.grey),
              ),
            ),
            SizedBox(width: 12),          
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // Sostituisci "FormIngredientiScreen" con il nome reale della tua classe
                          builder: (context) => const FormIngredientiScreen(), 
                        ),
                      );
                    },
        child: const Icon(Icons.playlist_add_rounded, color: primaryGreen),
        backgroundColor: Colors.white,
      ),
    );
  }
}

class FormIngredientiScreen extends StatefulWidget{
  const FormIngredientiScreen({super.key});

  @override
  State <FormIngredientiScreen> createState() => _FormIngredientiScreen();
}

class _FormIngredientiScreen extends State<FormIngredientiScreen>{ 
  final _nomeController = TextEditingController();
  final _quantitaController = TextEditingController();
  final _unitaController = TextEditingController();
  final _pezziController = TextEditingController();

  @override
  Widget build(BuildContext context){
    final List<String> _unitaDiMisura = ['g', 'kg', 'ml', 'l', 'pz', 'q.b.'];
    String _unitaSelezionata = 'g';
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen),
          onPressed: () => Navigator.pop(context, false), 
        ),
        title: Text("Aggiunta ingrediente", style: GoogleFonts.montserrat(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Un po' di spazio dai bordi
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FORM NOME
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: "Nome ingrediente", border: OutlineInputBorder(),),
              ),
              const SizedBox(height: 20),
              
              // FORM QUANTITÀ
              TextField(
                controller: _quantitaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantità (es. 500)",border: OutlineInputBorder(),),
              ),
              const SizedBox(height: 20),

              // FORM UNITÀ DI MISURA
              DropdownMenu<String>(
                initialSelection: _unitaSelezionata,
                label: const Text("Unità di misura"),
                // expandedInsets a zero fa in modo che il menù si allarghi 
                // esattamente come i TextField sopra e sotto di lui
                expandedInsets: EdgeInsets.zero, 
                menuHeight: 200, // Limita l'altezza massima per non fargli occupare tutto lo schermo
                dropdownMenuEntries: _unitaDiMisura.map((String unita) {
                  return DropdownMenuEntry<String>(
                    value: unita,
                    label: unita,
                    style: MenuItemButton.styleFrom(
                      textStyle: GoogleFonts.montserrat(), // Usa il tuo font anche dentro il menù
                    ),
                  );
                }).toList(),
                onSelected: (String? nuovoValore) {
                  setState(() {
                    if (nuovoValore != null) {
                      _unitaSelezionata = nuovoValore;
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // FORM PEZZI
              TextField(
                controller: _pezziController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Pezzi (es. 1)", border: OutlineInputBorder(),),
              ),
              const Spacer(), 
        
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const[
                        BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                      ],
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        "Annulla",
                        style: GoogleFonts.montserrat(
                          color: primaryGreen, // Usa il tuo grigio
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const[
                        BoxShadow(color: Color.fromARGB(31, 0, 0, 0), blurRadius: 4,offset: Offset(0,2))
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        final nuovoIngrediente = Ingredienti(
                          nome: _nomeController.text,
                          quantita: double.tryParse(_quantitaController.text) ?? 0,
                          unitaMisura: _unitaSelezionata,
                          pezzi: int.tryParse(_pezziController.text) ?? 1,
                        );
                      },
                      child: Text(
                        "Conferma",
                        style: GoogleFonts.montserrat(
                          color: Colors.white, // Usa il tuo grigio
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}