import 'package:daily_tasks_flutter/screens/TaskDetailsScreen.dart';
import 'package:daily_tasks_flutter/screens/addTaskScreen.dart';
import 'package:daily_tasks_flutter/screens/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class TaskScreen extends StatefulWidget {
  final String userId;

  TaskScreen({required this.userId});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Task> tasks = [];
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    fetchTasks(); // Fetch tasks when the widget is first initialized
  }

  @override
  void didUpdateWidget(TaskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    fetchTasks(); // Fetch tasks whenever the widget is updated
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:4000/tasks/${widget.userId}'));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final List<Task> fetchedTasks = responseData
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();
        setState(() {
          tasks = fetchedTasks;
          isLoading = false;
          isError = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isError = true;
        });
        print('Failed to fetch tasks. Status code: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isError = true;
      });
      print('Error fetching tasks: $error');
    }
  }
  Future<void> toggleTaskStatus(String taskId, bool isComplete) async {
    final String newStatus = isComplete ? 'complete' : 'pending';
    final response = await http.put(
      Uri.parse('http://127.0.0.1:4000/tasks/status/$taskId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'status': newStatus,
      }),
    );

    if (response.statusCode == 200) {
      // Task status updated successfully, refresh the task list
      fetchTasks();
    } else {
      print('Failed to update task status');
    }
  }
String _formatDeadline(String deadline) {
  // Parse the deadline string to a DateTime object
  DateTime parsedDeadline = DateTime.parse(deadline);
  // Format the DateTime object to the desired format
  return DateFormat('yyyy-MM-dd').format(parsedDeadline);
}

  Future<void> deleteTask(String taskId) async {
    final response = await http.delete(Uri.parse('http://127.0.0.1:4000/tasks/$taskId'));

    if (response.statusCode == 200) {
      // Task deleted successfully, refresh the task list
      fetchTasks();
    } else {
      print('Failed to delete task');
    }
  }

  Future<void> editTask(String taskId, String newDeadline) async {
    final response = await http.put(
      Uri.parse('http://127.0.0.1:4000/tasks/$taskId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'deadline': newDeadline,
      }),
    );

    if (response.statusCode == 200) {
      // Task edited successfully, refresh the task list
      fetchTasks();
    } else {
      print('Failed to edit task');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              signOutAndNavigateToLoginScreen(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
              ? Center(child: Text('Error fetching tasks'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(
                        task.name,
                        style: task.status == 'complete' ? TextStyle(decoration: TextDecoration.lineThrough) : null,
                      ),
                     subtitle: Text('Deadline: ${_formatDeadline(task.deadline)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: task.status == 'complete',
                            onChanged: (value) {
                              setState(() {
                                toggleTaskStatus(task.id, value);
                                task.status = value ? 'complete' : 'pending';
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () {
                              showTaskOptionsDialog(task);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TaskDetailsScreen(taskId: task.id),
  ),
);
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AddTaskScreen(
      userId: widget.userId,
      onTaskAdded: () {
        fetchTasks(); // Callback function to refresh task list
      },
    ),
  ),
);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void showTaskOptionsDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Task Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(task);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete Task'),
                onTap: () {
                  Navigator.pop(context);
                  deleteTask(task.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(Task task) async {
    TextEditingController deadlineController = TextEditingController(text: task.deadline);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: deadlineController,
                decoration: InputDecoration(labelText: 'Deadline'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                editTask(task.id, deadlineController.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class Task {
  String id;
  String name;
  String priority;
  String deadline;
  String status;

  Task({
    required this.id,
    required this.name,
    required this.priority,
    required this.deadline,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'],
      name: json['taskName'],
      priority: json['priority'],
      deadline: json['deadline'],
      status: json['taskStatus'],
    );
  }
}

Future<void> signOutAndNavigateToLoginScreen(BuildContext context) async {
    // Perform sign out operations here...
    // For example:
    // await signOut();

    // Navigate to the LoginScreen and clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Replace LoginScreen() with your actual LoginScreen widget
      (Route<dynamic> route) => false, // Clear the navigation stack
    );
  }