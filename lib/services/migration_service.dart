import 'package:cloud_firestore/cloud_firestore.dart';

class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateGroupsToTribes() async {
    try {
      // Get all documents from groups collection
      final groupsSnapshot = await _firestore.collection('groups').get();
      
      // Create a batch for writing to tribes collection
      final batch = _firestore.batch();
      
      // Copy each document to tribes collection
      for (var doc in groupsSnapshot.docs) {
        final tribesRef = _firestore.collection('tribes').doc(doc.id);
        batch.set(tribesRef, doc.data());
      }
      
      // Commit the batch
      await batch.commit();
      
      // Delete all documents from groups collection
      final deleteBatch = _firestore.batch();
      for (var doc in groupsSnapshot.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
      
      print('Successfully migrated ${groupsSnapshot.docs.length} documents from groups to tribes');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  Future<bool> checkMigrationStatus() async {
    try {
      final groupsCount = (await _firestore.collection('groups').count().get()).count ?? 0;
      final tribesCount = (await _firestore.collection('tribes').count().get()).count ?? 0;
      
      return groupsCount == 0 && tribesCount > 0;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }
} 