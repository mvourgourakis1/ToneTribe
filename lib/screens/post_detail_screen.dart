// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import '../data_models.dart';
import '../services/forum_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final User currentUser;
  final String? initialUserPostVote;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUser,
    this.initialUserPostVote,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  late String? _userPostVote;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  Comment? _replyingTo;
  final ForumService _forumService = ForumService();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _userPostVote = widget.initialUserPostVote;
  }

  void _handlePostVote(String voteType) async {
    await _forumService.voteOnPost(_post.id, voteType);
    // The post's votes will be updated through the stream
  }

  void _handleCommentVote(Comment comment, String voteType) async {
    await _forumService.voteOnComment(_post.id, comment.id, voteType);
    // The comment's votes will be updated through the stream
  }

  void _addComment(String content, {Comment? parentComment}) async {
    try {
      await _forumService.addComment(_post.id, content, parentCommentId: parentComment?.id);
      _commentController.clear();
      _replyController.clear();
      _replyingTo = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: ${e.toString()}')),
        );
      }
    }
  }

  void _showReplyDialog(Comment comment) {
    _replyingTo = comment;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reply to ${comment.author}'),
          content: TextField(
            controller: _replyController,
            decoration: const InputDecoration(
              labelText: 'Your reply',
              hintText: 'Write your reply here...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _replyingTo = null;
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_replyController.text.isNotEmpty) {
                  _addComment(_replyController.text, parentComment: comment);
                  Navigator.pop(context);
                }
              },
              child: const Text('Reply'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComment(Comment comment, {int depth = 0}) {
    return Card(
      color: Colors.black.withOpacity(0.2),
      margin: EdgeInsets.only(
        left: depth * 16.0,
        right: 8.0,
        top: 8.0,
        bottom: 8.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  comment.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(comment.timestamp),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content),
            const SizedBox(height: 8),
            Row(
              children: [
                StreamBuilder<String?>(
                  stream: _forumService.getUserCommentVote(_post.id, comment.id).asStream(),
                  builder: (context, snapshot) {
                    final userVote = snapshot.data;
                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_downward,
                            size: 18,
                            color: userVote == 'down' ? Colors.blue : Colors.grey,
                          ),
                          onPressed: () => _handleCommentVote(comment, 'down'),
                        ),
                        Text('${comment.downvotes}'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: userVote == 'up' ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _handleCommentVote(comment, 'up'),
                        ),
                        Text('${comment.upvotes}'),
                      ],
                    );
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Reply'),
                  onPressed: () => _showReplyDialog(comment),
                ),
              ],
            ),
          ],
        ),
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
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade700, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: _forumService.firestore.collection('posts').doc(_post.id).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  if (data == null) return const SizedBox.shrink();

                  final upvotes = data['upvotes'] ?? 0;
                  final downvotes = data['downvotes'] ?? 0;

                  return Card(
                    color: Colors.black.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.withOpacity(0.4), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          if (_post.tags.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: _post.tags.map((tag) => Chip(
                                label: Text(tag, style: TextStyle(color: Colors.white.withOpacity(0.9))),
                                backgroundColor: Colors.orange.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                              )).toList(),
                            ),
                          const SizedBox(height: 16),
                          Text(_post.content),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Posted by ${_post.author}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimestamp(_post.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              StreamBuilder<String?>(
                                stream: _forumService.getUserPostVote(_post.id).asStream(),
                                builder: (context, snapshot) {
                                  final userVote = snapshot.data;
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_downward,
                                          color: userVote == 'down' ? Colors.blue : Colors.grey,
                                        ),
                                        onPressed: () => _handlePostVote('down'),
                                      ),
                                      Text('$downvotes'),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.arrow_upward,
                                          color: userVote == 'up' ? Colors.red : Colors.grey,
                                        ),
                                        onPressed: () => _handlePostVote('up'),
                                      ),
                                      Text('$upvotes'),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Comments section
              Text(
                'Comments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              // Comment input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        _addComment(_commentController.text);
                      }
                    },
                    child: const Text('Post'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Comments list
              StreamBuilder<QuerySnapshot>(
                stream: _forumService.firestore
                    .collection('posts')
                    .doc(_post.id)
                    .collection('comments')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Group comments by parentCommentId
                  final comments = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Comment(
                      id: doc.id,
                      postId: _post.id,
                      parentCommentId: data['parentCommentId'],
                      author: data['author'] ?? 'Anonymous',
                      content: data['content'] ?? '',
                      timestamp: (data['timestamp'] as Timestamp).toDate(),
                      upvotes: data['upvotes'] ?? 0,
                      downvotes: data['downvotes'] ?? 0,
                    );
                  }).toList();

                  // Build comment tree
                  final commentMap = <String, List<Comment>>{};
                  final rootComments = <Comment>[];

                  for (final comment in comments) {
                    if (comment.parentCommentId == null) {
                      rootComments.add(comment);
                    } else {
                      commentMap.putIfAbsent(comment.parentCommentId!, () => []).add(comment);
                    }
                  }

                  Widget buildCommentTree(Comment comment, {int depth = 0}) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildComment(comment, depth: depth),
                        if (commentMap.containsKey(comment.id))
                          ...commentMap[comment.id]!.map((reply) => buildCommentTree(reply, depth: depth + 1)),
                      ],
                    );
                  }

                  return Column(
                    children: rootComments.map((comment) => buildCommentTree(comment)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper for time ago formatting (you might want a package like `