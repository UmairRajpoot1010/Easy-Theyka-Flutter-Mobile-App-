import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Jobs extends StatefulWidget {
  Jobs({super.key});

  @override
  State<Jobs> createState() => _JobsState();
}

class _JobsState extends State<Jobs> {
  String? userRole;
  String? userId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    getUserRole().then((role) {
      setState(() {
        userRole = role;
      });
    });
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;
  }

  Future<String?> getUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['role'] as String?;
  }

  void _showCreateJobForm() {
    String? title;
    String? location;
    String? description;
    File? jobImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create New Job"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (jobImage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            jobImage!,
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
                            jobImage = File(pickedFile.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Add Job Image'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      onChanged: (value) => title = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) => location = value,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      onChanged: (value) => description = value,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (title != null && location != null && description != null && userId != null) {
                      setState(() {
                        isUploading = true;
                      });

                      try {
                        // Fetch user info
                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                        final userData = userDoc.data();
                        String customerName = '';
                        if (userData != null) {
                          if (userData['firstName'] != null && userData['lastName'] != null) {
                            customerName = '${userData['firstName']} ${userData['lastName']}';
                          } else {
                            customerName = userData['firstName'] ?? userData['userName'] ?? '';
                          }
                        }
                        String? profileImage = userData != null ? userData['profileImage'] : null;

                        // Create job document first to get the ID
                        final jobRef = await FirebaseFirestore.instance.collection('jobs').add({
                          'title': title!,
                          'location': location!,
                          'description': description!,
                          'userId': userId,
                          'customerName': customerName,
                          'profileImage': profileImage,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        // Upload image if selected
                        if (jobImage != null) {
                          final storageRef = FirebaseStorage.instance
                              .ref()
                              .child('job_images/${jobRef.id}.jpg');
                          await storageRef.putFile(jobImage!);
                          final imageUrl = await storageRef.getDownloadURL();

                          // Update job with image URL
                          await jobRef.update({
                            'image': imageUrl,
                          });
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Job created successfully')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error creating job: ${e.toString()}')),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            isUploading = false;
                          });
                        }
                      }
                    }
                  },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text("Create Job"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search jobs by city',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (userRole == 'customer')
                ElevatedButton.icon(
                  onPressed: _showCreateJobForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff030e4e),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text("Create Job"),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('jobs').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading jobs',
                        style: TextStyle(color: Colors.red[300], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xff030e4e)),
                  ),
                );
              }
              var jobs = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
              if (_searchQuery.isNotEmpty) {
                jobs = jobs.where((job) {
                  final location = (job['location'] ?? '').toString().toLowerCase();
                  return location.contains(_searchQuery);
                }).toList();
              }
              if (jobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No jobs found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobDetailsScreen(job: job),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection('users').doc(job['userId']).get(),
                                builder: (context, snapshot) {
                                  String avatarUrl = '';
                                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                    avatarUrl = userData?['profileImage'] ?? '';
                                  } else {
                                    avatarUrl = job['profileImage'] ?? '';
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey.shade200, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: avatarUrl.startsWith('http') && avatarUrl.isNotEmpty
                                          ? NetworkImage(avatarUrl)
                                          : const AssetImage('images/profile.jpg') as ImageProvider,
                                      radius: 28,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xffF39F1B).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.work, color: Color(0xffF39F1B), size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'Job',
                                                style: TextStyle(
                                                  color: Color(0xffF39F1B),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            job['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              color: Color(0xff030E4E),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.grey[400], size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            job['location'] ?? '',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (job['description'] != null && job['description'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        job['description'],
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          job['customerName'] ?? 'Anonymous',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xff030E4E),
                                          ),
                                        ),
                                        Text(
                                          'Posted ${_getTimeAgo(job['createdAt'])}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
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
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailsScreen({required this.job, Key? key}) : super(key: key);

  Future<void> _deleteJob(BuildContext context) async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Job'),
            content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        // Delete job image from storage if exists
        if (job['image'] != null && job['image'].toString().isNotEmpty) {
          try {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('job_images/${job['id']}.jpg');
            await storageRef.delete();
          } catch (e) {
            // Ignore storage errors
          }
        }

        // Delete the job from Firestore
        await FirebaseFirestore.instance.collection('jobs').doc(job['id']).delete();
        
        if (context.mounted) {
          Navigator.pop(context); // Return to jobs list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting job: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isJobOwner = currentUserId == job['userId'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: const Color(0xffF39F1B),
        actions: [
          if (isJobOwner)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteJob(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job['image'] != null && job['image'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  job['image'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              job['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xff030E4E),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 20),
                const SizedBox(width: 4),
                Text(
                  job['location'] ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Description:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xff030E4E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final role = data?['role'] ?? '';
                if (role == 'builder') {
                  return ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BidScreen(job: job),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff030e4e),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Place Bid"),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BidScreen extends StatefulWidget {
  final Map<String, dynamic> job;
  const BidScreen({required this.job, Key? key}) : super(key: key);

  @override
  State<BidScreen> createState() => _BidScreenState();
}

class _BidScreenState extends State<BidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bidAmountController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _bidAmountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final builder = FirebaseAuth.instance.currentUser;
      if (builder == null) {
        setState(() {
          _errorMessage = 'You must be logged in to place a bid';
        });
        return;
      }

      // Get builder's details
      final builderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(builder.uid)
          .get();
      
      if (!builderDoc.exists) {
        setState(() {
          _errorMessage = 'Builder profile not found';
        });
        return;
      }

      final builderData = builderDoc.data() as Map<String, dynamic>;
      final builderName = builderData['name'] ?? 'Unknown Builder';
      final builderPhone = builderData['phone'] ?? 'No phone number';

      // Create bid message
      final bidMessage = '''
New Bid on "${widget.job['title']}"

Bid Amount: PKR ${_bidAmountController.text}
Builder: $builderName
Contact: $builderPhone

Message:
${_messageController.text}

Job Details:
Location: ${widget.job['location']}
''';

      // Get customer ID from job
      final customerId = widget.job['userId'];
      if (customerId == null) {
        setState(() {
          _errorMessage = 'Job owner not found';
        });
        return;
      }

      // Create or get conversation
      final conversationId = [builder.uid, customerId]..sort();
      final conversationRef = FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId.join('_'));

      // Create conversation if it doesn't exist
      if (!(await conversationRef.get()).exists) {
        await conversationRef.set({
          'participants': [builder.uid, customerId],
          'participantAvatars': {},
          'lastTimestamp': FieldValue.serverTimestamp(),
          'jobId': widget.job['id'],
          'jobTitle': widget.job['title'],
        });
      }

      // Add bid message
      await conversationRef.collection('messages').add({
        'senderId': builder.uid,
        'text': bidMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'isBid': true,
        'bidAmount': _bidAmountController.text,
      });

      // Update conversation
      await conversationRef.update({
        'lastMessage': 'New bid: PKR ${_bidAmountController.text}',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bid sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send bid: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Your Bid'),
        backgroundColor: const Color(0xffF39F1B),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job['title'] ?? 'Untitled Job',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${widget.job['location'] ?? 'Not specified'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _bidAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Your Bid Amount (PKR)',
                    border: OutlineInputBorder(),
                    prefixText: 'PKR ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your bid amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message to Customer',
                    border: OutlineInputBorder(),
                    hintText: 'Introduce yourself and explain why you\'re the best fit for this job...',
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a message';
                    }
                    if (value.length < 20) {
                      return 'Please provide a more detailed message (at least 20 characters)';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff030e4e),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Bid',
                            style: TextStyle(fontSize: 16),
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
