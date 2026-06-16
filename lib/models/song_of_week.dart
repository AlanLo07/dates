// lib/models/song_of_week.dart

class SongOfWeek {
  final String id;
  final String title;
  final String artista;
  final String link; // Spotify URL
  final String setBy; // 'alan' | 'nati' | 'random'
  final String weekKey; // 'yyyy-WW' para identificar la semana

  const SongOfWeek({
    required this.id,
    required this.title,
    required this.artista,
    required this.link,
    this.setBy = 'random',
    required this.weekKey,
  });

  factory SongOfWeek.fromJson(Map<String, dynamic> json) => SongOfWeek(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    artista: json['artista'] ?? '',
    link: json['link'] ?? '',
    setBy: json['setBy'] ?? 'random',
    weekKey: json['weekKey'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'type': 'cancion_semana',
    'id': id,
    'title': title,
    'artista': artista,
    'link': link,
    'setBy': setBy,
    'weekKey': weekKey,
  };

  /// Genera la clave de la semana actual: 'yyyy-WW'
  static String currentWeekKey() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final week = ((now.difference(startOfYear).inDays) / 7).ceil() + 1;
    return '${now.year}-W${week.toString().padLeft(2, '0')}';
  }

  // En lib/models/song_of_week.dart — dentro de la clase SongOfWeek
  SongOfWeek copyWith({
    String? id,
    String? title,
    String? artista,
    String? link,
    String? setBy,
    String? weekKey,
  }) => SongOfWeek(
    id: id ?? this.id,
    title: title ?? this.title,
    artista: artista ?? this.artista,
    link: link ?? this.link,
    setBy: setBy ?? this.setBy,
    weekKey: weekKey ?? this.weekKey,
  );
}
