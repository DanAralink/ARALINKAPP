import 'package:aralink_app/common/clasessMethods.dart';
import 'package:aralink_app/screens/authentication/forgotPassword.dart';
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
        body: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _header(context),
                    const SizedBox(height: 20),
                    _inputField(context),
                    _forgotPassword(context),
                    const SizedBox(height: 20),
                    _signup(context),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _signupTutee(context),
          ],
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
        const SizedBox(height: 20),
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
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isLoading ? null : _loginUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.teal)
              : Text(
                  "Login",
                  style: GoogleFonts.indieFlower(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
        );
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
            Navigator.push(
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
      // Reference to the 'tutors' node
      DatabaseReference tutorsRef =
          FirebaseDatabase.instance.ref().child('tutors');

      // Fetch data from the 'tutors' node
      DataSnapshot snapshot = await tutorsRef.get();

      bool emailExists = false;

      // Check if the email exists in the tutors node
      if (snapshot.exists) {
        Map<String, dynamic> tutorsMap =
            Map<String, dynamic>.from(snapshot.value as Map);

        for (var entry in tutorsMap.entries) {
          Map<String, dynamic> tutorData =
              Map<String, dynamic>.from(entry.value);
          if (tutorData['email'] == _emailController.text.trim()) {
            emailExists = true;
            break;
          }
        }
      }

      // If the email doesn't exist in the tutors node
      if (!emailExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Center(
              child: Text(
                'The email provided does not exist in the tutors list.',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Sign in the tutor
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Check if the tutor's account is verified
        DatabaseReference tutorRef = tutorsRef.child(user.uid);
        DatabaseEvent event = await tutorRef.once();
        DataSnapshot userSnapshot = event.snapshot;

        final tutorData = userSnapshot.value as Map<dynamic, dynamic>?;

        if (tutorData != null && tutorData['account-status'] == 'verified') {
          // Navigate to the tutor dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TutorTabNavigation()),
          );
        } else {
          // Account not verified
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account is not yet verified. Please try again later.',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: Colors.teal,
              duration: Duration(seconds: 3),
            ),
          );
          await _auth.signOut();
        }
      }
    } on FirebaseAuthException {
      // Handle invalid email or password
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid email or password!',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
