import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:easytheyka/settings.dart';
import 'package:easytheyka/homescreen.dart';

import 'Jobs.dart';
import 'UserProfileScreen.dart';
import 'costcalculator.dart';
import 'BuildersScreen.dart';
import 'login.dart';
import 'Cardscreen.dart';

void main() => runApp(const Page1());

class Page1 extends StatelessWidget {
  const Page1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Easy Theyka',
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Current index for the BottomNavigationBar

  // Screens for the BottomNavigationBar
  final List<Widget> _screens = [
    HomeTabScreen(), // Home tab with DefaultTabController
    MessageScreen(), // Message screen
    UserProfileScreen(), // Profile (You) screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'You',
          ),
        ],
        selectedItemColor: const Color(0xffF39F1B),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    return data ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Easy Theyka",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xffF39F1B),
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab( child: Text(
                    "Builders",
                    style: TextStyle(color: Colors.white),
                  ),

              ),
              Tab(
                child: Text(
                  "Jobs",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Tab(
                child: Text(
                  "Calculator",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserData(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? {};
              final profileImage = data['profileImage'] != null
                  ? NetworkImage(data['profileImage'])
                  : const AssetImage('images/profile.jpg') as ImageProvider;
              final name = (data['firstName'] != null && data['lastName'] != null)
                  ? '${data['firstName']} ${data['lastName']}'
                  : (data['firstName'] ?? data['userName'] ?? 'User');
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color(0xffF39F1B),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserProfileScreen()),
                            );
                          },
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: profileImage,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.black),
                    title: const Text("Profile"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfileScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.black),
                    title: const Text("Settings"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AppSettingsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.black),
                    title: const Text("Logout"),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => Homescreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        body: TabBarView(
          children: [
            BuildersScreen(),
            Jobs(),
            GrayStructureCostCalculator(),
          ],
        ),
      ),
    );
  }
}

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _deleteMessage(String conversationId, String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Update the last message in the conversation if needed
      final messages = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messages.docs.isNotEmpty) {
        final lastMessage = messages.docs.first.data();
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': lastMessage['text'] ?? lastMessage['message'] ?? '',
          'lastTimestamp': lastMessage['timestamp'],
        });
      } else {
        // If no messages left, update with empty values
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .update({
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "Please log in to view messages",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('conversations')
              .where('participants', arrayContains: _currentUser!.uid)
              .orderBy('lastTimestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff030e4e)),
                ),
              );
            }

            final conversations = snapshot.data!.docs;

            if (conversations.isEmpty) {
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
                        Icons.message_outlined,
                        size: 48,
                        color: Color(0xffF39F1B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff030E4E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a conversation with a builder',
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final data = conversations[index].data() as Map<String, dynamic>;
                final conversationId = conversations[index].id;
                final participants = List<String>.from(data['participants'] ?? []);
                final participantNames = Map<String, dynamic>.from(data['participantNames'] ?? {});
                final participantAvatars = Map<String, dynamic>.from(data['participantAvatars'] ?? {});
                final lastMessage = data['lastMessage'] ?? '';
                final lastTimestamp = data['lastTimestamp'] as Timestamp?;

                String otherId = participants.firstWhere(
                  (id) => id != _currentUser!.uid,
                  orElse: () => '',
                );
                if (otherId.isEmpty) return const SizedBox.shrink();

                final otherName = participantNames[otherId] ?? 'User';
                final otherAvatar = participantAvatars[otherId] ?? '';

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200, width: 2),
                      ),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
                        builder: (context, userSnapshot) {
                          String avatarUrl = '';
                          if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                            avatarUrl = userData?['profileImage'] ?? '';
                          } else {
                            avatarUrl = otherAvatar.toString();
                          }
                          return CircleAvatar(
                            radius: 24,
                            backgroundImage: avatarUrl.startsWith('http') && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : const AssetImage('images/profile.jpg') as ImageProvider,
                          );
                        },
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
                            builder: (context, userSnapshot) {
                              String displayName = '';
                              if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
                                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                                displayName = userData?['name'] ?? userData?['firstName'] ?? 'User';
                              } else {
                                displayName = otherName.toString();
                              }
                              return Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xff030E4E),
                                ),
                              );
                            },
                          ),
                        ),
                        if (lastTimestamp != null)
                          Text(
                            _getTimeAgo(lastTimestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConversationChatScreen(
                            conversationId: conversationId,
                            currentUserId: _currentUser!.uid,
                            builderId: otherId,
                            builderName: otherName,
                            builderAvatar: otherAvatar,
                          ),
                        ),
                      );
                    },
                    onLongPress: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Conversation'),
                          content: const Text('Are you sure you want to delete this conversation and all its messages?'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        // Delete all messages in the conversation
                        final messages = await FirebaseFirestore.instance
                            .collection('conversations')
                            .doc(conversationId)
                            .collection('messages')
                            .get();
                        for (var msg in messages.docs) {
                          await msg.reference.delete();
                        }
                        // Delete the conversation document
                        await FirebaseFirestore.instance
                            .collection('conversations')
                            .doc(conversationId)
                            .delete();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _getTimeAgo(Timestamp timestamp) {
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
  final ScrollController _scrollController = ScrollController();

  String? _otherUserName;
  String? _otherUserAvatar;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserInfo();
  }

  Future<void> _fetchOtherUserInfo() async {
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

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Update the last message in the conversation if needed
      final messages = await _firestore
          .collection('conversations')
          .doc(widget.conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messages.docs.isNotEmpty) {
        final lastMessage = messages.docs.first.data();
        await _firestore.collection('conversations').doc(widget.conversationId).update({
          'lastMessage': lastMessage['text'] ?? lastMessage['message'] ?? '',
          'lastTimestamp': lastMessage['timestamp'],
        });
      } else {
        await _firestore.collection('conversations').doc(widget.conversationId).update({
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error deleting message: $e');
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
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
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
                    .orderBy('timestamp', descending: true)
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
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == widget.currentUserId;
                      final messageText = data['text'] ?? data['message'] ?? '';
                      final messageId = docs[index].id;

                      return GestureDetector(
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Message'),
                              content: const Text('Are you sure you want to delete this message?'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _deleteMessage(messageId);
                          }
                        },
                        child: Align(
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


