import 'package:flutter/material.dart';
import 'models/message.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  Message? _replyingTo;
  int? _hoveredMessageIndex;

  @override
  void initState() {
    super.initState();
    // Add some sample messages
    _messages.addAll([
      Message(
        userId: '1',
        username: 'John Doe',
        profileImageUrl: 'https://via.placeholder.com/50',
        content: 'Hey everyone! How\'s it going?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        userId: '2',
        username: 'Jane Smith',
        profileImageUrl: 'https://via.placeholder.com/50',
        content: 'Doing great! Just working on some new features.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ]);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          userId: '1', // Current user ID
          username: 'John Doe', // Current username
          profileImageUrl: 'https://via.placeholder.com/50',
          content: _messageController.text,
          timestamp: DateTime.now(),
          replyTo: _replyingTo,
        ),
      );
      _messageController.clear();
      _replyingTo = null;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _startReply(Message message) {
    setState(() {
      _replyingTo = message;
      _messageController.clear();
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  Widget _buildMessageActions(Message message, int index) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _hoveredMessageIndex == index ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.reply, size: 20),
              onPressed: () => _startReply(message),
              tooltip: 'Reply',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.userId == '1';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          backgroundImage: NetworkImage(message.profileImageUrl),
                          radius: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredMessageIndex = index),
                          onExit: (_) => setState(() => _hoveredMessageIndex = null),
                          child: GestureDetector(
                            onLongPress: () => _startReply(message),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(
                                    message.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        if (message.replyTo != null) ...[
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Replying to ${message.replyTo!.username}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  message.replyTo!.content,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Theme.of(context).colorScheme.primary
                                                : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            message.content,
                                            style: TextStyle(
                                              color: isMe ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: isMe ? null : 0,
                                      left: isMe ? 0 : null,
                                      child: _buildMessageActions(message, index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundImage: NetworkImage(message.profileImageUrl),
                          radius: 20,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Replying to ${_replyingTo!.username}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyingTo!.content,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _replyingTo != null
                          ? 'Reply to ${_replyingTo!.username}...'
                          : 'Type a message...',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
