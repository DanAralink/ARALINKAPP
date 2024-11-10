import 'dart:async';

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
            print(
                'Booking found for Tutor ID: $tutorId by Student: $studentId');

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
          print(
              'No bookings found for Tutor ID: $tutorId or TutorBookings is null');
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
            return const Center(
                child: CircularProgressIndicator(color: Colors.teal));
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
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Subject: ${tutorProfile['subjects'] ?? 'N/A'}"),
                        Text(
                            "Rate: ${tutorProfile['ratePerHour'] ?? 'N/A'} per hour"),
                        Text("Status: ${booking['status']}"),
                        Text("Booked on: ${booking['timestamp'] ?? 'N/A'}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.book),
                          onPressed: () {
                            // Navigate to the TutorLearningMaterialsScreen
                            if (studentId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LearningMaterialsScreen(
                                      userId: studentId),
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
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            String tutorId = bookedTutors[index]['tutorId'];
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
    _childAddedSubscription = _messagesRef.onChildAdded.listen((DatabaseEvent event) {
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
    _childChangedSubscription = _messagesRef.onChildChanged.listen((DatabaseEvent event) {
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
      appBar: AppBar(
        title: const Text('Chat with Tutor'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isStudentMessage = message['senderId'] == widget.studentId;
                final sender = isStudentMessage ? 'Student' : 'Tutor';
                final timestamp = DateTime.parse(message['timestamp']);
                final formattedTime = '${timestamp.hour}:${timestamp.minute}';

                return Align(
                  alignment: isStudentMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isStudentMessage
                            ? Colors.blue[100] // Student's messages
                            : Colors.grey[300], // Tutor's messages
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: isStudentMessage
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$sender: ${message['message']}',
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
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
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