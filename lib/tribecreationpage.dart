import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Remove redundant Firebase import
import 'firebase_options.dart';

class CreateMusicTribePage extends StatefulWidget {
  const CreateMusicTribePage({super.key});

  @override
  _CreateMusicTribePageState createState() => _CreateMusicTribePageState();
}

class _CreateMusicTribePageState extends State<CreateMusicTribePage> {
  final _formKey = GlobalKey<FormState>();
  final _tribeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _musicFocusController = TextEditingController();
  String? _selectedPrivacy;
  List<String> _selectedGenres = [];
  final List<String> _availableGenres = [
    'Rock',
    'Pop',
    'Hip Hop',
    'Electronic',
    'Country',
    'Jazz',
    'Classical',
    'Blues',
    'Reggae',
    'Folk',
    'Indie',
    'Metal',
    'Punk',
    'R&B',
    'Soul',
  ];

  late final FirebaseFirestore _firestore;
  // Replace with actual user ID, e.g., FirebaseAuth.instance.currentUser?.uid
  final String _currentUserId = 'user123'; // Placeholder for testing

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  @override
  void dispose() {
    _tribeNameController.dispose();
    _descriptionController.dispose();
    _musicFocusController.dispose();
    super.dispose();
  }

  Future<void> _saveTribeToFirestore() async {
    try {
      await _firestore.collection('tribes').add({
        'tribeName': _tribeNameController.text,
        'description': _descriptionController.text,
        'musicFocus': _musicFocusController.text,
        'genres': _selectedGenres,
        'privacy': _selectedPrivacy,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [_currentUserId], // Add creator as initial member
      });
      print('Tribe created with creator: $_currentUserId'); // Debug log
    } catch (e) {
      print('Error saving to Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create tribe: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a Music Tribe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _tribeNameController,
                decoration: const InputDecoration(
                  labelText: 'Tribe Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a tribe name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Brief Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a brief description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _musicFocusController,
                decoration: const InputDecoration(
                  labelText: 'Specific Music Focus (Optional)',
                  hintText: 'e.g., 90s Grunge, Progressive Metal, Lo-fi Hip Hop',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20.0),
              Text('Genres:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: _availableGenres.map((genre) {
                  return FilterChip(
                    label: Text(genre),
                    selected: _selectedGenres.contains(genre),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20.0),
              Text('Privacy:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              RadioListTile<String>(
                title: const Text('Public'),
                value: 'public',
                groupValue: _selectedPrivacy,
                onChanged: (String? value) {
                  setState(() {
                    _selectedPrivacy = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Private'),
                value: 'private',
                groupValue: _selectedPrivacy,
                onChanged: (String? value) {
                  setState(() {
                    _selectedPrivacy = value;
                  });
                },
              ),
              if (_selectedPrivacy == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select the privacy setting',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 30.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _selectedPrivacy != null) {
                    await _saveTribeToFirestore();
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Music Tribe Created!'),
                            content: Text('Your music tribe "${_tribeNameController.text}" has been created.'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  }
                },
                child: const Text('Create Music Tribe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}