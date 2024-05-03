import 'package:daily_tasks_flutter/main.dart';
import 'package:daily_tasks_flutter/screens/TaskDetailsScreen.dart';
import 'package:daily_tasks_flutter/screens/addTaskScreen.dart';
import 'package:daily_tasks_flutter/screens/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import '../constants/constants.dart';
Timer? _notificationTimer;
class TaskScreen extends StatefulWidget {
  final String userId;
  TaskScreen({required this.userId});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
   bool showCompletedTasks = true; // Track the visibility of completed tasks
  List<Task> tasks = [];
  bool isLoading = true;
  bool isError = false;
    Set<String> notifiedTaskIds = Set();

  @override
  void initState() {
    super.initState();
    fetchTasks(); 
    _notificationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkAndScheduleNotifications();
    });
  }
  void dispose() {
    // Cancel the notification timer when the widget is disposed
    _notificationTimer?.cancel();
    super.dispose();
  }
  Future<void> _checkAndScheduleNotifications() async {
    final DateTime now = DateTime.now();
    final DateTime fiveMinutesLater = now.add(Duration(minutes: 5));

    // Iterate over tasks to check for deadlines
    for (final task in tasks) {
      // Check if notification has already been shown for this task in the current session
      if (!notifiedTaskIds.contains(task.id)) {
        final DateTime taskDeadline = DateTime.parse(task.deadline);
        // Check if the task deadline is within 5 minutes from now
        if (taskDeadline.isAfter(now) && taskDeadline.isBefore(fiveMinutesLater)) {
          await _scheduleNotification(task.name, 'Deadline is after 5 minutes');
          // Add the task ID to the set of notified tasks
          notifiedTaskIds.add(task.id);
        }
      }
    }
  }


  @override
  void didUpdateWidget(TaskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    fetchTasks(); // Fetch tasks whenever the widget is updated
  }
 Future<void> scheduleNotificationsForTasks(List<Task> tasks) async {
    final DateTime now = DateTime.now();
    final DateTime fiveMinutesLater = now.add(Duration(minutes: 5));

    // Iterate over tasks to check for deadlines
    for (final task in tasks) {
      // Check if notification has already been shown for this task in the current session
      if (!notifiedTaskIds.contains(task.id)) {
        final DateTime taskDeadline = DateTime.parse(task.deadline);
        // Check if the task deadline is within 5 minutes from now
        if (taskDeadline.isAfter(now) && taskDeadline.isBefore(fiveMinutesLater)) {
          await _scheduleNotification(task.name, 'Deadline is after 5 minutes');
          // Add the task ID to the set of notified tasks
          notifiedTaskIds.add(task.id);
        }
      }
    }
    
    // If no tasks with deadlines after 5 minutes were found, clear notifiedTaskIds
    if (tasks.every((task) => !DateTime.parse(task.deadline).isAfter(fiveMinutesLater))) {
      notifiedTaskIds.clear();
    }
  }

Future<void> _scheduleNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'task_notifications',
    'Task Notifications',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'task_notification',
  );
}


  Future<void> fetchTasks() async {
  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.get(Uri.parse('${Constants.baseUrl}tasks/${widget.userId}'));
 if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        final List<Task> fetchedTasks = responseData.map((taskJson) => Task.fromJson(taskJson)).toList();
        setState(() {
          tasks = fetchedTasks;
          isLoading = false;
          isError = false;
        });

        // Schedule notifications for fetched tasks
        _checkAndScheduleNotifications();
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
      Uri.parse('${Constants.baseUrl}tasks/status/$taskId'),
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
    final response = await http.delete(Uri.parse('${Constants.baseUrl}tasks/$taskId'));

    if (response.statusCode == 200) {
      // Task deleted successfully, refresh the task list
      fetchTasks();
    } else {
      print('Failed to delete task');
    }
  }

  Future<void> editTask(String taskId, String newDeadline) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}tasks/$taskId'),
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
        actions: [
          TextButton( // Button to toggle between showing and hiding completed tasks
            onPressed: () {
              setState(() {
                showCompletedTasks = !showCompletedTasks;
              });
            },
            child: Text(showCompletedTasks ? 'Hide Completed' : 'Show Completed'),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              signOutAndNavigateToLoginScreen(context, _notificationTimer);

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
          _buildTasksHeading('Today', tasks),
          _buildTaskList('Today', tasks.where((task) => isTodayDeadline(task.deadline) && (showCompletedTasks || task.status != 'complete')).toList()),
          SizedBox(height: 20),
          _buildTasksHeading('Tomorrow', tasks),
          _buildTaskList('Tomorrow', tasks.where((task) => isTomorrowDeadline(task.deadline) && (showCompletedTasks || task.status != 'complete')).toList()),
          SizedBox(height: 20),
          _buildTasksHeading('Other', tasks),
          _buildTaskList('Other', tasks.where((task) => !isTodayDeadline(task.deadline) && !isTomorrowDeadline(task.deadline) && (showCompletedTasks || task.status != 'complete')).toList()),
          SizedBox(height: 20),
          _buildTasksHeading('Date Passed', tasks),
          _buildTaskList('Date Passed', tasks.where((task) => isMissedDeadline(task.deadline) && (showCompletedTasks ||task.status != 'complete')).toList()),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
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
                  height: 650,
                  child: AddTaskScreen(
                    userId: widget.userId,
                    onTaskAdded: () {
                      fetchTasks();
                    },
                  ),
                ),
              );
            },
          );
        },
        child: CircleAvatar(
          backgroundColor: Colors.black,
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
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
  DateTime selectedDate = DateTime.parse(task.deadline);

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Edit Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != selectedDate)
                      setState(() {
                        selectedDate = picked;
                      });
                  },
                  child: Row(
                    children: [
                      Text('Date:'),
                      SizedBox(width: 10),
                      Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                    );
                    if (picked != null)
                      setState(() {
                        selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, picked.hour, picked.minute);
                      });
                  },
                  child: Row(
                    children: [
                      Text('Time:'),
                      SizedBox(width: 10),
                      Text(DateFormat('HH:mm').format(selectedDate)),
                    ],
                  ),
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
                  editTask(task.id, selectedDate.toIso8601String());
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}


  Widget _buildTasksHeading(String headingText, List<Task> tasks) {
  // Check if there are tasks under this category
  bool hasTasks = false;
  if (headingText == 'Today') {
    hasTasks = tasks.any((task) => isTodayDeadline(task.deadline));
  } else if (headingText == 'Tomorrow') {
    hasTasks = tasks.any((task) => isTomorrowDeadline(task.deadline));
  } else if (headingText == 'Other') {
    hasTasks = tasks.any((task) => !isTodayDeadline(task.deadline) && !isTomorrowDeadline(task.deadline) && !isMissedDeadline(task.deadline));
  } else if (headingText == 'Date Passed') {
    hasTasks = tasks.any((task) => isMissedDeadline(task.deadline));
  }

  // Only display the heading if there are tasks under this category
  if (hasTasks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        headingText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: "Poppins",
          fontSize: 30,
        ),
      ),
    );
  } else {
    // Return an empty container if there are no tasks under this category
    return SizedBox.shrink();
  }
}

Widget _buildTaskList(String category, List<Task> tasks) {
  return ListView.builder(
    shrinkWrap: true,
    physics: ClampingScrollPhysics(),
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      if ((category == 'Date Passed' && isMissedDeadline(task.deadline)) ||
          (category == 'Today' && isTodayDeadline(task.deadline)) ||
          (category == 'Tomorrow' && isTomorrowDeadline(task.deadline)) ||
          (category == 'Other' && !isTodayDeadline(task.deadline) && !isTomorrowDeadline(task.deadline) && !isMissedDeadline(task.deadline))) {
        return ListTile(
          leading: Checkbox(
            value: task.status == 'complete',
            onChanged: (value) {
              setState(() {
                toggleTaskStatus(task.id, value!);
                task.status = value ? 'complete' : 'pending';
              });
            },
            activeColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0), // Adjust the radius as needed
            ),
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
                      color: task.status == 'complete' ? Colors.grey : Color.fromARGB(207, 29, 29, 29), // Change color to grey for completed tasks
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
        // Return an empty container for tasks that don't match the category
        return SizedBox.shrink();
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

Future<void> signOutAndNavigateToLoginScreen(BuildContext context, Timer? notificationTimer) async {
  // Cancel the notification timer if it's active
  if (notificationTimer != null && notificationTimer.isActive) {
    notificationTimer.cancel();
  }
  // Cancel any pending notifications
  await flutterLocalNotificationsPlugin.cancelAll();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
    (Route<dynamic> route) => false,
  );
}

