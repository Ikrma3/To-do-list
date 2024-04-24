import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;

  TaskDetailsScreen({required this.taskId});

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  String taskName = '';
  String taskDetails = '';
  String deadline = '';
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchTaskDetails();
  }

  String _formatDeadline(String deadline) {
    // Parse the deadline string to a DateTime object
    DateTime parsedDeadline = DateTime.parse(deadline);
    // Format the DateTime object to the desired format
    return DateFormat('yyyy-MM-dd').format(parsedDeadline);
  }

  Future<void> fetchTaskDetails() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:4000/task/${widget.taskId}'));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          taskName = responseData['taskName'];
          taskDetails = responseData['taskDetails'];
          deadline = _formatDeadline(responseData['deadline']); // Format the deadline
          isLoading = false;
          isError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
        print('Failed to fetch task details. Status code: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      print('Error fetching task details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Details'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
              ? Center(child: Text('Error fetching task details'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskName,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Task Details:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        taskDetails,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Deadline: $deadline',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
    );
  }
}
