import 'package:aralink_app/screens/my-booked-tutors/myBookedTutors.dart';
import 'package:aralink_app/screens/my-profile/myProfile.dart';
import 'package:aralink_app/screens/search-tutors-nearby/searchTutorsNearby.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDashboardCard(
              context,
              icon: Iconsax.user,
              title: 'Profile',
              description: 'View and edit your profile details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyProfile()),
                );
              },
              backgroundImage: 'assets/images/cardsbg.png',
            ),
            _buildDashboardCard(
              context,
              icon: Iconsax.book,
              title: 'My Bookings',
              description: 'Check your booked sessions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyBookedTutors()),
                );
              },
              backgroundImage: 'assets/images/cardsbg.png',
            ),
            _buildDashboardCard(
              context,
              icon: Iconsax.search_normal_14,
              title: 'Search Tutors',
              description: 'Find tutors nearby or online',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchTutorsNearby()),
                );
              },
              backgroundImage: 'assets/images/cardsbg.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required String backgroundImage,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: ListTile(
          leading: Icon(icon, size: 40, color: Colors.white),
          title: Text(
            title,
            style: GoogleFonts.indieFlower(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            description,
            style: GoogleFonts.indieFlower(fontSize: 14, color: Colors.white70),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
