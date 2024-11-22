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
          'status:': 'Pending',
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
          title: Text("Add Learning Material",
              style: GoogleFonts.indieFlower(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // File URL field with applied style
              TextFormField(
                decoration: InputDecoration(
                  hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
                  hintText: "File URL",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.black.withOpacity(0.2),
                  filled: true,
                  prefixIcon: const Icon(
                    Iconsax.link,
                    color: Colors.white,
                  ),
                ),
                onChanged: (value) {
                  fileUrl = value;
                },
              ),
              const SizedBox(height: 10),

              // Description field with applied style (textarea-like)
              TextFormField(
                maxLines: 5, // Allow multiple lines for textarea behavior
                decoration: InputDecoration(
                  hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
                  hintText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: Colors.black.withOpacity(0.2),
                  filled: true,
                  prefixIcon: const Icon(
                    Iconsax.document,
                    color: Colors.white,
                  ),
                ),
                onChanged: (value) {
                  description = value;
                },
              ),
              const SizedBox(height: 10),

              // Display status (Pending)
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 255, 240, 183),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: () async {
                    DatabaseReference materialsRef = FirebaseDatabase.instance
                        .ref('LearningMaterials/${widget.studentId}');

                    await materialsRef.push().set({
                      'fileUrl': fileUrl,
                      'description': description,
                      'status': "Pending",
                    });

                    Navigator.of(context).pop();
                    setState(() {
                      _learningMaterials = _fetchLearningMaterials();
                    });
                  },
                  child: Text("Add", style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 255, 240, 183),
                    minimumSize: const Size(100, 40),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.black)),
                ),
              ],
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
        title: Text(
          'Learning Materials',
          style: GoogleFonts.indieFlower(
              fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _learningMaterials,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.teal,
            ));
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
                        "You can add some materials here \nby tapping the add button below.",
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
        child: Icon(
          Icons.add,
          color: Colors.white, // Icon color set to white for contrast
        ),
        backgroundColor: Colors.teal, // FloatingActionButton background color
      ),
    );
  }
}
