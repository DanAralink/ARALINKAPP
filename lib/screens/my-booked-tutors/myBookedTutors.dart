import 'dart:async';
import 'dart:convert';
import 'package:aralink_app/services/mail_service.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:aralink_app/screens/my-booked-tutors/learningMaterials.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

class MyBookedTutors extends StatefulWidget {
  const MyBookedTutors({super.key});

  @override
  _MyBookedTutorsState createState() => _MyBookedTutorsState();
}

class _MyBookedTutorsState extends State<MyBookedTutors> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isRequestingCancel = false;

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
        Map<dynamic, dynamic>? studentBookings =
            bookingsMap[tutorId] as Map<dynamic, dynamic>?;

        if (studentBookings != null && studentBookings.containsKey(studentId)) {
          Map<dynamic, dynamic>? bookingEntries =
              studentBookings[studentId] as Map<dynamic, dynamic>?;

          if (bookingEntries != null) {
            for (var bookingId in bookingEntries.keys) {
              Map<dynamic, dynamic>? bookingInfo =
                  bookingEntries[bookingId] as Map<dynamic, dynamic>?;

              if (bookingInfo != null) {
                print(
                    'Booking found for Tutor ID: $tutorId, Booking ID: $bookingId');

                // Fetch tutor profile
                DatabaseReference tutorProfileRef =
                    FirebaseDatabase.instance.ref('tutor_profiles/$tutorId');
                DataSnapshot tutorProfileSnapshot = await tutorProfileRef.get();

                if (tutorProfileSnapshot.exists) {
                  Map<dynamic, dynamic> tutorProfile =
                      tutorProfileSnapshot.value as Map<dynamic, dynamic>;

                  // Fetch tutor details
                  DatabaseReference tutorDetailsRef =
                      FirebaseDatabase.instance.ref('tutors/$tutorId');
                  DataSnapshot tutorDetailsSnapshot =
                      await tutorDetailsRef.get();

                  if (tutorDetailsSnapshot.exists) {
                    Map<dynamic, dynamic> tutorDetails =
                        tutorDetailsSnapshot.value as Map<dynamic, dynamic>;

                    bookedTutors.add({
                      'tutorId': tutorId,
                      'profile': Map<String, dynamic>.from(tutorProfile),
                      'details': Map<String, dynamic>.from(tutorDetails),
                      'booking': {
                        'bookingId': bookingId,
                        ...Map<String, dynamic>.from(bookingInfo),
                      },
                    });
                  } else {
                    print('No details found for Tutor ID: $tutorId');
                  }
                } else {
                  print('No profile found for Tutor ID: $tutorId');
                }
              } else {
                print('No valid booking info for Booking ID: $bookingId');
              }
            }
          } else {
            print('No booking entries found for Student ID: $studentId');
          }
        } else {
          print(
              'No bookings found for Tutor ID: $tutorId or Student ID: $studentId');
        }
      }
    } else {
      print('No bookings found');
    }

    return bookedTutors;
  }

  void _showCancelDialog(String tutorId, String studentId, String bookingId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel the booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestCancelBooking(tutorId, studentId, bookingId);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

Future<void> _requestCancelBooking(
    String tutorId, String studentId, String bookingId) async {
  try {
    // Reference the specific booking using the bookingId
    DatabaseReference bookingRef = FirebaseDatabase.instance
        .ref('Bookings/$tutorId/$studentId/$bookingId');

    await bookingRef.update({'status': 'Cancelled'});
    setState(() {});

    // Fetch tutor data from Firebase
    DatabaseReference tutorRef =
        FirebaseDatabase.instance.ref('tutors/$tutorId');
    DataSnapshot tutorSnapshot = await tutorRef.get();
    var tutorData = tutorSnapshot.value;

    // Get booking data to retrieve FCM token and email addresses
    DataSnapshot bookingSnapshot = await bookingRef.get();
    var bookingData = bookingSnapshot.value;

    if (bookingData != null && bookingData is Map) {
      // Safely retrieve required data
      String? tuteeFcmToken = bookingData['fcmToken'];
      String? tuteeEmail = bookingData['email'];
      String? tutorEmail = bookingData['email'];

      if (tuteeEmail != null && tutorEmail != null) {
        if (tutorData != null && tutorData is Map) {
          String tutorFirstName = tutorData['firstName'] ?? 'Tutor';
          String tutorLastName = tutorData['lastName'] ?? 'Name';

          // Email notification to the tutee
          await MailService.instance.sendMail(
            'Hi,\n\nYour booking with tutor $tutorFirstName $tutorLastName has been cancelled. Please contact the tutor for further details.\n\nBest Regards,\nTutor Booking App',
            'Booking Cancelled',
            tuteeEmail,
          );

          // Email notification to the tutor
          await MailService.instance.sendMail(
            'Hi,\n\nThe booking from student ID: $studentId has been cancelled. Please check your schedule for updates.\n\nBest Regards,\nTutor Booking App',
            'Booking Cancelled',
            tutorEmail,
          );

          // Optional: Send push notification if FCM token is available
          if (tuteeFcmToken != null) {
            await _sendPushNotification(
              tuteeFcmToken: tuteeFcmToken,
              title: "Booking Cancelled",
              body:
                  "Your booking with tutor $tutorFirstName $tutorLastName has been cancelled.",
            );
          }
        } else {
          // Handle case where tutor data is null or in an unexpected format
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Tutor data is not available.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle case where emails are missing
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Required email addresses are missing.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Handle case where booking data is null or malformed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Booking data is not in the expected format.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cancellation Request Submitted!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print('Error requesting cancellation: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to request cancellation.'),
        backgroundColor: Colors.red,
      ),
    );
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


Future<void> _sendPushNotification({
    required String tuteeFcmToken,
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
          'token': tuteeFcmToken,
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

      print("Sending message: ${jsonEncode(message)}");

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

  void _showFeedbackDialog(BuildContext context, String tutorId) {
    TextEditingController feedbackController = TextEditingController();
    double rating = 3.0; // Default rating
    DateTime currentDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Leave Feedback"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Rate Tutor:"),
              RatingBar.builder(
                initialRating: 3,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 40.0,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                onRatingUpdate: (ratingValue) {
                  rating = ratingValue;
                },
                itemBuilder: (context, index) => Icon(
                  Icons.star,
                  color: index < rating ? Colors.yellow : Colors.grey,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 255, 240, 183),
                minimumSize: const Size(100, 40),
              ),
              onPressed: () {
                // Save the feedback to Firebase Realtime Database
                _saveFeedbackToFirebase(rating, tutorId, currentDate);
                Navigator.of(context).pop();
              },
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  // Save the feedback to Firebase Realtime Database
  void _saveFeedbackToFirebase(double rating, String tutorId, DateTime date) {
    // Get the current user's ID from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user is logged in!");
      return; // If no user is logged in, exit the function
    }
    String userId = user.uid;

    // Get a reference to the database
    DatabaseReference feedbackRef = FirebaseDatabase.instance
        .ref()
        .child('Feedbacks')
        .child(userId) // User's ID
        .child(tutorId); // Tutor's ID

    feedbackRef.push().set({
      'tutorId': tutorId,
      'tuteeId': userId,
      'ratings': rating,
      'dateCreated': date.millisecondsSinceEpoch,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Feedback submitted successfully!",
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      print("Feedback saved successfully!");
    }).catchError((error) {
      print("Error saving feedback: $error");
    });
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    String studentId = auth.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Fetch booked tutors
        future: _fetchBookedTutors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final bookedTutors = snapshot.data!;

            if (bookedTutors.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/aralink-main-logo.png',
                          width: 100, height: 100),
                      const SizedBox(height: 10),
                      Text(
                        "No tutors booked yet.",
                        style: GoogleFonts.indieFlower(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Please check back later.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.indieFlower(
                            fontSize: 12, color: Colors.black),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            }

            String _formatTimestamp(String? timestamp) {
              if (timestamp == null || timestamp.isEmpty) {
                return 'N/A';
              }
              try {
                DateTime dateTime = DateTime.parse(timestamp);
                return DateFormat('MMMM dd, yyyy').format(dateTime);
              } catch (e) {
                return 'Invalid date format';
              }
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
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                      style: GoogleFonts.indieFlower(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Grade: ${tutorProfile['gradeLevel'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Subject: ${tutorProfile['subjects'] ?? 'N/A'}",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Rate: ${tutorProfile['ratePerHour'] ?? 'N/A'} per hour",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Status: ${booking['status']}",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Booked on: ${_formatTimestamp(booking['timestamp'])}",
                          style: TextStyle(fontSize: 12),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (booking['status'] == 'Pending')
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.close_circle,
                                        color: Colors.red),
                                    onPressed: () {
                                      _showCancelDialog(
                                        bookedTutors[index]['tutorId'],
                                        studentId,
                                        booking['bookingId'], // Pass bookingId
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 10, // Small text size
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            if (booking['status'] == 'Approved') ...[
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.book),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              LearningMaterialsScreen(
                                                  userId: studentId),
                                        ),
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Learning Materials',
                                    style: TextStyle(
                                      fontSize: 10, // Small text size
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.message),
                                    onPressed: () {
                                      String tutorId =
                                          bookedTutors[index]['tutorId'];
                                      // Navigate to the ChatScreen
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            studentId: _auth.currentUser!.uid,
                                            tutorId: tutorId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Message',
                                    style: TextStyle(
                                      fontSize: 10, // Small text size
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.heart),
                                    onPressed: () {
                                      String tutorId =
                                          bookedTutors[index]['tutorId'];
                                      _showFeedbackDialog(context,
                                          tutorId); // Show feedback dialog
                                    },
                                  ),
                                  const Text(
                                    'Feedback',
                                    style: TextStyle(
                                      fontSize: 10, // Small text size
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
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

class ChatScreen extends StatefulWidget {
  final String tutorId;
  final String studentId;

  const ChatScreen({super.key, required this.tutorId, required this.studentId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final TextEditingController _controller = TextEditingController();
  late String chatId;
  late DatabaseReference _messagesRef;
  List<Map<String, dynamic>> _messages = [];
  late StreamSubscription<DatabaseEvent> _childAddedSubscription;
  late StreamSubscription<DatabaseEvent> _childChangedSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    chatId = '${widget.tutorId}_${widget.studentId}';
    _messagesRef = _database.ref('Chats/$chatId');

    // Listening for new messages added
    _childAddedSubscription =
        _messagesRef.onChildAdded.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final messageData = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _messages.add(Map<String, dynamic>.from(messageData));
          _sortMessagesByTime();
        });
        _scrollToBottom();
      }
    });

    // Listening for changes in messages
    _childChangedSubscription =
        _messagesRef.onChildChanged.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final updatedMessage = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _messages = _messages.map((message) {
            if (message['timestamp'] == updatedMessage['timestamp']) {
              return Map<String, dynamic>.from(updatedMessage);
            }
            return message;
          }).toList();
          _sortMessagesByTime();
        });
        _scrollToBottom();
      }
    });
  }

  void _sortMessagesByTime() {
    _messages.sort((a, b) => DateTime.parse(a['timestamp'])
        .compareTo(DateTime.parse(b['timestamp'])));
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final message = {
      'senderId': widget.studentId,
      'message': _controller.text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _messagesRef.push().set(message);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _childAddedSubscription.cancel();
    _childChangedSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
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
          child: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        title: Text(
          'Chat with Tutor',
          style: GoogleFonts.indieFlower(
              color: Colors.teal, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isStudentMessage =
                    message['senderId'] == widget.studentId;
                final timestamp = DateTime.parse(message['timestamp']);
                final formattedTime = '${timestamp.hour}:${timestamp.minute}';

                return Align(
                  alignment: isStudentMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isStudentMessage
                            ? Colors.teal[100] // Tutor's messages
                            : Colors.grey[300], // Tutee's messages
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: isStudentMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            '${message['message']}',
                            style: TextStyle(
                              fontWeight: isStudentMessage
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle:
                          TextStyle(color: Colors.teal), // Hint text color
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.teal), // Border color
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.teal,
                            width: 2), // Focused border color
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Iconsax.send_1,
                    color: Colors.teal,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
