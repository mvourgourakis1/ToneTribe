// lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';
import '../data_models.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final User currentUser; // Pass the current user

  const PostDetailScreen({super.key, required this.post, required this.currentUser});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _currentPostData; // To allow updating votes and comments locally
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentPostData = widget.post; // Start with the passed post data

    // --- FIREBASE LISTENING FOR POST UPDATES & COMMENTS ---
    // In a real app, you might want to listen for real-time updates to this specific post
    // and its comments if they are fetched/updated separately.
    //
    // Example for post updates:
    // FirebaseFirestore.instance.collection('posts').doc(widget.post.id).snapshots().listen((snapshot) {
    //   if (snapshot.exists) {
    //     setState(() {
    //       _currentPostData = Post.fromFirestore(snapshot.data()!, snapshot.id);
    //       // You might need a more sophisticated way to merge comments if they are also live
    //     });
    //   }
    // });
    //
    // Example for comments (if comments are a subcollection):
    // FirebaseFirestore.instance
    //    .collection('posts').doc(widget.post.id).collection('comments')
    //    .orderBy('timestamp', descending: true) // Or however you order them
    //    .snapshots()
    //    .listen((snapshot) {
    //      final newComments = snapshot.docs.map((doc) => Comment.fromFirestore(doc.data(), doc.id)).toList();
    //      setState(() {
    //        _currentPostData.comments = newComments; // This assumes your Post model is mutable or you recreate it
    //      });
    // });
  }

  // --- METHOD PLACEHOLDER FOR REPLYING TO THE MAIN POST ---
  void _handleReplyToPost(String text) {
    if (text.trim().isEmpty) return;

    // This method would interact with your backend (e.g., Firebase)
    // to add a new comment to the post. It uses widget.currentUser.
    //
    // Example Firebase interaction (conceptual):
    //
    // String newCommentId = FirebaseFirestore.instance.collection('posts').doc(_currentPostData.id).collection('comments').doc().id;
    // Comment newComment = Comment(
    //   id: newCommentId,
    //   postId: _currentPostData.id,
    //   author: widget.currentUser.username, // Or widget.currentUser.id
    //   text: text,
    //   timestamp: DateTime.now(),
    //   // upvotes, downvotes, replies initialized
    // );
    //
    // FirebaseFirestore.instance
    //   .collection('posts').doc(_currentPostData.id)
    //   .collection('comments').doc(newCommentId)
    //   .set(newComment.toMap())
    //   .then((_) {
    //     print("Comment added successfully!");
    //     _replyController.clear();
    //     // Optionally, optimistically add to local list or rely on Firebase listener
    //   })
    //   .catchError((error) {
    //     print("Failed to add comment: $error");
    //     // Show error
    //   });

    // For now, add locally and show a snackbar
    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: _currentPostData.id,
      author: widget.currentUser.username,
      text: text,
      timestamp: DateTime.now(),
    );
    setState(() {
      _currentPostData.comments.insert(0, newComment); // Add to the beginning
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
    // to add a new reply to a specific comment. It uses widget.currentUser.
    // The 'parentComment' object helps identify where to add the reply.
    //
    // Storing nested replies in Firestore can be done in several ways:
    // 1. As a subcollection under the parent comment's document.
    // 2. As a list/array within the parent comment's document (less scalable for deep nesting).
    //
    // Example (conceptual, assuming replies are a list in the parent comment document):
    //
    // String newReplyId = FirebaseFirestore.instance.collection('posts').doc(_currentPostData.id)... .doc().id; // Path to new reply
    // Comment newReply = Comment(
    //   id: newReplyId,
    //   postId: _currentPostData.id,
    //   parentCommentId: parentComment.id,
    //   author: widget.currentUser.username,
    //   text: text,
    //   timestamp: DateTime.now(),
    // );
    //
    // // You'd need to fetch the parent comment, add the reply to its 'replies' list,
    // // and then update the parent comment document in Firebase.
    // // FirebaseFirestore.instance
    // //   .collection('posts').doc(_currentPostData.id)
    // //   .collection('comments').doc(parentComment.id)
    // //   .update({'replies': FieldValue.arrayUnion([newReply.toMap()])}) // Add to array
    // //   .then((_) { print("Reply added"); })
    // //   .catchError((error) { print("Failed to add reply: $error"); });

    // For now, add locally
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
      void _addReplyRecursively(List<Comment> comments, String parentId, Comment reply) {
          for (var comment in comments) {
              if (comment.id == parentId) {
                  comment.replies.insert(0, reply);
                  return;
              }
              _addReplyRecursively(comment.replies, parentId, reply);
          }
      }
      _addReplyRecursively(_currentPostData.comments, parentComment.id, newReply);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Replied to comment by ${widget.currentUser.username} (Locally added)')),
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (parentComment == null) {
                  _handleReplyToPost(dialogReplyController.text);
                } else {
                  _handleReplyToComment(parentComment, dialogReplyController.text);
                }
                Navigator.pop(context);
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
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, size: 20, color: post.downvotes > 0 ? Colors.blue : Colors.grey),
                onPressed: () {
                  // --- VOTE LIMITING COMMENT ---
                  // Similar to HomeScreen, check if widget.currentUser has already voted.
                  // Update Firebase accordingly.
                  setState(() {
                    _currentPostData.downvotes++; // Local update for responsiveness
                  });
                  // Potentially return updated post to HomeScreen via Navigator.pop(context, _currentPostData);
                },
              ),
              Text("${post.downvotes}"),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.arrow_upward, size: 20, color: post.upvotes > 0 ? Colors.red : Colors.grey),
                onPressed: () {
                  // --- VOTE LIMITING COMMENT ---
                  setState(() {
                    _currentPostData.upvotes++; // Local update
                  });
                },
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
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, top: 8.0, bottom: 0.0, right: 8.0), // Reduced left padding
      child: Card(
        elevation: depth == 0 ? 1 : 0,
        color: depth > 0 ? Theme.of(context).colorScheme.surface.withOpacity(0.5) : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: depth > 0 ? BorderSide(color: Colors.grey.shade300, width: 0.5) : BorderSide.none
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(10.0), // Reduced padding
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
                    onPressed: () {},
                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.arrow_downward, size: 16, color: comment.downvotes > 0 ? Colors.blue : Colors.grey),
                    onPressed: () {
                       // --- VOTE LIMITING COMMENT FOR COMMENTS ---
                       // Similar logic as post voting, but for comments.
                       // Store user votes for comments in Firebase, likely in a subcollection of the comment.
                       setState(() { comment.downvotes++; });
                    },
                     padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  ),
                   Text("${comment.downvotes}", style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.arrow_upward, size: 16, color: comment.upvotes > 0 ? Colors.red : Colors.grey),
                    onPressed: () {
                       // --- VOTE LIMITING COMMENT FOR COMMENTS ---
                      setState(() { comment.upvotes++; });
                    },
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
                  padding: const EdgeInsets.only(top: 0.0), // No extra top padding for replies list
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
        // Pass back the potentially updated post data when navigating back
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _currentPostData),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostContent(_currentPostData),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentPostData.comments.length,
                itemBuilder: (context, index) {
                  return _buildCommentItem(_currentPostData.comments[index]);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Helper for time ago formatting (same as before)
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