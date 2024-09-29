import 'package:aralink_app/screens/my-booked-tutors/learningMaterials.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class MyBookedTutors extends StatefulWidget {
  const MyBookedTutors({super.key});

  @override
  _MyBookedTutorsState createState() => _MyBookedTutorsState();
}

class _MyBookedTutorsState extends State<MyBookedTutors> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to fetch booked tutors and their profiles
  Future<List<Map<String, dynamic>>> _fetchBookedTutors() async {
    String studentId = _auth.currentUser!.uid;
    print('Student ID: $studentId'); // Debug: Check if student ID is correct

    DatabaseReference bookingsRef = FirebaseDatabase.instance.ref('Bookings');

    // Get all bookings
    DataSnapshot bookingsSnapshot = await bookingsRef.get();
    print('Bookings Snapshot: ${bookingsSnapshot.value}'); // Debug: Print bookings snapshot

    List<Map<String, dynamic>> bookedTutors = [];

    if (bookingsSnapshot.exists) {
      // Convert to Map<String, dynamic> carefully
      Map<dynamic, dynamic> bookingsMap =
          bookingsSnapshot.value as Map<dynamic, dynamic>;

      // Iterate through each tutor's bookings
      for (var tutorId in bookingsMap.keys) {
        // Get bookings for each tutor
        Map<dynamic, dynamic>? tutorBookings =
            bookingsMap[tutorId] as Map<dynamic, dynamic>?;

        if (tutorBookings != null && tutorBookings.containsKey(studentId)) {
          Map<dynamic, dynamic>? bookingInfo =
              tutorBookings[studentId] as Map<dynamic, dynamic>?;

          if (bookingInfo != null && bookingInfo['status'] == 'booked') {
            print('Booking found for Tutor ID: $tutorId by Student: $studentId'); // Debug

            // Fetch tutor profile from 'tutor_profiles' node
            DatabaseReference tutorProfileRef =
                FirebaseDatabase.instance.ref('tutor_profiles/$tutorId');
            DataSnapshot tutorProfileSnapshot = await tutorProfileRef.get();

            if (tutorProfileSnapshot.exists) {
              Map<dynamic, dynamic> tutorProfile =
                  tutorProfileSnapshot.value as Map<dynamic, dynamic>;

              // Fetch tutor details from 'tutors' node
              DatabaseReference tutorDetailsRef =
                  FirebaseDatabase.instance.ref('tutors/$tutorId');
              DataSnapshot tutorDetailsSnapshot = await tutorDetailsRef.get();

              if (tutorDetailsSnapshot.exists) {
                Map<dynamic, dynamic> tutorDetails =
                    tutorDetailsSnapshot.value as Map<dynamic, dynamic>;

                bookedTutors.add({
                  'tutorId': tutorId,
                  'profile': Map<String, dynamic>.from(tutorProfile),
                  'details': Map<String, dynamic>.from(tutorDetails), // Store tutor details
                  'booking': Map<String, dynamic>.from(bookingInfo!), // Ensure it's a Map<String, dynamic>
                });
              } else {
                print('No details found for Tutor ID: $tutorId'); // Debug: Tutor details not found
              }
            } else {
              print('No profile found for Tutor ID: $tutorId'); // Debug: Tutor profile not found
            }
          } else {
            print('No valid booking info for Tutor ID: $tutorId'); // Debug: No booking info found
          }
        } else {
          print('No bookings found for Tutor ID: $tutorId or TutorBookings is null'); // Debug
        }
      }
    } else {
      print('No bookings found'); // Debug: No bookings found
    }

    return bookedTutors;
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    String studentId = auth.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBookedTutors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final bookedTutors = snapshot.data!;

            if (bookedTutors.isEmpty) {
              return const Center(child: Text('No tutors booked yet.'));
            }

            return ListView.builder(
              itemCount: bookedTutors.length,
              itemBuilder: (context, index) {
                final tutorProfile = bookedTutors[index]['profile'];
                final tutorDetails = bookedTutors[index]['details'];
                final booking = bookedTutors[index]['booking'];

                return Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Text(
                        tutorDetails['firstName'] != null
                            ? tutorDetails['firstName'][0]
                            : 'T',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      "${tutorDetails['firstName'] ?? 'First Name'} ${tutorDetails['lastName'] ?? 'Last Name'}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Subject: ${tutorProfile['subjects'] ?? 'N/A'}"),
                        Text("Rate: ${tutorProfile['ratePerHour'] ?? 'N/A'} per hour"),
                        Text("Status: ${booking['status']}"),
                        Text("Booked on: ${booking['timestamp'] ?? 'N/A'}"),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LearningMaterialsScreen(
                              userId: studentId), // Use the correct tutorId
                        ),
                      );
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
