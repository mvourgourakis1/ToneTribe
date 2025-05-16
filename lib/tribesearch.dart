import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchMusicTribePage extends StatefulWidget {
  const SearchMusicTribePage({super.key});

  @override
  _SearchMusicTribePageState createState() => _SearchMusicTribePageState();
}

class _SearchMusicTribePageState extends State<SearchMusicTribePage> {
  final _searchController = TextEditingController();
  List<String> _selectedGenres = [];
  final List<String> _availableGenres = [
    'Rock',
    'Pop',
    'Hip Hop',
    'Electronic',
    'Country',
    'Jazz',
    'Classical',
    'Blues',
    'Reggae',
    'Folk',
    'Indie',
    'Metal',
    'Punk',
    'R&B',
    'Soul',
  ];
  late final FirebaseFirestore _firestore;
  String _searchQuery = '';
  // Replace with actual user ID, e.g., FirebaseAuth.instance.currentUser?.uid
  final String _currentUserId = 'user123'; // Placeholder for testing

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _searchController.addListener(_onSearchChanged);
    print('SearchMusicTribePage initialized'); // Debug log
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      print('Search query updated: $_searchQuery'); // Debug log
    });
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('tribes');
    if (_selectedGenres.isNotEmpty) {
      query = query.where('genres', arrayContainsAny: _selectedGenres);
      print('Genre filter applied: $_selectedGenres'); // Debug log
    }
    return query;
  }

  Future<void> _joinTribe(String tribeId, String tribeName, List<String> currentMembers) async {
    try {
      if (currentMembers.contains(_currentUserId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already a member of $tribeName')),
        );
        print('User $_currentUserId already in tribe $tribeName'); // Debug log
        return;
      }

      await _firestore.collection('tribes').doc(tribeId).update({
        'members': FieldValue.arrayUnion([_currentUserId]),
      });
      print('User $_currentUserId joined tribe $tribeName'); // Debug log
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
        title: const Text('Search Music Tribes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              print('Refresh triggered'); // Debug log
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Tribe Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filter by Genres:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8.0,
              children: _availableGenres.map((genre) {
                return FilterChip(
                  label: Text(genre),
                  selected: _selectedGenres.contains(genre),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                print('StreamBuilder state: ${snapshot.connectionState}'); // Debug log
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('Loading tribes...'); // Debug log
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print('Firestore error: ${snapshot.error}'); // Debug log
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error loading tribes. Please try again.'),
                        const SizedBox(height: 8),
                        Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No tribes found in Firestore'); // Debug log
                  return const Center(child: Text('No tribes found. Try creating one!'));
                }

                final tribes = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final tribeName = data['tribeName']?.toString().toLowerCase() ?? '';
                  print('Checking tribe: $tribeName'); // Debug log
                  return _searchQuery.isEmpty || tribeName.contains(_searchQuery.toLowerCase());
                }).toList();

                print('Filtered tribes count: ${tribes.length}'); // Debug log

                if (tribes.isEmpty) {
                  return const Center(child: Text('No tribes match your search or filters.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: tribes.length,
                  itemBuilder: (context, index) {
                    final doc = tribes[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tribeId = doc.id;
                    final tribeName = data['tribeName'] ?? 'Unnamed Tribe';
                    final description = data['description'] ?? 'No description';
                    final musicFocus = data['musicFocus'] ?? 'Not specified';
                    final genres = List<String>.from(data['genres'] ?? []);
                    final privacy = data['privacy'] ?? 'Unknown';
                    final members = List<String>.from(data['members'] ?? []);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(
                          tribeName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(description),
                            const SizedBox(height: 4.0),
                            Text('Focus: $musicFocus'),
                            const SizedBox(height: 4.0),
                            Text('Genres: ${genres.isEmpty ? "None" : genres.join(", ")}'),
                            const SizedBox(height: 4.0),
                            Text('Privacy: $privacy'),
                            const SizedBox(height: 4.0),
                            Text('Members: ${members.length}'),
                            const SizedBox(height: 8.0),
                            ElevatedButton(
                              onPressed: () => _joinTribe(tribeId, tribeName, members),
                              child: Text(members.contains(_currentUserId) ? 'Joined' : 'Join Tribe'),
                            ),
                          ],
                        ),
                        onTap: () {
                          print('Tapped tribe: $tribeName'); // Debug log
                          // TODO: Navigate to tribe details page or handle tap
                        },
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