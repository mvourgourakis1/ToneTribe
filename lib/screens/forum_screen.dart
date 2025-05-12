import 'package:flutter/material.dart';
import '../data_models.dart';
import 'post_detail_screen.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  String _searchQuery = '';
  String? _selectedFilter;

  final List<String> _filters = [
    "All", "Rock", "Pop", "Classic Rock", "Most Upvoted", "Newest"
  ];

  // Get the current user (dummy data for now)
  final User _currentUser = sampleCurrentUser;

  // --- LOCAL VOTE TRACKING (SIMULATION) ---
  // In a real Firebase app, this information would be fetched alongside posts
  // or derived from a separate 'userVotes' collection.
  // Key: postId, Value: 'up' or 'down' or null if no vote
  final Map<String, String?> _userPostVotes = {};

  @override
  void initState() {
    super.initState();
    // For now, using sample data:
    _allPosts = List.from(samplePosts); // Make a mutable copy
    for (var post in _allPosts) { // Initialize vote status (simulating no prior votes)
      _userPostVotes[post.id] = null;
    }
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        final matchesSearch = post.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            post.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        
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
        // Default sort (e.g., by newest) if no specific sort filter is active
        // or if a tag filter is active, still sort by newest within that tag.
        _filteredPosts.sort((a,b) => b.timestamp.compareTo(a.timestamp));
      }
    });
  }

  void _handleCreateNewPost(String title, String content, List<String> tags) {
    // For demo, add locally:
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Use a more robust ID in real app
      title: title,
      content: content,
      author: _currentUser.username,
      timestamp: DateTime.now(),
      tags: tags,
    );
    setState(() {
      _allPosts.insert(0, newPost); // Add to the beginning
      _userPostVotes[newPost.id] = null; // Initialize vote status for the new post
      _applyFilters(); // Re-apply filters to show the new post
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created Post: "$title" by ${_currentUser.username}')),
    );
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

  // --- VOTING LOGIC FOR POSTS ---
  void _handlePostVote(Post post, String voteType) { // voteType: 'up' or 'down'
    setState(() {
      final currentVote = _userPostVotes[post.id];

      // Local simulation:
      if (currentVote == voteType) { // User is clicking the same vote type again (to undo)
        _userPostVotes[post.id] = null;
        if (voteType == 'up') {
          post.upvotes--;
        } else { // voteType == 'down'
          post.downvotes--;
        }
      } else { // New vote or changing vote
        // If there was a previous, different vote, undo its effect first
        if (currentVote == 'up') post.upvotes--;
        if (currentVote == 'down') post.downvotes--;

        _userPostVotes[post.id] = voteType; // Set the new vote
        if (voteType == 'up') {
          post.upvotes++;
        } else { // voteType == 'down'
          post.downvotes++;
        }
      }
      _applyFilters(); // Re-apply filters if sorting by votes, or just to refresh UI
    });
  }

  Widget _buildFilterPanel() {
    return Container(
      width: 180, // Fixed width for the filter panel
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
                      _applyFilters();
                    });
                    // If in a drawer, close it
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
    final String? userVote = _userPostVotes[post.id];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostDetailScreen(
              post: post,
              currentUser: _currentUser,
              initialUserPostVote: userVote, // Pass current vote status for this post
            )),
          ).then((resultFromDetailScreen) {
            // Result could be a map like {'postId': String, 'newUserVote': String?, 'newUpvotes': int, 'newDownvotes': int }
            if (resultFromDetailScreen != null && resultFromDetailScreen is Map<String, dynamic>) {
              final String postId = resultFromDetailScreen['postId'];
              final String? updatedUserVoteForPost = resultFromDetailScreen['newUserVote'];
              final int newUpvotes = resultFromDetailScreen['newUpvotes'];
              final int newDownvotes = resultFromDetailScreen['newDownvotes'];

              final int postIndex = _allPosts.indexWhere((p) => p.id == postId);
              if (postIndex != -1) {
                setState(() {
                  _userPostVotes[postId] = updatedUserVoteForPost;
                  _allPosts[postIndex].upvotes = newUpvotes;
                  _allPosts[postIndex].downvotes = newDownvotes;
                  _applyFilters(); // Re-filter/sort if necessary
                });
              }
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
                  IconButton(
                    icon: Icon(Icons.arrow_downward, size: 18,
                        color: userVote == 'down' ? Colors.blue : Colors.grey), // Reflect user's vote
                    tooltip: "Downvote (${post.downvotes})",
                    onPressed: () => _handlePostVote(post, 'down'),
                  ),
                  Text("${post.downvotes}", style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.arrow_upward, size: 18,
                        color: userVote == 'up' ? Colors.red : Colors.grey), // Reflect user's vote
                    tooltip: "Upvote (${post.upvotes})",
                    onPressed: () => _handlePostVote(post, 'up'),
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
            Builder( // Use Builder to get context for Scaffold.of for the drawer
              builder: (context) => IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: "Filters",
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Open drawer for filters
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
                hintText: 'Search Posts, Tags...',
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
                                ? 'No posts found matching your criteria.'
                                : 'No posts yet. Create one!',
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