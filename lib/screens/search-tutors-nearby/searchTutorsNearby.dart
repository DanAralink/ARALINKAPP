import 'package:flutter/material.dart';

class SearchTutorsNearby extends StatelessWidget {
  const SearchTutorsNearby({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        body: Column(
          children: [
            TabBar(
              unselectedLabelColor: Colors.teal[200],
              labelColor: Colors.teal,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 2.0, color: Colors.teal),
                insets: EdgeInsets.symmetric(horizontal: 100),
              ),
              tabs: [
                Tab(text: 'Nearby Tutors'), // First tab
                Tab(text: 'Online Tutors'), // Second tab
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  NearbyTutorsTab(),
                  OnlineTutorsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NearbyTutorsTab extends StatelessWidget {
  const NearbyTutorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Nearby Tutors'),
    );
  }
}

class OnlineTutorsTab extends StatelessWidget {
  const OnlineTutorsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Online Tutors'),
    );
  }
}
