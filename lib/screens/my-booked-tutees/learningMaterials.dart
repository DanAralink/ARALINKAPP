import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LearningMaterialsScreen extends StatelessWidget {
  final String tutorId;

  LearningMaterialsScreen({required this.tutorId});

  Future<List<Map<String, dynamic>>> _fetchLearningMaterials() async {
    // Reference to the learning materials node for the specific tutor
    DatabaseReference materialsRef = FirebaseDatabase.instance.ref('LearningMaterials/$tutorId');
    DataSnapshot materialsSnapshot = await materialsRef.get();

    List<Map<String, dynamic>> materials = [];

    if (materialsSnapshot.exists) {
      // Convert to Map<String, dynamic>
      Map<dynamic, dynamic> materialsMap = materialsSnapshot.value as Map<dynamic, dynamic>;
      materialsMap.forEach((key, value) {
        materials.add({
          'id': key,
          'fileUrl': value['fileUrl'], // Assuming you have a fileUrl field
          'description': value['description'], // Add any other fields you want
        });
      });
    }

    return materials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Learning Materials"),
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

                return ListTile(
                  title: Text(material['description'] ?? 'No description'),
                  onTap: () {
                    // Handle the click to open the PDF file
                    // You can use a package like url_launcher to open PDFs
                    // launch(material['fileUrl']);
                    print("Opening ${material['fileUrl']}");
                  },
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
