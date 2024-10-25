import 'package:aralink_app/screens/authentication/OTPVerification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;
  String generatedOTP = '';

  Future<void> _sendOTP(String email) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

      if (signInMethods.isNotEmpty) {
        final random = Random();
        generatedOTP = (random.nextInt(900000) + 100000).toString();

        String username = 'capstonearalink@gmail.com';
        String password = 'rctk whhh ewae tnxv';

        final smtpServer = gmail(username, password);
        final message = Message()
          ..from = Address(username, 'Aralink')
          ..recipients.add(email)
          ..subject = 'Password Reset OTP'
          ..text = 'Your OTP for password reset is: $generatedOTP';

        try {
          await send(message, smtpServer);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP sent to $email'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPVerificationScreen(
                email: email,
                sentOTP: generatedOTP,
              ),
            ),
          );
        } on MailerException {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send OTP. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // If the email is not registered
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This email is not registered.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
        centerTitle: true,
        title: Text(
          'Forgot Password',
          style: GoogleFonts.indieFlower(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(
                'assets/images/aralink-logo.png',
                height: 120,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Forgot Password',
              style: GoogleFonts.indieFlower(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              cursorColor: Color.fromARGB(255, 255, 240, 183),
              controller: emailController,
              decoration: InputDecoration(
                prefixIcon: Icon(Iconsax.sms),
                hintText: 'Email address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 255, 240, 183),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 255, 240, 183),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 255, 240, 183),
                    width: 2.0,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final email = emailController.text.trim();
                      if (email.isNotEmpty) {
                        _sendOTP(email);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a valid email!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text(
                      'Send OTP',
                      style:
                          GoogleFonts.indieFlower(fontSize: 16, color: Colors.teal),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 255, 240, 183),
                minimumSize: Size(double.infinity, 50),
                textStyle:
                    GoogleFonts.indieFlower(fontSize: 16, color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
