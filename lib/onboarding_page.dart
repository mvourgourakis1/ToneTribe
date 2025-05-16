import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showSpotifyConnect = false;
  bool _isLoading = false;

  void _handleEmailAuth() {
    // Placeholder for auth logic
    setState(() => _showSpotifyConnect = true);
  }

  void _connectSpotify() {
    // Placeholder for Spotify connection logic
    print('Initiating Spotify connection...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Setup')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_showSpotifyConnect) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleEmailAuth,
                child: const Text('Sign Up/Login'),
              ),
            ] else ...[
              const Text('Success! Connect your Spotify account:'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _connectSpotify,
                child: const Text('Connect Spotify'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}