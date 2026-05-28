import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DispensaScreen extends StatelessWidget {
  const DispensaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'La mia dispensa',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text('card dispensa...'),
        ],
      ),
    );
  }
}
