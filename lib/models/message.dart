import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String userId;
  final String username;
  final String profileImageUrl;
  final String content;
  final DateTime timestamp;
  final Message? replyTo; // Reference to the message being replied to

  Message({
    required this.id,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.content,
    required this.timestamp,
    this.replyTo,
  });

  // Factory constructor to create a Message from Firestore data
  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      profileImageUrl: data['profileImageUrl'] ?? 'https://via.placeholder.com/50',
      content: data['content'] ?? '',
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      replyTo: data['replyTo'] != null
          ? Message.fromFirestore(data['replyTo'], data['replyTo']['id'] ?? '')
          : null,
    );
  }
} 