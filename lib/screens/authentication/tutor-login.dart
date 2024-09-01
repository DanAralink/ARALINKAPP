import 'package:aralink_app/common/clasessMethods.dart';
import 'package:aralink_app/screens/authentication/login.dart';
import 'package:aralink_app/screens/authentication/tutor-register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class TutorLoginScreen extends StatefulWidget {
  const TutorLoginScreen({Key? key}) : super(key: key);

  @override
  _TutorLoginScreenState createState() => _TutorLoginScreenState();
}

class _TutorLoginScreenState extends State<TutorLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  var height, width;

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 240, 183),
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(height: 20),
              _header(context),
              _inputField(context),
              _forgotPassword(context),
              _signup(context),
              _signupTutee(context),
            ],
          ),
        ),
      ),
    );
  }

  _header(context) {
    return Column(
      children: [
        Image.asset(
          "assets/images/aralink-logo.png",
          height: 150,
          width: 150,
        ),
        SizedBox(height: 20),
        Text(
          "Welcome Tutor!",
          style: GoogleFonts.indieFlower(
            fontSize: width * 0.068,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          "Login to continue",
          style: GoogleFonts.indieFlower(
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  bool _isPasswordVisible = false;

  Widget _inputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        TextField(
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
        ),
        const SizedBox(height: 20),
        TextField(
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
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isLoading ? null : _loginUser,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.teal)
              : Text(
                  "Login",
                  style: GoogleFonts.indieFlower(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {
        // Implement forgot password
      },
      child: Text(
        "Forgot Password?",
        style: GoogleFonts.indieFlower(
          fontSize: width * 0.032,
          color: Colors.black54,
        ),
      ),
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: GoogleFonts.indieFlower(
            fontSize: width * 0.032,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TutorRegisterScreen()),
            );
          },
          child: Text(
            "Sign up here!",
            style: GoogleFonts.indieFlower(
              fontSize: width * 0.032,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  _signupTutee(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Want to change to Tutee?",
          style: GoogleFonts.indieFlower(
            fontSize: width * 0.032,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          child: Text(
            "Go here!",
            style: GoogleFonts.indieFlower(
              fontSize: width * 0.032,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in the user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Reference to the tutor's data in the Realtime Database
        DatabaseReference tutorRef = FirebaseDatabase.instance
            .ref()
            .child('tutors')
            .child(user.uid); // Use user.uid to fetch the specific tutor data

        // Fetch tutor data
        DatabaseEvent event =
            await tutorRef.once(); // Once returns a DatabaseEvent

        // Access the snapshot from the event
        DataSnapshot snapshot = event.snapshot;

        // Ensure snapshot value is not null and contains the 'account-status' key
        final tutorData = snapshot.value as Map?;

        if (tutorData != null && tutorData['account-status'] == 'verified') {
          // Tutor is verified, proceed to the next screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => TutorTabNavigation()),
          );
        } else {
          // Show an error message if the tutor is not verified
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
                        'Your account is not yet verified. Please try again later.',
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

          // Optionally, sign out the user since they're not allowed to proceed
          await _auth.signOut();
        }
      }
    } on FirebaseAuthException catch (e) {
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
                    'Login Failed!',
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
