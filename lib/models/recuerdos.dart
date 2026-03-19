class Recuerdo {
  final String id;
  final String title;
  final String description;
  final String date; // "dd-MM-yyyy"
  final String imagePath;

  const Recuerdo({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.imagePath,
  });

  factory Recuerdo.fromJson(Map<String, dynamic> json) {
    return Recuerdo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      imagePath: json['imagePath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'recuerdo',
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'imagePath': imagePath,
  };
}
