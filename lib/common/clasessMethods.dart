import 'package:aralink_app/screens/home/home.dart';
import 'package:aralink_app/screens/home/homeTutors.dart';
import 'package:aralink_app/screens/my-booked-tutees/BookedTutees.dart';
import 'package:aralink_app/screens/my-booked-tutors/myBookedTutors.dart';
import 'package:aralink_app/screens/my-profile/myProfile.dart';
import 'package:aralink_app/screens/my-tutor-profile/myTutorProfile.dart';
import 'package:aralink_app/screens/search-tutors-nearby/searchTutorsNearby.dart';
import 'package:aralink_app/screens/set-booking-profile/setBookingProfile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class TabNavigation extends StatefulWidget {
  const TabNavigation({super.key});

  @override
  _TabNavigationState createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? firstName;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref('users/${user!.uid}');
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          setState(() {
            firstName = snapshot.child('firstName').value as String?;
          });
        } else {
          print('No user data found');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Image.asset(
              'assets/images/appbarlogo.png',
              width: 130,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  firstName != null ? "Hello, Tutee $firstName" : "Hello Tutee",
                  style: GoogleFonts.indieFlower(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          body: const TabBarView(
            children: [
              HomeScreen(),
              SearchTutorsNearby(),
              MyBookedTutors(),
              MyProfile(),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: TabBar(
              unselectedLabelColor: Colors.teal[200],
              labelColor: Colors.teal,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.0, color: Colors.teal),
                insets: EdgeInsets.symmetric(horizontal: 40),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Iconsax.grid_3),
                ),
                Tab(
                  icon: Icon(Iconsax.search_normal_14),
                ),
                Tab(
                  icon: Icon(Iconsax.book),
                ),
                Tab(
                  icon: Icon(Iconsax.user),
                ),
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        ),
      ),
    );
  }
}


class TutorTabNavigation extends StatefulWidget {
  const TutorTabNavigation({super.key});

  @override
  _TutorTabNavigationState createState() => _TutorTabNavigationState();
}

class _TutorTabNavigationState extends State<TutorTabNavigation> {
  final User? tutor = FirebaseAuth.instance.currentUser;
  String? firstName;

  @override
  void initState() {
    super.initState();
    _fetchTutorData();
  }

  Future<void> _fetchTutorData() async {
    if (tutor != null) {
      try {
        DatabaseReference userRef =
            FirebaseDatabase.instance.ref('tutors/${tutor!.uid}');
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          setState(() {
            firstName = snapshot.child('firstName').value as String?;
          });
        } else {
          print('No user data found');
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Image.asset(
              'assets/images/appbarlogo.png',
              width: 130,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  firstName != null ? "Hello, Tutor $firstName" : "Hello Tutor",
                  style: GoogleFonts.indieFlower(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          body: const TabBarView(
            children: [
              HomeTutorsScreen(),
              SetBookingProfile(),
              BookedTutees(),
              MyTutorProfile(),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: TabBar(
              unselectedLabelColor: Colors.teal[200],
              labelColor: Colors.teal,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.0, color: Colors.teal),
                insets: EdgeInsets.symmetric(horizontal: 40),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Iconsax.grid_3),
                ),
                Tab(
                  icon: Icon(Iconsax.user_edit),
                ),
                Tab(
                  icon: Icon(Iconsax.book),
                ),
                Tab(
                  icon: Icon(Iconsax.user),
                ),
              ],
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        ),
      ),
    );
  }
}
