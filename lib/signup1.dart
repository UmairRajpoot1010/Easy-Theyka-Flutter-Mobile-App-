import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'signup2.dart';
import 'package:google_sign_in/google_sign_in.dart';

class login1 extends StatefulWidget {
  const login1({super.key});


  @override
  State<login1> createState() => _login1State();
}

class _login1State extends State<login1> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Future<void> _registerUser() async {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   try {
  //     UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );
  //
  //     User? user = userCredential.user;
  //
  //     if (user != null) {
  //       await _firestore.collection('users').doc(user.uid).set({
  //         'uid': user.uid,
  //         'firstName': _firstNameController.text.trim(),
  //         'lastName': _lastNameController.text.trim(),
  //         'dob': _dobController.text.trim(),
  //         'email': _emailController.text.trim(),
  //         'createdAt': FieldValue.serverTimestamp(),
  //       });
  //
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Account created successfully!')),
  //         );
  //
  //         Navigator.of(context).pushReplacement(
  //           MaterialPageRoute(builder: (context) => login2()),
  //         );
  //       }
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     String errorMessage = "Registration failed";
  //
  //     if (e.code == 'email-already-in-use') {
  //       errorMessage = "This email is already registered.";
  //     } else if (e.code == 'weak-password') {
  //       errorMessage = "Password must be at least 6 characters long.";
  //     }
  //
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text(errorMessage)),
  //       );
  //     }
  //   }
  // }
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user == null) {
        throw Exception("User is null after registration");
      }

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dob': _dobController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        // Navigate after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => login2()),
          );
        });
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Registration failed";
      if (e.code == 'email-already-in-use') {
        errorMessage = "This email is already registered.";
      } else if (e.code == 'weak-password') {
        errorMessage = "Password must be at least 6 characters long.";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<void> _signupWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In was cancelled')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        // Check if user already exists in Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'firstName': user.displayName?.split(' ').first ?? '',
            'lastName': user.displayName?.split(' ').last ?? '',
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => login2()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-in failed: ${e.toString()}")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Image.asset(
                      'images/icon2.png',
                      height: 60,
                    ),
                  ),
                ),
                SizedBox(height: 6),
                Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff030E4E),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _firstNameController,
                  validator: (value) => value!.isEmpty ? 'Enter your first name' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _lastNameController,
                  validator: (value) => value!.isEmpty ? 'Enter your last name' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'DD/MM/YY',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _dobController,
                  validator: (value) => value!.isEmpty ? 'Enter your date of birth' : null,
                ),
                SizedBox(height: 15),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@gmail.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    if (!value.trim().endsWith('@gmail.com')) {
                      return 'Only Gmail addresses are allowed';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter Your Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    suffixIcon: Icon(Icons.visibility),
                  ),
                  controller: _passwordController,
                  validator: (value) =>
                  value!.length < 6 ? 'Password must be at least 6 characters' : null,
                ),
                SizedBox(height:40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff030E4E),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(child: Text('or', style: TextStyle(color: Colors.black54, fontSize: 14))),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Image.asset(
                      'images/google_logo.png',
                      height: 20,
                      width: 20,
                    ),
                    label: const Text(
                      "Continue with Google",
                      style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 2,
                      side: const BorderSide(color: Color(0xff030E4E), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _signupWithGoogle,
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
