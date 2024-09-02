import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class HomeSetBookingProfile extends StatelessWidget {
  const HomeSetBookingProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        centerTitle: true,
        title: Text(
          'Set Booking Profile',
          style: GoogleFonts.indieFlower(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
    );
  }
}
