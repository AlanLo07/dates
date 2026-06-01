class CartaSorpresa {
  final String id;
  final String title;
  final String description;
  final String date;
  final String imageUrl; // ← nuevo, puede ser vacío
  final String audioUrl; // ← nuevo, puede ser vacío
  bool abierta;

  CartaSorpresa({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.imageUrl = '',
    this.audioUrl = '',
    this.abierta = false,
  });

  factory CartaSorpresa.fromJson(Map<String, dynamic> json) {
    return CartaSorpresa(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      audioUrl: json['audioUrl'] ?? '',
      abierta: json['abierta'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'carta',
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'abierta': abierta,
  };
}
