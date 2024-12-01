import 'dart:io';
import 'package:aralink_app/screens/authentication/login.dart';
import 'package:aralink_app/screens/my-profile/about.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class MyTutorProfile extends StatefulWidget {
  const MyTutorProfile({Key? key}) : super(key: key);

  @override
  _MyTutorProfileState createState() => _MyTutorProfileState();
}

class _MyTutorProfileState extends State<MyTutorProfile> {
  final User? tutor = FirebaseAuth.instance.currentUser;
  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child('tutors');
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? firstName;
  String? lastName;
  String? email;
  String? profileImageUrl;
  String? password;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (tutor != null) {
      final snapshot = await dbRef.child(tutor!.uid).once();
      if (snapshot.snapshot.value != null) {
        final userData = snapshot.snapshot.value as Map<dynamic, dynamic>?;

        setState(() {
          firstName = userData?['firstName'] ?? 'First Name';
          lastName = userData?['lastName'] ?? 'Last Name';
          email = userData?['email'] ?? 'daniel_austin@yourdomain.com';
          profileImageUrl = userData?['idImageUrl'] ??
              'https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2247726673.jpg';
          password = userData?['password'] ?? 'No password set';
        });
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final storageRef = storage.ref().child('profile_images/${tutor!.uid}.jpg');

    try {
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await dbRef.child(tutor!.uid).update({'idImageUrl': downloadUrl});
      setState(() {
        profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _changePassword(String newPassword) async {
    try {
      await tutor!.updatePassword(newPassword);
      // Optionally update password in your database
      await dbRef.child(tutor!.uid).update({'password': newPassword});
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Password updated")));
    } catch (e) {
      print("Error changing password: $e");
    }
  }

  Future<void> _updateProfile(String newFirstName, String newLastName) async {
    try {
      await dbRef.child(tutor!.uid).update({
        'firstName': newFirstName,
        'lastName': newLastName,
      });

      setState(() {
        firstName = newFirstName;
        lastName = newLastName;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Profile updated")));
    } catch (e) {
      print("Error updating profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadProfileImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profileImageUrl ??
                          'https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2247726673.jpg'),
                    ),
                  ),
                  const SizedBox(height: 8),
               Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Centers the content horizontally
                    children: [
                      Text(
                        '${firstName ?? 'Loading...'} ${lastName ?? ''}',
                        style: GoogleFonts.indieFlower(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 22),
                      ),
                      const SizedBox(
                          width:
                              8), // Space between the name and "Verified" label
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(
                              0.3), // Background color with transparency
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                        ),
                        child: Text(
                          "Verified",
                          style: GoogleFonts.roboto(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    email ?? 'Loading...',
                    style: GoogleFonts.indieFlower(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ProfileMenuItem(
                      icon: Iconsax.message_question,
                      text: 'About',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AboutScreen()),
                        );
                      }),
                  ProfileMenuItem(
                    icon: Iconsax.setting,
                    text: 'Settings',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      hintText: firstName,
                                    ),
                                    onChanged: (value) {
                                      firstName = value;
                                    },
                                  ),
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      hintText: lastName,
                                    ),
                                    onChanged: (value) {
                                      lastName = value;
                                    },
                                  ),
                                  TextField(
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'New Password',
                                    ),
                                    onChanged: (value) {
                                      password = value;
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                          onPressed: () {
                                            if (firstName != null &&
                                                lastName != null) {
                                              _updateProfile(
                                                  firstName!, lastName!);
                                            }
                                            if (password != null) {
                                              _changePassword(password!);
                                            }
                                            Navigator.pop(context);
                                          },
                                          child: Text('Save Changes')),
                                      ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('Cancel')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Iconsax.logout, color: Colors.red),
                    title: Text(
                      'Logout',
                      style: GoogleFonts.indieFlower(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: null,
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    'Confirm Logout',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Are you sure you want to log out?',
                                    style: TextStyle(fontSize: 16.0),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: const Color.fromARGB(
                                              255, 255, 240, 183),
                                          minimumSize: const Size(100, 40),
                                        ),
                                        child: const Text('Logout'),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: const Color.fromARGB(
                                              255, 255, 240, 183),
                                          minimumSize: const Size(100, 40),
                                        ),
                                        child: const Text('Cancel'),
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      if (confirm ?? false) {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ProfileMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(
        text,
        style: GoogleFonts.indieFlower(
            color: Colors.black54, fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Iconsax.arrow_right),
    );
  }
}
