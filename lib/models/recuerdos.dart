import 'package:dates/models/date.dart';

class Recuerdo extends DateEvent {
  final String imagePath;

  Recuerdo({
    required super.title,
    required super.description,
    required super.date,
    required this.imagePath,
  }) : super(type: 'recuerdo');
}
