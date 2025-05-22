import 'package:cloud_firestore/cloud_firestore.dart';

class Tribe {
  final String id;
  final String tribeName;
  final String? description;
  final String? groupIcon;
  final List<String>? members;
  final bool isPinned;

  Tribe({
    required this.id,
    required this.tribeName,
    this.description,
    this.groupIcon,
    this.members,
    this.isPinned = false,
  });

  factory Tribe.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Tribe(
      id: snapshot.id,
      tribeName: data?['tribeName'] as String? ?? 'Unnamed Tribe',
      description: data?['description'] as String?,
      groupIcon: data?['groupIcon'] as String?,
      members: data?['members'] != null 
          ? List<String>.from(data!['members'] as List<dynamic>)
          : null,
      isPinned: data?['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (tribeName.isNotEmpty) 'tribeName': tribeName,
      if (description != null) 'description': description,
      if (groupIcon != null) 'groupIcon': groupIcon,
      if (members != null) 'members': members,
      'isPinned': isPinned,
    };
  }
} 