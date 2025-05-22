import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data_models.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Getter for Firestore instance
  FirebaseFirestore get firestore => _firestore;

  // Get posts stream
  Stream<List<Post>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Post(
          id: doc.id,
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          author: data['author'] ?? 'Anonymous',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          upvotes: data['upvotes'] ?? 0,
          downvotes: data['downvotes'] ?? 0,
          tags: List<String>.from(data['tags'] ?? []),
          comments: [], // Comments will be loaded separately
        );
      }).toList();
    });
  }

  // Get comments for a post
  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Comment(
          id: doc.id,
          postId: postId,
          parentCommentId: data['parentCommentId'],
          author: data['author'] ?? 'Anonymous',
          content: data['content'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          upvotes: data['upvotes'] ?? 0,
          downvotes: data['downvotes'] ?? 0,
          userVote: data['userVote'],
          replies: [], // Replies will be loaded separately
        );
      }).toList();
    });
  }

  // Create a new post
  Future<DocumentReference> createPost(String title, String content, List<String> tags) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return await _firestore.collection('posts').add({
      'title': title,
      'content': content,
      'author': user.displayName ?? user.email ?? 'Anonymous',
      'authorId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'upvotes': 0,
      'downvotes': 0,
      'tags': tags,
    });
  }

  // Add a comment
  Future<DocumentReference> addComment(String postId, String content, {String? parentCommentId}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'content': content,
      'author': user.displayName ?? user.email ?? 'Anonymous',
      'authorId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'upvotes': 0,
      'downvotes': 0,
      'parentCommentId': parentCommentId,
    });
  }

  // Vote on a post
  Future<void> voteOnPost(String postId, String voteType) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final postRef = _firestore.collection('posts').doc(postId);
    final userVoteRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('votes')
        .doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      final userVoteDoc = await transaction.get(userVoteRef);

      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final currentVote = userVoteDoc.exists ? (userVoteDoc.data()?['voteType'] as String?) : null;
      final upvotes = postDoc.data()?['upvotes'] ?? 0;
      final downvotes = postDoc.data()?['downvotes'] ?? 0;

      if (currentVote == voteType) {
        // Remove vote
        transaction.update(postRef, {
          voteType == 'up' ? 'upvotes' : 'downvotes': FieldValue.increment(-1)
        });
        transaction.delete(userVoteRef);
      } else {
        // Add new vote or change vote
        if (currentVote != null) {
          transaction.update(postRef, {
            currentVote == 'up' ? 'upvotes' : 'downvotes': FieldValue.increment(-1)
          });
        }
        transaction.update(postRef, {
          voteType == 'up' ? 'upvotes' : 'downvotes': FieldValue.increment(1)
        });
        transaction.set(userVoteRef, {'voteType': voteType});
      }
    });
  }

  // Vote on a comment
  Future<void> voteOnComment(String postId, String commentId, String voteType) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final commentRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    final userVoteRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('votes')
        .doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final commentDoc = await transaction.get(commentRef);
      final userVoteDoc = await transaction.get(userVoteRef);

      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final currentVote = userVoteDoc.exists ? (userVoteDoc.data()?['voteType'] as String?) : null;
      final upvotes = commentDoc.data()?['upvotes'] ?? 0;
      final downvotes = commentDoc.data()?['downvotes'] ?? 0;

      if (currentVote == voteType) {
        // Remove vote
        transaction.update(commentRef, {
          voteType == 'up' ? 'upvotes' : 'downvotes': FieldValue.increment(-1)
        });
        transaction.delete(userVoteRef);
      } else {
        // Add new vote or change vote
        if (currentVote != null) {
          transaction.update(commentRef, {
            currentVote == 'up' ? 'upvotes' : 'downvotes': FieldValue.increment(-1)
          });
        }
        transaction.update(commentRef, {
          voteType == 'up' ? 'upvotes' : 'downvotes': FieldValue.increment(1)
        });
        transaction.set(userVoteRef, {'voteType': voteType});
      }
    });
  }

  // Get user's vote on a post
  Future<String?> getUserPostVote(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final voteDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('votes')
        .doc(user.uid)
        .get();

    return voteDoc.exists ? (voteDoc.data()?['voteType'] as String?) : null;
  }

  // Get user's vote on a comment
  Future<String?> getUserCommentVote(String postId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final voteDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .collection('votes')
        .doc(user.uid)
        .get();

    return voteDoc.exists ? (voteDoc.data()?['voteType'] as String?) : null;
  }
} 