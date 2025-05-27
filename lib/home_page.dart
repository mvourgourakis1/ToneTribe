import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/tribe_model.dart';
import 'TribeChat.dart';
import 'tribecreationpage.dart';
import 'screens/forum_screen.dart';
import 'tribesearch.dart';
import 'screens/profile_screen.dart';
import 'tribePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) {
      // Show a dialog to select a tribe for chat
      _showTribeSelectionDialog();
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ForumScreen(),
        ),
      );
      return;
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Tribes',
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.grid_view_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateMusicTribePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchMusicTribePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
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
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Forums',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.transparent,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[500],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not signed in.'));
    } 
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tribes')
          .where('members', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tribes found.'));
        }
        final tribes = snapshot.data!.docs
            .map((doc) => Tribe.fromFirestore(doc))
            .toList();
        // Sort pinned tribes to the top
        tribes.sort((a, b) => (b.isPinned ? 1 : 0) - (a.isPinned ? 1 : 0));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          itemCount: tribes.length,
          itemBuilder: (context, index) {
            final tribe = tribes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildTribeItem(tribe),
            );
          },
        );
      },
    );
  }

  Widget _buildTribeItem(Tribe tribe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        leading: tribe.groupIcon != null && tribe.groupIcon!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  tribe.groupIcon!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.group, color: Colors.white),
              ),
        title: Text(tribe.tribeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(tribe.description ?? '', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        trailing: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange.withOpacity(0.7), width: 1.5),
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TribePage(tribe: tribe),
            ),
          );
        },
      ),
    );
  }
}

// To integrate this into your app, you would typically add it to your routes 
// or set it as the home property in your MaterialApp.
// For example, in your main.dart:
//
// import 'package:YOUR_APP_NAME/home_page.dart'; // Adjust path as needed
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'ToneTribe',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: const HomePage(), // Set HomePage as the initial screen
//     );
//   }
// } 