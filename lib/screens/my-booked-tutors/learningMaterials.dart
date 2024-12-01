import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_web_browser/flutter_web_browser.dart';

class LearningMaterialsScreen extends StatelessWidget {
  final String userId;

  LearningMaterialsScreen({required this.userId});

  Future<List<Map<String, dynamic>>> _fetchLearningMaterials() async {
    DatabaseReference materialsRef =
        FirebaseDatabase.instance.ref('LearningMaterials/$userId');
    DataSnapshot materialsSnapshot = await materialsRef.get();

    List<Map<String, dynamic>> materials = [];

    if (materialsSnapshot.exists) {
      Map<dynamic, dynamic> materialsMap =
          materialsSnapshot.value as Map<dynamic, dynamic>;
      materialsMap.forEach((key, value) {
        String status = value['status'];
        if (status == 'Approved') {
          materials.add({
            'id': key,
            'fileUrl': value['fileUrl'],
            'description': value['description'],
          });
        }
      });
    }

    return materials;
  }

Future<void> _openUrl(String? urli) async {
  if (urli == null || urli.isEmpty) {
    print('Invalid URL');
    return;
  }

  final Uri uri = Uri.parse(urli);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print('Could not launch $urli');
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
          'Learning Materials',
          style: GoogleFonts.indieFlower(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( 
        future: _fetchLearningMaterials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.teal));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final materials = snapshot.data!;
            if (materials.isEmpty) {
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
                        "No learning materials available yet.",
                        style: GoogleFonts.indieFlower(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Please wait for your tutor to publish your learning material.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.indieFlower(
                            fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];
                return Card(
                  color: Colors.white,
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: ListTile(
                    leading: Icon(Iconsax.link),
                    title: Text(material['description'] ?? 'No description',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.teal)),
                    subtitle: Text("Tap here to view",
                        style: TextStyle(color: Colors.grey)),
                    onTap: () {
                      // Open the URL using FlutterWebBrowser
                      _openUrl(material['fileUrl']);
                    },
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}
