class EventoImportante {
  final String id;
  final String title;
  final String description;
  final String date; // "dd-MM-yyyy"
  final String icon; // nombre del IconData de Flutter

  EventoImportante({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.icon = 'backpack_outlined',
  });

  factory EventoImportante.fromJson(Map<String, dynamic> json) {
    return EventoImportante(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      icon: json['icon'] ?? 'backpack_outlined',
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'evento',
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'icon': icon,
  };
}
