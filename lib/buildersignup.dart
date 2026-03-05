import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easytheyka/page1.dart';
import 'builderprofile.dart';

class BuilderSignup extends StatefulWidget {
  final String role;
  const BuilderSignup({super.key, required this.role});

  @override
  State<BuilderSignup> createState() => _BuilderSignupState();
}

class _BuilderSignupState extends State<BuilderSignup> {
  final _userNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Track loading state

  // Function to save builder data to Firestore
  Future<void> _saveBuilderData() async {
    if (!_formKey.currentState!.validate()) return; // Stop if form is invalid

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Get current authenticated user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated! Please log in.')),
        );
        return;
      }

      String uid = user.uid;

      // Save builder data to Firestore under "builders" collection
      await FirebaseFirestore.instance.collection('builders').doc(uid).set({
        'uid': uid,
        'userName': _userNameController.text.trim(),
        'city': _cityController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save role to users collection
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': widget.role,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Builder profile created successfully!')),
      );

      // Navigate to the next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BuilderProfile()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
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
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Builder Signup',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff030E4E),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'User Name',
                    hintText: 'Enter Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _userNameController,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'Enter your City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _cityController,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your city' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'CNIC',
                    hintText: 'Enter your CNIC (e.g., 12345-6789012-3)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _cnicController,
                  keyboardType: TextInputType.numberWithOptions(decimal: false),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your CNIC';
                    }
                    if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(value)) {
                      return 'Invalid CNIC format (e.g., 12345-6789012-3)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Phone No',
                    hintText: 'Enter Your Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                      return 'Invalid phone number (10-11 digits)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveBuilderData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff030E4E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
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
