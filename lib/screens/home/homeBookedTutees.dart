import 'package:aralink_app/screens/my-booked-tutees/tutorLearningMaterial.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeBookedTutees extends StatefulWidget {
  const HomeBookedTutees({super.key});

  @override
  _HomeBookedTuteesState createState() => _HomeBookedTuteesState();
}

class _HomeBookedTuteesState extends State<HomeBookedTutees> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> _fetchBookedTutees() async {
    String tutorId = _auth.currentUser!.uid; // Get current tutor ID
    DatabaseReference bookingsRef = FirebaseDatabase.instance.ref('Bookings');

    // Get all bookings
    DataSnapshot bookingsSnapshot = await bookingsRef.get();

    List<Map<String, dynamic>> bookedTutees = [];

    if (bookingsSnapshot.exists) {
      Map<dynamic, dynamic> bookingsMap =
          bookingsSnapshot.value as Map<dynamic, dynamic>;

      // Iterate through each tutor's bookings
      if (bookingsMap.containsKey(tutorId)) {
        Map<dynamic, dynamic>? tutorBookings =
            bookingsMap[tutorId] as Map<dynamic, dynamic>?;

        if (tutorBookings != null) {
          // Iterate through each booked tutee
          for (var studentId in tutorBookings.keys) {
            Map<dynamic, dynamic>? bookingInfo =
                tutorBookings[studentId] as Map<dynamic, dynamic>?;

            if (bookingInfo != null && bookingInfo['status'] == 'booked') {
              // Fetch tutee profile
              DatabaseReference tuteeProfileRef =
                  FirebaseDatabase.instance.ref('users/$studentId');
              DataSnapshot tuteeProfileSnapshot = await tuteeProfileRef.get();

              if (tuteeProfileSnapshot.exists) {
                Map<dynamic, dynamic> tuteeProfile =
                    tuteeProfileSnapshot.value as Map<dynamic, dynamic>;

                bookedTutees.add({
                  'studentId': studentId,
                  'profile': Map<String, dynamic>.from(tuteeProfile),
                  'booking': Map<String, dynamic>.from(bookingInfo),
                });
              }
            }
          }
        }
      }
    }

    return bookedTutees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Iconsax.arrow_left_2),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        centerTitle: true,
        title: Text(
          'Booked Tutees',
          style: GoogleFonts.indieFlower(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookedTutees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final bookedTutees = snapshot.data!;

            if (bookedTutees.isEmpty) {
              return const Center(child: Text('No tutees booked yet.'));
            }

            return ListView.builder(
              itemCount: bookedTutees.length,
              itemBuilder: (context, index) {
                final tutee =
                    bookedTutees[index]['profile']; // Profile of the tutee
                final booking = bookedTutees[index]['booking']; // Booking info
                final studentId =
                    bookedTutees[index]['studentId']; // Get studentId

                return Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(
                        tutee['firstName'] != null
                            ? tutee['firstName'][0]
                            : 'T',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      "${tutee['firstName'] ?? 'First Name'} ${tutee['lastName'] ?? 'Last Name'}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${booking['status']}"),
                        Text("Booked on: ${booking['timestamp'] ?? 'N/A'}"),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Check if studentId is not null before navigating
                      if (studentId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TutorLearningMaterialsScreen(
                                studentId:
                                    studentId), // Pass the studentId here
                          ),
                        );
                      } else {
                        // Handle the case where studentId is null
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Error: Student ID is missing')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
