import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'idcard.dart';

class BuilderProfile extends StatefulWidget {
  const BuilderProfile({super.key});

  @override
  State<BuilderProfile> createState() => _BuilderProfileState();
}

class _BuilderProfileState extends State<BuilderProfile> {
  File? _profileImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadImageToStorage() async {
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile picture.')),
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
      final metadata = SettableMetadata(contentType: "image/jpeg");
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference storageRef = storage.ref().child('profile_images/$uid.jpg');
      final uploadTask = storageRef.putFile(_profileImage!, metadata);
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        switch (taskSnapshot.state) {
          case TaskState.running:
            final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
            setState(() {
              _uploadProgress = progress;
            });
            break;
          default:
            break;
        }
      });
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();
      // Save the image URL to Firestore under the user's document
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profileImage': imageUrl,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture uploaded successfully!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const idcard()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Image.asset(
                    'images/icon2.png',
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Builder',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff030E4E),
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text(
                        'Upload Your Profile',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff030E4E),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isUploading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress / 100),
                    const SizedBox(height: 10),
                    Text(
                      "Uploading: ${_uploadProgress.toStringAsFixed(2)}%",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImageToStorage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff030E4E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
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
    );
  }
}
