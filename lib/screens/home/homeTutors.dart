import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class HomeTutorsScreen extends StatefulWidget {
  const HomeTutorsScreen({super.key});

  @override
  _HomeTutorsScreenState createState() => _HomeTutorsScreenState();
}

class _HomeTutorsScreenState extends State<HomeTutorsScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late PageController _pageController;

  List<String> imageUrls = [
    'https://via.placeholder.com/350x150/FF5733/FFFFFF?text=Image+1',
    'https://via.placeholder.com/350x150/33FF57/FFFFFF?text=Image+2',
    'https://via.placeholder.com/350x150/3357FF/FFFFFF?text=Image+3',
    'https://via.placeholder.com/350x150/FFFF33/FFFFFF?text=Image+4',
  ];

  List<Map<String, dynamic>> feedbacks = [];
  Map<String, Map<String, dynamic>> tutors =
      {}; // Map to store tutor data by ID
  Map<String, Map<String, dynamic>> tutees =
      {}; // Map to store tutee data by ID

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchData();
    // Auto sliding timer for banner images
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage >= imageUrls.length) nextPage = 0;
        _pageController.animateToPage(nextPage,
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fetch data from Firebase Realtime Database
  Future<void> _fetchData() async {
    final feedbackRef = _database.ref('Feedbacks');
    final tutorRef = _database.ref('tutors');
    final userRef = _database.ref('users');

    // Fetch feedbacks
    final feedbackSnapshot = await feedbackRef.get();
    final tutorSnapshot = await tutorRef.get();
    final userSnapshot = await userRef.get();

    if (feedbackSnapshot.exists) {
      print('Feedback Data Found');
      setState(() {
        feedbacks = [];
        (feedbackSnapshot.value as Map).forEach((userId, tutorsData) {
          (tutorsData as Map).forEach((tutorId, feedbackData) {
            feedbackData.forEach((feedbackId, feedbackDetails) {
              feedbacks.add({
                'tuteeId': userId,
                'tutorId': tutorId,
                'feedbackMessage': feedbackDetails['feedbackMessage'],
                'ratings': feedbackDetails['ratings'],
              });
            });
          });
        });
      });
    } else {
      print('No feedback data found');
    }

    // Fetch tutors
    if (tutorSnapshot.exists) {
      print('Tutor Data Found');
      setState(() {
        tutors = Map<String, Map<String, dynamic>>.from(
          (tutorSnapshot.value as Map).map((key, value) {
            return MapEntry(
              key,
              {
                'firstName': value['firstName'],
                'lastName': value['lastName'],
                'credentialLink': value['credentialLink'],
                'email': value['email'],
              },
            );
          }),
        );
      });
    } else {
      print('No tutor data found');
    }

    // Fetch tutees
    if (userSnapshot.exists) {
      print('Tutee Data Found');
      setState(() {
        tutees = Map<String, Map<String, dynamic>>.from(
          (userSnapshot.value as Map).map((key, value) {
            return MapEntry(
              key,
              {
                'firstName': value['firstName'],
                'lastName': value['lastName'],
              },
            );
          }),
        );
      });
    } else {
      print('No tutee data found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Banner Slideshow
            SizedBox(
              height: 200, // Adjust height as needed
              child: PageView.builder(
                controller: _pageController,
                itemCount: imageUrls.length,
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Horizontal Feedback List
            feedbacks.isEmpty
                ? Center(child: CircularProgressIndicator())
                : Container(
                    height: 150, // Set a fixed height for the feedback list
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        var feedback = feedbacks[index];
                        var tutorId = feedback['tutorId'];
                        var tuteeId = feedback['tuteeId'];
                        var tutor = tutors[
                            tutorId]; // Fetch tutor details using tutorId
                        var tutee = tutees[
                            tuteeId]; // Fetch tutee details using tuteeId
                        var tutorName =
                            '${tutor?['firstName']} ${tutor?['lastName']}';
                        var tuteeName =
                            '${tutee?['firstName']} ${tutee?['lastName']}';
                        var feedbackMessage = feedback['feedbackMessage'];
                        var rating = feedback['ratings'];

                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.only(right: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Feedback from: $tuteeName',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tutor: $tutorName',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feedbackMessage,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  RatingBarIndicator(
                                    rating: rating.toDouble(),
                                    itemCount: 5,
                                    itemSize: 20,
                                    direction: Axis.horizontal,
                                    itemBuilder: (context, index) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
