class CartaSorpresa {
  final String id;
  final String title;
  final String description;
  final String date; // "dd-MM-yyyy"
  bool abierta;

  CartaSorpresa({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.abierta = false,
  });

  factory CartaSorpresa.fromJson(Map<String, dynamic> json) {
    return CartaSorpresa(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      abierta: json['abierta'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'carta',
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    'abierta': abierta,
  };
}
