import 'package:flutter/material.dart';
import 'models/message.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'services/channel_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ChannelService _channelService = ChannelService();
  Message? _replyingTo;
  int? _hoveredMessageIndex;
  String _currentChannelId = 'general'; // Default channel
  final TextEditingController _newChannelNameController = TextEditingController();
  final TextEditingController _newChannelDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeGeneralChannel();
  }

  Future<void> _initializeGeneralChannel() async {
    try {
      // Check if general channel exists
      final generalChannelQuery = await _channelService.getChannelByName('general');
      if (generalChannelQuery == null) {
        // Create general channel if it doesn't exist
        final channelRef = await _channelService.createChannel(
          'general',
          'The main channel for all users',
        );
        setState(() {
          _currentChannelId = channelRef.id;
        });
      } else {
        setState(() {
          _currentChannelId = generalChannelQuery.id;
        });
      }
    } catch (e) {
      // Handle any errors silently - the default 'general' ID will be used
      print('Error initializing general channel: $e');
    }
  }

  void _createNewChannel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Channel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newChannelNameController,
              decoration: const InputDecoration(
                labelText: 'Channel Name',
                hintText: 'Enter channel name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newChannelDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter channel description',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_newChannelNameController.text.isNotEmpty) {
                try {
                  final channelRef = await _channelService.createChannel(
                    _newChannelNameController.text,
                    _newChannelDescriptionController.text,
                  );
                  setState(() {
                    _currentChannelId = channelRef.id;
                  });
                  _newChannelNameController.clear();
                  _newChannelDescriptionController.clear();
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating channel: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinChannel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Channel'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder(
            stream: _channelService.getUserChannels(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final channels = snapshot.data!.docs;

              if (channels.isEmpty) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No channels available'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _createNewChannel();
                      },
                      child: const Text('Create New Channel'),
                    ),
                  ],
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: channels.map((channel) {
                      return ListTile(
                        title: Text(channel['name'] ?? 'Unnamed Channel'),
                        subtitle: Text(channel['description'] ?? 'No description'),
                        onTap: () async {
                          try {
                            await _channelService.joinChannel(channel.id);
                            setState(() {
                              _currentChannelId = channel.id;
                            });
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error joining channel: $e')),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    _chatService.sendMessage(
      channelId: _currentChannelId,
      content: _messageController.text,
      replyTo: _replyingTo,
    );

    _messageController.clear();
    setState(() {
      _replyingTo = null;
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
            if (message.userId == _authService.currentUser?.uid)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _chatService.deleteMessage(_currentChannelId, message.id),
                tooltip: 'Delete',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewChannel,
            tooltip: 'Create Channel',
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _joinChannel,
            tooltip: 'Join Channel',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessages(_currentChannelId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                final currentUser = _authService.currentUser;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.userId == currentUser?.uid;

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
