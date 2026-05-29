import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Ingrediente {
  final String nome;
  final double quantita;
  final String tipo; // Es: 'g', 'ml', 'pz', 'bottiglia'
  int pezzi; 

  Ingrediente({
    required this.nome,
    required this.quantita,
    required this.tipo,
    required this.pezzi,
  });
}


class DispensaScreen extends StatefulWidget {
  const DispensaScreen({super.key});
  @override
  State<DispensaScreen> createState() => _DispensaScreenState();
}

class _DispensaScreenState extends State<DispensaScreen> {
  final Color primaryGreen = const Color.fromARGB(255, 75, 187, 120); 

  // La lista deve stare QUI dentro lo State, così setState può aggiornarla!
  List<Ingrediente> ingredientiDispensa = [
    Ingrediente(nome: "Spaghetti", quantita: 500, tipo: "g", pezzi: 1),
    Ingrediente(nome: "Passata di pomodoro", quantita: 1, tipo: "bottiglia", pezzi: 3),
    Ingrediente(nome: "Olio Extravergine", quantita: 750, tipo: "ml", pezzi: 5),
    Ingrediente(nome: "Sale grosso", quantita: 1, tipo: "kg", pezzi: 6),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // 1. TITOLO
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 4),
            child: Text(
              "La mia Dispensa", 
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          
          // 2. BARRA DI RICERCA + PULSANTE AGGIUNGI
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () {
                      // Azione al tap sulla barra
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: primaryGreen, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Cerca...', 
                            style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 15)
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Container(
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      print("Pulsante + premuto!");
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height:12),
          
          // 3. LISTA DELLA DISPENSA
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                
                _buildSectionTitle("In Dispensa", Icons.kitchen),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ingredientiDispensa.length,
                  itemBuilder: (context, index) {
                    final ingrediente = ingredientiDispensa[index]; 
                    
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.restaurant_menu, color: primaryGreen, size: 20),
                        ),
                        title: Text(
                          ingrediente.nome, 
                          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14)
                        ),
                        subtitle: Text(
                          "${ingrediente.quantita.toStringAsFixed(ingrediente.quantita.truncateToDouble() == ingrediente.quantita ? 0 : 1)} ${ingrediente.tipo}",
                          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black54),
                        ),
                        
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, // Fondamentale per non dare errore nel ListTile
                          children: [
                            // Bottone MENO
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  if (ingrediente.pezzi > 1) {
                                    ingrediente.pezzi--;
                                  } else {
                                    // Se scende sotto 1, rimuovilo dalla lista!
                                    ingredientiDispensa.removeAt(index);
                                  }
                                });
                              },
                            ),
                            
                            // Testo con il numero di PEZZI
                            SizedBox(
                              width: 24, // Larghezza fissa per evitare salti grafici
                              child: Text(
                                '${ingrediente.pezzi}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            
                            // Bottone PIÙ
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: primaryGreen),
                              onPressed: () {
                                setState(() {
                                  ingrediente.pezzi++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 100), // Spazio per la bottom bar
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==========================================================
  // WIDGET DI SUPPORTO INTERNI ALLA CLASSE
  // ==========================================================
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}