import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

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
        materials.add({
          'id': key,
          'fileUrl': value['fileUrl'],
          'description': value['description'],
        });
      });
    }

    return materials;
  }

  Future<void> _openUrl(String? url) async {
    if (url != null && await canLaunch(url)) {
      await launch(url);
    } else {
      // If the URL cannot be launched, fallback to a default web URL
      const String fallbackUrl = 'https://www.google.com'; // Adjust as necessary
      if (await canLaunch(fallbackUrl)) {
        await launch(fallbackUrl);
      } else {
        print('Could not launch: $url');
      }
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
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final materials = snapshot.data!;
            if (materials.isEmpty) {
              return Center(child: Text('No learning materials available.'));
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
                    title: Text(material['description'] ?? 'No description', style: GoogleFonts.indieFlower(fontWeight: FontWeight.bold)),
                    onTap: () {
                      // Use the _openUrl method to handle the URL
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
