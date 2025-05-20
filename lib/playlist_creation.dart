import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Song model
class Song {
  final String title;
  final String artist;
  final String spotifyId;
  final String thumbnailUrl;
  final List<String> genres;

  Song({
    required this.title,
    required this.artist,
    required this.spotifyId,
    required this.thumbnailUrl,
    required this.genres,
  });
}

class PlaylistCreation extends StatefulWidget {
  const PlaylistCreation({Key? key}) : super(key: key);

  @override
  _PlaylistCreationState createState() => _PlaylistCreationState();
}

class _PlaylistCreationState extends State<PlaylistCreation> {
  final TextEditingController _searchController = TextEditingController();
  final List<Song> _searchResults = [];
  final List<Song> _playlist = [];
  Timer? _debounce;
  bool _isLoading = false;
  String? _error;

  // Common music genres for suggestions
  final List<String> _suggestedGenres = [
    'Rock', 'Pop', 'Hip Hop', 'Jazz', 'Classical', 'Electronic',
    'R&B', 'Country', 'Blues', 'Metal', 'Folk', 'Indie',
    'Alternative', 'Punk', 'Reggae', 'Soul', 'Funk', 'Gospel'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchSpotify(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO: Replace with your Spotify API credentials and proper authentication
      const String spotifyApiUrl = 'https://api.spotify.com/v1/search';
      final response = await http.get(
        Uri.parse('$spotifyApiUrl?q=$query&type=track&limit=10'),
        headers: {
          'Authorization': 'Bearer YOUR_SPOTIFY_ACCESS_TOKEN',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tracks = data['tracks']['items'] as List;
        
        setState(() {
          _searchResults.clear();
          for (var track in tracks) {
            _searchResults.add(Song(
              title: track['name'],
              artist: track['artists'][0]['name'],
              spotifyId: track['id'],
              thumbnailUrl: track['album']['images'][0]['url'],
              genres: [], // Will be populated when added to playlist
            ));
          }
        });
      } else {
        setState(() {
          _error = 'Failed to search Spotify. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchSpotify(query);
    });
  }

  void _showGenreDialog(Song song) {
    final TextEditingController genreController = TextEditingController();
    List<String> selectedGenres = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Genres for ${song.title}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: genreController,
                    decoration: InputDecoration(
                      hintText: 'Enter a genre',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (genreController.text.isNotEmpty) {
                            setModalState(() {
                              selectedGenres.add(genreController.text);
                              genreController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setModalState(() {
                          selectedGenres.add(value);
                          genreController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _suggestedGenres.map((genre) {
                      return FilterChip(
                        label: Text(genre),
                        selected: selectedGenres.contains(genre),
                        onSelected: (bool selected) {
                          setModalState(() {
                            if (selected) {
                              selectedGenres.add(genre);
                            } else {
                              selectedGenres.remove(genre);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: selectedGenres.map((genre) {
                      return Chip(
                        label: Text(genre),
                        onDeleted: () {
                          setModalState(() {
                            selectedGenres.remove(genre);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedGenres.isNotEmpty) {
                        setState(() {
                          _playlist.add(Song(
                            title: song.title,
                            artist: song.artist,
                            spotifyId: song.spotifyId,
                            thumbnailUrl: song.thumbnailUrl,
                            genres: selectedGenres,
                          ));
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add to Playlist'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Playlist'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for a song...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final song = _searchResults[index];
                  return ListTile(
                    leading: Image.network(
                      song.thumbnailUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.music_note);
                      },
                    ),
                    title: Text(song.title),
                    subtitle: Text(song.artist),
                    onTap: () => _showGenreDialog(song),
                  );
                },
              ),
            ),
          if (_playlist.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Current Playlist (${_playlist.length} songs)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _playlist.length,
                      itemBuilder: (context, index) {
                        final song = _playlist[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Column(
                            children: [
                              Image.network(
                                song.thumbnailUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.title,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
