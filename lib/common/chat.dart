import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iconsax/iconsax.dart';

class ChatBoxScreen extends StatefulWidget {
  final String bookingId;
  final String chatId;

  const ChatBoxScreen({super.key, required this.bookingId, required this.chatId});

  @override
  _ChatBoxScreenState createState() => _ChatBoxScreenState();
}

class _ChatBoxScreenState extends State<ChatBoxScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  late DatabaseReference _chatRef;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid;
    _chatRef = FirebaseDatabase.instance.ref('chats/${widget.bookingId}/${widget.chatId}');
  }

  // Method to send a message
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final message = {
        'sender': _userId,
        'text': _messageController.text,
        'timestamp': timestamp,
      };

      // Push new message to Firebase
      await _chatRef.push().set(message);

      // Clear the input field after sending
      _messageController.clear();
    }
  }

  // Method to build the chat UI
  Widget _buildChatMessage(Map<String, dynamic> message) {
    final isSender = message['sender'] == _userId;
    final timeSent = DateTime.fromMillisecondsSinceEpoch(message['timestamp']);
    final timeString = "${timeSent.hour}:${timeSent.minute}";

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Material(
              color: isSender ? Colors.teal : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  message['text'],
                  style: TextStyle(color: isSender ? Colors.white : Colors.black),
                ),
              ),
            ),
            SizedBox(height: 4),
            Text(
              timeString,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Fetch messages from Firebase and display them
  Stream<List<Map<String, dynamic>>> _fetchMessages() {
    return _chatRef.orderByChild('timestamp').onChildAdded.map((event) {
      final messages = <Map<String, dynamic>>[];
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> messagesMap = event.snapshot.value as Map<dynamic, dynamic>;
        messagesMap.forEach((key, value) {
          messages.add(Map<String, dynamic>.from(value));
        });
      }
      return messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        title: Text("Chat"),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchMessages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildChatMessage(messages[index]);
                    },
                  );
                } else {
                  return Center(child: Text('No messages yet.'));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal),
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
