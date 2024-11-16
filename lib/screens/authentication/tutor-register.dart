import 'package:aralink_app/common/map_screen.dart';
import 'package:aralink_app/screens/authentication/tutor-login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TutorRegisterScreen extends StatefulWidget {
  @override
  _TutorRegisterScreenState createState() => _TutorRegisterScreenState();
}

class _TutorRegisterScreenState extends State<TutorRegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _credentialController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  LatLng? _userLocation;
  String? _uploadedImageUrl;
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 20),
              _header(context, width),
              _inputField(context, width),
              _signup(context, width),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, double width) {
    return Column(
      children: [
        Image.asset(
          "assets/images/aralink-logo.png",
          height: 150,
          width: 150,
        ),
        const SizedBox(height: 20),
        Text(
          "Register as Tutor!",
          style: GoogleFonts.indieFlower(
            fontSize: width * 0.068,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          "Please fill up the necessary credentials.",
          style: GoogleFonts.indieFlower(
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _inputField(BuildContext context, double width) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          TextFormField(
            controller: _firstNameController,
            cursorColor: Colors.black54,
            decoration: InputDecoration(
              hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
              hintText: "First Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.black.withOpacity(0.2),
              filled: true,
              prefixIcon: const Icon(
                Iconsax.user,
                color: Colors.white,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _lastNameController,
            cursorColor: Colors.black54,
            decoration: InputDecoration(
              hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
              hintText: "Last Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.black.withOpacity(0.2),
              filled: true,
              prefixIcon: const Icon(
                Iconsax.user,
                color: Colors.white,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            cursorColor: Colors.black54,
            decoration: InputDecoration(
              hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
              hintText: "Email Address",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.black.withOpacity(0.2),
              filled: true,
              prefixIcon: const Icon(
                Iconsax.user,
                color: Colors.white,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _credentialController,
            cursorColor: Colors.black54,
            decoration: InputDecoration(
              hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
              hintText: "Credential Links (Drive Link)",
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            cursorColor: Colors.black54,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
              hintText: "Password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.black.withOpacity(0.2),
              filled: true,
              prefixIcon: const Icon(
                Iconsax.lock,
                color: Colors.white,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Iconsax.eye : Iconsax.eye_slash,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              } else if (value.length < 8) {
                return 'Password must be at least 8 characters';
              } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'Password must contain at least one uppercase letter';
              } else if (!RegExp(r'[a-z]').hasMatch(value)) {
                return 'Password must contain at least one lowercase letter';
              } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'Password must contain at least one number';
              } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                return 'Password must contain at least one special character';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            cursorColor: Colors.black54,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              hintStyle: GoogleFonts.indieFlower(color: Colors.black54),
              hintText: "Confirm Password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              fillColor: Colors.black.withOpacity(0.2),
              filled: true,
              prefixIcon: const Icon(
                Iconsax.lock,
                color: Colors.white,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Iconsax.eye : Iconsax.eye_slash,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    LatLng? selectedLocation = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    );

                    if (selectedLocation != null) {
                      setState(() {
                        _userLocation = selectedLocation;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.teal,
            ),
            child: Text(
              "Select Location",
              style: GoogleFonts.indieFlower(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (_userLocation != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Location: ${_userLocation!.latitude}, ${_userLocation!.longitude}",
                style: const TextStyle(color: Colors.black),
              ),
            ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                activeColor: Colors.white,
                checkColor: Colors.black,
                value: _isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _isChecked = value ?? false;
                  });
                },
              ),
              Text(
                "I agree to the Terms & Conditions",
                style: GoogleFonts.indieFlower(color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _registerUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.teal)
                : Text(
                    "Sign up",
                    style: GoogleFonts.indieFlower(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () => _showTermsDialog(context),
            child: Text(
              "Terms & Conditions & Data Privacy",
              textAlign: TextAlign.center,
              style: GoogleFonts.indieFlower(
                  color: Colors.black, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Image.asset(
                "assets/images/aralink-logo.png",
                width: 90,
                height: 90,
              ),
              const Text(
                "Data Privacy and Terms and Conditions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Terms and Conditions for Tutors\n"
                  "Last Updated: November 16, 2024\n\n"
                  "Welcome to Aralink. By registering as a Tutor, you agree to the following terms:\n\n"
                  "1. User Account\n"
                  "1. Eligibility\n"
                  "• Tutors must provide accurate and verifiable information, including credentials, identification, and availability.\n"
                  "• Tutors must comply with local laws and regulations related to providing tutoring services.\n\n"
                  "2. Account Security\n"
                  "• Maintain the confidentiality of your login credentials.\n"
                  "• Notify the Application administrators in case of account-related issues or unauthorized access.\n\n"
                  "2. Responsibilities of Tutors\n"
                  "• Deliver professional and respectful tutoring services to Tutees.\n"
                  "• Provide accurate and up-to-date information on subjects, schedules, and rates.\n"
                  "• Respond promptly to booking requests and communication from Tutees.\n"
                  "• Adhere to agreed schedules and notify Parents/Guardians in advance of any changes.\n"
                  "• Maintain a safe and conducive environment for tutoring sessions.\n"
                  "• Conduct all transactions and agreements exclusively within the Application platform.\n\n"
                  "3. Privacy and Security\n"
                  "• Respect the privacy of Tutees and their Parents/Guardians.\n"
                  "• Do not share or misuse the personal information of Tutees obtained through the Application.\n"
                  "• Keep records of all tutoring activities confidential unless required by law or agreed upon with Parents/Guardians.\n\n"
                  "4. Booking and Payment\n"
                  "1. Booking Process\n"
                  "• Accept or decline booking requests based on your availability.\n"
                  "• Update your profile regularly to reflect accurate availability and rates.\n\n"
                  "2. Payment\n"
                  "• All payment arrangements are managed independently between Tutors and Parents/Guardians.\n"
                  "• Tutors are responsible for specifying their rates and ensuring clarity in payment terms.\n\n"
                  "5. Prohibited Actions\n"
                  "• Misrepresenting qualifications or credentials.\n"
                  "• Engaging in inappropriate behavior or communication with Tutees or their Parents/Guardians.\n"
                  "• Using the Application to solicit services unrelated to tutoring.\n\n"
                  "6. Verification and Compliance\n"
                  "• Tutors must provide proof of identity (e.g., valid ID, police clearance, or NBI clearance) during registration for security purposes.\n"
                  "• Comply with any additional verification procedures required by the Application administrators.\n\n"
                  "7. Termination of Use\n"
                  "The Application reserves the right to suspend or terminate accounts for:\n"
                  "• Providing false or misleading information.\n"
                  "• Violations of these Terms and Conditions.\n"
                  "• Unprofessional conduct toward Tutees or Parents/Guardians.\n\n"
                  "General Provisions\n"
                  "• Both Tutees and Tutors must adhere to the Code of Conduct and any updates to these Terms and Conditions.\n"
                  "• By continuing to use the Application, you accept any updates or modifications made to these Terms.\n"
                  "For questions or support, contact Mr. Dan Noble at capstonearalink@gmail.com.\n\n"
                  "\n"
                  "Privacy Policy for Tutors\n"
                  "Last Updated: November 16, 2024\n\n"
                  "Aralink is committed to protecting the privacy of Tutors using the Application. This Privacy Policy outlines how your data is collected, used, and protected. By using the Application, you agree to this policy.\n\n"
                  "1. Information We Collect\n"
                  "1. Personal Information\n"
                  "• Name, email address, phone number, location, educational qualifications, valid ID, and profile picture.\n"
                  "2. Technical Information\n"
                  "• Device type, operating system, IP address, and Application usage data.\n"
                  "3. Communication Data\n"
                  "• Messages exchanged with Tutees/Parents via the in-app chat feature are stored temporarily but are not monitored by administrators.\n\n"
                  "2. How We Use Your Information\n"
                  "1. Facilitate Tutor Matching\n"
                  "• Connect you with Tutees based on location, subject expertise, and availability.\n"
                  "2. Profile Management\n"
                  "• Showcase your credentials and availability to potential clients.\n"
                  "3. Notifications and Updates\n"
                  "• Notify you of new bookings, messages, and relevant system updates.\n"
                  "4. Prohibited Transactions\n"
                  "• All payments and service agreements must occur exclusively within the Application. Engaging in transactions outside the platform is prohibited to ensure security and accountability.\n\n"
                  "3. Data Security Measures\n"
                  "• Personal data is encrypted during transmission and storage.\n"
                  "• Access is restricted to authorized personnel.\n"
                  "• While we implement robust security measures, Tutors are responsible for safeguarding their accounts.\n"
                  "Note: The in-app chat feature is not monitored by administrators. Tutors are responsible for maintaining professional and respectful communication.\n\n"
                  "4. User Rights\n"
                  "1. Access and Correction\n"
                  "• Update your information through your profile.\n"
                  "2. Data Deletion\n"
                  "• Request the removal of your account and associated data by contacting support.\n"
                  "3. Consent Withdrawal\n"
                  "• Manage settings to disable specific data processing features.\n\n"
                  "5. Data Retention\n"
                  "We retain personal data only for:\n"
                  "• Service delivery and legal compliance.\n"
                  "Inactive accounts may be deleted after [Insert Retention Period].\n\n"
                  "6. Contact Information\n"
                  "For questions or concerns about this policy, contact us at:\n"
                  "Email: capstonearalink@gmail.com\n"
                  "Phone: +639471749955\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 255, 240, 183),
                minimumSize: const Size(100, 40),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Widget _signup(BuildContext context, double width) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account?",
              style: GoogleFonts.indieFlower(
                fontSize: width * 0.032,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TutorLoginScreen()),
                );
              },
              child: Text(
                "Log in here!",
                style: GoogleFonts.indieFlower(
                  fontSize: width * 0.032,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (!_isChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Center(child: Text("Please accept the terms and conditions.")),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await userCredential.user!.sendEmailVerification();

        // Get the FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // Store the user's data in the Firebase Realtime Database
        await _database.child("tutors/${userCredential.user!.uid}").set({
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "email": _emailController.text.trim(),
          "credentialLink": _credentialController.text.trim(),
          "password": _passwordController.text.trim(),
          "account-status": "not verified",
          "location": _userLocation != null
              ? {
                  "latitude": _userLocation!.latitude,
                  "longitude": _userLocation!.longitude,
                }
              : null,
          "idImageUrl": _uploadedImageUrl,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
          "fcmToken": fcmToken, // Store the FCM token
        });

        // Notify user to verify their email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Verification email sent. Please verify your email before logging in.",
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.teal,
            duration: Duration(seconds: 5),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorLoginScreen()),
        );
      } on FirebaseAuthException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Failed!')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
