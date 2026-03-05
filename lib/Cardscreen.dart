import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easytheyka/page1.dart';

class Cardscreen extends StatefulWidget {
  final Map<String, dynamic> builder;

  Cardscreen({required this.builder});

  @override
  State<Cardscreen> createState() => _CardscreenState();
}

class _CardscreenState extends State<Cardscreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _latestBuilderProfile;
  List<Map<String, dynamic>> _pastProjects = [];
  List<Map<String, dynamic>> portfolioProjects = [];
  String? _builderPhone;

  @override
  void initState() {
    super.initState();
    _fetchLatestBuilderProfile();
    _fetchPastProjects();
    _fetchBuilderPhone();
  }

  Future<void> _fetchLatestBuilderProfile() async {
    final userId = widget.builder['userId'];
    final snapshot = await _firestore
        .collection('builderprofile')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _latestBuilderProfile = snapshot.docs.first.data() as Map<String, dynamic>;
      });
    }
  }

  Future<void> _fetchPastProjects() async {
    // Example: If you store past projects in a subcollection 'projects' under builderprofile
    final userId = widget.builder['userId'];
    final builderProfileSnap = await _firestore
        .collection('builderprofile')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (builderProfileSnap.docs.isNotEmpty) {
      final docId = builderProfileSnap.docs.first.id;
      final projectsSnap = await _firestore
          .collection('builderprofile')
          .doc(docId)
          .collection('projects')
          .get();
      setState(() {
        _pastProjects = projectsSnap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    }
  }

  Future<void> _fetchBuilderPhone() async {
    final userId = widget.builder['userId'];
    if (userId == null) return;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        _builderPhone = userDoc.data()?['phone'] ?? '';
      });
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to send a message.")),
      );
      return;
    }
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    try {
      await _firestore.collection('messages').add({
        'senderId': currentUser.uid,
        'receiverId': widget.builder['userId'],
        'builderName': widget.builder['name'],
        'builderId': widget.builder['id'],
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message sent successfully!")),
      );
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _openChatWithBuilder() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to send a message.")),
      );
      return;
    }
    final builderId = widget.builder['userId'];
    final builderName = widget.builder['name'] ?? 'Builder';
    final builderAvatar = widget.builder['image'] ?? 'https://via.placeholder.com/150';
    final userId = currentUser.uid;

    // Find or create a conversation document
    String? conversationId;
    final conversationQuery = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();
    // Try to find a conversation with both participants
    for (var doc in conversationQuery.docs) {
      final data = doc.data();
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(builderId) && participants.contains(userId) && participants.length == 2) {
        conversationId = doc.id;
        break;
      }
    }
    if (conversationId == null) {
      // Create a new conversation with Firestore auto-ID
      final newDoc = _firestore.collection('conversations').doc();
      conversationId = newDoc.id;
      await newDoc.set({
        'participants': [userId, builderId],
        'participantNames': {
          userId: currentUser.displayName ?? '',
          builderId: builderName,
        },
        'participantAvatars': {
          userId: currentUser.photoURL ?? '',
          builderId: builderAvatar,
        },
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }
    // Navigate to the chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationChatScreen(
          conversationId: conversationId!,
          currentUserId: userId,
          builderId: builderId,
          builderName: builderName,
          builderAvatar: builderAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final builder = _latestBuilderProfile ?? widget.builder;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Builder Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xffF39F1B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xffF39F1B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
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
                      backgroundImage: NetworkImage(builder['image'] ?? 'https://via.placeholder.com/150'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    builder['name'] ?? 'Unnamed Builder',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      builder['type'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "About",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff030E4E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          builder['description'] ?? 'No description available',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Contact Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff030E4E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.location_on, "Location", builder['location'] ?? 'Location not specified'),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.phone, "Phone", _builderPhone ?? 'Not provided'),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.attach_money,
                          "Starting Price",
                          "${builder['price'] ?? 'Price not specified'} PKR",
                          valueColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Past Projects",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff030E4E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_pastProjects.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No past projects yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._pastProjects.map((project) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (project['thumbnail'] != null && project['thumbnail'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    project['thumbnail'],
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff030E4E),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      project['description'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (project['cost'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Cost: PKR ${project['cost']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openChatWithBuilder,
                      icon: const Icon(Icons.message, color: Colors.white),
                      label: const Text(
                        "Message Builder",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff030e4e),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xffF39F1B), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? const Color(0xff030E4E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConversationChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String builderId;
  final String builderName;
  final String builderAvatar;
  const ConversationChatScreen({
    required this.conversationId,
    required this.currentUserId,
    required this.builderId,
    required this.builderName,
    required this.builderAvatar,
    Key? key,
  }) : super(key: key);

  @override
  State<ConversationChatScreen> createState() => _ConversationChatScreenState();
}

class _ConversationChatScreenState extends State<ConversationChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _otherUserName;
  String? _otherUserAvatar;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserInfo();
  }

  Future<void> _fetchOtherUserInfo() async {
    // Find the other participant
    final convoDoc = await _firestore.collection('conversations').doc(widget.conversationId).get();
    final data = convoDoc.data();
    if (data != null && data['participants'] != null) {
      final participants = List<String>.from(data['participants']);
      final otherId = participants.firstWhere((id) => id != widget.currentUserId, orElse: () => widget.builderId);
      final userDoc = await _firestore.collection('users').doc(otherId).get();
      final userData = userDoc.data();
      setState(() {
        _otherUserName = userData?['name'] ?? userData?['firstName'] ?? 'User';
        _otherUserAvatar = userData?['profileImage'] ?? '';
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    await _firestore
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
          'senderId': widget.currentUserId,
          'receiverId': widget.builderId,
          'message': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
    await _firestore.collection('conversations').doc(widget.conversationId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: (_otherUserAvatar != null && _otherUserAvatar!.isNotEmpty)
                    ? NetworkImage(_otherUserAvatar!)
                    : (widget.builderAvatar.startsWith('http')
                        ? NetworkImage(widget.builderAvatar)
                        : AssetImage(widget.builderAvatar) as ImageProvider),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUserName ?? widget.builderName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xffF39F1B),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffF39F1B), Colors.white],
            stops: [0.0, 0.1],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('conversations')
                    .doc(widget.conversationId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xff030e4e)),
                      ),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == widget.currentUserId;
                      final messageText = data['text'] ?? data['message'] ?? '';
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xff030e4e) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            messageText,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xff030e4e),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
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