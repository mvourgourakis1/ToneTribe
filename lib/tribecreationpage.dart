import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class CreateMusicTribePage extends StatefulWidget {
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
      });
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
        title: Text('Create a Music Tribe'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _tribeNameController,
                decoration: InputDecoration(
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
              SizedBox(height: 20.0),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
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
              SizedBox(height: 20.0),
              TextFormField(
                controller: _musicFocusController,
                decoration: InputDecoration(
                  labelText: 'Specific Music Focus (Optional)',
                  hintText: 'e.g., 90s Grunge, Progressive Metal, Lo-fi Hip Hop',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),
              Text('Genres:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              SizedBox(height: 20.0),
              Text('Privacy:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select the privacy setting',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 30.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() && _selectedPrivacy != null) {
                    await _saveTribeToFirestore();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Music Tribe Created!'),
                          content: Text('Your music tribe "${_tribeNameController.text}" has been created.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text('Create Music Tribe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}