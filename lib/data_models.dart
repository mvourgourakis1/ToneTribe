// lib/data_models.dart

// TEMPORARY USER DATA MODEL - This will need to be expanded later
// for authentication, user profiles, storing user's votes, etc.
class User {
  final String id;
  final String username;
  // Potentially add: email, profilePictureUrl, likedPosts, dislikedPosts, etc.

  User({
    required this.id,
    required this.username,
  });
}

// Dummy User Data
User sampleCurrentUser = User(id: 'user123', username: 'MusicLover99');

class Post {
  final String id;
  final String title;
  final String content;
  final String author; // Could be a User object in a real app
  final DateTime timestamp;
  int upvotes;
  int downvotes;
  List<Comment> comments; // Made mutable for easier local updates in demo
  final List<String> tags; // Added tags for filtering

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.timestamp,
    this.upvotes = 0,
    this.downvotes = 0,
    List<Comment>? comments,
    this.tags = const [],
  }) : comments = comments ?? [];
}

class Comment {
  final String id;
  final String postId;
  final String? parentCommentId;
  final String author; // Could be a User object
  final String content; // Changed from text to content
  final DateTime timestamp;
  int upvotes;
  int downvotes;
  String? userVote; // Added userVote field
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.postId,
    this.parentCommentId,
    required this.author,
    required this.content, // Changed from text to content
    required this.timestamp,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote, // Added userVote parameter
    List<Comment>? replies,
  }) : replies = replies ?? [];
}

// Updated Sample Data with Tags
List<Post> samplePosts = [
  Post(
    id: '1',
    title: 'Bohemian Rhapsody - Queen',
    content: 'Is this the real life? Is this just fantasy? A true masterpiece of rock opera.',
    author: 'FreddieFan',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    upvotes: 120,
    downvotes: 5,
    tags: ['Rock', 'Classic Rock', 'Queen', 'Opera'],
    comments: [
      Comment(
        id: 'c1',
        postId: '1',
        author: 'RockLover',
        content: 'Absolutely iconic! The vocal harmonies are insane.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        upvotes: 15,
        replies: [
          Comment(
            id: 'c1_r1',
            postId: '1',
            parentCommentId: 'c1',
            author: 'GuitarHero',
            content: 'And Brian May\'s solo... legendary!',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            upvotes: 8,
          ),
        ]
      ),
      Comment(
        id: 'c2',
        postId: '1',
        author: 'Newbie',
        content: 'Just heard this for the first time. Mind blown!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        upvotes: 5,
      ),
    ]
  ),
  Post(
    id: '2',
    title: 'Stairway to Heaven - Led Zeppelin',
    content: 'The build-up in this song is incredible. A journey in itself.',
    author: 'ZeppelinHead',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    upvotes: 95,
    downvotes: 2,
    tags: ['Rock', 'Classic Rock', 'Led Zeppelin', 'Folk Rock'],
    comments: [
       Comment(
        id: 'c3',
        postId: '2',
        author: 'Music Critic',
        content: 'A classic for a reason. The lyrics are so poetic.',
        timestamp: DateTime.now().subtract(const Duration(hours: 20)),
        upvotes: 10,
      ),
    ]
  ),
  Post(
    id: '3',
    title: 'Imagine - John Lennon',
    content: 'A timeless message of peace and unity. Still relevant today.',
    author: 'PeaceSeeker',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    upvotes: 250,
    downvotes: 10,
    tags: ['Pop', 'Peace', 'John Lennon', 'Classic'],
  ),
  Post(
    id: '4',
    title: 'Shape of You - Ed Sheeran',
    content: 'Catchy tune, great for a workout playlist!',
    author: 'PopFanatic',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    upvotes: 180,
    downvotes: 15,
    tags: ['Pop', 'Ed Sheeran', 'Contemporary'],
  ),
];