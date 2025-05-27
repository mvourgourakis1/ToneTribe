import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/profile_picture.dart';
import '../widgets/song_thumbnail.dart';
import '../widgets/playlist_grid_item.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    final user = _auth.currentUser;
    if (user != null) {
      final url = await _userService.getProfilePictureUrl(user.uid);
      if (mounted) {
        setState(() {
          _profilePictureUrl = url;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Not signed in'),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfilePicture(imageUrl: _profilePictureUrl),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? user.email ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  )
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Favorite Songs",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (index) => SongThumbnail(isSelected: index == 1),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Your Playlists",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: List.generate(
                  4,
                  (index) => PlaylistGridItem(
                    onTap: () {
                      Navigator.pushNamed(context, '/playlist/$index');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
        ],
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[500],
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}