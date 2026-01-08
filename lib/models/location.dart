class Location {
  final String name;
  final String type; // 'Museo', 'Parque' o 'Pueblo'
  bool isVisited;

  Location({required this.name, required this.type, this.isVisited = false});

  // Para persistencia
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'isVisited': isVisited,
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    name: json['name'],
    type: json['type'],
    isVisited: json['isVisited'],
  );
}
