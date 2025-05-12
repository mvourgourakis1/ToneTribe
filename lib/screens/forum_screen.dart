import 'package:flutter/material.dart';
import '../data_models.dart' show User, Post, Comment;
import 'post_detail_screen.dart';
import '../services/forum_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  final AuthService _authService = AuthService();
  String _searchQuery = '';
  String? _selectedFilter;

  final List<String> _filters = [
    "All", "Rock", "Pop", "Classic Rock", "Most Upvoted", "Newest"
  ];

  void _handleCreateNewPost(String title, String content, List<String> tags) async {
    try {
      await _forumService.createPost(title, content, tags);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: ${e.toString()}')),
        );
      }
    }
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Post"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                TextField(controller: contentController, decoration: const InputDecoration(labelText: "Content"), maxLines: 3,),
                TextField(controller: tagsController, decoration: const InputDecoration(labelText: "Tags (comma-separated)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text;
                final content = contentController.text;
                final tags = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                if (title.isNotEmpty && content.isNotEmpty) {
                  _handleCreateNewPost(title, content, tags);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Title and Content cannot be empty!"))
                  );
                }
              },
              child: const Text("Post"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Filters", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return ListTile(
                  title: Text(filter),
                  dense: true,
                  selected: _selectedFilter == filter,
                  selectedTileColor: Colors.red.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    if (Scaffold.of(context).isEndDrawerOpen) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, Post post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostDetailScreen(
              post: post,
              currentUser: User(
                id: _authService.currentUser!.uid,
                username: _authService.currentUser!.displayName ?? 'Anonymous',
              ),
            )),
          ).then((result) {
            if (result != null) {
              // Update the post's votes in the list
              setState(() {
                post.upvotes = result['newUpvotes'];
                post.downvotes = result['newDownvotes'];
              });
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: Theme.of(context).textTheme.titleLarge),
              if (post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                  child: Wrap(
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children: post.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 10)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      backgroundColor: Colors.grey.shade200,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.question_mark, size: 18),
                    tooltip: "Info/Options",
                    onPressed: () { /* Handle '?' action */ },
                  ),
                  StreamBuilder<String?>(
                    stream: _forumService.getUserPostVote(post.id).asStream(),
                    builder: (context, snapshot) {
                      final userVote = snapshot.data;
                      return Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_downward, size: 18,
                                color: userVote == 'down' ? Colors.blue : Colors.grey),
                            tooltip: "Downvote (${post.downvotes})",
                            onPressed: () async {
                              await _forumService.voteOnPost(post.id, 'down');
                              // The post's votes will be updated through the stream
                            },
                          ),
                          StreamBuilder<DocumentSnapshot>(
                            stream: _forumService.firestore.collection('posts').doc(post.id).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Text("0");
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              return Text("${data?['downvotes'] ?? 0}", style: const TextStyle(fontSize: 12));
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.arrow_upward, size: 18,
                                color: userVote == 'up' ? Colors.red : Colors.grey),
                            tooltip: "Upvote (${post.upvotes})",
                            onPressed: () async {
                              await _forumService.voteOnPost(post.id, 'up');
                              // The post's votes will be updated through the stream
                            },
                          ),
                          StreamBuilder<DocumentSnapshot>(
                            stream: _forumService.firestore.collection('posts').doc(post.id).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Text("0");
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              return Text("${data?['upvotes'] ?? 0}", style: const TextStyle(fontSize: 12));
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  StreamBuilder<QuerySnapshot>(
                    stream: _forumService.firestore
                        .collection('posts')
                        .doc(post.id)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("0");
                      return Row(
                        children: [
                          const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("${snapshot.data!.docs.length}", style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Forums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Create Post",
            onPressed: _showCreatePostDialog,
          ),
          if (!isWideScreen)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: "Filters",
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              ),
            ),
        ],
      ),
      endDrawer: !isWideScreen ? Drawer(child: _buildFilterPanel()) : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Posts, Tags...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWideScreen) _buildFilterPanel(),
                Expanded(
                  child: StreamBuilder<List<Post>>(
                    stream: _forumService.getPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var posts = snapshot.data!;

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        posts = posts.where((post) {
                          return post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                 post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                 post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
                        }).toList();
                      }

                      // Apply tag filter
                      if (_selectedFilter != null && _selectedFilter != "All") {
                        if (_selectedFilter == "Most Upvoted") {
                          posts.sort((a, b) => b.upvotes.compareTo(a.upvotes));
                        } else if (_selectedFilter == "Newest") {
                          posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                        } else {
                          posts = posts.where((post) =>
                            post.tags.any((tag) => tag.toLowerCase() == _selectedFilter!.toLowerCase())
                          ).toList();
                        }
                      }

                      if (posts.isEmpty) {
                        return Center(
                          child: Text(
                            _searchQuery.isNotEmpty || (_selectedFilter != null && _selectedFilter != "All")
                                ? 'No posts found matching your criteria.'
                                : 'No posts yet. Create one!',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          return _buildPostItem(context, posts[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 