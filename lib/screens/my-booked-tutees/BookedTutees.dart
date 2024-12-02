import 'dart:async';
import 'dart:convert';
import 'package:aralink_app/services/mail_service.dart';
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
    DatabaseReference bookingsRef =
        FirebaseDatabase.instance.ref('Bookings/$tutorId');

    DataSnapshot bookingsSnapshot = await bookingsRef.get();

    List<Map<String, dynamic>> bookedTutees = [];

    if (bookingsSnapshot.exists) {
      Map<dynamic, dynamic> studentBookings =
          bookingsSnapshot.value as Map<dynamic, dynamic>;

      for (var studentId in studentBookings.keys) {
        Map<dynamic, dynamic>? bookingEntries =
            studentBookings[studentId] as Map<dynamic, dynamic>?;

        if (bookingEntries != null) {
          for (var bookingId in bookingEntries.keys) {
            Map<dynamic, dynamic>? bookingInfo =
                bookingEntries[bookingId] as Map<dynamic, dynamic>?;

            if (bookingInfo != null) {
              DatabaseReference tuteeProfileRef =
                  FirebaseDatabase.instance.ref('users/$studentId');
              DataSnapshot tuteeProfileSnapshot = await tuteeProfileRef.get();

              if (tuteeProfileSnapshot.exists) {
                Map<dynamic, dynamic> tuteeProfile =
                    tuteeProfileSnapshot.value as Map<dynamic, dynamic>;

                bookedTutees.add({
                  'studentId': studentId,
                  'bookingId': bookingId,
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

  void _showScheduleDialog(String tutorId, String studentId, String bookingId) {
    DateTime? selectedDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Schedule Booking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(selectedDate == null
                        ? 'Select Date'
                        : 'Date: ${selectedDate!.toLocal().toString().split(' ')[0]}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(startTime == null
                        ? 'Select Start Time'
                        : 'Start Time: ${startTime!.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          startTime = pickedTime;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(endTime == null
                        ? 'Select End Time'
                        : 'End Time: ${endTime!.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          endTime = pickedTime;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedDate == null ||
                        startTime == null ||
                        endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select date and time'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final scheduleDate =
                        selectedDate!.toLocal().toString().split(' ')[0];
                    final scheduleStartTime =
                        '${startTime!.hour}:${startTime!.minute}';
                    final scheduleEndTime =
                        '${endTime!.hour}:${endTime!.minute}';

                    Navigator.of(context).pop();
                    _scheduleBooking(tutorId, studentId, bookingId,
                        scheduleDate, scheduleStartTime, scheduleEndTime);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _scheduleBooking(
      String tutorId,
      String studentId,
      String bookingId,
      String scheduleDate,
      String scheduleStartTime,
      String scheduleEndTime) async {
    try {
      // Reference the specific booking using the bookingId
      DatabaseReference bookingRef = FirebaseDatabase.instance
          .ref('Bookings/$tutorId/$studentId/$bookingId');

      // Update booking details
      await bookingRef.update({
        'scheduleDate': scheduleDate,
        'scheduleStartTime': scheduleStartTime,
        'scheduleEndTime': scheduleEndTime,
        'status': 'Scheduled',
      });

      // Fetch booking data for push notification
      DataSnapshot bookingSnapshot = await bookingRef.get();
      var bookingData = bookingSnapshot.value;

      if (bookingData != null && bookingData is Map) {
        String? tuteeFcmToken = bookingData['tutee_fcmToken'];
        if (tuteeFcmToken != null) {
          // Fetch tutor data
          DatabaseReference tutorRef =
              FirebaseDatabase.instance.ref('tutors/$tutorId');
          DataSnapshot tutorSnapshot = await tutorRef.get();
          var tutorData = tutorSnapshot.value;

          if (tutorData != null && tutorData is Map) {
            String tutorFirstName = tutorData['firstName'] ?? 'Tutor';
            String tutorLastName = tutorData['lastName'] ?? 'Name';

            // Send a push notification to notify the tutee of the scheduled session
            await _sendPushNotification(
              tuteeFcmToken: tuteeFcmToken,
              title: "Tutorial Scheduled",
              body:
                  "Your tutorial session has been scheduled with $tutorFirstName $tutorLastName on $scheduleDate from $scheduleStartTime to $scheduleEndTime.",
            );

            // // Schedule a push notification for when the session starts
            // DateTime startDateTime = DateTime.parse(
            //     "$scheduleDate $scheduleStartTime:00"); // Combine date and time
            // Duration timeUntilSession = startDateTime.difference(DateTime.now());

            // if (timeUntilSession.inSeconds > 0) {
            //   // Schedule the push notification
            //   Future.delayed(timeUntilSession, () async {
            //     await _sendPushNotification(
            //       tuteeFcmToken: tuteeFcmToken,
            //       title: "Session Starting Soon",
            //       body:
            //           "Your tutorial session with $tutorFirstName $tutorLastName is starting now.",
            //     );
            //   });
            // }
          } else {
            throw "Tutor data not available.";
          }
        } else {
          throw "Tutee FCM token is missing.";
        }
      } else {
        throw "Booking data not found.";
      }

      // Notify user of successful schedule creation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule Submitted!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error Scheduling: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to Schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    // Get the booking data to retrieve the FCM token and email addresses
    DataSnapshot bookingSnapshot = await bookingRef.get();
    var bookingData = bookingSnapshot.value;

    if (bookingData != null && bookingData is Map) {
      // Safely retrieve required data
      String? tuteeFcmToken = bookingData['fcmToken'];
      String? tuteeEmail = bookingData['email'];
      String? tutorEmail = bookingData['email'];

      if (tuteeFcmToken != null && tuteeEmail != null && tutorEmail != null) {
        // Check if tutorData is not null and retrieve values safely
        if (tutorData != null && tutorData is Map) {
          String tutorFirstName = tutorData['firstName'] ?? 'Tutor';
          String tutorLastName = tutorData['lastName'] ?? 'Name';

          // Send push notification
          await _sendPushNotification(
            tuteeFcmToken: tuteeFcmToken,
            title: "Booking Cancelled!",
            body:
                "Your booking with tutor: $tutorFirstName $tutorLastName has been cancelled.",
          );

          // Send email notifications
          // Email to tutee
          await MailService.instance.sendMail(
            'Hi,\n\nYour booking with tutor $tutorFirstName $tutorLastName has been cancelled. Please contact the tutor for further details.\n\nBest Regards,\nTutor Booking App',
            'Booking Cancelled',
            tuteeEmail,
          );

          // Email to tutor
          await MailService.instance.sendMail(
            'Hi,\n\nThe booking from tutee ID: $studentId has been cancelled. Please check your schedule for updates.\n\nBest Regards,\nTutor Booking App',
            'Booking Cancelled',
            tutorEmail,
          );
        } else {
          // Handle case where tutor data is null or not in expected format
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Tutor data is not available')),
          );
        }
      } else {
        // Handle case where required data is missing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Required email or FCM token is missing')),
        );
      }
    } else {
      // Handle case where booking data is null or in an unexpected format
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Booking data is not in the expected format')),
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
      const SnackBar(content: Text('Failed to request cancellation')),
    );
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
    String studentId, String newStatus, String bookingId) async {
  String tutorId = _auth.currentUser!.uid;
  DatabaseReference bookingRef = FirebaseDatabase.instance
      .ref('Bookings/$tutorId/$studentId/$bookingId');

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

    // Fetch necessary data
    var bookingSnapshot = await bookingRef.get();
    var tutorSnapshot =
        await FirebaseDatabase.instance.ref('tutors/$tutorId').get();

    if (!bookingSnapshot.exists || !tutorSnapshot.exists) {
      throw Exception('Required data not found.');
    }

    Map<String, dynamic> bookingData =
        Map<String, dynamic>.from(bookingSnapshot.value as Map);
    Map<String, dynamic> tutorData =
        Map<String, dynamic>.from(tutorSnapshot.value as Map);

    String? tuteeFcmToken = bookingData['fcmToken'];
    String? tuteeEmail = bookingData['email'];
    String tutorFirstName = tutorData['firstName'] ?? 'Tutor';
    String tutorLastName = tutorData['lastName'] ?? 'Name';

    if (tuteeFcmToken == null || tuteeEmail == null) {
      throw Exception('Tutee FCM token or email is missing.');
    }

    // Handle status-specific logic
    if (newStatus == 'Approved') {
      await _sendPushNotification(
        tuteeFcmToken: tuteeFcmToken,
        title: "Booking Approved!",
        body:
            "Your booking request has been approved by your tutor: $tutorFirstName $tutorLastName.",
      );

      await MailService.instance.sendMail(
        'Hi,\n\nYour booking request with tutor $tutorFirstName $tutorLastName has been approved. Please proceed as discussed.\n\nBest Regards,\nTutor Booking App',
        'Booking Approved',
        tuteeEmail,
      );
    } else if (newStatus == 'Finished') {
      await _sendPushNotification(
        tuteeFcmToken: tuteeFcmToken,
        title: "Booking Completed!",
        body:
            "Your booking with tutor: $tutorFirstName $tutorLastName has been marked as Complete.",
      );

      await MailService.instance.sendMail(
        'Hi,\n\nYour booking with tutor $tutorFirstName $tutorLastName has been successfully completed. Thank you for using Tutor Booking App.\n\nBest Regards,\nTutor Booking App',
        'Booking Completed',
        tuteeEmail,
      );
    } else if (newStatus == 'Scheduled') {
      await _sendPushNotification(
        tuteeFcmToken: tuteeFcmToken,
        title: "Booking Scheduled!",
        body:
            "Your booking with tutor $tutorFirstName $tutorLastName has been scheduled. Please check your schedule for details.",
      );

      await MailService.instance.sendMail(
        'Hi,\n\nYour booking with tutor $tutorFirstName $tutorLastName has been scheduled. Please check your schedule for details.\n\nBest Regards,\nTutor Booking App',
        'Booking Scheduled',
        tuteeEmail,
      );
    } else if (newStatus == 'Cancelled') {
      await _sendPushNotification(
        tuteeFcmToken: tuteeFcmToken,
        title: "Booking Cancelled",
        body:
            "Your booking with tutor $tutorFirstName $tutorLastName has been cancelled. Please contact your tutor for further details.",
      );

      await MailService.instance.sendMail(
        'Hi,\n\nYour booking with tutor $tutorFirstName $tutorLastName has been cancelled. Please contact your tutor for further details.\n\nBest Regards,\nTutor Booking App',
        'Booking Cancelled',
        tuteeEmail,
      );
    }
  } catch (error) {
    // Handle errors
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
                final bookingId = bookedTutees[index]['bookingId'];

                return Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        10.0), // Added padding to give extra space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
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
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "Booked on: ${_formatTimestamp(booking['timestamp'])}",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (booking['status'] == 'Pending') ...[
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                            studentId,
                                            'Approved',
                                            bookingId,
                                          );
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Accept',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.close_circle,
                                        color: Colors.red),
                                    onPressed: () {
                                      _showCancelDialog(
                                        _auth.currentUser!.uid,
                                        studentId,
                                        bookingId,
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (booking['status'] == 'Approved' ||
                                booking['status'] == 'Scheduled') ...[
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.document,
                                        color: Colors.teal),
                                    onPressed: () {
                                      _showScheduleDialog(
                                        _auth.currentUser!.uid,
                                        studentId,
                                        bookingId,
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Schedule',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.check,
                                        color: Colors.green),
                                    onPressed: () {
                                      showConfirmationDialog(
                                        context,
                                        title: 'Finish Booking',
                                        content:
                                            "This can't be undone. Are you sure you want to mark this booking as Completed/Finished?",
                                        onConfirm: () async {
                                          await updateBookingStatus(
                                            studentId,
                                            'Finished',
                                            bookingId,
                                          );
                                          setState(() {});
                                        },
                                      );
                                    },
                                  ),
                                  const Text(
                                    'Mark as Complete',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.book,
                                        color: Colors.teal),
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Error: Student ID is missing')),
                                        );
                                      }
                                    },
                                  ),
                                  const Text(
                                    'Learning Materials',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Iconsax.message,
                                        color: Colors.teal),
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
                                  const Text(
                                    'Message',
                                    style: TextStyle(
                                      fontSize: 10,
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
