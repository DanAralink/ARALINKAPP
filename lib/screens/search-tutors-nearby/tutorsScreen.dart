import 'dart:convert';
import 'package:aralink_app/screens/search-tutors-nearby/locationDetails.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';

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

  Future<void> _openUrl(String? urli) async {
    if (urli != null) {
      // Use FlutterWebBrowser to open the URL
      FlutterWebBrowser.openWebPage(
        url: urli,
        customTabsOptions: const CustomTabsOptions(
          colorScheme: CustomTabsColorScheme.dark,
          toolbarColor: Color.fromARGB(255, 255, 240, 183),
          secondaryToolbarColor: Colors.teal,
          navigationBarColor: Color.fromARGB(255, 255, 240, 183),
          shareState: CustomTabsShareState.on,
          instantAppsEnabled: true,
          showTitle: true,
          urlBarHidingEnabled: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          barCollapsingEnabled: true,
          preferredBarTintColor: Colors.teal,
          preferredControlTintColor: Color.fromARGB(255, 255, 240, 183),
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
          modalPresentationCapturesStatusBarAppearance: true,
        ),
      );
    } else {
      print("URL is null, cannot launch");
    }
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 255, 240, 183),
                minimumSize: const Size(100, 40),
              ),
              child: const Text('Book Now', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        DatabaseReference tutorRef =
            FirebaseDatabase.instance.ref('tutors/$userId');
        DataSnapshot tutorSnapshot = await tutorRef.get();

        if (!tutorSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Tutor data not found.')),
          );
          return;
        }

        Map<String, dynamic> tutorData =
            Map<String, dynamic>.from(tutorSnapshot.value as Map);
        String tutorFcmToken = tutorData['fcmToken'] ?? '';

        DatabaseReference tuteeRef =
            FirebaseDatabase.instance.ref('users/$studentId');
        DataSnapshot tuteeSnapshot = await tuteeRef.get();

        if (!tuteeSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Tutee data not found.')),
          );
          return;
        }

        Map<String, dynamic> tuteeData =
            Map<String, dynamic>.from(tuteeSnapshot.value as Map);
        String tuteeFcmToken = tuteeData['fcmToken'] ?? '';

        DatabaseReference bookingsRef =
            FirebaseDatabase.instance.ref('Bookings/$userId/$studentId');

        await bookingsRef.set({
          'isRequestingCancel': false,
          'status': 'Pending',
          'timestamp': DateTime.now().toIso8601String(),
          'tutor_id': userId,
          'tutee_id': studentId,
          'tutor_fcmToken': tutorFcmToken,
          'tutee_fcmToken': tuteeFcmToken,
        });

        await _sendPushNotification(
          tutorFcmToken: tutorFcmToken,
          title: "New Booking Request!",
          body:
              "You have a new booking request from tutee: ${tuteeData['firstName']} ${tuteeData['lastName']}.",
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Center(child: Text('You have successfully booked a tutor!')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking tutor: $e')),
        );
      }
    }
  }

  Future<void> _sendPushNotification({
    required String tutorFcmToken,
    required String title,
    required String body,
  }) async {
    const String projectId = 'aralink-d9c4c';
    final String url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    try {
      String accessToken = await _getAccessToken();

      final Map<String, dynamic> message = {
        'message': {
          'token': tutorFcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'new',
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully.');
      } else {
        print('Failed to send push notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  Future<String> _getAccessToken() async {
    try {
      final serviceAccountKey =
          await rootBundle.loadString('assets/aralink-d9c4c-87ed3286d716.json');

      final Map<String, dynamic> keyData = jsonDecode(serviceAccountKey);

      final accountCredentials = ServiceAccountCredentials.fromJson(keyData);

      const List<String> scopes = [
        'https://www.googleapis.com/auth/cloud-platform',
      ];

      final client = await clientViaServiceAccount(accountCredentials, scopes);

      final accessToken = client.credentials.accessToken;

      return accessToken.data;
    } catch (e) {
      throw Exception('Error getting access token: $e');
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
                            case "Credentials":
                              subtitle = 'Tap to view credentials';
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
                                  } else if (tile.title == "Credentials") {
                                      _openUrl(tutorData['credentialLink']);
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
  CustomListTile(
    title: "Credentials",
    icon: Iconsax.link,
  ),
];
