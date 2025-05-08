// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import '../data_models.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final User currentUser;
  final String? initialUserPostVote; // Receive initial vote status for the main post

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
  late Post _currentPostData; // Local mutable copy of the post
  final TextEditingController _replyController = TextEditingController();

  // --- LOCAL VOTE TRACKING (SIMULATION) ---
  late String? _userVoteForThisPost; // User's vote for the main post being viewed
  // Key: commentId, Value: 'up' or 'down' or null
  final Map<String, String?> _userCommentVotes = {};

  @override
  void initState() {
    super.initState();
    // Deep copy the post to work on a local mutable version
    _currentPostData = Post(
      id: widget.post.id,
      title: widget.post.title,
      content: widget.post.content,
      author: widget.post.author,
      timestamp: widget.post.timestamp,
      upvotes: widget.post.upvotes,
      downvotes: widget.post.downvotes,
      tags: List.from(widget.post.tags), // Copy tags list
      comments: widget.post.comments.map((c) => _copyComment(c)).toList(), // Deep copy comments
    );

    _userVoteForThisPost = widget.initialUserPostVote;

    // --- FIREBASE LISTENING FOR POST UPDATES & COMMENTS ---
    // In a real app, you might want to listen for real-time updates to this specific post
    // and its comments if they are fetched/updated separately.
    //
    // Example for post updates:
    // FirebaseFirestore.instance.collection('posts').doc(widget.post.id).snapshots().listen((snapshot) {
    //   if (snapshot.exists && mounted) { // Check mounted
    //     setState(() {
    //       // Update _currentPostData carefully, especially comment merging if comments are also live
    //       _currentPostData = Post.fromFirestore(snapshot.data()!, snapshot.id);
    //     });
    //   }
    // });
    //
    // Example for comments (if comments are a subcollection):
    // FirebaseFirestore.instance
    //    .collection('posts').doc(widget.post.id).collection('comments')
    //    .orderBy('timestamp', descending: true)
    //    .snapshots()
    //    .listen((snapshot) {
    //      if (mounted) {
    //        final newComments = snapshot.docs.map((doc) => Comment.fromFirestore(doc.data(), doc.id)).toList();
    //        setState(() {
    //          _currentPostData.comments = newComments; // This assumes your Post model's comments list is mutable or you recreate it
    //          // Also re-initialize _userCommentVotes for these new/updated comments
    //          _userCommentVotes.clear();
    //          for (var comment in _currentPostData.comments) {
    //            _initializeCommentVotesRecursive(comment);
    //          }
    //        });
    //      }
    // });

    // Initialize local vote tracking for existing comments
    for (var comment in _currentPostData.comments) {
      _initializeCommentVotesRecursive(comment);
    }
  }

  // Helper to recursively initialize _userCommentVotes for comments and their replies
  void _initializeCommentVotesRecursive(Comment comment) {
    _userCommentVotes[comment.id] = null; // Assume no vote initially, or fetch from Firebase
    for (var reply in comment.replies) {
      _initializeCommentVotesRecursive(reply);
    }
  }

  // Helper for deep copying comments and their replies
  Comment _copyComment(Comment original) {
    return Comment(
      id: original.id,
      postId: original.postId,
      parentCommentId: original.parentCommentId,
      author: original.author,
      text: original.text,
      timestamp: original.timestamp,
      upvotes: original.upvotes,
      downvotes: original.downvotes,
      replies: original.replies.map((r) => _copyComment(r)).toList(),
    );
  }

  // --- VOTING LOGIC FOR THE MAIN POST ON THIS SCREEN ---
  void _handleMainPostVote(String voteType) { // voteType: 'up' or 'down'
    setState(() {
      final currentVote = _userVoteForThisPost;
      // --- FIREBASE: ATOMIC VOTE UPDATE FOR MAIN POST (Similar to HomeScreen) ---
      // This logic would mirror the Firebase transaction described in HomeScreen's _handlePostVote
      // but target _currentPostData and _userVoteForThisPost.

      // Local simulation:
      if (currentVote == voteType) { // Undoing vote
        _userVoteForThisPost = null;
        if (voteType == 'up') _currentPostData.upvotes--;
        else _currentPostData.downvotes--;
      } else { // New vote or changing vote
        if (currentVote == 'up') _currentPostData.upvotes--;
        if (currentVote == 'down') _currentPostData.downvotes--;

        _userVoteForThisPost = voteType;
        if (voteType == 'up') _currentPostData.upvotes++;
        else _currentPostData.downvotes++;
      }
    });
    // In a real app, this local change would trigger an update to Firebase.
    // The UI might then update based on a Firebase listener, or you'd confirm success.
  }

  // --- VOTING LOGIC FOR COMMENTS ---
  void _handleCommentVote(Comment comment, String voteType) {
    setState(() {
      // --- FIREBASE: ATOMIC VOTE UPDATE FOR COMMENT ---
      // Similar to post voting, this would involve a Firebase transaction to:
      // 1. Update the user's vote record for this specific comment.
      // 2. Atomically increment/decrement the comment's upvote/downvote count in Firestore.
      _updateCommentVoteRecursive(_currentPostData.comments, comment.id, voteType);
    });
  }

  // Recursive helper to find and update comment votes in the local state
  bool _updateCommentVoteRecursive(List<Comment> commentsList, String targetCommentId, String voteType) {
    for (var c in commentsList) {
      if (c.id == targetCommentId) {
        final currentVote = _userCommentVotes[c.id];
        if (currentVote == voteType) { // Undoing vote
          _userCommentVotes[c.id] = null;
          if (voteType == 'up') c.upvotes--; else c.downvotes--;
        } else { // New or changing vote
          if (currentVote == 'up') c.upvotes--;
          if (currentVote == 'down') c.downvotes--;
          _userCommentVotes[c.id] = voteType;
          if (voteType == 'up') c.upvotes++; else c.downvotes++;
        }
        return true; // Found and updated
      }
      if (c.replies.isNotEmpty) {
        if (_updateCommentVoteRecursive(c.replies, targetCommentId, voteType)) {
          return true; // Found in nested replies
        }
      }
    }
    return false; // Not found in this branch
  }

  // --- METHOD PLACEHOLDER FOR REPLYING TO THE MAIN POST ---
  void _handleReplyToPost(String text) {
    if (text.trim().isEmpty) return;

    // This method would interact with your backend (e.g., Firebase)
    // to add a new comment to the post. It uses widget.currentUser.
    // Example Firebase interaction (conceptual):
    // String newCommentId = FirebaseFirestore.instance.collection('posts').doc(_currentPostData.id).collection('comments').doc().id;
    // Comment newCommentData = Comment( /* ... data ... */ );
    // FirebaseFirestore.instance.collection('posts').doc(_currentPostData.id).collection('comments').doc(newCommentId).set(newCommentData.toMap())
    //   .then((_) { /* Success */ }).catchError((error) { /* Handle error */ });

    // For demo, add locally:
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: _currentPostData.id,
      author: widget.currentUser.username,
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _currentPostData.comments.insert(0, newComment); // Add to the beginning of the list
      _userCommentVotes[newComment.id] = null; // Initialize vote status for the new comment
    });
    _replyController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Replied to post by ${widget.currentUser.username} (Locally added)')),
    );
  }

  // --- METHOD PLACEHOLDER FOR REPLYING TO A SPECIFIC COMMENT ---
  void _handleReplyToComment(Comment parentComment, String text) {
     if (text.trim().isEmpty) return;
    // This method would interact with your backend (e.g., Firebase)
    // to add a new reply to a specific comment.
    // Storing nested replies in Firestore can be done via subcollections or arrays.
    // Example (conceptual, adding to a 'replies' array in parent comment):
    // Comment newReplyData = Comment( /* ... data ... */ );
    // FirebaseFirestore.instance.collection('posts').doc(_currentPostData.id)
    //   .collection('comments').doc(parentComment.id)
    //   .update({'replies': FieldValue.arrayUnion([newReplyData.toMap()])})
    //   .then((_) { /* Success */ }).catchError((error) { /* Handle error */ });

    // For demo, add locally:
    final newReply = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: _currentPostData.id,
      parentCommentId: parentComment.id,
      author: widget.currentUser.username,
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      // Find the parent comment and add the reply
      // This is a simplified local update; real updates might need more robust state management
      bool _addReplyRecursively(List<Comment> comments, String targetParentId, Comment replyToAdd) {
          for (var comment_ in comments) {
              if (comment_.id == targetParentId) {
                  comment_.replies.insert(0, replyToAdd); // Add to the beginning
                  _userCommentVotes[replyToAdd.id] = null; // Initialize vote status for the new reply
                  return true;
              }
              if (comment_.replies.isNotEmpty) {
                if(_addReplyRecursively(comment_.replies, targetParentId, replyToAdd)) return true;
              }
          }
          return false;
      }
      _addReplyRecursively(_currentPostData.comments, parentComment.id, newReply);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Replied to ${parentComment.author} by ${widget.currentUser.username} (Locally added)')),
    );
  }

  void _showReplyDialog({Comment? parentComment}) {
    final TextEditingController dialogReplyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(parentComment == null ? "Reply to Post" : "Reply to ${parentComment.author}"),
          content: TextField(
            controller: dialogReplyController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Write your reply..."),
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (value) { // Allow submitting with enter key
                 if (value.trim().isNotEmpty) {
                    if (parentComment == null) {
                        _handleReplyToPost(dialogReplyController.text);
                    } else {
                        _handleReplyToComment(parentComment, dialogReplyController.text);
                    }
                    Navigator.pop(context); // Close dialog after submitting
                 }
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final text = dialogReplyController.text;
                if (text.trim().isNotEmpty) {
                    if (parentComment == null) {
                    _handleReplyToPost(text);
                    } else {
                    _handleReplyToComment(parentComment, text);
                    }
                    Navigator.pop(context);
                } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Reply cannot be empty!"))
                    );
                }
              },
              child: const Text("Reply"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostContent(Post post) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text("by ${post.author} - ${TimeAgo.timeAgoSinceDate(post.timestamp)}",
              style: Theme.of(context).textTheme.bodySmall),
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: post.tags.map((tag) => Chip(
                  label: Text(tag),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  backgroundColor: Colors.grey.shade200,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.question_mark, size: 20),
                tooltip: "Info/Options",
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, size: 20,
                    color: _userVoteForThisPost == 'down' ? Colors.blue : Colors.grey),
                tooltip: "Downvote (${post.downvotes})",
                onPressed: () => _handleMainPostVote('down'),
              ),
              Text("${post.downvotes}"),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.arrow_upward, size: 20,
                    color: _userVoteForThisPost == 'up' ? Colors.red : Colors.grey),
                tooltip: "Upvote (${post.upvotes})",
                onPressed: () => _handleMainPostVote('up'),
              ),
              Text("${post.upvotes}"),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.reply_outlined),
                label: const Text("Reply to Post"),
                onPressed: () => _showReplyDialog(),
              )
            ],
          ),
          const Divider(height: 30),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, {int depth = 0}) {
    final String? userVote = _userCommentVotes[comment.id];
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 8.0, bottom: 0.0, right: 8.0),
      child: Card(
        elevation: depth == 0 ? 1 : 0,
        color: depth > 0 ? Theme.of(context).colorScheme.surface.withOpacity(0.5) : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: depth > 0 ? BorderSide(color: Colors.grey.shade300, width: 0.5) : BorderSide.none
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.author,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "• ${TimeAgo.timeAgoSinceDate(comment.timestamp)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(comment.text, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.question_mark, size: 16),
                    tooltip: "Info/Options",
                    onPressed: () {},
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.arrow_downward, size: 16,
                        color: userVote == 'down' ? Colors.blue : Colors.grey),
                    tooltip: "Downvote (${comment.downvotes})",
                    onPressed: () => _handleCommentVote(comment, 'down'),
                     padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                   Text("${comment.downvotes}", style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.arrow_upward, size: 16,
                        color: userVote == 'up' ? Colors.red : Colors.grey),
                    tooltip: "Upvote (${comment.upvotes})",
                    onPressed: () => _handleCommentVote(comment, 'up'),
                     padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  Text("${comment.upvotes}", style: const TextStyle(fontSize: 10)),
                  const Spacer(),
                  TextButton(
                    child: const Text("Reply", style: TextStyle(fontSize: 12)),
                    onPressed: () => _showReplyDialog(parentComment: comment),
                     style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: Size.zero),
                  )
                ],
              ),
              if (comment.replies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: comment.replies.map((reply) => _buildCommentItem(reply, depth: depth + 1)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPostData.title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Pass back the updated post data AND the user's vote for THIS post
            Navigator.pop(context, {
              'postId': _currentPostData.id,
              'newUserVote': _userVoteForThisPost, // The user's vote for the main post
              'newUpvotes': _currentPostData.upvotes, // Total upvotes for the main post
              'newDownvotes': _currentPostData.downvotes, // Total downvotes for the main post
              // For simplicity, not passing back individual comment updates or full comment list.
              // HomeScreen would typically re-fetch or rely on listeners for detailed comment changes.
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostContent(_currentPostData),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Replies (${_currentPostData.comments.length})",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_currentPostData.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: Text("No replies yet. Be the first!"))
              )
            else
              ListView.builder(
                shrinkWrap: true, // Important for ListView inside SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling for this ListView
                itemCount: _currentPostData.comments.length,
                itemBuilder: (context, index) {
                  return _buildCommentItem(_currentPostData.comments[index]);
                },
              ),
            const SizedBox(height: 20), // Some spacing at the bottom
          ],
        ),
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