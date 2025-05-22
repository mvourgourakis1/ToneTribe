import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'username_prompt.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isChecking = true;
  bool _needsUsername = false;

  @override
  void initState() {
    super.initState();
    _checkUsername();
  }

  Future<void> _checkUsername() async {
    setState(() {
      _isChecking = true;
    });

    final needsUsername = _authService.needsUsername();

    if (mounted) {
      setState(() {
        _isChecking = false;
        _needsUsername = needsUsername;
      });
    }
  }

  void _onUsernameComplete() {
    setState(() {
      _needsUsername = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_needsUsername) {
      return Scaffold(
        body: Center(
          child: UsernamePrompt(
            onComplete: _onUsernameComplete,
          ),
        ),
      );
    }

    return widget.child;
  }
} 