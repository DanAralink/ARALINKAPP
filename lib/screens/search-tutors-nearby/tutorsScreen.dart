import 'package:aralink_app/screens/search-tutors-nearby/locationDetails.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class TutorScreen extends StatelessWidget {
  final String userId;

  TutorScreen({required this.userId});

  Future<Map<String, dynamic>> _fetchTutorData() async {
    // Reference to the Firebase Realtime Database
    DatabaseReference tutorsRef =
        FirebaseDatabase.instance.ref('tutors/$userId');
    DatabaseReference tutorProfilesRef =
        FirebaseDatabase.instance.ref('tutor_profiles/$userId');

    // Fetch data from the 'tutors' node
    DataSnapshot tutorsSnapshot = await tutorsRef.get();
    Map<String, dynamic> tutorData = {};
    if (tutorsSnapshot.exists) {
      tutorData = Map<String, dynamic>.from(tutorsSnapshot.value as Map);
    }
    print('Tutor Data: $tutorData'); // Debugging line

    // Fetch data from the 'tutor_profiles' node
    DataSnapshot tutorProfilesSnapshot = await tutorProfilesRef.get();
    Map<String, dynamic> tutorProfileData = {};
    if (tutorProfilesSnapshot.exists) {
      tutorProfileData =
          Map<String, dynamic>.from(tutorProfilesSnapshot.value as Map);
    }
    print('Profile Data: $tutorProfileData'); // Debugging line

    // Return the data as a map
    return {
      'tutor': tutorData,
      'profile': tutorProfileData,
    };
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
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final tutorData = snapshot.data!['tutor'] ?? {};
            final tutorProfileData = snapshot.data!['profile'] ?? {};

            // Populate UI with the fetched data
            return ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // COLUMN THAT WILL CONTAIN THE PROFILE
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
                // Profile Data Section
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
                          value = tutorProfileData['dayAvailability'] ?? 'N/A';
                          break;
                        case "Preferred Sessions":
                          value =
                              tutorProfileData['preferredSessions'] ?? 'N/A';
                          break;
                        case "Rate Per Hour":
                          value = tutorProfileData['ratePerHour'] ?? 'N/A';
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
                // Custom List Tiles Section
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
                        final location = tutorData['location'] ?? {};
                        final latitude = location['latitude'];
                        final longitude = location['longitude'];
                        subtitle =
                            'Tap to view location';
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
                              final location = tutorData['location'] ?? {};
                              final latitude = (location['latitude'] as double?)
                                      ?.toString() ??
                                  'N/A';
                              final longitude =
                                  (location['longitude'] as double?)
                                          ?.toString() ??
                                      'N/A';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocationDetailsScreen(
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
    icon: Iconsax.timer_1,
  ),
  ProfileCompletionCard(
    title: "Rate Per Hour",
    icon: Iconsax.diagram,
  ),
  ProfileCompletionCard(
    title: "Total Hours",
    icon: Iconsax.clock,
  ),
  ProfileCompletionCard(
    title: "Tutoring Grade Level",
    icon: Iconsax.level,
  ),
  ProfileCompletionCard(
    title: "Tutoring Subject",
    icon: Iconsax.book,
  ),
];

class CustomListTile {
  final IconData icon;
  final String title;
  CustomListTile({
    required this.icon,
    required this.title,
  });
}

List<CustomListTile> customListTiles = [
  CustomListTile(
    icon: Iconsax.home,
    title: "Address",
  ),
  CustomListTile(
    icon: Iconsax.text_italic,
    title: "Tagline",
  ),
  CustomListTile(
    title: "Location",
    icon: Iconsax.location,
  ),
];
