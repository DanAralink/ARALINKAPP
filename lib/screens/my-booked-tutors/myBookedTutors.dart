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

  Future<List<Map<String, dynamic>>> _fetchBookedTutors() async {
    String studentId = _auth.currentUser!.uid;
    print('Student ID: $studentId'); 

    DatabaseReference bookingsRef = FirebaseDatabase.instance.ref('Bookings');

    DataSnapshot bookingsSnapshot = await bookingsRef.get();
    print('Bookings Snapshot: ${bookingsSnapshot.value}');

    List<Map<String, dynamic>> bookedTutors = [];

    if (bookingsSnapshot.exists) {
      Map<dynamic, dynamic> bookingsMap =
          bookingsSnapshot.value as Map<dynamic, dynamic>;

      for (var tutorId in bookingsMap.keys) {
        Map<dynamic, dynamic>? tutorBookings =
            bookingsMap[tutorId] as Map<dynamic, dynamic>?;

        if (tutorBookings != null && tutorBookings.containsKey(studentId)) {
          Map<dynamic, dynamic>? bookingInfo =
              tutorBookings[studentId] as Map<dynamic, dynamic>?;

          if (bookingInfo != null && bookingInfo['status'] == 'booked') {
            print('Booking found for Tutor ID: $tutorId by Student: $studentId');

            DatabaseReference tutorProfileRef =
                FirebaseDatabase.instance.ref('tutor_profiles/$tutorId');
            DataSnapshot tutorProfileSnapshot = await tutorProfileRef.get();

            if (tutorProfileSnapshot.exists) {
              Map<dynamic, dynamic> tutorProfile =
                  tutorProfileSnapshot.value as Map<dynamic, dynamic>;

              DatabaseReference tutorDetailsRef =
                  FirebaseDatabase.instance.ref('tutors/$tutorId');
              DataSnapshot tutorDetailsSnapshot = await tutorDetailsRef.get();

              if (tutorDetailsSnapshot.exists) {
                Map<dynamic, dynamic> tutorDetails =
                    tutorDetailsSnapshot.value as Map<dynamic, dynamic>;

                bookedTutors.add({
                  'tutorId': tutorId,
                  'profile': Map<String, dynamic>.from(tutorProfile),
                  'details': Map<String, dynamic>.from(tutorDetails),
                  'booking': Map<String, dynamic>.from(bookingInfo!),
                });
              } else {
                print('No details found for Tutor ID: $tutorId');
              }
            } else {
              print('No profile found for Tutor ID: $tutorId'); 
            }
          } else {
            print('No valid booking info for Tutor ID: $tutorId');
          }
        } else {
          print('No bookings found for Tutor ID: $tutorId or TutorBookings is null');
        }
      }
    } else {
      print('No bookings found');
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
                              userId: studentId), 
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
