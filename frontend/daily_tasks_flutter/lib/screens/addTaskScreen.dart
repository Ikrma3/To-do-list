import 'package:daily_tasks_flutter/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddTaskScreen extends StatefulWidget {
  final VoidCallback onTaskAdded; // Callback function to trigger task list refresh
final String token; // Add token as a parameter

  AddTaskScreen({required this.token,required this.onTaskAdded});
  
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDetailsController = TextEditingController();
  String _priority = 'medium'; // Default priority
  bool _isTodaySelected = true; // Default value for the today switch
  DateTime _selectedDateTime = DateTime.now(); // Default selected date and time

  Future<void> _submitTask() async {
    final String taskName = _taskNameController.text;
    final String taskDetails = _taskDetailsController.text;
    final String priority = _priority;

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}tasks'),
       headers: <String, String>{
          'Authorization': 'Bearer ${widget.token}', // Access token from widget property
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'taskName': taskName,
          'taskDetails': taskDetails,
          'priority': priority,
          'deadline': _selectedDateTime.toIso8601String(), // Send selected date and time to backend
        }),
      );

      if (response.statusCode == 201) {
        // Task created successfully
        widget.onTaskAdded(); // Trigger task list refresh in TaskScreen
        Navigator.pop(context); // Return to the TaskScreen
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
         centerTitle: true,
        title:
         Text(
          'Task',
            //textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
         bottom: PreferredSize(
      preferredSize: Size.fromHeight(1.0), // Set the height of the Divider
      child: Divider(
        height: 1.0, // Set the height of the Divider
        thickness: 1.0, // Set the thickness of the Divider
        color: Colors.grey, // Set the color of the Divider
      ),
    ),
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add a task",
              style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 35,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,),
                      SizedBox(height: 14,),
              Row(
                children: [
                  
                  Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 20,

                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _taskNameController,
                      decoration: InputDecoration(
                        hintText: 'Project Name',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Detail',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                       fontSize: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
  controller: _taskDetailsController,
  maxLines: null, // Allow multiple lines
  decoration: InputDecoration(
    hintText: 'Task Details',
    border: OutlineInputBorder(), // Add an outline border
    contentPadding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 10.0), // Add padding
  ),
),

                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                  Switch(
                    value: _isTodaySelected,
                    onChanged: (bool value) {
                      setState(() {
                        _isTodaySelected = value;
                        if (!value) {
                          _selectedDateTime = DateTime.now();
                        }
                      });
                    },
                     activeTrackColor: Colors.green,// Change the color of the thumb to green

                  ),
                ],
              ),
              SizedBox(height: 16),
              !_isTodaySelected
                  ? GestureDetector(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              _selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_selectedDateTime.year}-${_selectedDateTime.month}-${_selectedDateTime.day} ${_selectedDateTime.hour}:${_selectedDateTime.minute}',
                              style: TextStyle(fontSize: 18),
                            ),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    )
                  : 
                 Row(
  children: [
    Text("Hours",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    SizedBox(width: 10,),
    GestureDetector(
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        );
        if (pickedTime != null) {
          setState(() {
            // Create a new DateTime object with the selected time
            _selectedDateTime = DateTime(
              _selectedDateTime.year,
              _selectedDateTime.month,
              _selectedDateTime.day,
              // Convert the selected time to 24-hour format
              pickedTime.hour > 12 ? pickedTime.hour : pickedTime.hour + 12,
              pickedTime.minute,
            );
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              // Update the text to show the selected time in 24-hour format
              '${_selectedDateTime.hour}:${_selectedDateTime.minute}',
              style: TextStyle(fontSize: 18),
            ),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    ),
  ],
),

              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: InputDecoration(labelText: 'Priority', labelStyle: TextStyle(fontSize: 20),
                ),
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
              SizedBox(height: 36),
              SizedBox(
                width: double.infinity, // Make button full width
                child: ElevatedButton(
  onPressed: _submitTask,
  child: Text(
    'Done',
    style: TextStyle(
      color: Colors.white,
    ),
  ),
  style: ElevatedButton.styleFrom(
    primary: Colors.black, // Change button color to black
    shape: RoundedRectangleBorder( // Set button shape to box
      borderRadius: BorderRadius.circular(10), 
      // Set border radius to 0 for box shape
    ),
     minimumSize: Size(double.infinity, 50),
  ),
),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
