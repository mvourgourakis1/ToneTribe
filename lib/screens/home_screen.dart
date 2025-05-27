// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data_models.dart';
import '../TribeChat.dart';
import 'forum_screen.dart';
import '../services/auth_service.dart';
import '../playlist_creation.dart';
import '../models/tribe_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  void _showTribeSelectionDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select a Tribe'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('tribes')
                .where('members', arrayContains: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Text('No tribes found. Join a tribe first!');
              }

              final tribes = snapshot.data!.docs
                  .map((doc) => Tribe.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                shrinkWrap: true,
                itemCount: tribes.length,
                itemBuilder: (context, index) {
                  final tribe = tribes[index];
                  return ListTile(
                    leading: tribe.groupIcon != null && tribe.groupIcon!.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(tribe.groupIcon!),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.group),
                          ),
                    title: Text(tribe.tribeName),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TribeChat(tribe: tribe),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    final username = currentUser?.displayName ?? currentUser?.email ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToneTribe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.forum),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForumScreen(),
                ),
              );
            },
            tooltip: 'Forums',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome, $username',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildFeatureCard(
                      context,
                      'Chat Channels',
                      'Join music discussion channels',
                      Icons.chat,
                      _showTribeSelectionDialog,
                    ),
                    _buildFeatureCard(
                      context,
                      'Forums',
                      'Discuss music in forums',
                      Icons.forum,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForumScreen(),
                          ),
                        );
                      },
                    ),
                    _buildFeatureCard(
                      context,
                      'Create Playlist',
                      'Build and share your music playlists',
                      Icons.playlist_add,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlaylistCreation(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      color: Colors.black.withOpacity(0.3),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}