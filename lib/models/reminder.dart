class Reminder {
  int? id;
  String title;
  String description;
  DateTime dateTime;
  bool isDaily;

  Reminder({this.id, required this.title, required this.description, required this.dateTime, required this.isDaily});

  factory Reminder.fromMap(Map<String, dynamic> json) => Reminder(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    dateTime: DateTime.parse(json['dateTime']),
    isDaily: json['isDaily'] == 1,
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'isDaily': isDaily ? 1 : 0,
    };
  }
}
