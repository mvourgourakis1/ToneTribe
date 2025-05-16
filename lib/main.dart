import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'tribecreationpage.dart';
import 'tribesearch.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully'); // Debug log
  } catch (e) {
    print('Firebase initialization error: $e'); // Debug log
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToneTribe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToneTribe'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                print('Navigating to CreateMusicTribePage'); // Debug log
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateMusicTribePage()),
                );
              },
              child: const Text('Create a Music Tribe'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Navigating to SearchMusicTribePage'); // Debug log
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchMusicTribePage()),
                );
              },
              child: const Text('Search Music Tribes'),
            ),
          ],
        ),
      ),
    );
  }
}