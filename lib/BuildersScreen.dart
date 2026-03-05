// import 'dart:html' as html; // For web image support
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easytheyka/page1.dart';
import 'cardscreen.dart';

class BuildersScreen extends StatefulWidget {
  const BuildersScreen({super.key});

  @override
  State<BuildersScreen> createState() => _BuildersScreenState();
}

class _BuildersScreenState extends State<BuildersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  XFile? _selectedImage;
  bool _isLoading = false;
  String _searchQuery = '';

  final ImagePicker _picker = ImagePicker();

  // Add a state variable to store the current user's builder profile
  Map<String, dynamic>? _myBuilderProfile;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchMyBuilderProfile();
    _fetchUserRole();
  }

  Future<void> _fetchMyBuilderProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore
        .collection('builderprofile')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _myBuilderProfile = snapshot.docs.first.data() as Map<String, dynamic>;
      });
    } else {
      setState(() {
        _myBuilderProfile = null;
      });
    }
  }

  Future<void> _fetchUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    setState(() {
      _userRole = doc.data()?['role'] as String?;
    });
  }

  Future<XFile?> _pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  void _showCreateForm() {
    final typeController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Color(0xffF39F1B).withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Center(
                        child: Text(
                          "Create Your Builder Profile",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff030E4E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _modernTextField("Type (e.g., House/Building)", typeController, Icons.category),
                      _modernTextField("Name", nameController, Icons.person),
                      _modernTextField("Description", descController, Icons.description, maxLines: 2),
                      _modernTextField("Location", locController, Icons.location_on),
                      _modernTextField("Starting Price", priceController, Icons.attach_money, keyboardType: TextInputType.number),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff030E4E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (typeController.text.trim().isNotEmpty &&
                        nameController.text.trim().isNotEmpty &&
                        descController.text.trim().isNotEmpty &&
                        locController.text.trim().isNotEmpty &&
                                  priceController.text.trim().isNotEmpty) {
                      try {
                        final user = _auth.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please log in first.")),
                          );
                          return;
                        }
                                  // Get the user's profile image from Firestore
                                  final userDoc = await _firestore.collection('users').doc(user.uid).get();
                                  final userData = userDoc.data();
                                  String? profileImageUrl = userData != null ? userData['profileImage'] : null;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                                  Map<String, dynamic> newProfile = {
                          'userId': user.uid,
                          'type': typeController.text.trim(),
                          'name': nameController.text.trim(),
                          'description': descController.text.trim(),
                          'location': locController.text.trim(),
                          'price': priceController.text.trim(),
                                    'image': profileImageUrl,
                          'createdAt': FieldValue.serverTimestamp(),
                        };
                                  await _firestore.collection('builderprofile').add(newProfile);
                        Navigator.pop(context); // Close loading
                        Navigator.pop(context); // Close form
                                  _fetchMyBuilderProfile(); // Refresh
                      } catch (e) {
                        Navigator.pop(context); // Close loading
                                  print("Error saving builder profile: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error saving builder profile: $e")),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please fill all fields.")),
                      );
                    }
                  },
                  child: const Text("Done"),
                ),
              ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _modernTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xffF39F1B)),
          labelText: label,
          labelStyle: TextStyle(color: Color(0xff030E4E)),
          filled: true,
          fillColor: Color(0xffFFF3E0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xffF39F1B), width: 2),
          ),
        ),
      ),
    );
  }

  Future<String> _uploadImage(XFile image) async {
    final ref = _storage.ref().child('builder_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final bytes = await image.readAsBytes();
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffF39F1B), Colors.white],
            stops: [0.0, 0.2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Row(
                  children: [
                    const Text(
                      "Builders",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (_myBuilderProfile == null && _userRole != 'customer')
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _showCreateForm,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            "Create Profile",
                            style: TextStyle(fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffF39F1B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search builders by name, type, or location...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.search, color: Color(0xffF39F1B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('builderprofile').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Connection Error',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff030E4E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your internet connection',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {}); // Trigger rebuild to retry
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffF39F1B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xffF39F1B)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading builders...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xff030E4E),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xffF39F1B).withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Color(0xffF39F1B),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No builders found',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff030E4E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final builders = snapshot.data?.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .where((builder) {
                          final name = (builder['name'] ?? '').toString().trim();
                          if (name.isEmpty) return false;
                          if (_searchQuery.isEmpty) return true;
                          final type = (builder['type'] ?? '').toString().toLowerCase();
                          final location = (builder['location'] ?? '').toString().toLowerCase();
                          return name.toLowerCase().contains(_searchQuery) ||
                              type.contains(_searchQuery) ||
                              location.contains(_searchQuery);
                        })
                        .toList() ?? [];

                    if (builders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xffF39F1B).withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Color(0xffF39F1B),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No matching builders found',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff030E4E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try different search terms',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: builders.length,
                      itemBuilder: (context, index) {
                        return _buildProfileCard(builders[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Cardscreen(builder: profile),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (profile['image'] != null && profile['image'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  profile['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile['name'] ?? 'Unnamed',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff030E4E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xffF39F1B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                profile['type'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xffF39F1B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PKR ${profile['price'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Color(0xffF39F1B), size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile['location'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
