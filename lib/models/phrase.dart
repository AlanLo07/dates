// lib/models/hangman_phrase.dart

enum PhraseType { pelicula, cancion, libro, serie, pareja }

extension PhraseTypeX on PhraseType {
  String get label {
    switch (this) {
      case PhraseType.pelicula:
        return 'Película';
      case PhraseType.cancion:
        return 'Canción';
      case PhraseType.serie:
        return 'Serie';
      case PhraseType.libro:
        return 'Libro';
      case PhraseType.pareja:
        return 'Nuestra frase';
    }
  }

  String get emoji {
    switch (this) {
      case PhraseType.pelicula:
        return '🎬';
      case PhraseType.cancion:
        return '🎵';
      case PhraseType.serie:
        return '📺';
      case PhraseType.libro:
        return '📖';
      case PhraseType.pareja:
        return '💌';
    }
  }

  static PhraseType fromString(String value) {
    switch (value) {
      case 'pelicula':
        return PhraseType.pelicula;
      case 'cancion':
        return PhraseType.cancion;
      case 'serie':
        return PhraseType.serie;
      case 'libro':
        return PhraseType.libro;
      case 'pareja':
        return PhraseType.pareja;
      default:
        return PhraseType.cancion;
    }
  }

  static String fromPhraseType(PhraseType value) {
    switch (value) {
      case PhraseType.pelicula:
        return 'pelicula';
      case PhraseType.cancion:
        return 'cancion';
      case PhraseType.serie:
        return 'serie';
      case PhraseType.libro:
        return 'libro';
      case PhraseType.pareja:
        return 'pareja';
    }
  }

  String get toJson => name; // usa el nombre del enum directamente
}

class LovePhrase {
  final String id;
  final String text; // La frase a adivinar
  final PhraseType type; // Tipo: pelicula o cancion
  final String title; // Nombre de la película o canción
  final String minute; // En qué minuto se dice/escucha (ej: "1:24", "0:45")
  final String credits; // Director/Actor o Artista/Álbum
  final String emoji; // Emoticón que será la "cara" del ahorcado
  final String link;
  final bool completado; // Bandera: la frase ya fue adivinada en el ahorcado

  const LovePhrase({
    this.id = '',
    required this.text,
    required this.type,
    required this.title,
    this.minute = '',
    this.credits = '',
    required this.emoji,
    this.link = '',
    this.completado = false,
  });

  // Para cuando se consuma desde una API
  factory LovePhrase.fromJson(Map<String, dynamic> json) {
    return LovePhrase(
      id: (json['id'] ?? json['phraseId'] ?? json['phrase_id'] ?? '').toString(),
      text: json['text'],
      type: PhraseTypeX.fromString(json['type'] ?? 'cancion'),
      title: json['title'] ?? '',
      minute: json['minute'] ?? '',
      credits: json['credits'] ?? '',
      emoji: json['emoji'] ?? '💬',
      link: json['link'] ?? '',
      completado: _parseBool(json['completado']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'text': text,
      'type': type.toJson,
      'title': title,
      'minute': minute,
      'credits': credits,
      'emoji': emoji,
      'link': link,
      'completado': completado,
    };
  }

  LovePhrase copyWith({
    String? id,
    String? text,
    PhraseType? type,
    String? title,
    String? minute,
    String? credits,
    String? emoji,
    String? link,
    bool? completado,
  }) {
    return LovePhrase(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      title: title ?? this.title,
      minute: minute ?? this.minute,
      credits: credits ?? this.credits,
      emoji: emoji ?? this.emoji,
      link: link ?? this.link,
      completado: completado ?? this.completado,
    );
  }

  // Getter para facilitar la lógica del juego (sin tildes)
  String get normalizedText => text
      .toUpperCase()
      .replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A')
      .replaceAll(RegExp(r'[ÉÈËÊ]'), 'E')
      .replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I')
      .replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O')
      .replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U')
      .replaceAll('Ñ', 'N');
}
