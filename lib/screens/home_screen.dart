// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../data_models.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  String _searchQuery = '';
  String? _selectedFilter;

  // Updated filters to include tags
  final List<String> _filters = [
    "All",
    "Rock", // Tag
    "Pop",  // Tag
    "Classic Rock", // Tag
    "Most Upvoted",
    "Newest"
  ];

  // Get the current user (dummy data for now)
  final User _currentUser = sampleCurrentUser;

  @override
  void initState() {
    super.initState();
    // --- FIREBASE FETCHING COMMENT ---
    // In a real app, you would fetch posts from Firebase here.
    // Example:
    // FirebaseFirestore.instance.collection('posts').snapshots().listen((snapshot) {
    //   setState(() {
    //     _allPosts = snapshot.docs.map((doc) => Post.fromFirestore(doc.data(), doc.id)).toList();
    //     _applyFilters();
    //   });
    // }).onError((error) {
    //   // Handle error
    //   print("Error fetching posts: $error");
    // });
    // For now, using sample data:
    _allPosts = List.from(samplePosts);
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        final matchesSearch = post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              post.content.toLowerCase().contains(_searchQuery.toLowerCase());
        
        bool matchesFilter = true;
        if (_selectedFilter != null && _selectedFilter != "All") {
          // Check if the selected filter is one of the special sort types
          if (_selectedFilter == "Most Upvoted" || _selectedFilter == "Newest") {
            matchesFilter = true; // Sorting is handled separately
          } else {
            // Assume other filters are tags
            matchesFilter = post.tags.any((tag) => tag.toLowerCase() == _selectedFilter!.toLowerCase());
          }
        }
        return matchesSearch && matchesFilter;
      }).toList();

      // Sorting based on filter
      if (_selectedFilter == "Most Upvoted") {
        _filteredPosts.sort((a, b) => b.upvotes.compareTo(a.upvotes));
      } else if (_selectedFilter == "Newest") {
         _filteredPosts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        // Default sort or sort by relevance if search is active (not implemented here)
        _filteredPosts.sort((a,b) => b.timestamp.compareTo(a.timestamp)); // Default to newest if no specific sort
      }
    });
  }

  // --- METHOD PLACEHOLDER FOR CREATING A NEW POST ---
  void _handleCreateNewPost(String title, String content, List<String> tags) {
    // This method would interact with your backend (e.g., Firebase)
    // to create a new post. It would use the _currentUser data.
    //
    // Example Firebase interaction (conceptual):
    //
    // String newPostId = FirebaseFirestore.instance.collection('posts').doc().id;
    // Post newPost = Post(
    //   id: newPostId,
    //   title: title,
    //   content: content,
    //   author: _currentUser.username, // Or _currentUser.id
    //   timestamp: DateTime.now(),
    //   tags: tags,
    //   // upvotes, downvotes, comments initialized to 0 or empty
    // );
    //
    // FirebaseFirestore.instance.collection('posts').doc(newPostId).set(newPost.toMap())
    //   .then((_) {
    //     print("Post created successfully!");
    //     // Optionally refresh posts or add to local list optimistically
    //     // _fetchPosts(); // Or add newPost to _allPosts and call _applyFilters()
    //   })
    //   .catchError((error) {
    //     print("Failed to create post: $error");
    //     // Show error to user
    //   });

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Create New Post: "$title" by ${_currentUser.username} (Not implemented yet)')),
    );
    // In a real app, you'd likely navigate away or refresh the list.
    // For this demo, let's add it to the local list.
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      author: _currentUser.username,
      timestamp: DateTime.now(),
      tags: tags,
    );
    setState(() {
      _allPosts.insert(0, newPost); // Add to the beginning
      _applyFilters(); // Re-apply filters to show the new post
    });
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController(); // For comma-separated tags

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
                  // Show error if fields are empty
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
                  selected: _selectedFilter == filter,
                  dense: true,
                  selectedTileColor: Colors.red.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                      _applyFilters();
                    });
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
            MaterialPageRoute(builder: (context) => PostDetailScreen(post: post, currentUser: _currentUser)),
          ).then((updatedPost) {
            // If PostDetailScreen returns an updated post (e.g., after a vote), update it here
            if (updatedPost != null && updatedPost is Post) {
              setState(() {
                final index = _allPosts.indexWhere((p) => p.id == updatedPost.id);
                if (index != -1) {
                  _allPosts[index] = updatedPost;
                  _applyFilters();
                }
              });
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                    onPressed: () { /* Handle '?' action */ },
                    tooltip: "Info/Options",
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_downward, size: 18, color: post.downvotes > 0 ? Colors.blue : Colors.grey),
                    onPressed: () {
                      // --- VOTE LIMITING COMMENT ---
                      // In a real app, you'd check if _currentUser has already downvoted this post.
                      // This typically involves:
                      // 1. A subcollection on the 'posts' document in Firebase, e.g., 'userVotes' or 'downvotes'.
                      // 2. Storing a document with _currentUser.id if they vote.
                      // 3. If they vote again, you might remove their upvote if it exists, or just disallow the second downvote.
                      // 4. Update the post's downvote count in Firebase atomically.
                      // Example:
                      // if (await hasUserAlreadyVoted(post.id, _currentUser.id, 'downvote')) {
                      //   removeUserVote(post.id, _currentUser.id, 'downvote');
                      //   decrementDownvoteCount(post.id);
                      // } else {
                      //   if (await hasUserAlreadyVoted(post.id, _currentUser.id, 'upvote')) {
                      //      removeUserVote(post.id, _currentUser.id, 'upvote');
                      //      decrementUpvoteCount(post.id);
                      //   }
                      //   addUserVote(post.id, _currentUser.id, 'downvote');
                      //   incrementDownvoteCount(post.id);
                      // }
                      setState(() {
                        post.downvotes++;
                        _applyFilters();
                      });
                    },
                     tooltip: "Downvote (${post.downvotes})",
                  ),
                  Text("${post.downvotes}", style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.arrow_upward, size: 18, color: post.upvotes > 0 ? Colors.red : Colors.grey),
                    onPressed: () {
                      // --- VOTE LIMITING COMMENT (similar to downvote) ---
                      // Check if _currentUser has already upvoted.
                      // Manage removing downvote if it exists.
                      // Update upvote count in Firebase.
                      setState(() {
                        post.upvotes++;
                        _applyFilters();
                      });
                    },
                    tooltip: "Upvote (${post.upvotes})",
                  ),
                  Text("${post.upvotes}", style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  const Icon(Icons.comment_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("${post.comments.length}", style: const TextStyle(fontSize: 12)),
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
    bool isWideScreen = MediaQuery.of(context).size.width > 700; // Adjusted for better layout

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reddit for Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: "Create Post",
            onPressed: _showCreatePostDialog,
          ),
          if (!isWideScreen)
            Builder( // Use Builder to get context for Scaffold.of
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
      endDrawer: !isWideScreen ? Drawer(child: _buildFilterPanel()) : null, // Use endDrawer for filters on mobile
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Songs, Artists, Tags...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWideScreen) _buildFilterPanel(),
                Expanded(
                  child: _filteredPosts.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isNotEmpty || (_selectedFilter != null && _selectedFilter != "All")
                                ? 'No songs found matching your criteria.'
                                : 'No songs yet. Create one!',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) {
                            return _buildPostItem(context, _filteredPosts[index]);
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