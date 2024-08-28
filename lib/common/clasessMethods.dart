import 'package:aralink_app/screens/home/home.dart';
import 'package:aralink_app/screens/my-booked-tutors/myBookedTutors.dart';
import 'package:aralink_app/screens/my-profile/myProfile.dart';
import 'package:aralink_app/screens/search-tutors-nearby/searchTutorsNearby.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TabNavigation extends StatelessWidget {
  const TabNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          body: TabBarView(
            children: [
              HomeScreen(),
              SearchTutorsNearby(),
              MyBookedTutors(),
              MyProfile(),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(bottom: 25),
            child: TabBar(
              unselectedLabelColor: Colors.black54,
              labelColor: Colors.black,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.0, color: Colors.black),
                insets: EdgeInsets.symmetric(horizontal: 40),
              ),
              tabs: [
                Tab(
                  icon: Icon(Iconsax.home),
                ),
                Tab(
                  icon: Icon(Iconsax.search_normal),
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
          backgroundColor: Color.fromARGB(255, 255, 240, 183),
        ),
      ),
    );
  }
}
