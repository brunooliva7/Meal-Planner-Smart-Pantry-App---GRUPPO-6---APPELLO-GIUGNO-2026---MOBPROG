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
  List<Ingredienti> ingredienti = [];

  bool _showForm = false;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _quantitaController = TextEditingController();
  final TextEditingController _unitaController = TextEditingController();
  final TextEditingController _pezziController = TextEditingController();

  void _salvaIngrediente() {
    // Se non ha inserito il nome, non facciamo nulla
    if (_nomeController.text.trim().isEmpty) return;

    setState(() {
      ingredienti.add(
        Ingredienti(
          nome: _nomeController.text.trim(),
          quantita: double.tryParse(_quantitaController.text) ?? 1.0,
          unitaMisura: _unitaController.text.trim().isEmpty ? 'pz' : _unitaController.text.trim(),
          pezzi: int.parse(_pezziController.text),
        )
      );
      
      _showForm = false;
      _nomeController.clear();
      _quantitaController.clear();
      _unitaController.clear();
      _pezziController.clear();
    });
  }

  // È buona norma pulire i controller quando si distrugge la pagina
  @override
  void dispose() {
    _nomeController.dispose();
    _quantitaController.dispose();
    _unitaController.dispose();
    super.dispose();
  }



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
                      setState(() {
                        _showForm = true; 
                      });
                    },
                    icon: const Icon(Icons.playlist_add_rounded, color: primaryGreen),
                  ),
                ),
              ],
            ), 
          ),
          SizedBox(width: 12),
          Expanded(
            child: ingredienti.isEmpty ? Center(
              child:Text(
                "Non hai niente nella dispensa!\nDovresti fare la spesa!",
                style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 15)
              ),
            ) : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: ingredienti.length, // Sostituisci con il nome della tua lista
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ingrediente = ingredienti[index];
                
                return Container(
                  padding: const EdgeInsets.all(16),
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
                      // Icona
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1), 
                          shape: BoxShape.circle
                        ),
                        child: Icon(Icons.kitchen, color: primaryGreen, size: 20),
                      ),
                      const SizedBox(width: 14),
                      
                      // Testi (Nome e Quantità nominale)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ingrediente.nome,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              '${ingrediente.quantita} ${ingrediente.unitaMisura}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                      
                      // Controller Pezzi (+ e -)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () {
                              // TODO: setState per diminuire ingrediente.pezzi
                            },
                          ),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${ingrediente.pezzi}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: primaryGreen),
                            onPressed: () {
                              // TODO: setState per aumentare ingrediente.pezzi
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (_showForm)
              Positioned.fill(
                child: Container(
                  color: Colors.black54, // Sfondo scuro semi-trasparente
                  child: Center(
                    child: SingleChildScrollView( // Aiuta se la tastiera copre lo schermo
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Nuovo Ingrediente",
                                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nomeController,
                                decoration: InputDecoration(
                                  labelText: "Nome",
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _quantitaController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: "Quantità",
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _unitaController,
                                      decoration: InputDecoration(
                                        labelText: "Unità (es. g, ml)",
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // Chiude il form senza salvare
                                      setState(() {
                                        _showForm = false;
                                      });
                                    },
                                    child: const Text("Annulla", style: TextStyle(color: Colors.grey)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _salvaIngrediente, // Chiama la funzione creata in alto
                                    child: const Text("Salva", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      )
    );
  }
}

