import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/tribe_model.dart';

class SearchMusicTribePage extends StatefulWidget {
  const SearchMusicTribePage({super.key});

  @override
  State<SearchMusicTribePage> createState() => _SearchMusicTribePageState();
}

class _SearchMusicTribePageState extends State<SearchMusicTribePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _joinTribe(String tribeId, String tribeName, List<String> currentMembers) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to join a tribe')),
      );
      return;
    }

    try {
      if (currentMembers.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already a member of $tribeName')),
        );
        print('User ${user.uid} already in tribe $tribeName'); // Debug log
        return;
      }

      await _firestore.collection('tribes').doc(tribeId).update({
        'members': FieldValue.arrayUnion([user.uid]),
      });
      print('User ${user.uid} joined tribe $tribeName'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined $tribeName!')),
      );
    } catch (e) {
      print('Error joining tribe: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join tribe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Tribes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tribes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _searchQuery.isEmpty
                  ? _firestore.collection('tribes').snapshots()
                  : _firestore
                      .collection('tribes')
                      .where('tribeName', isGreaterThanOrEqualTo: _searchQuery)
                      .where('tribeName',
                          isLessThanOrEqualTo: '${_searchQuery}z')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tribes = snapshot.data!.docs
                    .map((doc) => Tribe.fromFirestore(doc))
                    .toList();

                if (tribes.isEmpty) {
                  return const Center(
                    child: Text('No tribes found. Try a different search term.'),
                  );
                }

                return ListView.builder(
                  itemCount: tribes.length,
                  itemBuilder: (context, index) {
                    final tribe = tribes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: tribe.groupIcon != null &&
                                tribe.groupIcon!.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage:
                                    NetworkImage(tribe.groupIcon!),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.group),
                              ),
                        title: Text(tribe.tribeName),
                        subtitle: Text(tribe.description ?? ''),
                        trailing: ElevatedButton(
                          onPressed: () => _joinTribe(
                            tribe.id,
                            tribe.tribeName,
                            tribe.members ?? [],
                          ),
                          child: const Text('Join'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}