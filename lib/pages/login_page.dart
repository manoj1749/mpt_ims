// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../layout/app_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLogin = true;
  bool showPassword = false;
  final _formKey = GlobalKey<FormState>();

  void toggleMode() {
    setState(() => isLogin = !isLogin);
  }

  Future<void> authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text.trim();

    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AppScaffold()),
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created. Please login.")),
        );
        setState(() => isLogin = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "${isLogin ? 'Login' : 'Signup'} Failed: ${e.toString()}")),
      );
    }
  }

  Future<void> resetPassword() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid email")),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLogin ? "IMS Login" : "Create Account",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: !showPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => showPassword = !showPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter password';
                    if (!isLogin && value.length < 6) {
                      return 'Minimum 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: resetPassword,
                      child: const Text("Forgot Password?"),
                    ),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: authenticate,
                  child: Text(isLogin ? "Sign In" : "Sign Up"),
                ),
                TextButton(
                  onPressed: toggleMode,
                  child: Text(isLogin
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Sign In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
