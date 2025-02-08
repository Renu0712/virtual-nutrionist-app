// Suggested code may be subject to a license. Learn more: ~LicenseLog:3226052279.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2286544111.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2318515588.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1113126016.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2446298291.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3676477969.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2069492323.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2712705027.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2937535211.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:2771958615.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1072287851.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3720200334.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:159503831.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:4079994446.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:993257347.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:3585735227.
// Suggested code may be subject to a license. Learn more: ~LicenseLog:1874645250.

import 'package:flutter/material.dart';
import 'package:myapp/screens/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Perform sign-up logic
                },
                child: const Text('Sign Up'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
