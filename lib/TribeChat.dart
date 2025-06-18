import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/message.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'models/tribe_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TribeChat extends StatefulWidget {
  final Tribe tribe;

  const TribeChat({super.key, required this.tribe});

  @override
  State<TribeChat> createState() => _TribeChatState();
}

class _TribeChatState extends State<TribeChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  Message? _replyingTo;
  int? _hoveredMessageIndex;
  bool _isLoading = true;
  String? _error;
  Channel? _selectedChannel;
  final TextEditingController _newChannelNameController = TextEditingController();
  final TextEditingController _newChannelDescriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkTribeMembership();
  }

  Future<void> _checkTribeMembership() async {
    try {
      final isMember = await _chatService.isUserInTribe(widget.tribe.id);
      setState(() {
        _isLoading = false;
        if (!isMember) {
          _error = 'You are not a member of this tribe';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error checking tribe membership: $e';
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _selectedChannel == null) return;

    _chatService.sendChannelMessage(
      tribeId: widget.tribe.id,
      channelId: _selectedChannel!.id,
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

  Future<void> _createNewChannel() async {
    if (_newChannelNameController.text.trim().isEmpty) return;

    try {
      final channel = await _chatService.createChannel(
        tribeId: widget.tribe.id,
        name: _newChannelNameController.text.trim(),
        description: _newChannelDescriptionController.text.trim().isEmpty
            ? null
            : _newChannelDescriptionController.text.trim(),
      );

      setState(() {
        _selectedChannel = channel;
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

  void _showCreateChannelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline),
            const SizedBox(width: 8),
            const Text('Create New Channel'),
          ],
        ),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _newChannelNameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                  hintText: 'e.g., general, announcements, music',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a channel name';
                  }
                  if (value.trim().length < 3) {
                    return 'Channel name must be at least 3 characters';
                  }
                  if (value.trim().length > 30) {
                    return 'Channel name must be less than 30 characters';
                  }
                  return null;
                },
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newChannelDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What is this channel for?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (_newChannelNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a channel name'),
                  ),
                );
                return;
              }
              _createNewChannel();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Channel'),
          ),
        ],
      ),
    );
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
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _deleteMessage(message),
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            IconButton(
              icon: const Icon(Icons.flag, size: 20),
              onPressed: () => _reportMessage(message),
              tooltip: 'Report',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    if (_selectedChannel == null) return;
    try {
      await _chatService.deleteChannelMessage(
        widget.tribe.id,
        _selectedChannel!.id,
        message.id,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  Future<void> _reportMessage(Message message) async {
    if (_selectedChannel == null) return;
    try {
      await _chatService.reportChannelMessage(
        widget.tribe.id,
        _selectedChannel!.id,
        message.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message reported')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reporting message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tribe.tribeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateChannelDialog,
            tooltip: 'Create Channel',
          ),
        ],
      ),
      body: Row(
        children: [
          // Channel list
          Container(
            width: 240,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              children: [
                // Channel list header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Channels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _showCreateChannelDialog,
                        tooltip: 'Create Channel',
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                // Channel list
                Expanded(
                  child: StreamBuilder<List<Channel>>(
                    stream: _chatService.getTribeChannels(widget.tribe.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final channels = snapshot.data!;

                      if (channels.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No channels yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _showCreateChannelDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Create Channel'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: channels.length,
                        itemBuilder: (context, index) {
                          final channel = channels[index];
                          final isSelected = _selectedChannel?.id == channel.id;
                          
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            leading: Icon(
                              Icons.tag,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                            title: Text(
                              channel.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: channel.description != null
                                ? Text(
                                    channel.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.grey,
                                    ),
                                  )
                                : null,
                            trailing: StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('tribes')
                                  .doc(widget.tribe.id)
                                  .collection('channels')
                                  .doc(channel.id)
                                  .collection('members')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final memberCount = snapshot.hasData ? snapshot.data!.size : 0;
                                return Text(
                                  '$memberCount',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              setState(() {
                                _selectedChannel = channel;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Chat area
          Expanded(
            child: _selectedChannel == null
                ? const Center(
                    child: Text('Select a channel to start chatting'),
                  )
                : Column(
                    children: [
                      // Channel header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tag),
                            const SizedBox(width: 8),
                            Text(
                              _selectedChannel!.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (_selectedChannel!.description != null) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedChannel!.description!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Messages
                      Expanded(
                        child: StreamBuilder<List<Message>>(
                          stream: _chatService.getChannelMessages(
                            widget.tribe.id,
                            _selectedChannel!.id,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final messages = snapshot.data!;

                            if (messages.isEmpty) {
                              return const Center(
                                child: Text(
                                    'No messages yet. Start the conversation!'),
                              );
                            }

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _hoveredMessageIndex = index),
                                  onExit: (_) =>
                                      setState(() => _hoveredMessageIndex = null),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (message.replyTo != null) ...[
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Replying to ${message.replyTo!.username}: ${message.replyTo!.content}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              backgroundImage: NetworkImage(
                                                  message.profileImageUrl),
                                              radius: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        message.username,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        _formatTimestamp(
                                                            message.timestamp),
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(message.content),
                                                ],
                                              ),
                                            ),
                                            _buildMessageActions(
                                                message, index),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      // Reply preview
                      if (_replyingTo != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Replying to ${_replyingTo!.username}: ${_replyingTo!.content}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _cancelReply,
                              ),
                            ],
                          ),
                        ),
                      // Message input
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: RawKeyboardListener(
                                focusNode: FocusNode(),
                                onKey: (RawKeyEvent event) {
                                  if (event is RawKeyDownEvent) {
                                    if (event.logicalKey == LogicalKeyboardKey.enter) {
                                      if (event.isShiftPressed) {
                                        // Insert new line
                                        final text = _messageController.text;
                                        final selection = _messageController.selection;
                                        final newText = text.replaceRange(
                                          selection.start,
                                          selection.end,
                                          '\n',
                                        );
                                        _messageController.value = TextEditingValue(
                                          text: newText,
                                          selection: TextSelection.collapsed(
                                            offset: selection.start + 1,
                                          ),
                                        );
                                      } else {
                                        // Send message
                                        if (_messageController.text.trim().isNotEmpty) {
                                          _sendMessage();
                                        }
                                      }
                                    }
                                  }
                                },
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message... (Enter to send, Shift+Enter for new line)',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: null,
                                  textInputAction: TextInputAction.send,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization: TextCapitalization.sentences,
                                  onEditingComplete: () {
                                    if (_messageController.text.trim().isNotEmpty) {
                                      _sendMessage();
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _newChannelNameController.dispose();
    _newChannelDescriptionController.dispose();
    super.dispose();
  }
}
