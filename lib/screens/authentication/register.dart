import 'package:aralink_app/common/map_screen.dart';
import 'package:aralink_app/screens/authentication/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
        ],
      ),
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
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        _database.child("users/${userCredential.user!.uid}").set({
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "location": _userLocation != null
              ? {
                  "latitude": _userLocation!.latitude,
                  "longitude": _userLocation!.longitude,
                }
              : null,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } on FirebaseAuthException {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/aralink-main-logo.png',
                  width: 26,
                  height: 26,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Registration Failed!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Iconsax.warning_25,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
            backgroundColor: Colors.teal,
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
