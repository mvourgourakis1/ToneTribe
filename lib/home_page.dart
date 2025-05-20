import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tonetribe/models/tribe_model.dart';
import 'package:tonetribe/tribecreationpage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic here later
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Your Tribes',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.grid_view_outlined, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateMusicTribePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black54),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Center(child: Text('HomePage loaded')), // TEMP: Debug if HomePage is loading
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
            icon: CircleAvatar(
              radius: 14, // Slightly larger to match proportions
              backgroundColor: Colors.grey, // Placeholder color, image shows just an outline
              // child: Icon(Icons.person_outline, size: 18, color: Colors.white), // Optional: if you want an icon inside
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0, 
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Assuming your collection is named 'tribes'
      // TODO: If you need to filter by user, modify this query e.g.:
      // .where('members', arrayContains: FirebaseAuth.instance.currentUser?.uid)
      stream: FirebaseFirestore.instance.collection('tribes').snapshots() 
        as Stream<QuerySnapshot<Map<String, dynamic>>>,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
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

        // Separate the HTCS tribe if it exists and needs special handling/pinning
        // For now, we assume the first tribe in the list might be styled differently or sorted to be first.
        // The image shows "HTCS" at the top with an image.
        // Let's assume a field like `isPinned` or a specific ID for HTCS.
        // For simplicity, I'll use the `imageUrl` to differentiate for now.

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            const SizedBox(height: 10),
            ...tribes.map((tribe) {
              // Determine if it's the special "HTCS"-like item
              // This logic might need to be more robust based on your data
              final bool isSpecialItem = tribe.imageUrl != null && tribe.imageUrl!.isNotEmpty;
              return Column(
                children: [
                  _buildTribeItem(
                    name: tribe.name,
                    subtitle: tribe.subtitle ?? ' ', // Ensure subtitle is not null
                    imageUrl: tribe.imageUrl,
                    isSpecial: isSpecialItem, 
                  ),
                  const Divider(height: 1, color: Colors.grey),
                ],
              );
            }).toList(),
            const SizedBox(height: 20),
            const Text(
              'Friends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            // Placeholder for friends list
            // Text('Friends list will go here...'),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildTribeItem({
    required String name,
    required String subtitle,
    String? imageUrl,
    required bool isSpecial,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0), // Match image padding
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: isSpecial
          ? (imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    width: 48, // Slightly larger image
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                    ),
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                )
              : Container( 
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(Icons.group_work, color: Colors.grey[700]), // Changed icon
                ))
          : Container(
              width: 36, // Adjusted size for the square
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white, // White background for the square
                border: Border.all(color: Colors.grey.shade400, width: 1.5), // Thicker border
                borderRadius: BorderRadius.circular(6.0), // Slightly rounded corners
              ),
            ),
      onTap: () {
        // TODO: Navigate to Tribe details page or handle tap
        print('Tapped on tribe: $name');
      },
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