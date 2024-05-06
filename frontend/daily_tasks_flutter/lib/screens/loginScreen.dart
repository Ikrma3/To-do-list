import 'package:daily_tasks_flutter/screens/signupScreen.dart';
import 'package:flutter/material.dart';
import 'package:daily_tasks_flutter/screens/TaskScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}login'),
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];

        // Store token in shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // Navigate to task screen with token
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TaskScreen(token: token),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid email or password';
        });
      }
    } catch (error) {
      print('Error logging in: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Server error';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if token exists, if yes navigate to TaskScreen
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(token: token),
        ),
      );
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TO DO List', style: const TextStyle(color: Colors.blue)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'images/do-list.jpeg',
                  height: 150, // Adjust the height of the image
                  width: 150, // Adjust the width of the image
                ), // Load image from assets
                SizedBox(height: 20),
                Text(
                  'Email',
                  style: TextStyle(fontSize: 16), // Decrease the font size
                ),
                SizedBox(height: 5), // Decrease the height of the SizedBox
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                     contentPadding: EdgeInsets.symmetric(vertical: 10), 
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Password',
                  style: TextStyle(fontSize: 16), // Decrease the font size
                ),
                SizedBox(height: 5), // Decrease the height of the SizedBox
                TextField(
                  
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                     contentPadding: EdgeInsets.symmetric(vertical: 10), 
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login', style: TextStyle(
                  color: Colors.white,
                ),),
                style: ElevatedButton.styleFrom(
                    primary: Colors.black, // Change button color to black
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SignupScreen(),
                    ),
                  ),
                  child: Container(
                    child: const Text(
                      "Sign Up.",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 39, 168),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}