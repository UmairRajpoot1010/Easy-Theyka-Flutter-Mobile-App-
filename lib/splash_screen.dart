import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'homescreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {  // Check if widget is still mounted
        Navigator.pushReplacement(  // Use pushReplacement instead of push
          context,
          MaterialPageRoute(builder: (context) => const Homescreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff030e4e),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 150),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: 164,
                    height: 175,
                    child: Image.asset('images/icon.png'),
                  ),
                ),
                Text(
                  'Easy Theyka',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Color(0xffF39F1B),
                      fontSize: 20,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                Text(
                  'Build Your Dreams',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 300),
                Text(
                  'version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
