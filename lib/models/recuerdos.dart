class Recuerdo {
  final String id;
  final String title;
  final String description;
  final String date; // "dd-MM-yyyy"
  final String? imagePath;
  final List<String> imagesPath;

  const Recuerdo({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.imagePath,
    this.imagesPath = const [],
  });

  List<String> get imageUrls => {
    ...imagesPath.where((path) => path.trim().isNotEmpty),
    if (imagePath?.trim().isNotEmpty ?? false) imagePath!,
  }.toList(growable: false);

  factory Recuerdo.fromJson(Map<String, dynamic> json) {
    final rawImages = json['imagesPath'];
    return Recuerdo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      imagePath: json['imagePath'] as String?,
      imagesPath: rawImages is List
          ? rawImages.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'recuerdo',
    'id': id,
    'title': title,
    'description': description,
    'date': date,
    if (imagePath?.trim().isNotEmpty ?? false) 'imagePath': imagePath,
    'imagesPath': imagesPath,
  };
}
