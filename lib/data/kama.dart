enum KamaLevel { facil, medio, avanzado }

extension KamaLevelX on KamaLevel {
  String get label {
    switch (this) {
      case KamaLevel.facil:
        return 'Fácil';
      case KamaLevel.medio:
        return 'Intermedio';
      case KamaLevel.avanzado:
        return 'Avanzado';
    }
  }

  int get fires {
    switch (this) {
      case KamaLevel.facil:
        return 1;
      case KamaLevel.medio:
        return 2;
      case KamaLevel.avanzado:
        return 3;
    }
  }

  static KamaLevel fromApi(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'facil':
      case 'fácil':
        return KamaLevel.facil;
      case 'medio':
      case 'intermedio':
        return KamaLevel.medio;
      case 'avanzado':
      case 'dificil':
      case 'difícil':
        return KamaLevel.avanzado;
      default:
        return KamaLevel.facil;
    }
  }
}

class KamaPosition {
  final String id;
  final String name;
  final String emoji;
  final String shortDesc;
  final String fullDesc;
  final String tips;
  final KamaLevel level;
  final String link;

  const KamaPosition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.shortDesc,
    required this.fullDesc,
    required this.tips,
    required this.level,
    required this.link,
  });

  factory KamaPosition.fromJson(Map<String, dynamic> json) {
    return KamaPosition(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      emoji: (json['emoji'] ?? '❤️').toString(),
      shortDesc: (json['shortDesc'] ?? '').toString(),
      fullDesc: (json['fullDesc'] ?? '').toString(),
      tips: (json['tips'] ?? '').toString(),
      level: KamaLevelX.fromApi(json['level']?.toString()),
      link: (json['link'] ?? '').toString(),
    );
  }
}

const List<KamaPosition> kKamaPositions = [
  KamaPosition(
    id: '8eef46ec-909e-4e6c-81cc-ed09c1ce4ebc',
    name: 'Flor de loto',
    emoji: '🪑',
    shortDesc: 'Sentados frente a frente, máxima conexión.',
    fullDesc:
        'Él se sienta con las piernas cruzadas o extendidas. Ella se sienta sobre su regazo mirándole de frente, envolviéndolo con sus piernas. Los cuerpos quedan muy pegados, permitiendo besarse libremente, mirarse a los ojos y moverse juntos en un ritmo sincronizado. El movimiento principal es un balanceo de caderas.',
    tips:
        'Apoyarse en una pared o cabecera de cama le da estabilidad a él. Ella puede apoyar los pies en el suelo para tener más control del movimiento.',
    level: KamaLevel.facil,
    link:
        'https://www.womenshealthmag.com/es/sexo-relaciones-pareja/a34820891/mejores-posturas-kamasutra/#:~:text=1.-,La%20flor%20de%20loto,-Cosmopolitan',
  ),
  KamaPosition(
    id: '13d78205-ba00-4298-9a63-8ea26b2d417b',
    name: 'El misionero',
    emoji: '🌹',
    shortDesc: 'Clásica cara a cara, íntima y perfecta para conectar.',
    fullDesc:
        'Ella se recuesta boca arriba con las piernas ligeramente abiertas. Él se coloca encima apoyándose en los antebrazos para no cargar su peso sobre ella. La penetración es profunda y el contacto visual es constante, lo que la hace muy íntima. Ella puede subir las caderas para cambiar el ángulo y aumentar la estimulación.',
    tips:
        'Él puede colocar una almohada bajo las caderas de ella para cambiar el ángulo de penetración y estimular el punto G con más facilidad.',
    level: KamaLevel.facil,
    link: 'https://www.healthline.com/health/healthy-sex/missionary-position',
  ),
  KamaPosition(
    id: '21acd18c-a7bb-4c81-98ad-983273e35a57',
    name: 'El arco iris',
    emoji: '🌈',
    shortDesc: 'De lado con las piernas entrelazadas, muy íntima.',
    fullDesc:
        'Ambos se acuestan de lado pero mirándose de frente. Ella levanta la pierna de arriba y la coloca sobre la cadera de él. Las piernas quedan entrelazadas permitiendo la penetración desde esta posición lateral. El movimiento es más limitado pero la cercanía de los cuerpos y el contacto visual es máximo.',
    tips:
        'Esta posición es excelente para las manos: él puede estimular su clítoris fácilmente y ella puede acariciarlo a él. Va muy bien combinada con besos lentos.',
    level: KamaLevel.medio,
    link: 'https://sexpositions.club/positions/139.html',
  ),
  KamaPosition(
    id: '154fe872-30ca-4a10-adaf-78b4d4f39a87',
    name: 'El tren',
    emoji: '🚂',
    shortDesc: 'Todos los ángulos del doggy en posición vertical.',
    fullDesc:
        'Ambos de pie, ella frente a una pared o superficie estable con las manos apoyadas. Él detrás de ella. Es un doggy vertical que permite mucha profundidad y una dinámica muy apasionada. Él tiene acceso a toda la espalda, hombros y cuello de ella.',
    tips:
        'La posición de los pies de ella importa: si los separa más, baja las caderas y cambia el ángulo. Él puede ajustar la altura doblando ligeramente las rodillas.',
    level: KamaLevel.avanzado,
    link: 'https://www.healthline.com/health/healthy-sex/standing-sex-positions',
  ),
  KamaPosition(
    id: 'a42c6d69-8576-4274-be76-23670f87bcc2',
    name: 'El escorpión',
    emoji: '🦂',
    shortDesc: 'Acrobática e intensa, requiere flexibilidad.',
    fullDesc:
        'Ella se acuesta boca abajo. Él se coloca encima de ella también boca abajo pero invertido, es decir, sus pies quedan junto a la cabeza de ella. La penetración se logra desde este ángulo invertido. Es una posición muy inusual que ofrece sensaciones completamente distintas por el ángulo de penetración.',
    tips:
        'Calentar bien antes: stretching de caderas y espalda baja para ambos. Comunicarse constantemente sobre el nivel de comodidad. No forzar el ángulo.',
    level: KamaLevel.avanzado,
    link: 'https://www.cosmopolitan.com/sex-love/positions/',
  ),
  KamaPosition(
    id: '316a9446-0e96-452c-9142-0c03e5a6e8d9',
    name: 'El doggy',
    emoji: '🐾',
    shortDesc: 'Él detrás, penetración profunda y muy intensa.',
    fullDesc:
        'Ella se apoya en manos y rodillas (o apoya el pecho en la cama). Él se arrodilla detrás de ella y la penetra. Permite una penetración muy profunda y estimula la pared posterior de la vagina. Él tiene las manos libres para estimular el clítoris, la espalda o los glúteos de ella.',
    tips:
        'Ella puede bajar los hombros hacia la cama y levantar más las caderas para cambiar el ángulo. Si ella apoya los antebrazos en lugar de las manos, la posición es más cómoda durante más tiempo.',
    level: KamaLevel.facil,
    link: 'https://www.healthline.com/health/healthy-sex/doggy-style-position',
  ),
  KamaPosition(
    id: 'f2a5a431-26a1-4474-97d1-159eeb113671',
    name: 'El bambú',
    emoji: '🎍',
    shortDesc: 'De pie, ambos de frente, desafía el equilibrio.',
    fullDesc:
        'Ambos de pie frente a frente. Ella levanta una pierna y la coloca alrededor de la cintura o cadera de él. La penetración ocurre desde esta posición vertical. Requiere buen equilibrio de ambos y que las alturas sean compatibles. Es intensa, apasionada y muy cinematic.',
    tips:
        'Hacerlo contra una pared da mucha más estabilidad. Él puede sostenerle la pierna o las caderas para más control. Si hay diferencia de altura, un escalón o zapatos con algo de taco de ella ayudan.',
    level: KamaLevel.avanzado,
    link: 'https://www.healthline.com/health/healthy-sex/standing-sex-positions',
  ),
  KamaPosition(
    id: '6586142a-3eaa-468f-b3bd-037072374893',
    name: 'El sillón',
    emoji: '🛋️',
    shortDesc: 'Él sentado, ella sobre él dándole la espalda.',
    fullDesc:
        'Él se sienta en el borde de la cama o en una silla sin brazos. Ella se sienta sobre él dándole la espalda, con los pies en el suelo. Ella controla el movimiento completamente. Él tiene libre acceso al clítoris, el vientre y los senos de ella desde atrás. La estimulación del clítoris en esta posición es muy fácil de lograr.',
    tips:
        'Ella puede apoyar los pies en el suelo para empujar con más fuerza. Si usa una silla, la altura importa: sus pies deben llegar cómodamente al suelo.',
    level: KamaLevel.medio,
    link: 'https://www.healthline.com/health/healthy-sex/lap-dance-sex-position',
  ),
  KamaPosition(
    id: '0636d7f9-5aa0-42dc-b485-a900040bef34',
    name: 'La mariposa',
    emoji: '🦋',
    shortDesc: 'Ella en el borde de la cama, él de pie frente a ella.',
    fullDesc:
        'Ella se acuesta en el borde de la cama con las caderas justo al filo. Él está de pie frente a ella y la penetra. Ella puede tener las piernas elevadas sobre los hombros de él, cruzadas sobre su pecho, o extendidas hacia los lados. Esta variación permite una penetración muy profunda y un buen ángulo de estimulación del punto G.',
    tips:
        'Cuanto más altas estén las piernas de ella, más profunda e intensa es la penetración. Él puede sostener sus caderas para más control. Una almohada bajo las caderas de ella ayuda mucho.',
    level: KamaLevel.medio,
    link:
        'https://www.womenshealthmag.com/es/sexo-relaciones-pareja/a34820891/mejores-posturas-kamasutra/#:~:text=2.-,La%20mariposa,-MH%20USA',
  ),
  KamaPosition(
    id: '372990c6-f93f-492c-8c1f-46f94ca6a3c6',
    name: 'El jinete invertido',
    emoji: '🔄',
    shortDesc: 'Ella arriba pero de espaldas, vista y ángulo únicos.',
    fullDesc:
        'Él se acuesta boca arriba. Ella se sienta sobre él pero mirando hacia sus pies en lugar de su cara. Le da a él una vista completamente diferente y el ángulo de penetración estimula zonas distintas. Ella puede apoyarse en los muslos de él o en la cama para mejor control.',
    tips:
        'Ella puede inclinarse hacia adelante o hacia atrás para explorar distintos ángulos. Él puede elevar ligeramente las caderas para mayor profundidad.',
    level: KamaLevel.medio,
    link: 'https://www.healthline.com/health/healthy-sex/reverse-cowgirl',
  ),
  KamaPosition(
    id: '69ce6ff9-a481-44ea-822b-dc93541ce6a0',
    name: 'Las tijeras',
    emoji: '✂️',
    shortDesc: 'Las caderas entrelazadas forman unas tijeras.',
    fullDesc:
        'Ambos se acuestan boca arriba pero en direcciones opuestas, con las caderas entrelazadas formando una "T" o unas tijeras. Las piernas quedan cruzadas. La penetración se logra girando las caderas. El movimiento es suave y oscilante, y ambos tienen las manos completamente libres para estimularse.',
    tips:
        'La clave está en la posición de caderas: experimentar con el ángulo al principio hasta encontrar la penetración correcta. Va muy bien para sesiones largas sin tanto esfuerzo físico.',
    level: KamaLevel.medio,
    link: 'https://www.healthline.com/health/healthy-sex/scissoring',
  ),
  KamaPosition(
    id: '23a979b0-adc6-48ec-aae9-02f9562fd363',
    name: 'El jinete',
    emoji: '🎠',
    shortDesc: 'Ella arriba, controla el ritmo y la profundidad.',
    fullDesc:
        'Él se acuesta boca arriba. Ella se sienta sobre él mirándole la cara, con las rodillas a los lados de sus caderas. Ella controla completamente el ritmo, la profundidad y el ángulo de penetración. Esta posición también estimula el clítoris por fricción directa y le da a él una vista privilegiada de su cuerpo.',
    tips:
        'Ella puede inclinarse hacia adelante apoyándose en el pecho de él para cambiar el ángulo y estimular mejor el punto G. Él puede sujetarle las caderas para ayudar con el ritmo.',
    level: KamaLevel.facil,
    link: 'https://www.healthline.com/health/healthy-sex/cowgirl-sex-position',
  ),
  KamaPosition(
    id: 'eb01ec79-22a3-4ea0-a30e-4af528ec3673',
    name: 'La cuchara',
    emoji: '🥄',
    shortDesc: 'Acurrucados de lado, tierna y muy sensual.',
    fullDesc:
        'Ambos se acuestan de lado, él detrás de ella, ambos mirando en la misma dirección. Él la penetra desde atrás mientras la abraza. Es una posición de mucha intimidad emocional: él puede besarle el cuello, las orejas y la espalda mientras sus manos tienen libre acceso a todo su cuerpo.',
    tips:
        'Ella puede doblar ligeramente las rodillas hacia el pecho para facilitar la penetración y aumentar la profundidad. Ideal para sesiones largas y relajadas.',
    level: KamaLevel.facil,
    link: 'https://www.healthline.com/health/healthy-sex/spooning-sex-position',
  ),
  KamaPosition(
    id: 'f4715569-f31d-45c5-a576-3a16e561cf78',
    name: 'El puente',
    emoji: '🌉',
    shortDesc: 'Él hace un arco con su cuerpo, muy intenso.',
    fullDesc:
        'Él se coloca en posición de puente (espalda arqueada, manos y pies en el suelo, caderas elevadas). Ella se sienta sobre él, mirando hacia sus pies o hacia su cara. Requiere mucha fuerza de core y brazos de parte de él, pero el ángulo de penetración es completamente único.',
    tips:
        'Él debe tener la espalda baja bien calentada. No intentar mantener la posición demasiado tiempo. Ella lleva el peso y el control del movimiento para que él pueda concentrarse en mantener el arco.',
    level: KamaLevel.avanzado,
    link: 'https://www.healthline.com/health/healthy-sex',
  ),
];
