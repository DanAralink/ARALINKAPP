import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeSearchTutorsNearby extends StatelessWidget {
  const HomeSearchTutorsNearby({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 240, 183),
          centerTitle: true,
          title: Text(
            'Search Tutors Nearby',
            style: GoogleFonts.indieFlower(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ),
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
                tabs: const [
                  Tab(text: 'Nearby Tutors'),
                  Tab(text: 'Online Tutors'),
                ],
                labelStyle: GoogleFonts.indieFlower(
                    fontSize: 16, fontWeight: FontWeight.bold)),
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

class NearbyTutorsTab extends StatefulWidget {
  const NearbyTutorsTab({super.key});

  @override
  _NearbyTutorsTabState createState() => _NearbyTutorsTabState();
}

class _NearbyTutorsTabState extends State<NearbyTutorsTab> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('tutors');
  List<Map<String, dynamic>> nearbyTutors = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Container(
            height: 40,
            width: double.infinity,
            child: TextButton(
              child: Text("Serach Nearby Tutors",
                  style: GoogleFonts.indieFlower(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () {
                _searchNearbyTutors();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.teal)
                : nearbyTutors.isEmpty
                    ? _buildNoTutorsFound()
                    : _buildTutorsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoTutorsFound() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/aralink-main-logo.png',
              width: 100, height: 100),
          const SizedBox(height: 10),
          Text(
            "No nearby tutors found",
            style: GoogleFonts.indieFlower(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Try to tap search again or check back later.",
            textAlign: TextAlign.center,
            style: GoogleFonts.indieFlower(fontSize: 12, color: Colors.black),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTutorsList() {
    return ListView.builder(
      itemCount: nearbyTutors.length,
      itemBuilder: (context, index) {
        final tutor = nearbyTutors[index];
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                image: DecorationImage(
                  image: AssetImage('assets/images/cardsbg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListTile(
                leading: ClipOval(
                  child: Image.network(
                    tutor['profileImageUrl']?.isNotEmpty == true
                        ? tutor['profileImageUrl']
                        : 'https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2247726673.jpg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  '${tutor['firstName']} ${tutor['lastName']}',
                  style: GoogleFonts.indieFlower(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                subtitle: Text(
                  'Email: ${tutor['email']}',
                  style: GoogleFonts.indieFlower(
                      fontSize: 14, color: Colors.white70),
                ),
                onTap: () {
                  // Handle tap event
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _searchNearbyTutors() async {
    setState(() {
      isLoading = true;
    });

    try {
      Position position = await _determinePosition();
      print(
          'Current Position: Lat ${position.latitude}, Lng ${position.longitude}');

      final testPosition = Position(
        latitude:
            13.79079053314057,
        longitude:
            121.04230220219588,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 5.0,
        speed: 0.0,
        speedAccuracy: 5.0,
      );

      final snapshot = await _databaseRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
            snapshot.snapshot.value as Map<dynamic, dynamic>);
        List<Map<String, dynamic>> tempTutors = [];

        data.forEach((key, value) {
          final user =
              Map<String, dynamic>.from(value as Map<dynamic, dynamic>);

          if (user.containsKey('location') && user['location'] != null) {
            final location = user['location'];
            print('Raw location data for user ${user['firstName']}: $location');

            try {
              final double latitude =
                  double.parse(location['latitude'].toString());
              final double longitude =
                  double.parse(location['longitude'].toString());

              final double distance = Geolocator.distanceBetween(
                testPosition.latitude,
                testPosition.longitude,
                latitude,
                longitude,
              );

              print(
                  'User: ${user['firstName']} ${user['lastName']} is $distance meters away');

              if (distance <= 10000) {
                tempTutors.add(user);
              }
            } catch (e) {
              print('Error parsing location for user ${user['firstName']}: $e');
            }
          } else {
            print(
                'Location data is missing for user: ${user['firstName']} ${user['lastName']}');
          }
        });

        setState(() {
          nearbyTutors = tempTutors;
          isLoading = false;
        });
      } else {
        setState(() {
          nearbyTutors = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching nearby tutors: $e');
      setState(() {
        isLoading = false; 
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}

class OnlineTutorsTab extends StatefulWidget {
  const OnlineTutorsTab({super.key});

  @override
  _OnlineTutorsTabState createState() => _OnlineTutorsTabState();
}

class _OnlineTutorsTabState extends State<OnlineTutorsTab> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref('tutors');
  List<Map<String, dynamic>> allTutors = [];
  bool isLoading = false; 

  @override
  void initState() {
    super.initState();
    _fetchAllTutors();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 10),
        Expanded(
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.teal)
                : allTutors.isEmpty
                    ? _buildNoTutorsFound()
                    : _buildTutorsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoTutorsFound() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/aralink-main-logo.png',
              width: 100, height: 100),
          const SizedBox(height: 10),
          Text(
            "No tutors found",
            style: GoogleFonts.indieFlower(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Try checking back later.",
            textAlign: TextAlign.center,
            style: GoogleFonts.indieFlower(fontSize: 12, color: Colors.black),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTutorsList() {
    return ListView.builder(
      itemCount: allTutors.length,
      itemBuilder: (context, index) {
        final tutor = allTutors[index];
        return Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                image: DecorationImage(
                  image: AssetImage('assets/images/cardsbg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: ListTile(
                leading: ClipOval(
                  child: Image.network(
                    tutor['profileImageUrl']?.isNotEmpty == true
                        ? tutor['profileImageUrl']
                        : 'https://www.shutterstock.com/image-vector/user-profile-icon-vector-avatar-600nw-2247726673.jpg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  '${tutor['firstName']} ${tutor['lastName']}',
                  style: GoogleFonts.indieFlower(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                subtitle: Text(
                  'Email: ${tutor['email']}',
                  style: GoogleFonts.indieFlower(
                      fontSize: 14, color: Colors.white70),
                ),
                onTap: () {
                  // Handle tap event
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchAllTutors() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await _databaseRef.once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(
            snapshot.snapshot.value as Map<dynamic, dynamic>);
        List<Map<String, dynamic>> tempTutors = [];

        data.forEach((key, value) {
          final user =
              Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          tempTutors.add(user);
        });

        setState(() {
          allTutors = tempTutors;
          isLoading = false;
        });
      } else {
        setState(() {
          allTutors = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching tutors: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
}
