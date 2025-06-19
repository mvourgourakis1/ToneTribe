import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'models/tribe_model.dart';
import 'playlist_creation.dart';
import 'TribeChat.dart';
import 'screens/tribe-election-system.dart';
import 'package:url_launcher/url_launcher.dart';

class TribePage extends StatelessWidget {
  final Tribe tribe;

  const TribePage({Key? key, required this.tribe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tribe.tribeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_vote),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TribeLeaderElectionPage(tribe: tribe),
                ),
              );
            },
            tooltip: 'Tribe Elections',
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TribeChat(tribe: tribe),
                ),
              );
            },
            tooltip: 'Chat',
          ),
          if (tribe.isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.push_pin, color: Colors.amber),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistCreation(tribeId: tribe.id),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Playlist',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (tribe.groupIcon != null && tribe.groupIcon!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    tribe.groupIcon!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              tribe.tribeName,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (tribe.description != null && tribe.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  tribe.description!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            // Members Section
            Text(
              'Members (${tribe.members?.length ?? 0})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (tribe.members != null && tribe.members!.isNotEmpty)
              FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                future: Future.wait(
                  tribe.members!.map((memberId) => 
                    FirebaseFirestore.instance.collection('users').doc(memberId).get()
                  )
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error loading members: ${snapshot.error}');
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final memberDocs = snapshot.data!;
                  return Column(
                    children: memberDocs.map((doc) {
                      final data = doc.data();
                      final username = data?['username'] ?? 'Unknown User';
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(username[0].toUpperCase()),
                        ),
                        title: Text(username),
                      );
                    }).toList(),
                  );
                },
              ),
            if (tribe.members == null || tribe.members!.isEmpty)
              const Text('No members yet.'),
            const SizedBox(height: 24),
            // Old Playlists Section (replace placeholder)
            Text(
              'Old Playlists',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tribes')
                  .doc(tribe.id)
                  .collection('playlists')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Text('No playlists yet.');
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final createdBy = data['createdBy'] ?? 'Unknown';
                    final tracks = (data['tracks'] as List<dynamic>? ?? []);
                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance.collection('users').doc(createdBy).get(),
                      builder: (context, userSnapshot) {
                        String username = createdBy;
                        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.data() != null) {
                          username = userSnapshot.data!.data()!['username'] ?? createdBy;
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(data['name'] ?? 'Untitled'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Created by: $username'),
                                const SizedBox(height: 4),
                                if (tracks.isNotEmpty)
                                  SizedBox(
                                    height: 40,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: tracks.length,
                                      itemBuilder: (context, idx) {
                                        final img = tracks[idx]['imageUrl'] ?? '';
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4.0),
                                          child: img.isNotEmpty
                                              ? Image.network(img, width: 40, height: 40, fit: BoxFit.cover)
                                              : const Icon(Icons.music_note, size: 40),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              final url = data['spotifyUrl'];
                              if (url != null) {
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not open Spotify playlist.'))
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}