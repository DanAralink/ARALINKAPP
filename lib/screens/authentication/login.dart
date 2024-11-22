import 'package:aralink_app/common/clasessmethods.dart';
import 'package:aralink_app/screens/authentication/forgotPassword.dart';
import 'package:aralink_app/screens/authentication/register.dart';
import 'package:aralink_app/screens/authentication/tutor-login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
            _signupTutor(context),
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
          "Welcome Tutee!",
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
            shape: const StadiumBorder(),
            backgroundColor: Colors.teal,
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
              MaterialPageRoute(builder: (context) => RegisterScreen()),
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

  _signupTutor(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Want to change to Tutor?",
          style: GoogleFonts.indieFlower(
            fontSize: width * 0.032,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TutorLoginScreen()),
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
        await user.reload(); 
        if (user.emailVerified) {
          DatabaseReference userRef =
              FirebaseDatabase.instance.ref().child('users').child(user.uid);

          await userRef.update({'verified': true});

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TabNavigation()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your email is not verified. Please verify your email to log in.',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          _auth.signOut(); // Sign out the user if not verified
        }
      }
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Invalid email or password!',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.white),
            ),
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
