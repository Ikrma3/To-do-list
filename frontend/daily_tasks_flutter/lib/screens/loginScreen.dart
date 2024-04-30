import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:daily_tasks_flutter/screens/signupScreen.dart';
import 'package:daily_tasks_flutter/screens/TaskScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _userId = '';

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  void _login() async {
    print("Login");
    final String email = _emailController.text;
    final String password = _passwordController.text;

    final response = await http.post(
      Uri.parse('http://192.168.18.79:4000/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );
    print("Response=");
    print(response.statusCode);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _userId = data['userId'];
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(userId: _userId),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Login Failed'),
            content: Text('Invalid email or password'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
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
