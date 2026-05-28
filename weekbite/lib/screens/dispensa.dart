import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DispensaScreen extends StatelessWidget {
  const DispensaScreen({super.key});

  final Color primaryGreen = const Color.fromARGB(255, 75, 187, 120); 

  @override
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Allinea il testo a sinistra
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 16, right: 20, bottom: 4),
            child: Text(
              "La mia Dispensa", // Inserisci qui il tuo testo
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildSearchBar(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100], 
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: primaryGreen, size: 20),
              const SizedBox(width: 12),
              Text('Cerca ingredienti nella tua dipensa...', 
                style: GoogleFonts.montserrat(color: Colors.grey, fontSize: 15)
              ),
            ],
          ),
        ),
      ),
    );
  }
}