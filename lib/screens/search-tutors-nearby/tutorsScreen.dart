import 'package:aralink_app/screens/search-tutors-nearby/locationDetails.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class TutorScreen extends StatelessWidget {
  final String userId;

  TutorScreen({required this.userId});

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> _fetchTutorData() async {
    DatabaseReference tutorsRef =
        FirebaseDatabase.instance.ref('tutors/$userId');
    DatabaseReference tutorProfilesRef =
        FirebaseDatabase.instance.ref('tutor_profiles/$userId');

    DataSnapshot tutorsSnapshot = await tutorsRef.get();
    Map<String, dynamic> tutorData = {};
    if (tutorsSnapshot.exists) {
      tutorData = Map<String, dynamic>.from(tutorsSnapshot.value as Map);
    }
    print('Tutor Data: $tutorData');

    DataSnapshot tutorProfilesSnapshot = await tutorProfilesRef.get();
    Map<String, dynamic> tutorProfileData = {};
    if (tutorProfilesSnapshot.exists) {
      tutorProfileData =
          Map<String, dynamic>.from(tutorProfilesSnapshot.value as Map);
    }
    print('Profile Data: $tutorProfileData');

    return {
      'tutor': tutorData,
      'profile': tutorProfileData,
    };
  }

  Future<void> _bookTutor(BuildContext context) async {
    String studentId = _auth.currentUser!.uid;

    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: const Text('Are you sure you want to book this tutor?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Book Now'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      DatabaseReference bookingsRef =
          FirebaseDatabase.instance.ref('Bookings/$userId/$studentId');
      await bookingsRef.set({
        'status': 'booked',
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have successfully booked a tutor!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        title: Text(
          "Tutor Profile",
          style: GoogleFonts.indieFlower(
              fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Image.asset(
              'assets/images/aralink-main-logo.png',
              width: 40,
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchTutorData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final tutorData = snapshot.data!['tutor'] ?? {};
            final tutorProfileData = snapshot.data!['profile'] ?? {};

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(10),
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              tutorData['profileImageUrl'] ??
                                  "https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2247726673.jpg",
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${tutorData['firstName'] ?? 'First Name'} ${tutorData['lastName'] ?? 'Last Name'}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(tutorData['email'] ?? 'Email not available'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 180,
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final card = profileCompletionCards[index];
                            String value = '';
                            switch (card.title) {
                              case "Day Availability":
                                value = tutorProfileData['dayAvailability'] ??
                                    'N/A';
                                break;
                              case "Preferred Sessions":
                                value = tutorProfileData['preferredSessions'] ??
                                    'N/A';
                                break;
                              case "Rate Per Hour":
                                value =
                                    tutorProfileData['ratePerHour'] ?? 'N/A';
                                break;
                              case "Total Hours":
                                value = tutorProfileData['totalHours'] ?? 'N/A';
                                break;
                              case "Tutoring Grade Level":
                                value = tutorProfileData['gradeLevel'] ?? 'N/A';
                                break;
                              case "Tutoring Subject":
                                value = tutorProfileData['subjects'] ?? 'N/A';
                                break;
                              default:
                                value = 'N/A';
                            }
                            return SizedBox(
                              width: 160,
                              child: Card(
                                elevation: 2,
                                shadowColor: Colors.black12,
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    children: [
                                      Icon(
                                        card.icon,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        card.title,
                                        textAlign: TextAlign.center,
                                      ),
                                      const Spacer(),
                                      Text(
                                        value,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const Padding(padding: EdgeInsets.only(right: 5)),
                          itemCount: profileCompletionCards.length,
                        ),
                      ),
                      const SizedBox(height: 35),
                      ...List.generate(
                        customListTiles.length,
                        (index) {
                          final tile = customListTiles[index];
                          String subtitle = '';
                          switch (tile.title) {
                            case "Address":
                              subtitle = tutorProfileData['address'] ?? 'N/A';
                              break;
                            case "Tagline":
                              subtitle = tutorProfileData['tagline'] ?? 'N/A';
                              break;
                            case "Location":
                              subtitle = 'Tap to view location';
                              break;
                            default:
                              subtitle = 'N/A';
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Card(
                              elevation: 4,
                              shadowColor: Colors.black12,
                              child: ListTile(
                                leading: Icon(tile.icon),
                                title: Text(tile.title),
                                subtitle: Text(subtitle),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  if (tile.title == "Location") {
                                    final location =
                                        tutorData['location'] ?? {};
                                    final latitude =
                                        (location['latitude'] as double?)
                                                ?.toString() ??
                                            'N/A';
                                    final longitude =
                                        (location['longitude'] as double?)
                                                ?.toString() ??
                                            'N/A';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LocationDetailsScreen(
                                          latitude: latitude,
                                          longitude: longitude,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _bookTutor(context),
                      child: Text('Book Now',
                          style: GoogleFonts.indieFlower(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}

class ProfileCompletionCard {
  final String title;
  final IconData icon;
  ProfileCompletionCard({
    required this.title,
    required this.icon,
  });
}

List<ProfileCompletionCard> profileCompletionCards = [
  ProfileCompletionCard(
    title: "Day Availability",
    icon: Iconsax.sun,
  ),
  ProfileCompletionCard(
    title: "Preferred Sessions",
    icon: Iconsax.timer,
  ),
  ProfileCompletionCard(
    title: "Rate Per Hour",
    icon: Iconsax.money,
  ),
  ProfileCompletionCard(
    title: "Total Hours",
    icon: Iconsax.clock,
  ),
  ProfileCompletionCard(
    title: "Tutoring Grade Level",
    icon: Iconsax.ruler,
  ),
  ProfileCompletionCard(
    title: "Tutoring Subject",
    icon: Iconsax.book,
  ),
];

class CustomListTile {
  final String title;
  final IconData icon;
  CustomListTile({
    required this.title,
    required this.icon,
  });
}

List<CustomListTile> customListTiles = [
  CustomListTile(
    title: "Address",
    icon: Iconsax.map_1,
  ),
  CustomListTile(
    title: "Tagline",
    icon: Iconsax.quote_down,
  ),
  CustomListTile(
    title: "Location",
    icon: Iconsax.location,
  ),
];
