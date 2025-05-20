import 'package:cloud_firestore/cloud_firestore.dart';

class Tribe {
  final String id;
  final String name;
  final String? subtitle; // Corresponds to the '........' in the UI
  final String? imageUrl; // URL for the tribe's image (e.g., for HTCS)
  final List<String>? members; // Optional: list of member UIDs

  Tribe({
    required this.id,
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.members,
  });

  factory Tribe.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Tribe(
      id: snapshot.id,
      name: data?['name'] as String? ?? 'Unnamed Tribe',
      subtitle: data?['subtitle'] as String?,
      imageUrl: data?['imageUrl'] as String?,
      members: data?['members'] != null 
          ? List<String>.from(data!['members'] as List<dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (name.isNotEmpty) 'name': name,
      if (subtitle != null) 'subtitle': subtitle,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (members != null) 'members': members,
    };
  }
} 