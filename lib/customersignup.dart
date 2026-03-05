import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class CustomerSignup extends StatefulWidget {
  final String role;
  const CustomerSignup({super.key, required this.role});

  @override
  State<CustomerSignup> createState() => _CustomerSignupState();
}

class _CustomerSignupState extends State<CustomerSignup> {
  final _userNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Function to save customer data to Firestore
  Future<void> _saveCustomerData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated! Please log in.')),
        );
        return;
      }

      String uid = user.uid;

      // Save customer data in Firestore under "customers" collection
      await FirebaseFirestore.instance.collection('customers').doc(uid).set({
        'uid': uid,
        'userName': _userNameController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save role to users collection
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'role': widget.role,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer profile created successfully!')),
      );

      // Navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  Login()),
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
                    padding: const EdgeInsets.only(top: 60),
                    child: Image.asset(
                      'images/icon2.png', // Replace with your logo path
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Customer Signup',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff030E4E),
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'User Name',
                    hintText: 'Enter Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  controller: _userNameController,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration:  InputDecoration(
                    labelText: 'CNIC',
                    hintText: 'Enter your CNIC (e.g., 12345-6789012-3)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
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
                const SizedBox(height: 16),
                TextFormField(
                  decoration:  InputDecoration(
                    labelText: 'Phone No',
                    hintText: 'Enter Your Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
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
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomerData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff030E4E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
