import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../models/tribe_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if user is a member of the tribe
  Future<bool> isUserInTribe(String tribeId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final tribeDoc = await _firestore.collection('tribes').doc(tribeId).get();
    if (!tribeDoc.exists) return false;

    final members = List<String>.from(tribeDoc.data()?['members'] ?? []);
    return members.contains(user.uid);
  }

  // Get messages stream for a specific channel in a tribe
  Stream<List<Message>> getChannelMessages(String tribeId, String channelId) {
    return _firestore
        .collection('tribes')
        .doc(tribeId)
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

  // Send a message to a channel in a tribe
  Future<void> sendChannelMessage({
    required String tribeId,
    required String channelId,
    required String content,
    Message? replyTo,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is a member of the tribe
    if (!await isUserInTribe(tribeId)) {
      throw Exception('You are not a member of this tribe');
    }

    final messageData = {
      'userId': user.uid,
      'username': user.displayName ?? user.email ?? 'Anonymous',
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
        .collection('tribes')
        .doc(tribeId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .add(messageData);
  }

  // Delete a message from a channel
  Future<void> deleteChannelMessage(String tribeId, String channelId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is a member of the tribe
    if (!await isUserInTribe(tribeId)) {
      throw Exception('You are not a member of this tribe');
    }

    final messageDoc = await _firestore
        .collection('tribes')
        .doc(tribeId)
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

  // Report a message in a channel
  Future<void> reportChannelMessage(String tribeId, String channelId, String messageId) async {
    if (!await isUserInTribe(tribeId)) {
      throw Exception('You are not a member of this tribe');
    }

    await _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('channels')
        .doc(channelId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reported': true,
      'reportedAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new channel in a tribe
  Future<Channel> createChannel({
    required String tribeId,
    required String name,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is a member of the tribe
    if (!await isUserInTribe(tribeId)) {
      throw Exception('You are not a member of this tribe');
    }

    final channelData = {
      'name': name,
      if (description != null) 'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': user.uid,
    };

    final channelRef = await _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('channels')
        .add(channelData);

    return Channel(
      id: channelRef.id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      createdBy: user.uid,
    );
  }

  // Get all channels for a tribe
  Stream<List<Channel>> getTribeChannels(String tribeId) {
    return _firestore
        .collection('tribes')
        .doc(tribeId)
        .collection('channels')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Channel.fromFirestore(doc);
      }).toList();
    });
  }
} 