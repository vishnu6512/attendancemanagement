import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee.dart';
import 'admin.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _getRememberedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn(BuildContext context, String email, String password) async {
    try {
      // Sign in with email and password
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user data from Firestore
      final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();

      // Get the role from user data
      final String role = userSnapshot.get('role');

      // Navigate to appropriate page based on role
      if (role == 'user') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => EmployeePage()));
      } else if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminPage()));
      } else {
        // Handle other roles or scenarios
      }
    } catch (e) {
      // Show error message if sign-in fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: $e'),
        ),
      );
    }
  }

  Future<void> _getRememberedCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rememberedEmail = prefs.getString('email');
    final String? rememberedPassword = prefs.getString('password');
    if (rememberedEmail != null && rememberedPassword != null) {
      setState(() {
        _emailController.text = rememberedEmail;
        _passwordController.text = rememberedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberedCredentials(String email, String password) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', email);
      await prefs.setString('password', password);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              onChanged: (value) {},
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              onChanged: (value) {},
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value!;
                    });
                  },
                ),
                Text('Remember Me'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Call sign-in function with email and password
                _signIn(context, _emailController.text.trim(), _passwordController.text.trim());
                _saveRememberedCredentials(_emailController.text.trim(), _passwordController.text.trim());
              },
              child: Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

