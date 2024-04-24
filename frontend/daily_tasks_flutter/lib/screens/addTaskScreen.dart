import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTaskScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onTaskAdded; // Callback function to trigger task list refresh

  AddTaskScreen({required this.userId, required this.onTaskAdded});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();
  String _priority = 'medium'; // Default priority

 Future<void> _submitTask() async {
  final String taskName = _taskNameController.text;
  final String taskDetails = _taskDetailsController.text;
  final String deadline = _deadlineController.text;
  final String priority = _priority;

  try {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:4000/tasks'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'taskName': taskName,
        'taskDetails': taskDetails,
        'deadline': deadline,
        'priority': priority,
        'userId': widget.userId,
      }),
    );

    if (response.statusCode == 201) {
      // Task created successfully
      widget.onTaskAdded(); // Trigger task list refresh in TaskScreen
    Navigator.pop(context); // Return to the TaskScreen // Return to the TaskScreen
    } else {
      print('Failed to add task. Status code: ${response.statusCode}');
    }
  } catch (error) {
    print('Error adding task: $error');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _taskDetailsController,
              decoration: InputDecoration(labelText: 'Task Details'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _deadlineController,
              decoration: InputDecoration(labelText: 'Deadline (yyyy-mm-dd)'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: InputDecoration(labelText: 'Priority'),
              onChanged: (String? newValue) {
                setState(() {
                  _priority = newValue!;
                });
              },
              items: <String>['high', 'medium', 'low']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitTask,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
