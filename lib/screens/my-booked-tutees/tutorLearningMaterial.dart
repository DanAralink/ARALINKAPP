import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class TutorLearningMaterialsScreen extends StatefulWidget {
  final String studentId;

  const TutorLearningMaterialsScreen({required this.studentId, Key? key})
      : super(key: key);

  @override
  _TutorLearningMaterialsScreenState createState() =>
      _TutorLearningMaterialsScreenState();
}

class _TutorLearningMaterialsScreenState
    extends State<TutorLearningMaterialsScreen> {
  late Future<List<Map<String, dynamic>>> _learningMaterials;

  @override
  void initState() {
    super.initState();
    _learningMaterials = _fetchLearningMaterials();
  }

  Future<List<Map<String, dynamic>>> _fetchLearningMaterials() async {
    DatabaseReference materialsRef =
        FirebaseDatabase.instance.ref('LearningMaterials/${widget.studentId}');
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
          'status:': 'not verified',
        });
      });
    }

    return materials;
  }

  void _addLearningMaterial() {
    showDialog(
      context: context,
      builder: (context) {
        String fileUrl = '';
        String description = '';

        return AlertDialog(
          title: Text("Add Learning Material"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: "File URL"),
                onChanged: (value) {
                  fileUrl = value;
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: "Description"),
                onChanged: (value) {
                  description = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                DatabaseReference materialsRef = FirebaseDatabase.instance
                    .ref('LearningMaterials/${widget.studentId}');

                await materialsRef.push().set({
                  'fileUrl': fileUrl,
                  'description': description,
                });

                Navigator.of(context).pop();
                setState(() {
                  _learningMaterials = _fetchLearningMaterials();
                });
              },
              child: Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
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
        future: _learningMaterials,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final materials = snapshot.data!;

            if (materials.isEmpty) {
              return const Center(
                  child: Text('No learning materials available.'));
            }

            return ListView.builder(
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];

                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text(material['description'] ?? 'No description'),
                    subtitle: Text(material['fileUrl'] ?? 'No URL'),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLearningMaterial,
        child: Icon(Icons.add),
      ),
    );
  }
}
