import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:aralink_app/screens/my-booked-tutees/tutorLearningMaterial.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class BookedTutees extends StatefulWidget {
  const BookedTutees({super.key});

  @override
  _BookedTuteesState createState() => _BookedTuteesState();
}

class _BookedTuteesState extends State<BookedTutees> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> _fetchBookedTutees() async {
    String tutorId = _auth.currentUser!.uid;
    DatabaseReference bookingsRef = FirebaseDatabase.instance.ref('Bookings');

    DataSnapshot bookingsSnapshot = await bookingsRef.get();

    List<Map<String, dynamic>> bookedTutees = [];

    if (bookingsSnapshot.exists) {
      Map<dynamic, dynamic> bookingsMap =
          bookingsSnapshot.value as Map<dynamic, dynamic>;

      if (bookingsMap.containsKey(tutorId)) {
        Map<dynamic, dynamic>? tutorBookings =
            bookingsMap[tutorId] as Map<dynamic, dynamic>?;

        if (tutorBookings != null) {
          for (var studentId in tutorBookings.keys) {
            Map<dynamic, dynamic>? bookingInfo =
                tutorBookings[studentId] as Map<dynamic, dynamic>?;

            if (bookingInfo != null) {
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
                        "No tutees booked yet.",
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
                // Parse the timestamp string into a DateTime object
                DateTime dateTime = DateTime.parse(timestamp);
                // Format the DateTime into a readable string
                return DateFormat('MMMM dd, yyyy').format(dateTime);
              } catch (e) {
                return 'Invalid date format';
              }
            }

            Future<void> updateBookingStatus(
                String studentId, String newStatus) async {
              String tutorId = _auth.currentUser!.uid;
              DatabaseReference bookingRef =
                  FirebaseDatabase.instance.ref('Bookings/$tutorId/$studentId');

              try {
                // Update the status in the database
                await bookingRef.update({'status': newStatus});

                // Show success notification for updating status
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Center(
                      child: Text('Booking status updated to $newStatus'),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                // If the status is approved, send a push notification
                if (newStatus == 'Approved') {
                  // Fetch tutor data from Firebase
                  DatabaseReference tutorRef =
                      FirebaseDatabase.instance.ref('tutors/$tutorId');
                  DataSnapshot tutorSnapshot = await tutorRef.get();
                  var tutorData = tutorSnapshot.value;

                  // Get the booking data to retrieve the FCM token
                  DataSnapshot bookingSnapshot = await bookingRef.get();
                  var bookingData = bookingSnapshot.value;

                  // Log the booking data for debugging
                  print("Booking Data: $bookingData");

                  if (bookingData != null && bookingData is Map) {
                    // Safely retrieve FCM token from the booking data
                    String? tuteeFcmToken = bookingData['tutee_fcmToken'];

                    if (tuteeFcmToken != null) {
                      // Check if tutorData is not null and retrieve values safely
                      if (tutorData != null && tutorData is Map) {
                        String tutorFirstName =
                            tutorData['firstName'] ?? 'Tutor';
                        String tutorLastName = tutorData['lastName'] ?? 'Name';

                        // Send push notification
                        await _sendPushNotification(
                          tuteeFcmToken: tuteeFcmToken,
                          title: "Booking Approved!",
                          body:
                              "Your booking request has been approved by your tutor: $tutorFirstName $tutorLastName.",
                        );
                      } else {
                        // Handle case where tutor data is null or not in expected format
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Error: Tutor data is not available')),
                        );
                      }
                    } else {
                      // Handle case where FCM token is missing
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('FCM token is missing for this booking')),
                      );
                    }
                  } else {
                    // Handle case where booking data is null or in an unexpected format
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Error: Booking data is not in the expected format')),
                    );
                  }
                }
              } catch (error) {
                // Handle error if status update fails
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating status: $error')),
                );
              }
            }

            void showConfirmationDialog(
              BuildContext context, {
              required String title,
              required String content,
              required VoidCallback onConfirm,
            }) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(title),
                    content: Text(content),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          onConfirm(); // Execute the confirm action
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );
            }

            return ListView.builder(
              itemCount: bookedTutees.length,
              itemBuilder: (context, index) {
                final tutee = bookedTutees[index]['profile'];
                final booking = bookedTutees[index]['booking'];
                final studentId = bookedTutees[index]['studentId'];

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
                      style: GoogleFonts.indieFlower(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Status: ${booking['status']}",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Booked on: ${_formatTimestamp(booking['timestamp'])}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (booking['status'] == 'Pending') ...[
                          IconButton(
                            icon: const Icon(Iconsax.tick_circle,
                                color: Colors.green),
                            onPressed: () {
                              showConfirmationDialog(
                                context,
                                title: 'Approve Booking',
                                content:
                                    'Are you sure you want to approve this booking?',
                                onConfirm: () async {
                                  await updateBookingStatus(
                                      studentId, 'Approved');
                                  setState(() {});
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.close_circle,
                                color: Colors.red),
                            onPressed: () {
                              showConfirmationDialog(
                                context,
                                title: 'Cancel Booking',
                                content:
                                    'Are you sure you want to cancel this booking?',
                                onConfirm: () async {
                                  DatabaseReference bookingRef =
                                      FirebaseDatabase.instance.ref(
                                          'Bookings/${_auth.currentUser!.uid}/$studentId');

                                  bookingRef
                                      .update({'isRequestingCancel': true});

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Center(
                                          child: Text(
                                              'Cancellation Request Submitted!')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ] else if (booking['status'] == 'Approved') ...[
                          IconButton(
                            icon: const Icon(Iconsax.book),
                            onPressed: () {
                              if (studentId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TutorLearningMaterialsScreen(
                                            studentId: studentId),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Error: Student ID is missing')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.message),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    tutorId: _auth.currentUser!.uid,
                                    studentId: studentId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else if (booking['status'] == 'Rejected') ...[
                          const Icon(Iconsax.close_circle, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Rejected',
                              style: TextStyle(color: Colors.red)),
                        ] else if (booking['status'] == 'Cancelled') ...[
                          const Icon(Iconsax.close_circle, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Cancelled',
                              style: TextStyle(color: Colors.red)),
                        ],
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
  late StreamSubscription<DatabaseEvent> _messagesSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    chatId = '${widget.tutorId}_${widget.studentId}';
    _messagesRef = _database.ref('Chats/$chatId');

    // Listen to changes in messages
    _messagesSubscription = _messagesRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final messagesData = event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _messages = messagesData.entries
              .map((e) => Map<String, dynamic>.from(e.value))
              .toList();

          // Sort messages by timestamp to display them in chronological order
          _messages.sort((a, b) => DateTime.parse(a['timestamp'])
              .compareTo(DateTime.parse(b['timestamp'])));
        });

        // Scroll to the latest message
        _scrollToBottom();
      }
    });
  }

  // Send a message to Firebase
  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final message = {
      'senderId': widget.tutorId,
      'message': _controller.text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _messagesRef.push().set(message);
    _controller.clear();
    _scrollToBottom();
  }

  // Function to scroll to the bottom of the chat
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
    _messagesSubscription.cancel();
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
          'Chat with Tutee',
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
                final isTutorMessage = message['senderId'] == widget.tutorId;
                final sender = isTutorMessage ? 'Tutor' : 'Tutee';
                final timestamp = DateTime.parse(message['timestamp']);
                final formattedTime = '${timestamp.hour}:${timestamp.minute}';

                return Align(
                  alignment: isTutorMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isTutorMessage
                            ? Colors.teal[100] // Tutor's messages
                            : Colors.grey[300], // Tutee's messages
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: isTutorMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            '${message['message']}',
                            style: TextStyle(
                              color:
                                  isTutorMessage ? Colors.black : Colors.black,
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
