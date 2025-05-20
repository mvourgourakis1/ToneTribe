import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get messages stream
  Stream<List<Message>> getMessages(String channelId) {
    return _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Send a message
  Future<void> sendMessage({
    required String channelId,
    required String content,
    Message? replyTo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final messageData = {
      'userId': user.uid,
      'username': user.displayName ?? 'Anonymous',
      'profileImageUrl': user.photoURL ?? 'https://via.placeholder.com/50',
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      if (replyTo != null)
        'replyTo': {
          'id': replyTo.id,
          'userId': replyTo.userId,
          'username': replyTo.username,
          'profileImageUrl': replyTo.profileImageUrl,
          'content': replyTo.content,
          'timestamp': Timestamp.fromDate(replyTo.timestamp),
        },
    };

    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .add(messageData);
  }

  // Delete a message
  Future<void> deleteMessage(String channelId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final messageDoc = await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (messageDoc.data()?['userId'] != user.uid) {
      throw Exception('Not authorized to delete this message');
    }

    await messageDoc.reference.delete();
  }

  // Report a message
  Future<void> reportMessage(String channelId, String messageId) async {
    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reported': true,
      'reportedAt': FieldValue.serverTimestamp(),
    });
  }
} 