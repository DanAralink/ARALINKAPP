import 'dart:async';

import 'package:aralink_app/screens/my-booked-tutees/tutorLearningMaterial.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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

            if (bookingInfo != null && bookingInfo['status'] == 'booked') {
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
                    bookedTutees[index]['profile']; 
                final booking = bookedTutees[index]['booking'];
                final studentId =
                    bookedTutees[index]['studentId']; 

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
                                  builder: (context) => TutorLearningMaterialsScreen(
                                      studentId: studentId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Error: Student ID is missing')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            // Navigate to the ChatScreen
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
      appBar: AppBar(
        title: const Text('Chat with Tutee'),
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
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isTutorMessage
                            ? Colors.grey[300] // Tutor's messages
                            : Colors.blue[100], // Tutee's messages
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: isTutorMessage
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$sender: ${message['message']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isTutorMessage ? Colors.black : Colors.black,
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