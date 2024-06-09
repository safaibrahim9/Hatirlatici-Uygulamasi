import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hatirlatici_uyg_son/db_helper.dart';
import 'package:hatirlatici_uyg_son/models/reminder.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones();
  runApp(ReminderApp());

}

class ReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Reminder App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: ReminderListPage(),
    );
  }
}

class ReminderListPage extends StatefulWidget {
  @override
  _ReminderListPageState createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  final DBHelper _dbHelper = DBHelper();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadReminders();
  }

  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = IOSInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: iOS);
    flutterLocalNotificationsPlugin.initialize(settings);
  }

  void _scheduleNotification(Reminder reminder) async {
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Channel for reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iOSDetails = IOSNotificationDetails();
    const generalNotificationDetails = NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      reminder.id!,
      reminder.title,
      reminder.description,
      reminder.isDaily
          ? _nextInstanceOfTime(reminder.dateTime)
          : tz.TZDateTime.from(reminder.dateTime, tz.local),
      generalNotificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: reminder.isDaily
          ? DateTimeComponents.time
          : DateTimeComponents.dateAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute, time.second);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> _loadReminders() async {
    final data = await _dbHelper.queryAllReminders();
    setState(() {
      _reminders = data.map((item) => Reminder.fromMap(item)).toList();
    });
  }

  Future<void> _addOrUpdateReminder({Reminder? reminder}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReminderDetailPage(reminder: reminder),
      ),
    );

    if (result != null) {
      if (reminder != null) {
        await _dbHelper.updateReminder(result.toMap());
      } else {
        await _dbHelper.insertReminder(result.toMap());
      }
      _scheduleNotification(result);
      _loadReminders();
    }
  }

  void _deleteReminder(int id) async {
    await _dbHelper.deleteReminder(id);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminders'),

      ),
      body: ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final reminder = _reminders[index];
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.asset("resimler/barry_allen2.jpg"),
          );
          return ListTile(

            title: Text(reminder.title),
            subtitle: Text('${reminder.description}\n${reminder.dateTime}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteReminder(reminder.id!),
            ),
            onTap: () => _addOrUpdateReminder(reminder: reminder),
          );
        },

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateReminder(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class ReminderDetailPage extends StatefulWidget {
  final Reminder? reminder;

  ReminderDetailPage({this.reminder});

  @override
  _ReminderDetailPageState createState() => _ReminderDetailPageState();
}

class _ReminderDetailPageState extends State<ReminderDetailPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isDaily = false;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _titleController.text = widget.reminder!.title;
      _descriptionController.text = widget.reminder!.description;
      _selectedDate = widget.reminder!.dateTime;
      _isDaily = widget.reminder!.isDaily;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null)
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder != null ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),

            Row(
              children: [
                Expanded(
                  child: Text('Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text('Time: ${TimeOfDay.fromDateTime(_selectedDate).format(context)}'),
                ),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ],
            ),
            Row(
              children: [
                Text('Daily Reminder'),
                Switch(
                  value: _isDaily,
                  onChanged: (value) {
                    setState(() {
                      _isDaily = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newReminder = Reminder(
                  id: widget.reminder?.id,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  dateTime: _selectedDate,
                  isDaily: _isDaily,
                );
                Navigator.of(context).pop(newReminder);
              },
              child: Text(widget.reminder != null ? 'Update' : 'Add'),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                "resimler/reminder.png",
                width: 200, // Genişlik
                height: 200, // Yükseklik
                fit: BoxFit.cover, // Resmi belirtilen boyuta sığdırmak için
              ),
            )
          ],
        ),
      ),
    );
  }
}
