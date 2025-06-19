// This file will be rewritten to implement playlist creation using the Spotify API only.

import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' as spot;
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpotifySong {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;

  SpotifySong({required this.id, required this.title, required this.artist, required this.imageUrl});
}

class PlaylistCreation extends StatefulWidget {
  final String tribeId;
  const PlaylistCreation({Key? key, required this.tribeId}) : super(key: key);

  @override
  State<PlaylistCreation> createState() => _PlaylistCreationState();
}

class _PlaylistCreationState extends State<PlaylistCreation> {
  final TextEditingController _searchController = TextEditingController();
  final List<SpotifySong> _searchResults = [];
  final List<SpotifySong> _playlist = [];
  String? _accessToken;
  String? _playlistName;
  String? _createdPlaylistId;
  String? _error;
  bool _isLoading = false;
  Timer? _debounce;
  spot.SpotifyApi? _spotify;
  String? _userId;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    final client = OAuth2Client(
      authorizeUrl: 'https://accounts.spotify.com/authorize',
      tokenUrl: 'https://accounts.spotify.com/api/token',
      redirectUri: 'tonetribe://callback', // must match your Spotify app settings
      customUriScheme: 'tonetribe', // must match your app's scheme
    );

    final helper = OAuth2Helper(
      client,
      clientId: 'd4bd2825b4584320b0d3f23aa02bcfdd',
      clientSecret: '95f0b318abd940228ad9cdcd5fc90411',
      scopes: [
        'playlist-modify-public',
        'playlist-modify-private',
        'user-read-private',
        'user-read-email'
      ],
    );

    try {
      final token = await helper.getToken();
      if (token != null && token.accessToken != null) {
        _accessToken = token.accessToken;
        _spotify = spot.SpotifyApi.withAccessToken(_accessToken!);
        final me = await _spotify!.me.get();
        _userId = me.id;
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to get Spotify access token.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Spotify authentication error: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) _searchSpotify(query);
    });
  }

  Future<void> _searchSpotify(String query) async {
    if (_spotify == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults.clear();
    });
    try {
      final pages = await _spotify!.search.get(query).first();
      _searchResults.clear();
      for (var page in pages) {
        if (page.items == null) continue;
        for (var item in page.items!) {
          if (item is spot.Track) {
            _searchResults.add(
              SpotifySong(
                id: item.id ?? '',
                title: item.name ?? '',
                artist: item.artists?.isNotEmpty == true ? item.artists!.first.name ?? '' : '',
                imageUrl: item.album?.images?.isNotEmpty == true ? item.album!.images!.first.url ?? '' : '',
              ),
            );
          }
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Spotify search error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createSpotifyPlaylist() async {
    if (_playlistName == null || _playlistName!.isEmpty || _playlist.isEmpty || _spotify == null || _userId == null) {
      setState(() {
        _error = 'Missing playlist name, songs, or authentication.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final playlist = await _spotify!.playlists.createPlaylist(_userId!, _playlistName!, public: true, description: 'Created with ToneTribe');
      final uris = _playlist.map((s) => 'spotify:track:${s.id}').toList();
      await _spotify!.playlists.addTracks(uris, playlist.id!);
      // Save playlist to Firestore
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance
        .collection('tribes')
        .doc(widget.tribeId)
        .collection('playlists')
        .add({
          'name': _playlistName,
          'createdBy': user?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'spotifyId': playlist.id,
          'spotifyUrl': 'https://open.spotify.com/playlist/${playlist.id}',
          'tracks': _playlist.map((s) => {
            'id': s.id,
            'title': s.title,
            'artist': s.artist,
            'imageUrl': s.imageUrl,
          }).toList(),
        });
      setState(() {
        _createdPlaylistId = playlist.id;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error creating playlist: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(SpotifySong song) async {
    final uri = Uri.parse('https://open.spotify.com/track/${song.id}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        _error = 'Could not launch Spotify app.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Spotify Playlist')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_spotify == null)
                    ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.link),
                      label: const Text('Connect to Spotify'),
                    ),
                  if (_spotify != null) ...[
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search for songs',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, idx) {
                          final song = _searchResults[idx];
                          return ListTile(
                            leading: song.imageUrl.isNotEmpty
                                ? Image.network(song.imageUrl, width: 48, height: 48, fit: BoxFit.cover)
                                : const Icon(Icons.music_note),
                            title: Text(song.title),
                            subtitle: Text(song.artist),
                            trailing: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  if (!_playlist.any((s) => s.id == song.id)) {
                                    _playlist.add(song);
                                  }
                                });
                              },
                            ),
                            onTap: () => _playSong(song),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Playlist:', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _playlist.length,
                        itemBuilder: (context, idx) {
                          final song = _playlist[idx];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Column(
                              children: [
                                song.imageUrl.isNotEmpty
                                    ? Image.network(song.imageUrl, width: 48, height: 48, fit: BoxFit.cover)
                                    : const Icon(Icons.music_note),
                                Text(song.title, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _playlist.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Playlist Name',
                        prefixIcon: Icon(Icons.playlist_add),
                      ),
                      onChanged: (v) => _playlistName = v,
                    ),
                    ElevatedButton.icon(
                      onPressed: _playlist.isNotEmpty && _playlistName != null
                          ? _createSpotifyPlaylist
                          : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Create Spotify Playlist'),
                    ),
                    if (_createdPlaylistId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Playlist created! Open in Spotify.', style: TextStyle(color: Colors.green[700])),
                      ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
    );
  }
}
