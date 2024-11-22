import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _totalHoursController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _taglineController = TextEditingController();

  List<String> _selectedDayAvailability = [];
  List<String> _selectedSessions = [];
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
    'Pre-kinder',
    'Grade I',
    'Grade II',
    'Grade III',
    'Grade IV',
    'Grade V',
    'Grade VI',
  ];
  final List<String> _subjectOptions = [
    'Mathematics',
    'Science',
    'English',
    'History'
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

      try {
        final snapshot = await databaseRef.get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;

          setState(() {
            _selectedDayAvailability =
                (data['dayAvailability'] as String?)?.split(', ') ?? [];
            _selectedSessions =
                (data['preferredSessions'] as String?)?.split(', ') ?? [];
            _addressController.text = data['address'] as String? ?? '';
            _totalHoursController.text = data['totalHours'] as String? ?? '';
            _rateController.text = data['ratePerHour'] as String? ?? '';
            _selectedGradeLevel = data['gradeLevel'] as String?;
            _selectedSubject = data['subjects'] as String?;
            _taglineController.text = data['tagline'] as String? ?? '';
            _isLoading = false;
          });
        } else {
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
          'dayAvailability': _selectedDayAvailability.join(', '),
          'address': _addressController.text,
          'preferredSessions': _selectedSessions.join(', '),
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
                    _buildMultiSelectField(
                        'Day Availability', _dayAvailabilityOptions, (value) {
                      setState(() {
                        _selectedDayAvailability = value;
                      });
                    }, _selectedDayAvailability),
                    const SizedBox(height: 20),
                    _buildMultiSelectField('Tutoring Sessions', _sessionOptions,
                        (value) {
                      setState(() {
                        _selectedSessions = value;
                      });
                    }, _selectedSessions),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildTextField(
                              'Total Hours', _totalHoursController,
                              isNumber: true),
                        ),
                        const SizedBox(
                            width: 10), 
                        Expanded(
                          child: _buildTextField(
                              'Rate per Hour', _rateController,
                              isNumber: true),
                        ),
                      ],
                    ),
                    _buildDropdownField('Grade Level', _gradeLevelOptions,
                        (value) {
                      setState(() {
                        _selectedGradeLevel = value;
                      });
                    }, _selectedGradeLevel),
                    _buildDropdownField('Subject', _subjectOptions, (value) {
                      setState(() {
                        _selectedSubject = value;
                      });
                    }, _selectedSubject),
                    _buildTextField('Address', _addressController),
                    _buildTextField('Tagline', _taglineController),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
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

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.indieFlower(
            color: Colors.teal,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
        style: GoogleFonts.indieFlower(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        inputFormatters:
            isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
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
                  fontSize: 16),
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

  Widget _buildMultiSelectField(String label, List<String> options,
      ValueChanged<List<String>> onChanged, List<String> selectedValues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.indieFlower(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
        Wrap(
          spacing: 10,
          children: options.map((option) {
            final bool isSelected = selectedValues.contains(option);
            return ChoiceChip(
              label: Text(
                option,
                style: GoogleFonts.indieFlower(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.teal,
                ),
              ),
              selected: isSelected,
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    selectedValues.add(option);
                  } else {
                    selectedValues.remove(option);
                  }
                  onChanged(selectedValues);
                });
              },
              selectedColor: Colors.teal,
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
      ],
    );
  }
}
