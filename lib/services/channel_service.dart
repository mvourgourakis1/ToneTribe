import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChannelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new channel
  Future<DocumentReference> createChannel(String name, String description) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final channelRef = await _firestore.collection('channels').add({
      'name': name,
      'description': description,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add creator as member and moderator
    await Future.wait([
      channelRef.collection('members').doc(user.uid).set({
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'member',
      }),
      channelRef.collection('moderators').doc(user.uid).set({
        'addedAt': FieldValue.serverTimestamp(),
      }),
    ]);

    return channelRef;
  }

  // Get user's channels
  Stream<QuerySnapshot> getUserChannels() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('channels')
        .where('createdAt', isNull: false)  // This ensures we get all channels
        .snapshots();
  }

  // Join a channel
  Future<void> joinChannel(String channelId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('members')
        .doc(user.uid)
        .set({
      'joinedAt': FieldValue.serverTimestamp(),
      'role': 'member',
    });
  }

  // Leave a channel
  Future<void> leaveChannel(String channelId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('members')
        .doc(user.uid)
        .delete();
  }

  // Add moderator to channel
  Future<void> addModerator(String channelId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if current user is a moderator
    final moderatorDoc = await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('moderators')
        .doc(user.uid)
        .get();

    if (!moderatorDoc.exists) {
      throw Exception('Not authorized to add moderators');
    }

    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('moderators')
        .doc(userId)
        .set({
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': user.uid,
    });
  }

  // Remove moderator from channel
  Future<void> removeModerator(String channelId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if current user is a moderator
    final moderatorDoc = await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('moderators')
        .doc(user.uid)
        .get();

    if (!moderatorDoc.exists) {
      throw Exception('Not authorized to remove moderators');
    }

    await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('moderators')
        .doc(userId)
        .delete();
  }

  // Check if user is a moderator
  Future<bool> isModerator(String channelId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final moderatorDoc = await _firestore
        .collection('channels')
        .doc(channelId)
        .collection('moderators')
        .doc(user.uid)
        .get();

    return moderatorDoc.exists;
  }
} 