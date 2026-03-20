import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthForm extends StatefulWidget {
  final AuthService authService;
  final Function(String) onError;

  const AuthForm({
    super.key,
    required this.authService,
    required this.onError,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLogin ? 'Welcome Back' : 'Create an Account',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          if (!_isLogin)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
          if (!_isLogin) const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              try {
                if (_isLogin) {
                  await widget.authService.signInWithEmailPassword(
                    _emailController.text,
                    _passwordController.text,
                  );
                } else {
                  await widget.authService.registerWithEmailPassword(
                    _emailController.text,
                    _passwordController.text,
                    _nameController.text,
                  );
                }
              } catch (e) {
                widget.onError(e.toString());
              }
            },
            child: Text(_isLogin ? 'Sign In' : 'Register'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
            child: Text(
              _isLogin
                  ? 'Need an account? Register'
                  : 'Have an account? Sign in',
            ),
          ),
          const Divider(height: 48),
          OutlinedButton(
            onPressed: () async {
              try {
                await widget.authService.signInAnonymously();
              } catch (e) {
                widget.onError(e.toString());
              }
            },
            child: const Text('Continue Anonymously'),
          ),
        ],
      ),
    );
  }
}
