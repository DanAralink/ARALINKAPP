import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class AboutTutorScreen extends StatefulWidget {
  @override
  _AboutTutorScreenState createState() => _AboutTutorScreenState();
}

class _AboutTutorScreenState extends State<AboutTutorScreen> {
  late Size mediaSize;

  @override
  Widget build(BuildContext context) {
    mediaSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Center(
          child: Text(
            'About',
            style: GoogleFonts.indieFlower(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 223, 223, 223),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Done',
              style: GoogleFonts.indieFlower(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14.0),
        children: [
          SizedBox(
            width: mediaSize.width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/aralink-logo.png",
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            title: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'App Description\n',
                    style: GoogleFonts.indieFlower(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            subtitle: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(
                children: [
                  TextSpan(
                    text:
                        '“Aralink: A Mobile Application for Pre-Kinder to Elementary Tutor Matching”, is an application that can be able to search registered tutors on the application and provide recommendation to the users. Data was filtered according to location, grade level and subjects. The program contains personal details of every registered tutor and their respective location. It also has the image and contact information of the mentors.',
                    style: GoogleFonts.indieFlower(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 14, right: 14),
            child: Divider(
              thickness: 1,
              color: Color.fromARGB(255, 70, 70, 70),
            ),
          ),
          ListTile(
            title: Text('Developed by',
                style: GoogleFonts.indieFlower(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                )),
            subtitle: Text('Team Aralink',
                style: GoogleFonts.indieFlower(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                )),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 14, right: 14),
            child: Divider(
              thickness: 1,
              color: Color.fromARGB(255, 70, 70, 70),
            ),
          ),
          ListTile(
            title: Row(
              children: [
                Text('© Aralink 2024',
                    style: GoogleFonts.indieFlower(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    )),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
    );
  }
}
