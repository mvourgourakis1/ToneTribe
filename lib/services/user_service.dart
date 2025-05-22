import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getProfilePictureUrl(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['profile_picture_url'];
  }

  Future<void> updateProfilePicture(String uid, String url) async {
    await _firestore.collection('users').doc(uid).update({
      'profile_picture_url': url,
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).update(userData);
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }
}