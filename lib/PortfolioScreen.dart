import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PortfolioScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSaveProject;  // Callback to send project data back
  PortfolioScreen({required this.onSaveProject});

  @override
  _PortfolioScreenState createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _thumbnail;
  final _formKey = GlobalKey<FormState>();

  String _projectName = '';
  String _location = '';
  String _description = '';
  double _cost = 0.0;

  // Function to handle image upload
  Future<void> _uploadThumbnail() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnail = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadThumbnailToStorage(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final storageRef = FirebaseStorage.instance.ref().child('project_thumbnails/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading thumbnail: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Project Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xff030e4e),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff030e4e), Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Project Name Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      labelStyle: const TextStyle(color: Color(0xff030E4E)),
                      prefixIcon: const Icon(Icons.work, color: Color(0xffF39F1B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff030E4E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffF39F1B), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSaved: (value) {
                      _projectName = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter project name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: const TextStyle(color: Color(0xff030E4E)),
                      prefixIcon: const Icon(Icons.location_on, color: Color(0xffF39F1B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff030E4E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffF39F1B), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onSaved: (value) {
                      _location = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Color(0xff030E4E)),
                      prefixIcon: const Icon(Icons.description, color: Color(0xffF39F1B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff030E4E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffF39F1B), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 3,
                    onSaved: (value) {
                      _description = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Cost Field
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Cost (PKR)',
                      labelStyle: const TextStyle(color: Color(0xff030E4E)),
                      prefixIcon: const Icon(Icons.attach_money, color: Color(0xffF39F1B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff030E4E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xffF39F1B), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      _cost = double.tryParse(value!) ?? 0.0;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the cost';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Upload Thumbnail Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Project Thumbnail',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff030E4E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _uploadThumbnail,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              image: _thumbnail != null
                                  ? DecorationImage(
                                      image: FileImage(_thumbnail!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _thumbnail == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload,
                                        color: Colors.grey[400],
                                        size: 50,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to upload thumbnail',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();

                          String? thumbnailUrl;
                          if (_thumbnail != null) {
                            thumbnailUrl = await _uploadThumbnailToStorage(_thumbnail!);
                          }

                          Map<String, dynamic> projectData = {
                            'title': _projectName,
                            'location': _location,
                            'description': _description,
                            'cost': _cost,
                            'thumbnail': thumbnailUrl ?? '',
                          };

                          widget.onSaveProject(projectData);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff030e4e),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Project',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
