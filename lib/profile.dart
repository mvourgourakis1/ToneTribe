// ToneTribe App - Profile Section Implementation
// This file implements the profile section UI and functionality based on the technical specification

import 'dart:convert';
import 'dart:ui';

// User Profile Model
class UserProfile {
  final String userId;
  final String username;
  final String profilePictureUrl;
  final String bio;
  final DateTime dateJoined;
  final List<Song> topSongs;

  UserProfile({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
    required this.bio,
    required this.dateJoined,
    required this.topSongs,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      username: json['username'],
      profilePictureUrl: json['profilePicture'],
      bio: json['bio'],
      dateJoined: DateTime.parse(json['dateJoined']),
      topSongs: (json['topSongs'] as List)
          .map((songJson) => Song.fromJson(songJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profilePicture': profilePictureUrl,
      'bio': bio,
      'dateJoined': dateJoined.toIso8601String(),
      'topSongs': topSongs.map((song) => song.toJson()).toList(),
    };
  }
}

// Song Model
class Song {
  final String songId;
  final String title;
  final String artist;
  final String albumArtUrl;
  final int durationInSeconds;
  final String previewUrl;

  Song({
    required this.songId,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    required this.durationInSeconds,
    required this.previewUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      songId: json['songId'],
      title: json['title'],
      artist: json['artist'],
      albumArtUrl: json['albumArt'],
      durationInSeconds: json['duration'],
      previewUrl: json['previewUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songId': songId,
      'title': title,
      'artist': artist,
      'albumArt': albumArtUrl,
      'duration': durationInSeconds,
      'previewUrl': previewUrl,
    };
  }

  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Theme Management
class ThemeManager {
  bool _isDarkMode = false;
  
  // Singleton pattern
  static final ThemeManager _instance = ThemeManager._internal();
  
  factory ThemeManager() {
    return _instance;
  }
  
  ThemeManager._internal();
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners();
  }
  
  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveThemePreference();
    notifyListeners();
  }
  
  // In a real implementation, this would use platform-specific storage
  void _saveThemePreference() {
    print('Saving theme preference: $_isDarkMode');
    // Implementation would use SharedPreferences or similar
  }
  
  // In a real implementation, this would use a proper state management solution
  final List<Function()> _listeners = [];
  
  void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

// API Service
class ProfileApiService {
  final String baseUrl = 'https://api.tonetribe.com';
  
  Future<UserProfile> getUserProfile(String userId) async {
    // In a real implementation, this would make an HTTP request
    // For now, we'll return mock data
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
    
    final mockResponse = {
      'userId': userId,
      'username': 'music_lover_42',
      'profilePicture': 'https://tonetribe.com/images/profiles/default.jpg',
      'bio': 'Music enthusiast with a passion for indie rock and electronic beats.',
      'dateJoined': '2024-03-15T10:30:00Z',
      'topSongs': [
        {
          'songId': 's1',
          'title': 'Starlight',
          'artist': 'Stellar Wave',
          'albumArt': 'https://tonetribe.com/images/albums/starlight.jpg',
          'duration': 237,
          'previewUrl': 'https://tonetribe.com/previews/starlight.mp3'
        },
        {
          'songId': 's2',
          'title': 'Midnight Drive',
          'artist': 'Urban Echo',
          'albumArt': 'https://tonetribe.com/images/albums/midnight_drive.jpg',
          'duration': 198,
          'previewUrl': 'https://tonetribe.com/previews/midnight_drive.mp3'
        },
        {
          'songId': 's3',
          'title': 'Ocean Breeze',
          'artist': 'Coastal Sounds',
          'albumArt': 'https://tonetribe.com/images/albums/ocean_breeze.jpg',
          'duration': 224,
          'previewUrl': 'https://tonetribe.com/previews/ocean_breeze.mp3'
        }
      ]
    };
    
    return UserProfile.fromJson(mockResponse);
  }
  
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    // In a real implementation, this would make an HTTP request
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    print('Profile updated for user: $userId');
    print('Updates: $updates');
  }
}

// Share Service
class ShareService {
  Future<void> shareProfile(UserProfile profile) async {
    // In a real implementation, this would use platform-specific sharing APIs
    final shareUrl = 'https://tonetribe.com/profile/${profile.userId}';
    
    // Generate share content
    final shareContent = 'Check out ${profile.username} on ToneTribe!\n'
        'Top songs: ${profile.topSongs.map((s) => s.title).join(", ")}\n'
        '$shareUrl';
    
    print('Sharing profile with content:');
    print(shareContent);
    
    // In a real implementation, this would open the native share dialog
    await Future.delayed(Duration(milliseconds: 300)); // Simulate share dialog
    print('Profile shared successfully');
  }
  
  String generateShareableLink(String userId) {
    return 'https://tonetribe.com/profile/$userId';
  }
}

// UI Components
// Note: In a real implementation, these would be proper UI widgets
// Since we're not using Flutter libraries, this is a simplified representation

class ProfileSection {
  final UserProfile profile;
  final ThemeManager themeManager;
  final ShareService shareService;
  final ProfileApiService apiService;
  
  ProfileSection({
    required this.profile,
    required this.themeManager,
    required this.shareService,
    required this.apiService,
  });
  
  void render() {
    final isDarkMode = themeManager.isDarkMode;
    final backgroundColor = isDarkMode ? '#121212' : '#FFFFFF';
    final textColor = isDarkMode ? '#FFFFFF' : '#333333';
    final accentColor = '#1DB954'; // ToneTribe green
    
    print('Rendering profile section with ${isDarkMode ? "dark" : "light"} theme');
    print('Background: $backgroundColor, Text: $textColor, Accent: $accentColor');
    
    _renderProfileHeader();
    _renderTopSongs();
    _renderActionButtons();
  }
  
  void _renderProfileHeader() {
    print('=== PROFILE HEADER ===');
    print('Username: ${profile.username}');
    print('Profile Picture: ${profile.profilePictureUrl}');
    print('Bio: ${profile.bio}');
    print('Member since: ${_formatDate(profile.dateJoined)}');
  }
  
  void _renderTopSongs() {
    print('=== TOP SONGS ===');
    for (int i = 0; i < profile.topSongs.length; i++) {
      final song = profile.topSongs[i];
      print('${i + 1}. ${song.title} - ${song.artist} (${song.formattedDuration})');
    }
  }
  
  void _renderActionButtons() {
    print('=== ACTIONS ===');
    print('- Share Profile');
    print('- Toggle Theme (Currently: ${themeManager.isDarkMode ? "Dark" : "Light"})');
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  void handleShareButtonPress() {
    shareService.shareProfile(profile);
  }
  
  void handleThemeToggle() {
    themeManager.toggleTheme();
    render(); // Re-render with new theme
  }
  
  void handleSongTap(Song song) {
    print('Playing preview for: ${song.title}');
    // In a real implementation, this would play the song preview
  }
  
  void handleSongLongPress(Song song) {
    print('Showing options for: ${song.title}');
    // In a real implementation, this would show a context menu
  }
  
  void handleProfilePictureTap() {
    print('Opening profile picture options');
    // In a real implementation, this would show profile picture options
  }
  
  void handlePullToRefresh() async {
    print('Refreshing profile data...');
    final updatedProfile = await apiService.getUserProfile(profile.userId);
    // In a real implementation, this would update the UI with new data
    print('Profile refreshed successfully');
  }
}

// Main function to demonstrate usage
void main() {
  final apiService = ProfileApiService();
  final themeManager = ThemeManager();
  final shareService = ShareService();
  
  // Set initial theme based on system preference (simplified)
  final systemDarkMode = true; // This would be determined from the system
  themeManager.setDarkMode(systemDarkMode);
  
  // Fetch user profile
  apiService.getUserProfile('user123').then((profile) {
    final profileSection = ProfileSection(
      profile: profile,
      themeManager: themeManager,
      shareService: shareService,
      apiService: apiService,
    );
    
    // Render the profile section
    profileSection.render();
    
    // Demonstrate theme toggle
    print('\nToggling theme...');
    profileSection.handleThemeToggle();
    
    // Demonstrate share functionality
    print('\nSharing profile...');
    profileSection.handleShareButtonPress();
    
    // Demonstrate song interaction
    print('\nInteracting with a song...');
    profileSection.handleSongTap(profile.topSongs[0]);
  });
}
