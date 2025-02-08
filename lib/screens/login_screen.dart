// Suggested code may be subject to a license. Learn more: ~LicenseLog:2076303332.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2756562968.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2645375222.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3768758127.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2086582786.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2174872634.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3088484491.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2755456827.

import 'package:flutter/material.dart';

import 'package:myapp/screens/signup_screen.dart';
import 'package:myapp/screens/chat_screen.dart';

import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Handle login logic
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                  (route) =>
                      false, // This predicate ensures all routes are removed
                );
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text('Forgot Password?'),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text("Don't have an account?"),
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignUpScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
