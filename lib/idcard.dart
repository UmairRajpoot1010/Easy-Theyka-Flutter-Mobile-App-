:flutter/material.dart';
import 'login.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class idcard extends StatefulWidget {
  const idcard({super.key});

  @override
  State<idcard> createState() => _idcardState();
}

class _idcardState extends State<idcard> {
  File? _frontIdImage; // Store front ID image
  File? _backIdImage; // Store back ID image
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Function to pick an image from the gallery
  Future<void> _pickImage(bool isFront) async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        if (isFront) {
          _frontIdImage = File(pickedImage.path);
        } else {
          _backIdImage = File(pickedImage.path);
        }
      });
    }
  }

  Future<void> _uploadIdImages() async {
    if (_frontIdImage == null || _backIdImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both front and back of your ID card.')),
      );
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user signed in! Please log in.')),
        );
        return;
      }
      String uid = user.uid;
      FirebaseStorage storage = FirebaseStorage.instance;
      // Upload front image
      Reference frontRef = storage.ref().child('idcards/$uid-front.jpg');
      final frontTask = frontRef.putFile(_frontIdImage!);
      final frontSnapshot = await frontTask;
      final frontUrl = await frontSnapshot.ref.getDownloadURL();
      // Upload back image
      Reference backRef = storage.ref().child('idcards/$uid-back.jpg');
      final backTask = backRef.putFile(_backIdImage!);
      final backSnapshot = await backTask;
      final backUrl = await backSnapshot.ref.getDownloadURL();
      // Save URLs to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'idCardFront': frontUrl,
        'idCardBack': backUrl,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID card images uploaded successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload ID card images: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildIdCardSection({
    required String title,
    File? image,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            image != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(image, height: 120, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: onRemove,
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.red,
                            child: Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Icon(Icons.photo, size: 50, color: Colors.grey[400]),
                  ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file, color: Color(0xff030E4E)),
              label: const Text('Choose Image', style: TextStyle(color: Color(0xff030E4E))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xff030E4E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'images/icon2.png',
                  height: 50,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Upload Your ID Card',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff030E4E),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Please upload clear images of the front and back of your ID card.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildIdCardSection(
                title: "Front of ID Card",
                image: _frontIdImage,
                onUpload: () => _pickImage(true),
                onRemove: () => setState(() => _frontIdImage = null),
              ),
              const SizedBox(height: 20),
              _buildIdCardSection(
                title: "Back of ID Card",
                image: _backIdImage,
                onUpload: () => _pickImage(false),
                onRemove: () => setState(() => _backIdImage = null),
              ),
              const SizedBox(height: 30),
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress / 100),
                    const SizedBox(height: 10),
                    const Text(
                      "Uploading...",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadIdImages,
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
                label: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff030E4E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
