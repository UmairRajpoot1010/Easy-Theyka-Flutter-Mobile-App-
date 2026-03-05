import 'package:flutter/material.dart';
import 'PortfolioScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

defaultProfileImage() {
  return AssetImage(''); // Replace with your default profile image
}

void main() => runApp(MaterialApp(
  home: UserProfileScreen(),
  debugShowCheckedModeBanner: false,
));

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String phoneNumber = '';
  String username = '';
  String bio = 'Add a few words about yourself';
  String profileOverview = 'Add a detailed overview about yourself here.';
  String name = '';
  String location = '';
  ImageProvider profileImage = defaultProfileImage();
  List<Map<String, dynamic>> portfolioProjects = [];
  Map<String, dynamic>? _myBuilderProfile;
  String? _builderProfileDocId;
  File? _newProfileImageFile;
  bool _isUploadingProfileImage = false;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchMyBuilderProfileAndProjects();
    _fetchUserRole();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        name = data['firstName'] != null && data['lastName'] != null
            ? '${data['firstName']} ${data['lastName']}'
            : (data['firstName'] ?? data['userName'] ?? '');
        location = data['city'] ?? '';
        phoneNumber = data['phone'] ?? '';
        username = data['userName'] != null ? '@${data['userName']}' : '';
        if (data['profileOverview'] != null) {
          profileOverview = data['profileOverview'];
        }
        if (data['profileImage'] != null) {
          profileImage = NetworkImage(data['profileImage']);
        }
      });
    }
  }

  Future<void> _fetchMyBuilderProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('builderprofile')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _myBuilderProfile = snapshot.docs.first.data() as Map<String, dynamic>;
        _builderProfileDocId = snapshot.docs.first.id;
      });
    } else {
      setState(() {
        _myBuilderProfile = null;
        _builderProfileDocId = null;
      });
    }
  }

  Future<void> _fetchPortfolioProjects() async {
    if (_builderProfileDocId == null) {
      setState(() {
        portfolioProjects = [];
      });
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('builderprofile')
        .doc(_builderProfileDocId)
        .collection('projects')
        .get();
    setState(() {
      portfolioProjects = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'title': data['title'] ?? '',
          'location': data['location'] ?? '',
          'description': data['description'] ?? '',
          'cost': data['cost'] ?? '',
          'thumbnail': data['thumbnail'] ?? '',
        };
      }).toList();
    });
  }

  Future<void> _fetchMyBuilderProfileAndProjects() async {
    await _fetchMyBuilderProfile();
    await _fetchPortfolioProjects();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      userRole = doc.data()?['role'] as String?;
    });
  }

  void _editField(String title, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: title,
            ),
            maxLines: title == 'Profile Overview' ? 5 : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final value = controller.text;
                onSave(value);
                // Save to Firestore if phone, username, or overview
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                  if (title == 'Phone Number') {
                    await userDoc.set({'phone': value}, SetOptions(merge: true));
                  } else if (title == 'Username') {
                    await userDoc.set({'userName': value.startsWith('@') ? value.substring(1) : value}, SetOptions(merge: true));
                  } else if (title == 'Profile Overview') {
                    await userDoc.set({'profileOverview': value}, SetOptions(merge: true));
                  }
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPortfolioProject(Map<String, dynamic> projectData) async {
    if (_builderProfileDocId == null) {
      // Try to refresh builder profile in case it was just created
      await _fetchMyBuilderProfile();
      if (_builderProfileDocId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create your builder profile first!')),
        );
        return;
      }
    }
    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('builderprofile')
        .doc(_builderProfileDocId)
        .collection('projects')
        .add({
          'title': projectData['title'],
          'location': projectData['location'],
          'description': projectData['description'],
          'cost': projectData['cost'],
          'thumbnail': projectData['thumbnail'],
        });
    // Refresh builder profile and local list
    await _fetchMyBuilderProfileAndProjects();
  }

  void _editBuilderProfile() {
    if (_myBuilderProfile == null) return;
    final typeController = TextEditingController(text: _myBuilderProfile!['type'] ?? '');
    final nameController = TextEditingController(text: _myBuilderProfile!['name'] ?? '');
    final descController = TextEditingController(text: _myBuilderProfile!['description'] ?? '');
    final locController = TextEditingController(text: _myBuilderProfile!['location'] ?? '');
    final priceController = TextEditingController(text: _myBuilderProfile!['price'] ?? '');
    String? currentImageUrl = _myBuilderProfile!['image'];
    File? newImageFile;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Builder Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentImageUrl != null && currentImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            currentImageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            newImageFile = File(pickedFile.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Change Image'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: locController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Starting Price'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;
                    final snapshot = await FirebaseFirestore.instance
                        .collection('builderprofile')
                        .where('userId', isEqualTo: user.uid)
                        .limit(1)
                        .get();
                    if (snapshot.docs.isNotEmpty) {
                      final docId = snapshot.docs.first.id;
                      String? imageUrl = currentImageUrl;

                      if (newImageFile != null) {
                        // Upload new image
                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child('builder_profile_images/$docId.jpg');
                        await storageRef.putFile(newImageFile!);
                        imageUrl = await storageRef.getDownloadURL();
                      }

                      await FirebaseFirestore.instance.collection('builderprofile').doc(docId).update({
                        'type': typeController.text.trim(),
                        'name': nameController.text.trim(),
                        'description': descController.text.trim(),
                        'location': locController.text.trim(),
                        'price': priceController.text.trim(),
                        'image': imageUrl,
                      });
                      Navigator.pop(context);
                      _fetchMyBuilderProfile();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _isUploadingProfileImage = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final storageRef = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    final uploadTask = await storageRef.putFile(File(pickedFile.path));
    final imageUrl = await uploadTask.ref.getDownloadURL();
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'profileImage': imageUrl,
    }, SetOptions(merge: true));
    // Update all conversations with new avatar
    await _updateProfileImageInConversations(uid, imageUrl);
    setState(() {
      profileImage = NetworkImage(imageUrl);
      _isUploadingProfileImage = false;
    });
  }

  Future<void> _updateProfileImageInConversations(String userId, String newImageUrl) async {
    final conversations = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();
    for (var doc in conversations.docs) {
      await doc.reference.update({
        'participantAvatars.$userId': newImageUrl,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xffF39F1B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xffF39F1B),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: profileImage,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingProfileImage ? null : _pickAndUploadProfileImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: _isUploadingProfileImage
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt, color: Color(0xffF39F1B), size: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name.isNotEmpty ? name : 'Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location.isNotEmpty ? location : 'Location',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEditableField(
                    title: phoneNumber.isNotEmpty ? phoneNumber : 'Phone Number',
                    subtitle: 'Tap to change phone number',
                    onEdit: () => _editField('Phone Number', phoneNumber, (value) {
                      setState(() {
                        phoneNumber = value;
                      });
                    }),
                  ),
                  _buildEditableField(
                    title: username.isNotEmpty ? username : 'Username',
                    subtitle: 'Username',
                    onEdit: () => _editField('Username', username, (value) {
                      setState(() {
                        username = value;
                      });
                    }),
                  ),
                  _buildEditableField(
                    title: profileOverview,
                    subtitle: 'Profile Overview',
                    onEdit: () => _editField('Profile Overview', profileOverview, (value) {
                      setState(() {
                        profileOverview = value;
                      });
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (userRole == 'customer') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Jobs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff030E4E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _myJobsListWidget(),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Past Projects',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff030E4E),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PortfolioScreen(
                                  onSaveProject: _addPortfolioProject,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff030e4e),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Project'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...portfolioProjects.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final project = entry.value;
                        return _buildProjectCard(project, index);
                      },
                    ).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Builder Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff030E4E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _myBuilderProfileCard(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff030E4E),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff030E4E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xffF39F1B)),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _myJobsListWidget() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Error loading jobs'),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final jobs = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        if (jobs.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No jobs created yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff030E4E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          job['location'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xffF39F1B),
                          ),
                        ),
                        Text(
                          job['budget'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff030E4E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _myBuilderProfileCard() {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_myBuilderProfile == null) ...[
              const Text(
                'No Builder Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff030E4E),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createNewBuilderProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff030e4e),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create New Profile'),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (_myBuilderProfile!['image'] != null && _myBuilderProfile!['image'].toString().isNotEmpty)
                        ? Image.network(
                            _myBuilderProfile!['image'],
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'images/profile.jpg',
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'images/profile.jpg',
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _myBuilderProfile!['name'] ?? 'Unnamed',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff030E4E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _myBuilderProfile!['type'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xffF39F1B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _myBuilderProfile!['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _myBuilderProfile!['location'] ?? '',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              'PKR ${_myBuilderProfile!['price'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _editBuilderProfile,
                              child: const Text('Edit Profile'),
                            ),
                            TextButton(
                              onPressed: _deleteBuilderProfile,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete Profile'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBuilderProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: const Text('Are you sure you want to delete your builder profile? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _builderProfileDocId != null) {
      try {
        // Delete all projects first
        final projectsSnapshot = await FirebaseFirestore.instance
            .collection('builderprofile')
            .doc(_builderProfileDocId)
            .collection('projects')
            .get();
        
        for (var doc in projectsSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete the profile
        await FirebaseFirestore.instance
            .collection('builderprofile')
            .doc(_builderProfileDocId)
            .delete();

        setState(() {
          _myBuilderProfile = null;
          _builderProfileDocId = null;
          portfolioProjects = [];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting profile')),
          );
        }
      }
    }
  }

  Future<void> _createNewBuilderProfile() async {
    final typeController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final locController = TextEditingController();
    final priceController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Builder Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeController,
                decoration: const InputDecoration(labelText: 'Type (e.g., Contractor, Architect)'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Business Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: locController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Starting Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final docRef = await FirebaseFirestore.instance.collection('builderprofile').add({
          'userId': user.uid,
          'type': typeController.text.trim(),
          'name': nameController.text.trim(),
          'description': descController.text.trim(),
          'location': locController.text.trim(),
          'price': priceController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _builderProfileDocId = docRef.id;
          _myBuilderProfile = {
            'type': typeController.text.trim(),
            'name': nameController.text.trim(),
            'description': descController.text.trim(),
            'location': locController.text.trim(),
            'price': priceController.text.trim(),
          };
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error creating profile')),
          );
        }
      }
    }
  }

  Future<void> _showEditProjectDialog(Map<String, dynamic> project, int index) async {
    final titleController = TextEditingController(text: project['title'] ?? '');
    final locationController = TextEditingController(text: project['location'] ?? '');
    final descriptionController = TextEditingController(text: project['description'] ?? '');
    final costController = TextEditingController(text: project['cost']?.toString() ?? '');
    String? currentImageUrl = project['thumbnail'];
    File? newImageFile;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Project'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentImageUrl != null && currentImageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            currentImageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            newImageFile = File(pickedFile.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Change Image'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: costController,
                      decoration: const InputDecoration(labelText: 'Cost'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_builderProfileDocId == null) return;
                    final snapshot = await FirebaseFirestore.instance
                        .collection('builderprofile')
                        .doc(_builderProfileDocId)
                        .collection('projects')
                        .get();
                    if (snapshot.docs.length > index) {
                      final docId = snapshot.docs[index].id;
                      String? imageUrl = currentImageUrl;

                      if (newImageFile != null) {
                        // Upload new image
                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child('project_images/${_builderProfileDocId}/$docId.jpg');
                        await storageRef.putFile(newImageFile!);
                        imageUrl = await storageRef.getDownloadURL();
                      }

                      await FirebaseFirestore.instance
                          .collection('builderprofile')
                          .doc(_builderProfileDocId)
                          .collection('projects')
                          .doc(docId)
                          .update({
                            'title': titleController.text.trim(),
                            'location': locationController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'cost': double.tryParse(costController.text.trim()) ?? 0.0,
                            'thumbnail': imageUrl,
                          });
                      await _fetchMyBuilderProfileAndProjects();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteProject(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _builderProfileDocId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('builderprofile')
            .doc(_builderProfileDocId)
            .collection('projects')
            .get();
        
        if (snapshot.docs.length > index) {
          final docId = snapshot.docs[index].id;
          
          // Delete project image from storage if exists
          final project = portfolioProjects[index];
          if (project['thumbnail'] != null && project['thumbnail'].toString().isNotEmpty) {
            try {
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('project_images/${_builderProfileDocId}/$docId.jpg');
              await storageRef.delete();
            } catch (e) {
              // Ignore storage errors
            }
          }

          // Delete project document
          await FirebaseFirestore.instance
              .collection('builderprofile')
              .doc(_builderProfileDocId)
              .collection('projects')
              .doc(docId)
              .delete();

          await _fetchMyBuilderProfileAndProjects();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Project deleted successfully')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error deleting project')),
          );
        }
      }
    }
  }

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xff030E4E),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Color(0xffF39F1B)),
                      onPressed: () async {
                        await _showEditProjectDialog(project, index);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProject(index),
                    ),
                  ],
                ),
              ],
            ),
            if (project['thumbnail'] != null && project['thumbnail'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  project['thumbnail'],
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            _buildProjectInfoRow('Title', project['title'] ?? ''),
            const SizedBox(height: 8),
            _buildProjectInfoRow('Location', project['location'] ?? ''),
            const SizedBox(height: 8),
            _buildProjectInfoRow('Description', project['description'] ?? ''),
            const SizedBox(height: 8),
            _buildProjectInfoRow('Cost', 'PKR ${project['cost']?.toString() ?? ''}'),
          ],
        ),
      ),
    );
  }
}

