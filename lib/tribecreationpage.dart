import 'package:flutter/material.dart';

class CreateTribePage extends StatefulWidget {
  @override
  _CreateTribePageState createState() => _CreateTribePageState();
}

class _CreateTribePageState extends State<CreateTribePage> {
  final _formKey = GlobalKey<FormState>();
  final _tribeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPrivacy;
  List<String> _selectedGenres = [];
  final List<String> _availableGenres = [
    'Fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Thriller',
    'Romance',
    'Historical Fiction',
    'Contemporary',
    'Young Adult',
    'Children\'s',
    'Non-Fiction',
    'Biography',
    'History',
    'Science',
    'Self-Help',
    // Add more genres as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create a Tribe'),
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
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedPrivacy != null) {
                    // Process the form data here
                    String tribeName = _tribeNameController.text;
                    String description = _descriptionController.text;
                    // List<String> selectedGenres = _selectedGenres;
                    String privacy = _selectedPrivacy!;

                    print('Tribe Name: $tribeName');
                    print('Description: $description');
                    print('Selected Genres: $_selectedGenres');
                    print('Privacy: $privacy');

                    // You would typically send this data to your backend
                    // or perform other actions here.

                    // For now, let's show a simple dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Tribe Created!'),
                          content: Text('Your tribe "$tribeName" has been created.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                                Navigator.of(context).pop(); // Go back to the home page
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } else if (_selectedPrivacy == null) {
                    // The validator in the RadioListTile handles the error message
                  }
                },
                child: Text('Create Tribe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}