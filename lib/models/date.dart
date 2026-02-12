abstract class DateEvent {
  final String title;
  final String description;
  final String date; // "dd-mm-yyyy"
  final String type; // "recuerdo", "carta", "evento"

  const DateEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}
