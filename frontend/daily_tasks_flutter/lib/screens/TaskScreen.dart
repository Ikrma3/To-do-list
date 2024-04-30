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
  bool showCompletedTasks = true; // Track the visibility of completed tasks

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
      final response = await http.get(Uri.parse('http://192.168.18.79:4000/tasks/${widget.userId}'));

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
      Uri.parse('http://192.168.18.79:4000/tasks/status/$taskId'),
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
  // Format the DateTime object to include both date and time
  String formattedDeadline = DateFormat('yyyy-MM-dd HH:mm').format(parsedDeadline);
  return formattedDeadline;
}


  Future<void> deleteTask(String taskId) async {
    final response = await http.delete(Uri.parse('http://192.168.18.79:4000/tasks/$taskId'));

    if (response.statusCode == 200) {
      // Task deleted successfully, refresh the task list
      fetchTasks();
    } else {
      print('Failed to delete task');
    }
  }

  Future<void> editTask(String taskId, String newDeadline) async {
    final response = await http.put(
      Uri.parse('http://192.168.18.79:4000/tasks/$taskId'),
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
          IconButton( // Button to toggle between showing and hiding completed tasks
            icon: Icon(showCompletedTasks ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                showCompletedTasks = !showCompletedTasks;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isError
          ? Center(child: Text('Error fetching tasks'))
          : ListView(
              children: [
                _buildTasksHeading('Today'),
                _buildTaskList(
                    'Today', tasks.where((task) => isTodayDeadline(task.deadline) && (showCompletedTasks || task.status != 'complete')).toList()),
                SizedBox(height: 20),
                _buildTasksHeading('Tomorrow'),
                _buildTaskList('Tomorrow',
                    tasks.where((task) => isTomorrowDeadline(task.deadline) && (showCompletedTasks || task.status != 'complete')).toList()),
                SizedBox(height: 20),
                _buildTasksHeading('Other'),
                _buildTaskList('Other',
                    tasks.where((task) => !isTodayDeadline(task.deadline) && !isTomorrowDeadline(task.deadline) && (showCompletedTasks || task.status != 'complete')).toList()),
                SizedBox(height: 20),
                _buildTasksHeading('Date Passed'),
                _buildTaskList('Date Passed', tasks.where((task) => isMissedDeadline(task.deadline) && (showCompletedTasks ||task.status != 'complete')).toList()),
              ],
            ),
  floatingActionButton: FloatingActionButton(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Container(
            height: 650 ,//MediaQuery.of(context).size.height , // Adjust the height as needed
            child: AddTaskScreen(
              userId: widget.userId,
              onTaskAdded: () {
                fetchTasks(); // Callback function to refresh task list
              },
            ),
          ),
        );
      },
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

  Widget _buildTasksHeading(String headingText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        headingText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

Widget _buildTaskList(String category, List<Task> tasks) {
  return ListView.builder(
    shrinkWrap: true,
    physics: ClampingScrollPhysics(),
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      if (category == 'Date Passed' || !isMissedDeadline(task.deadline)) {
        // Show tasks with missed deadlines under the "Date Passed" section
        return ListTile(
          leading: Checkbox(
            value: task.status == 'complete',
            onChanged: (value) {
              setState(() {
                toggleTaskStatus(task.id, value!);
                task.status = value ? 'complete' : 'pending';
              });
            },
          ),
          title: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailsScreen(taskId: task.id),
                      ),
                    );
                  },
                  style: ButtonStyle(
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    task.name,
                    style: TextStyle(
                      color: task.status == 'complete' ? Colors.grey : Colors.black, // Change color to grey for completed tasks
                      fontSize: 16, // Adjust the font size as needed
                      decoration: task.status == 'complete' ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ];
                },
                onSelected: (String value) {
                  if (value == 'edit') {
                    _showEditDialog(task);
                  } else if (value == 'delete') {
                    deleteTask(task.id);
                  }
                },
              ),
            ],
          ),
          subtitle: Text('Deadline: ${_formatDeadline(task.deadline)}'), // Show deadline with date and time
        );
      } else {
        // Return an empty container for tasks that are not under the "Date Passed" section
        return Container();
      }
    },
  );
}




  bool isTodayDeadline(String deadline) {
    DateTime today = DateTime.now();
    DateTime taskDeadline = DateTime.parse(deadline);
    return today.year == taskDeadline.year &&
        today.month == taskDeadline.month &&
        today.day == taskDeadline.day;
  }

  bool isTomorrowDeadline(String deadline) {
    DateTime tomorrow = DateTime.now().add(Duration(days: 1));
    DateTime taskDeadline = DateTime.parse(deadline);
    return tomorrow.year == taskDeadline.year &&
        tomorrow.month == taskDeadline.month &&
        tomorrow.day == taskDeadline.day;
  }

  bool isMissedDeadline(String deadline) {
    DateTime now = DateTime.now();
    DateTime taskDeadline = DateTime.parse(deadline);
    return now.isAfter(taskDeadline);
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
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()), // Replace LoginScreen() with your actual LoginScreen widget
        (Route<dynamic> route) => false, // Clear the navigation stack
  );
}
