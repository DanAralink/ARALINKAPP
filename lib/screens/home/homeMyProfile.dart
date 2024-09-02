import 'dart:io';

import 'package:aralink_app/screens/authentication/login.dart';
import 'package:aralink_app/screens/my-profile/about.dart';
import 'package:aralink_app/screens/my-profile/edit-profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class HomeMyProfile extends StatefulWidget {
  const HomeMyProfile({Key? key}) : super(key: key);

  @override
  _HomeMyProfileState createState() => _HomeMyProfileState();
}

class _HomeMyProfileState extends State<HomeMyProfile> {
  final User? user = FirebaseAuth.instance.currentUser;
  final DatabaseReference dbRef =
      FirebaseDatabase.instance.ref().child('users');
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? firstName;
  String? lastName;
  String? email;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user != null) {
      final snapshot = await dbRef.child(user!.uid).once();
      if (snapshot.snapshot.value != null) {
        final userData = snapshot.snapshot.value as Map<dynamic, dynamic>?;
        setState(() {
          firstName = userData?['firstName'] ?? 'First Name';
          lastName = userData?['lastName'] ?? 'Last Name';
          email = userData?['email'] ?? 'daniel_austin@yourdomain.com';
          profileImageUrl =
              userData?['profileImageUrl'] ?? 'https://via.placeholder.com/150';
        });
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final file = File(image.path);
    final storageRef = storage.ref().child('profile_images/${user!.uid}.jpg');

    try {
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await dbRef.child(user!.uid).update({'profileImageUrl': downloadUrl});
      setState(() {
        profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
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
        centerTitle: true,
        title: Text(
          'My Profile',
          style: GoogleFonts.indieFlower(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
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
                  Text(
                    '${firstName ?? 'Loading...'} ${lastName ?? ''}',
                    style: GoogleFonts.indieFlower(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
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
                      icon: Iconsax.user,
                      text: 'Edit Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditProfileScreen()),
                        );
                      }),
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
                                  Text(
                                    'Confirm Logout',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18.0,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Are you sure you want to log out?',
                                    style: TextStyle(fontSize: 16.0),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: Color.fromARGB(
                                              255, 255, 240, 183),
                                          minimumSize: Size(100, 40),
                                        ),
                                        child: Text('Logout'),
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: Color.fromARGB(
                                              255, 255, 240, 183),
                                          minimumSize: Size(100, 40),
                                        ),
                                        child: Text('Cancel'),
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

                      if (confirm == true) {
                        try {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        } catch (e) {
                          print('Sign out error: $e');
                        }
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
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        text,
        style: GoogleFonts.indieFlower(
            color: Colors.black54, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }
}
