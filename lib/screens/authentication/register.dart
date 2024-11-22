import 'package:aralink_app/common/map_screen.dart';
import 'package:aralink_app/screens/authentication/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  LatLng? _userLocation;
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
          "Register as Tutee!",
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
          const SizedBox(height: 30),
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
                        fontWeight: FontWeight.bold),
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
                  "Terms and Conditions for Tutees (Parents/Guardians)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Last Updated: November 16, 2024",
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Welcome to the Aralink. By registering as a Tutee or on behalf of a Tutee (Parent/Guardian), you agree to the following terms:",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "1. User Account",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "1.1 Eligibility\n"
                  "• Parents/Guardians must be at least 18 years old to register and manage a Tutee account.\n"
                  "• Accurate and up-to-date information must be provided during registration.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                Text(
                  "1.2 Account Security\n"
                  "• You are responsible for maintaining the confidentiality of your login credentials.\n"
                  "• Notify the Application administrators immediately in case of unauthorized account access.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "2. Responsibilities of Parents/Guardians",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "2.1 Ensure that interactions with Tutors are respectful and professional.\n"
                  "2.2 Monitor the Tutee's safety and progress during and after tutoring sessions.\n"
                  "2.3 Use the Application solely for finding and booking qualified Tutors to support the academic needs of the Tutee.\n"
                  "2.4 Avoid editing or tampering with any Tutor profile or provided credentials.\n"
                  "2.5 Refrain from initiating or engaging in any transactions or agreements outside the Application.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "3. Booking and Payment",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "3.1 Booking Process\n"
                  "• Book sessions through the Application by selecting from available Tutors based on their schedules, rates, and qualifications.\n"
                  "• Ensure the accuracy of the information provided when booking a Tutor.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                Text(
                  "3.2 Payment\n"
                  "• Payments for tutoring services are managed independently and are not processed within the Application.\n"
                  "• Agree upon payment terms directly with the Tutor.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "4. Prohibited Actions",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "• Using the Application to harass, threaten, or misuse communication features.\n"
                  "• Providing false or misleading information when registering, booking, or interacting with Tutors.\n"
                  "• Recording or disseminating private tutoring sessions without prior consent.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "5. Privacy and Data Use",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "• Your data will be collected and used to facilitate the tutor-matching process.\n"
                  "• The Application is committed to protecting your information, but it is not liable for third-party breaches or negligence.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "6. Termination of Use",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "The Application reserves the right to suspend or terminate accounts for:\n"
                  "• Misuse of the platform.\n"
                  "• Violations of these Terms and Conditions.\n"
                  "• Disrespectful or unprofessional conduct toward Tutors or other users.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 20),
                Text(
                  "Privacy Policy for Tutees (Parents/Guardians)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Last Updated: November 16, 2024",
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  "Aralink values the privacy of Tutees and Parents/Guardians. This Privacy Policy explains how we collect, use, and protect your information when you use the Aralink application. By using the Application, you agree to this policy.",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "1. Information We Collect",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "1.1 Personal Information\n"
                  "• Name, email address, phone number, location, and details of the Tutee (e.g., grade level, subject preferences).\n"
                  "1.2 Technical Information\n"
                  "• Device type, operating system, IP address, and Application usage data (e.g., pages viewed, session logs).\n"
                  "1.3 Communication Data\n"
                  "• Messages exchanged with Tutors through the in-app chat feature are stored temporarily for functionality purposes but are not monitored by administrators.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "2. How We Use Your Information",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "2.1 Facilitate Tutor Matching\n"
                  "• Help connect you with qualified Tutors based on your preferences and location.\n"
                  "2.2 Account Management\n"
                  "• Maintain your account and provide a secure user experience.\n"
                  "2.3 Notifications and Updates\n"
                  "• Send booking confirmations, schedule reminders, and important updates.\n"
                  "2.4 Prohibited Transactions\n"
                  "• All payments and transactions must be conducted exclusively within the Application. Transactions or agreements outside the platform are prohibited to ensure security and transparency.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "3. Data Security Measures",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "• Your data is encrypted during transmission and at rest.\n"
                  "• Access is restricted to authorized personnel only.\n"
                  "• While we strive to secure your information, users are responsible for safeguarding their account credentials.\n"
                  "Note: The in-app chat feature is not monitored. Parents/Guardians are responsible for ensuring respectful and lawful communication with Tutors.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "4. User Rights",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "4.1 Access and Correction\n"
                  "• Update your information via account settings.\n"
                  "4.2 Data Deletion\n"
                  "• Request deletion of your account by contacting support.\n"
                  "4.3 Consent Withdrawal\n"
                  "• Withdraw consent at any time by deactivating your account, although some information may remain in our records.\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "5. Third-Party Services",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "We do not share your data with third-party services unless required by law or to provide functionality (e.g., payment processing).\n",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 10),
                Text(
                  "By using the Application, you consent to our Privacy Policy and Terms and Conditions. If you disagree, please refrain from using the Application.",
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                SizedBox(height: 20),
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
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
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
        // Create user
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Send email verification
        await userCredential.user!.sendEmailVerification();
        
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // Save user data in the database
        _database.child("users/${userCredential.user!.uid}").set({
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "email": _emailController.text.trim(),
          "location": _userLocation != null
              ? {
                  "latitude": _userLocation!.latitude,
                  "longitude": _userLocation!.longitude,
                }
              : null,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
          "fcmToken": fcmToken,
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

        // Redirect to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = e.message ?? "Registration failed!";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, textAlign: TextAlign.center),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
