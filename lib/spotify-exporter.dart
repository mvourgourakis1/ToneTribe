import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const SpotifyPlaylistImporter());
}

class SpotifyPlaylistImporter extends StatelessWidget {
  const SpotifyPlaylistImporter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const PlaylistImportScreen(),
      theme: ThemeData(primarySwatch: Colors.green),
    );
  }
}

class PlaylistImportScreen extends StatefulWidget {
  const PlaylistImportScreen({super.key});

  @override
  _PlaylistImportScreenState createState() => _PlaylistImportScreenState();
}

class _PlaylistImportScreenState extends State<PlaylistImportScreen> {
  final String clientId = 'YOUR_CLIENT_ID'; // Replace with your Spotify Client ID
  final String redirectUri = 'myapp://callback';
  String? accessToken;
  String? refreshToken;
  String? userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTokens();
    _handleRedirect();
  }

  // Load stored tokens from shared preferences
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      accessToken = prefs.getString('access_token');
      refreshToken = prefs.getString('refresh_token');
    });
    if (accessToken != null) {
      await _getUserId();
    }
  }

  // Handle redirect URI after Spotify login
  Future<void> _handleRedirect() async {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      await _exchangeCodeForToken(code!);
      // Clear query parameters from URL
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  // Launch Spotify OAuth login
  Future<void> _loginWithSpotify() async {
    final authUrl = 'https://accounts.spotify.com/authorize'
        '?client_id=$clientId'
        '&response_type=code'
        '&redirect_uri=$redirectUri'
        '&scope=user-read-private playlist-modify-public playlist-modify-private';
    if (await canLaunch(authUrl)) {
      await launch(authUrl);
    } else {
      _showError('Could not launch Spotify login');
    }
  }

  // Exchange authorization code for access token
  Future<void> _exchangeCodeForToken(String code) async {
    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ' +
            base64Encode(utf8.encode('$clientId:YOUR_CLIENT_SECRET')),
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        accessToken = data['access_token'];
        refreshToken = data['refresh_token'];
      });
      await prefs.setString('access_token', accessToken!);
      await prefs.setString('refresh_token', refreshToken!);
      await _getUserId();
    } else {
      _showError('Failed to authenticate with Spotify');
    }
    setState(() => isLoading = false);
  }

  // Refresh access token
  Future<void> _refreshAccessToken() async {
    if (refreshToken == null) return;
    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic ' +
            base64Encode(utf8.encode('$clientId:YOUR_CLIENT_SECRET')),
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        accessToken = data['access_token'];
      });
      await prefs.setString('access_token', accessToken!);
    } else {
      _showError('Failed to refresh token');
    }
    setState(() => isLoading = false);
  }

  // Get Spotify user ID
  Future<void> _getUserId() async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userId = data['id'];
      });
    } else if (response.statusCode == 401) {
      await _refreshAccessToken();
      await _getUserId();
    } else {
      _showError('Failed to get user ID');
    }
  }

  // Search for a track on Spotify
  Future<String?> _searchTrack(String query) async {
    final response = await http.get(
      Uri.parse(
          'https://api.spotify.com/v1/search?q=${Uri.encodeQueryComponent(query)}&type=track&limit=1'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['tracks']['items'].isNotEmpty) {
        return data['tracks']['items'][0]['uri'];
      }
    } else if (response.statusCode == 401) {
      await _refreshAccessToken();
      return _searchTrack(query);
    }
    return null;
  }

  // Create a playlist
  Future<String?> _createPlaylist(String name) async {
    final response = await http.post(
      Uri.parse('https://api.spotify.com/v1/users/$userId/playlists'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'public': false,
        'description': 'Imported playlist from Flutter app',
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else if (response.statusCode == 401) {
      await _refreshAccessToken();
      return _createPlaylist(name);
    }
    return null;
  }

  // Add tracks to playlist
  Future<void> _addTracksToPlaylist(String playlistId, List<String> trackUris) async {
    final response = await http.post(
      Uri.parse('https://api.spotify.com/v1/playlists/$playlistId/tracks'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'uris': trackUris}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      if (response.statusCode == 401) {
        await _refreshAccessToken();
        await _addTracksToPlaylist(playlistId, trackUris);
      } else {
        _showError('Failed to add tracks to playlist');
      }
    }
  }

  // Import playlist
  Future<void> _importPlaylist() async {
    if (userId == null || accessToken == null) {
      _showError('Please log in to Spotify');
      return;
    }

    setState(() => isLoading = true);

    // Sample playlist (replace with your input method)
    final songs = [
      'Blinding Lights - The Weeknd',
      'Shape of You - Ed Sheeran',
      'Bohemian Rhapsody - Queen',
    ];

    // Search for track URIs
    final trackUris = <String>[];
    for (final song in songs) {
      final uri = await _searchTrack(song);
      if (uri != null) {
        trackUris.add(uri);
      }
    }

    if (trackUris.isEmpty) {
      _showError('No tracks found');
      setState(() => isLoading = false);
      return;
    }

    // Create playlist
    final playlistId = await _createPlaylist('My Imported Playlist');
    if (playlistId == null) {
      _showError('Failed to create playlist');
      setState(() => isLoading = false);
      return;
    }

    // Add tracks to playlist
    await _addTracksToPlaylist(playlistId, trackUris);
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playlist imported successfully!')),
    );
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotify Playlist Importer')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (accessToken == null)
                    ElevatedButton(
                      onPressed: _loginWithSpotify,
                      child: const Text('Login with Spotify'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _importPlaylist,
                      child: const Text('Import Playlist'),
                    ),
                ],
              ),
      ),
    );
  }
}