// Suggested code may be subject to a license. Learn more: ~LicenseLog:254330526.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1191134402.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:129974940.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:4182755184.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1514417481.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3549307617.

import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // send password reset mail.
              },
              child: const Text('Send Reset Mail'),
            ),
          ],
        ),
      ),
    );
  }
}
