import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SetBookingProfile extends StatefulWidget {
  const SetBookingProfile({super.key});

  @override
  _SetBookingProfileState createState() => _SetBookingProfileState();
}

class _SetBookingProfileState extends State<SetBookingProfile> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _totalHoursController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();

  String? _selectedDayAvailability;
  String? _selectedSession;
  String? _selectedGradeLevel;
  String? _selectedSubject;

  final List<String> _dayAvailabilityOptions = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> _sessionOptions = ['Morning', 'Afternoon', 'Evening'];
  final List<String> _gradeLevelOptions = [
    'Elementary',
    'Middle School',
    'High School',
    'College'
  ];
  final List<String> _subjectOptions = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Computer Science'
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  void _fetchProfileData() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final uid = user.uid;
      final DatabaseReference databaseRef =
          FirebaseDatabase.instance.ref().child('tutor_profiles').child(uid);

      print('Fetching profile data for user: $uid');

      try {
        final snapshot = await databaseRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;

          print('Profile data retrieved: $data');

          setState(() {
            _selectedDayAvailability = data['dayAvailability'] as String?;
            _addressController.text = data['address'] as String? ?? '';
            _statusController.text = data['status'] as String? ?? '';
            _selectedSession = data['preferredSessions'] as String?;
            _totalHoursController.text = data['totalHours'] as String? ?? '';
            _rateController.text = data['ratePerHour'] as String? ?? '';
            _selectedGradeLevel = data['gradeLevel'] as String?;
            _selectedSubject = data['subjects'] as String?;
            _taglineController.text = data['tagline'] as String? ?? '';
            _isLoading = false; 
          });
        } else {
          print('No profile data found for user: $uid');
          setState(() {
            _isLoading = false;
          });
        }
      } catch (error) {
        print('Error fetching profile data: $error');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('No user logged in.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveBookingProfile() async {
    if (_formKey.currentState!.validate()) {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final uid = user.uid;
        final DatabaseReference databaseRef =
            FirebaseDatabase.instance.ref().child('tutor_profiles').child(uid);

        await databaseRef.set({
          'dayAvailability': _selectedDayAvailability,
          'address': _addressController.text,
          'status': _statusController.text,
          'preferredSessions': _selectedSession,
          'totalHours': _totalHoursController.text,
          'ratePerHour': _rateController.text,
          'gradeLevel': _selectedGradeLevel,
          'subjects': _selectedSubject,
          'tagline': _taglineController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile saved successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 240, 183),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        centerTitle: true,
        title: Text(
          'Set Booking Profile',
          style: GoogleFonts.indieFlower(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.teal))
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField(
                                  'Day Availability', _dayAvailabilityOptions,
                                  (value) {
                                setState(() {
                                  _selectedDayAvailability = value;
                                });
                              }, _selectedDayAvailability),
                              _buildTextField(
                                  'Total Hours', _totalHoursController),
                              _buildDropdownField(
                                  'Grade Level', _gradeLevelOptions, (value) {
                                setState(() {
                                  _selectedGradeLevel = value;
                                });
                              }, _selectedGradeLevel),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDropdownField(
                                  'Tutoring Sessions', _sessionOptions,
                                  (value) {
                                setState(() {
                                  _selectedSession = value;
                                });
                              }, _selectedSession),
                              _buildTextField('Rate/Hour', _rateController),
                              _buildDropdownField('Subject', _subjectOptions,
                                  (value) {
                                setState(() {
                                  _selectedSubject = value;
                                });
                              }, _selectedSubject),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField('Status', _statusController),
                        _buildTextField('Address', _addressController),
                        _buildTextField('Tagline', _taglineController),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width:
                          double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveBookingProfile,
                        child: Text('Save Profile',
                            style: GoogleFonts.indieFlower(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.indieFlower(
              color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.teal, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> options,
      ValueChanged<String?> onChanged, String? selectedValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.indieFlower(
              color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.teal, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
        ),
        value: selectedValue,
        onChanged: onChanged,
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: GoogleFonts.indieFlower(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          );
        }).toList(),
        validator: (value) {
          if (value == null) {
            return 'Please select $label';
          }
          return null;
        },
      ),
    );
  }
}
