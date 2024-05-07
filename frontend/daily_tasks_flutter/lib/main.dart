import 'package:daily_tasks_flutter/constants/private.dart';
import 'package:daily_tasks_flutter/screens/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initNotifications();
  runApp(MyApp());
}

Future<void> _initOneSignal(BuildContext context) async {
  OneSignal.shared.setAppId("${PrivateValues.appId}");

  // Check if the user is already subscribed
  bool isSubscribed = await _checkSubscription();
  if (!isSubscribed) {
    // If not subscribed, ask for permission
    _promptForNotificationPermission(context);
  }
}

Future<bool> _checkSubscription() async {
  try {
    // Check if the user has the subscribed tag
    var result = await OneSignal.shared.getTags();
    if (result != null &&
        result.containsKey('tags') &&
        result['tags'] != null &&
        result['tags'].containsKey('subscribed')) {
      // User has the subscribed tag
      return true;
    } else {
      // User does not have the subscribed tag
      return false;
    }
  } catch (e) {
    print('Error checking subscription status: $e');
    // Return false in case of any error
    return false;
  }
}

void _promptForNotificationPermission(BuildContext context) {
  // Display a prompt to the user asking them to subscribe to notifications
  // You can use dialogs, alerts, or any other UI element to prompt the user
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Allow Notifications'),
        content: Text('Do you want to receive notifications for new tasks?'),
        actions: <Widget>[
          TextButton(
            child: Text('No'),
            onPressed: () {
              // Optionally handle if the user chooses not to subscribe
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () {
              // Handle subscription logic here
              // For example, subscribe the user to notifications
              // You can call OneSignal SDK methods to subscribe the user
              // Once subscribed, you can close the dialog
              _handleSubscription(context);
            },
          ),
        ],
      );
    },
  );
}

void _handleSubscription(BuildContext context) async {
  try {
    // Call the OneSignal SDK method to subscribe the user to notifications
    // For example, you can add a tag 'subscribed' to indicate the user is subscribed
    await OneSignal.shared.sendTag('subscribed', 'true');

    // Once subscribed, you can close the dialog
    Navigator.of(context).pop();
  } catch (e) {
    print('Error subscribing to notifications: $e');
    // Handle any errors that occur during the subscription process
    // You may display an error message to the user or retry the subscription
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TO DO LIST',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Builder(
        builder: (context) {
          // Pass the context to _initOneSignal
          _initOneSignal(context);
          return LoginScreen();
        },
      ),
    );
  }
}
