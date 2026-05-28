import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Il controller serve per leggere e modificare il testo dentro la barra
  final TextEditingController _searchController = TextEditingController();
  
  // Questa variabile tiene traccia di quello che l'utente sta scrivendo
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Stesso sfondo del main_screen
      
      // L'AppBar è la barra in alto. Invece del titolo, ci mettiamo dentro il campo di testo!
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87), // Freccia indietro nera
        title: TextField(
          controller: _searchController,
          autofocus: true, // Apre la tastiera in automatico
          decoration: InputDecoration(
            hintText: "Cerca ricette, ingredienti...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
            
            // Pulsante "X" per svuotare la barra se c'è del testo
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = ""; // Azzera la ricerca
                      });
                    },
                  )
                : null,
          ),
          // Ogni volta che digiti una lettera, aggiorna la schermata
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
      
      // Il corpo della pagina cambia in base a se hai scritto qualcosa o meno
      body: _searchQuery.isEmpty
          ? _buildRicercheRecenti() // Mostra i bottoncini finti
          : _buildRisultatiMock(),  // Mostra il testo che stai cercando
    );
  }

  // --- SCHERMATA INIZIALE (Barra vuota) ---
  Widget _buildRicercheRecenti() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ricerche Recenti",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          // Wrap mette i bottoncini uno a fianco all'altro e va a capo da solo
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chipRicerca("Pollo"),
              _chipRicerca("Pasta al forno"),
              _chipRicerca("Zucchine"),
              _chipRicerca("Dolci veloci"),
            ],
          )
        ],
      ),
    );
  }

  // Widget riutilizzabile per creare i bottoncini stile "etichetta"
  Widget _chipRicerca(String testo) {
    return ActionChip(
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey[300]!),
      label: Text(testo),
      onPressed: () {
        // Se l'utente clicca il chip, il testo va nella barra di ricerca in automatico
        _searchController.text = testo;
        setState(() {
          _searchQuery = testo;
        });
      },
    );
  }

  // --- SCHERMATA DI RICERCA (Mentre stai scrivendo) ---
  Widget _buildRisultatiMock() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.manage_search, size: 70, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'Ricerca per: "$_searchQuery"',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Qui sotto metteremo i risultati API\nquando premerai invio!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}