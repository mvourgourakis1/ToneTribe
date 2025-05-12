// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import '../data_models.dart';

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

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _userPostVote = widget.initialUserPostVote;
  }

  void _handlePostVote(String voteType) {
    setState(() {
      if (_userPostVote == voteType) { // User is clicking the same vote type again (to undo)
        _userPostVote = null;
        if (voteType == 'up') {
          _post.upvotes--;
        } else { // voteType == 'down'
          _post.downvotes--;
        }
      } else { // New vote or changing vote
        // If there was a previous, different vote, undo its effect first
        if (_userPostVote == 'up') _post.upvotes--;
        if (_userPostVote == 'down') _post.downvotes--;

        _userPostVote = voteType; // Set the new vote
        if (voteType == 'up') {
          _post.upvotes++;
        } else { // voteType == 'down'
          _post.downvotes++;
        }
      }
    });

    // Notify parent screen of vote changes
    Navigator.pop(context, {
      'postId': _post.id,
      'newUserVote': _userPostVote,
      'newUpvotes': _post.upvotes,
      'newDownvotes': _post.downvotes,
    });
  }

  void _handleCommentVote(Comment comment, String voteType) {
    setState(() {
      if (comment.userVote == voteType) { // User is clicking the same vote type again (to undo)
        comment.userVote = null;
        if (voteType == 'up') {
          comment.upvotes--;
        } else { // voteType == 'down'
          comment.downvotes--;
        }
      } else { // New vote or changing vote
        // If there was a previous, different vote, undo its effect first
        if (comment.userVote == 'up') comment.upvotes--;
        if (comment.userVote == 'down') comment.downvotes--;

        comment.userVote = voteType; // Set the new vote
        if (voteType == 'up') {
          comment.upvotes++;
        } else { // voteType == 'down'
          comment.downvotes++;
        }
      }
    });
  }

  void _addComment(String content, {Comment? parentComment}) {
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: _post.id,
      parentCommentId: parentComment?.id,
      content: content,
      author: widget.currentUser.username,
      timestamp: DateTime.now(),
      upvotes: 0,
      downvotes: 0,
      userVote: null,
      replies: [],
    );

    setState(() {
      if (parentComment != null) {
        parentComment.replies.add(newComment);
      } else {
        _post.comments.add(newComment);
      }
    });

    _commentController.clear();
    _replyController.clear();
    _replyingTo = null;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.only(
            left: depth * 16.0,
            right: 8.0,
            top: 8.0,
            bottom: 8.0,
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
                        color: Colors.grey[600],
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
                    IconButton(
                      icon: Icon(
                        Icons.arrow_downward,
                        size: 18,
                        color: comment.userVote == 'down' ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => _handleCommentVote(comment, 'down'),
                    ),
                    Text('${comment.downvotes}'),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: comment.userVote == 'up' ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _handleCommentVote(comment, 'up'),
                    ),
                    Text('${comment.upvotes}'),
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
        ),
        if (comment.replies.isNotEmpty)
          ...comment.replies.map((reply) => _buildComment(reply, depth: depth + 1)),
      ],
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
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Post content
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _post.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (_post.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 6.0,
                              runSpacing: 4.0,
                              children: _post.tags.map((tag) => Chip(
                                label: Text(tag),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                backgroundColor: Colors.grey.shade200,
                              )).toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(_post.content),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Posted by ${_post.author}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(_post.timestamp),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.arrow_downward,
                                color: _userPostVote == 'down' ? Colors.blue : Colors.grey,
                              ),
                              onPressed: () => _handlePostVote('down'),
                            ),
                            Text('${_post.downvotes}'),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.arrow_upward,
                                color: _userPostVote == 'up' ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => _handlePostVote('up'),
                            ),
                            Text('${_post.upvotes}'),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                ..._post.comments.map((comment) => _buildComment(comment)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper for time ago formatting (you might want a package like `timeago` for more features)
class TimeAgo {
  static String timeAgoSinceDate(DateTime date, {bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(date);

    if (difference.inSeconds < 5) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    }
    return '${(difference.inDays / 365).floor()} years ago';
  }
}