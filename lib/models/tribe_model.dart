import 'package:cloud_firestore/cloud_firestore.dart';

class Channel {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final String createdBy;

  Channel({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.createdBy,
  });

  factory Channel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    return Channel(
      id: snapshot.id,
      name: data?['name'] as String? ?? 'Unnamed Channel',
      description: data?['description'] as String?,
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data?['createdBy'] as String? ?? '',
    );
  }

  factory Channel.fromMap(Map<String, dynamic> data, String id) {
    return Channel(
      id: id,
      name: data['name'] as String? ?? 'Unnamed Channel',
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }
}

class Tribe {
  final String id;
  final String tribeName;
  final String? description;
  final String? groupIcon;
  final List<String>? members;
  final bool isPinned;
  final List<Channel>? channels;

  Tribe({
    required this.id,
    required this.tribeName,
    this.description,
    this.groupIcon,
    this.members,
    this.isPinned = false,
    this.channels,
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
      channels: data?['channels'] != null
          ? List<Channel>.from(
              (data!['channels'] as List<dynamic>).map(
                (channel) => Channel.fromMap(
                  channel as Map<String, dynamic>,
                  channel['id'] as String? ?? '',
                ),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (tribeName.isNotEmpty) 'tribeName': tribeName,
      if (description != null) 'description': description,
      if (groupIcon != null) 'groupIcon': groupIcon,
      if (members != null) 'members': members,
      'isPinned': isPinned,
      if (channels != null) 'channels': channels!.map((c) => c.toFirestore()).toList(),
    };
  }
} 