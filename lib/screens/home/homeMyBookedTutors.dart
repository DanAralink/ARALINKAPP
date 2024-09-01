import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeMyBookedTutors extends StatelessWidget {
  const HomeMyBookedTutors({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        centerTitle: true,
        title: Text(
          'My Booked Tutors',
          style: GoogleFonts.indieFlower(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
    );
  }
}
