import 'package:flutter/material.dart';

class Message {
  final String userId;
  final String username;
  final String profileImageUrl;
  final String content;
  final DateTime timestamp;
  final Message? replyTo; // Reference to the message being replied to

  Message({
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.content,
    required this.timestamp,
    this.replyTo,
  });
} 