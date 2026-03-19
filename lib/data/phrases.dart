// lib/data/hangman_phrases.dart
import 'dart:math';
import '../models/phrase.dart';

const List<LovePhrase> kLovePhrases = [
  // ── CARLA MORRISON ──────────────────────────────────────────────────────────
  LovePhrase(
    text: 'HOY DESPERTE CON GANAS DE BESARTE',
    type: PhraseType.cancion,
    title: 'Eres Tú',
    minute: '0:05',
    credits: 'Carla Morrison — Déjenme Llorar (2012)',
    emoji: '🌸',
    link:
        'https://open.spotify.com/intl-es/track/75zvC8d4iozawMJvxt8T1f?si=8e0db7ae72a44c15',
  ),
  LovePhrase(
    text: 'TODO LO BUENO DE MI FLORECE ERES TU',
    type: PhraseType.cancion,
    title: 'Eres Tú',
    minute: '1:10',
    credits: 'Carla Morrison — Déjenme Llorar (2012)',
    emoji: '🌸',
    link:
        'https://open.spotify.com/intl-es/track/75zvC8d4iozawMJvxt8T1f?si=8e0db7ae72a44c15',
  ),
  LovePhrase(
    text: 'MIS VENAS TAN SUTILMENTE DISFRUTAN TANTO QUERERTE',
    type: PhraseType.cancion,
    title: 'Eres Tú',
    minute: '2:05',
    credits: 'Carla Morrison — Déjenme Llorar (2012)',
    emoji: '🌸',
    link:
        'https://open.spotify.com/intl-es/track/75zvC8d4iozawMJvxt8T1f?si=8e0db7ae72a44c15',
  ),
  LovePhrase(
    text: 'COMPARTIR CONTIGO LO QUE TENGO',
    type: PhraseType.cancion,
    title: 'Compartir',
    minute: '0:20',
    credits: 'Carla Morrison — Mientras Tú Dormías (2018)',
    emoji: '💜',
    link:
        'https://open.spotify.com/intl-es/track/50Jd7tX7dMu79Oknn7sXSW?si=419521216d914bc6',
  ),

  // ── NANPA BÁSICO ─────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'FLACA VENTE PA ESTE LAO Y ESCAPEMONOS SOLOS',
    type: PhraseType.cancion,
    title: 'Flaca',
    minute: '0:18',
    credits: 'Nanpa Básico — Flaca (2018)',
    emoji: '🎸',
    link:
        'https://open.spotify.com/intl-es/track/18PywrD2EQCVJEXMjETy8p?si=06374b8d08f442cb',
  ),
  LovePhrase(
    text: 'TUS BESOS SON UN VICIO INOCENTE Y NO QUIERO DEJARLOS',
    type: PhraseType.cancion,
    title: 'Flaca',
    minute: '1:35',
    credits: 'Nanpa Básico — Flaca (2018)',
    emoji: '🎸',
    link:
        'https://open.spotify.com/intl-es/track/18PywrD2EQCVJEXMjETy8p?si=06374b8d08f442cb',
  ),
  LovePhrase(
    text: 'PORQUE TU TIENES MI MEDIDA PRECISA',
    type: PhraseType.cancion,
    title: 'Flaca',
    minute: '0:45',
    credits: 'Nanpa Básico — Flaca (2018)',
    emoji: '🎸',
    link:
        'https://open.spotify.com/intl-es/track/18PywrD2EQCVJEXMjETy8p?si=06374b8d08f442cb',
  ),
  LovePhrase(
    text: 'NUNCA TUVE TANTO Y LO TENGO TODO',
    type: PhraseType.cancion,
    title: 'Nunca Tuve Tanto',
    minute: '0:50',
    credits: 'Nanpa Básico ft. Ximena Sariñana — Nunca Tuve Tanto (2018)',
    emoji: '🌊',
    link:
        'https://open.spotify.com/intl-es/track/676WeBQ2T3dW4p8mywOZvG?si=7b9c43adbf5f4b96',
  ),
  LovePhrase(
    text: 'PORQUE QUISE ESTAR A TU LADO',
    type: PhraseType.cancion,
    title: 'Porque Quise',
    minute: '0:30',
    credits: 'Nanpa Básico — Porque Quise (2019)',
    emoji: '🌊',
    link:
        'https://open.spotify.com/intl-es/track/4BPrDt0J43Jo0UHut7smYM?si=07efba1100e447ad',
  ),

  // ── IMAGINE DRAGONS ──────────────────────────────────────────────────────────
  LovePhrase(
    text: 'I KNOW THAT ONE DAY I WILL BE THAT ONE THING THAT MAKES YOU HAPPY',
    type: PhraseType.cancion,
    title: 'One Day',
    minute: '0:10',
    credits: 'Imagine Dragons — Mercury Acts 1 & 2 (2021)',
    emoji: '⚡',
    link:
        'https://open.spotify.com/intl-es/track/0xBlufYjHrtf8xk0QifNn1?si=9bd1f3783ca34c93',
  ),
  LovePhrase(
    text: 'YOUR SUN ON A CLOUDED DAY',
    type: PhraseType.cancion,
    title: 'One Day',
    minute: '0:25',
    credits: 'Imagine Dragons — Mercury Acts 1 & 2 (2021)',
    emoji: '⚡',
    link:
        'https://open.spotify.com/intl-es/track/0xBlufYjHrtf8xk0QifNn1?si=9bd1f3783ca34c93',
  ),
  LovePhrase(
    text: 'WEST COAST SUN ALWAYS SHINING ON ME',
    type: PhraseType.cancion,
    title: 'West Coast',
    minute: '0:15',
    credits: 'Imagine Dragons — Origins Deluxe (2018)',
    emoji: '🐉',
    link:
        'https://open.spotify.com/intl-es/track/2nkoWsTZa8LKPNGdjI5uxj?si=055a414dc323421d',
  ),

  // ── COUNTING CROWS ───────────────────────────────────────────────────────────
  LovePhrase(
    text: 'COME ON COME ON TURN A LITTLE FASTER',
    type: PhraseType.cancion,
    title: 'Accidentally In Love',
    minute: '0:38',
    credits: 'Counting Crows — Shrek 2 Soundtrack (2004)',
    emoji: '💚',
    link:
        'https://open.spotify.com/intl-es/track/5W10CyNhnCoIxUYfANwZqR?si=d4997b3af8e94182',
  ),
  LovePhrase(
    text: 'WELL MAYBE I AM IN LOVE THINK ABOUT IT EVERY TIME',
    type: PhraseType.cancion,
    title: 'Accidentally In Love',
    minute: '0:05',
    credits: 'Counting Crows — Shrek 2 Soundtrack (2004)',
    emoji: '💚',
    link:
        'https://open.spotify.com/intl-es/track/5W10CyNhnCoIxUYfANwZqR?si=d4997b3af8e94182',
  ),
  LovePhrase(
    text: 'BABY I SURRENDER TO THE STRAWBERRY ICE CREAM',
    type: PhraseType.cancion,
    title: 'Accidentally In Love',
    minute: '1:10',
    credits: 'Counting Crows — Shrek 2 Soundtrack (2004)',
    emoji: '💚',
    link:
        'https://open.spotify.com/intl-es/track/5W10CyNhnCoIxUYfANwZqR?si=d4997b3af8e94182',
  ),

  // ── DAFT PUNK ────────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'SOMETHING ABOUT US MAKES ME WANT TO MAKE YOU MINE',
    type: PhraseType.cancion,
    title: 'Something About Us',
    minute: '0:45',
    credits: 'Daft Punk — Discovery (2001)',
    emoji: '🤖',
    link:
        'https://open.spotify.com/intl-es/track/1NeLwFETswx8Fzxl2AFl91?si=099f40269bd74807',
  ),
  LovePhrase(
    text: 'IT MIGHT NOT BE THE RIGHT TIME',
    type: PhraseType.cancion,
    title: 'Something About Us',
    minute: '0:12',
    credits: 'Daft Punk — Discovery (2001)',
    emoji: '🤖',
    link:
        'https://open.spotify.com/intl-es/track/1NeLwFETswx8Fzxl2AFl91?si=099f40269bd74807',
  ),

  // ── AURORA ───────────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'I EXIST FOR LOVE I EXIST FOR YOU',
    type: PhraseType.cancion,
    title: 'Exist for Love',
    minute: '1:20',
    credits: 'AURORA — The Gods We Can Touch (2022)',
    emoji: '🌌',
    link:
        'https://open.spotify.com/intl-es/track/09fAL7YwPV3YzVmQDzLY8d?si=a78516a154ca451e',
  ),

  // ── TWENTY ONE PILOTS ────────────────────────────────────────────────────────
  LovePhrase(
    text: 'MY HEART IS MY ARMOR',
    type: PhraseType.cancion,
    title: 'Tear in My Heart',
    minute: '0:55',
    credits: 'Twenty One Pilots — Blurryface (2015)',
    emoji: '🔴',
    link:
        'https://open.spotify.com/intl-es/track/2zYy3u2k294y9w9W9w9w9w?si=a78516a154ca451e',
  ),
  LovePhrase(
    text: 'YOU FELL ASLEEP IN MY CAR I DROVE THE WHOLE TIME',
    type: PhraseType.cancion,
    title: 'Tear in My Heart',
    minute: '0:20',
    credits: 'Twenty One Pilots — Blurryface (2015)',
    emoji: '🔴',
    link:
        'https://open.spotify.com/intl-es/track/2zYy3u2k294y9w9W9w9w9w?si=a78516a154ca451e',
  ),

  // ── DUKI ─────────────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'ANTES DE PERDERTE QUIERO DECIRTE QUE TE AMO',
    type: PhraseType.cancion,
    title: 'Antes de Perderte',
    minute: '0:40',
    credits: 'Duki — Antes de Perderte (2024)',
    emoji: '🔥',
    link:
        'https://open.spotify.com/intl-es/track/4RtPruLRZbyirtJGqYHPQm?si=db217fed0c374018',
  ),
  LovePhrase(
    text: 'BUSCARTE LEJOS O CERCA SIEMPRE TE VOY A ENCONTRAR',
    type: PhraseType.cancion,
    title: 'Buscarte Lejos',
    minute: '0:50',
    credits: 'Duki ft. Bizarrap — AMERI (2024)',
    emoji: '🔥',
    link:
        'https://open.spotify.com/intl-es/track/7b9hpzFQJaKUAAKsOeDafS?si=34f481b0c4f94f64',
  ),

  // ── KAROL G ──────────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'MI EX TENIA RAZON YO SOY TREMENDA',
    type: PhraseType.cancion,
    title: 'MI EX TENÍA RAZÓN',
    minute: '0:05',
    credits: 'KAROL G — Mañana Será Bonito Bichota Season (2024)',
    emoji: '💙',
    link:
        'https://open.spotify.com/intl-es/track/54zcJnb3tp9c5OVKREZ1Is?si=1d45de6652a545ec',
  ),
  LovePhrase(
    text: 'TUS GAFITAS ME ENCANTAN EN TU CARA',
    type: PhraseType.cancion,
    title: 'TUS GAFITAS',
    minute: '0:15',
    credits: 'KAROL G — Mañana Será Bonito (2023)',
    emoji: '💙',
    link:
        'https://open.spotify.com/intl-es/track/3gOI5aQD4mOMLsP3aWrkon?si=fbfcd11a8da14169',
  ),

  // ── RELS B ───────────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'UN VERANO EN MALLORCA SIN SALIR DE CASA',
    type: PhraseType.cancion,
    title: 'Un Verano En Mallorca',
    minute: '0:20',
    credits: 'Rels B — La Isla LP (2023)',
    emoji: '🌴',
    link:
        'https://open.spotify.com/intl-es/track/15tpxASJbTcAAfezvJfvuj?si=6d420658c9dd4bdb',
  ),
  LovePhrase(
    text: 'PA QUERERTE NECESITO TIEMPO',
    type: PhraseType.cancion,
    title: 'pa quererte',
    minute: '0:30',
    credits: 'Rels B — pa quererte (2025)',
    emoji: '🌴',
    link:
        'https://open.spotify.com/intl-es/track/0FDTPGlLjF8SGWSsHyzNBe?si=0d5727c2421d43d7',
  ),
  LovePhrase(
    text: 'VUELVE CONMIGO ESTA NOCHE',
    type: PhraseType.cancion,
    title: 'vuelve contigo',
    minute: '0:25',
    credits: 'Rels B — afroLOVA 25 (2025)',
    emoji: '🌴',
    link:
        'https://open.spotify.com/intl-es/track/4iXCSUkCTdCdNBgGmGm9nU?si=bd61bd7a51324d29',
  ),

  // ── KYGO ─────────────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'I NEED A FIRESTONE TO HOLD ME',
    type: PhraseType.cancion,
    title: 'Firestone',
    minute: '0:40',
    credits: 'Kygo ft. Conrad Sewell — Cloud Nine (2016)',
    emoji: '🌅',
    link:
        'https://open.spotify.com/intl-es/track/1I8tHoNBFTuoJAlh4hfVVE?si=082030ebaf3f4039',
  ),

  // ── POST MALONE ──────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'FALLIN IN LOVE AIN T HARD TO DO',
    type: PhraseType.cancion,
    title: "Fallin' In Love",
    minute: '0:20',
    credits: 'Post Malone — F-1 Trillion: Long Bed (2024)',
    emoji: '⭐',
    link:
        'https://open.spotify.com/intl-es/track/1QTNo6sCt8km4v3GyHRNlS?si=1b8f664ed3e9417b',
  ),

  // ── JUAN GABRIEL ─────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'ABRAZAME MUY FUERTE Y DIME QUE ME QUIERES',
    type: PhraseType.cancion,
    title: 'Abrázame Muy Fuerte',
    minute: '0:30',
    credits: 'Juan Gabriel — Abrázame Muy Fuerte (2000)',
    emoji: '🌟',
    link:
        'https://open.spotify.com/intl-es/track/2nejvFyJeTDtMRP2nUMt0J?si=e2d7e26ff9ab47de',
  ),

  // ── LIBERACIÓN ───────────────────────────────────────────────────────────────
  LovePhrase(
    text: 'COMO DECIRTE QUE TE QUIERO SIN PALABRAS',
    type: PhraseType.cancion,
    title: 'Cómo Decirte',
    minute: '0:35',
    credits: 'Liberación — Directo Al Corazón (2025)',
    emoji: '💌',
    link:
        'https://open.spotify.com/intl-es/track/54xnhGZCLwQNbZsXl976F7?si=5f89c78bb66d4107',
  ),

  // ── GARDENSTATE / BIEN ───────────────────────────────────────────────────────
  LovePhrase(
    text: 'THIS IS THE BEST PART OF ME',
    type: PhraseType.cancion,
    title: 'The Best Part',
    minute: '0:20',
    credits: 'gardenstate, Bien — Inspirations (2024)',
    emoji: '🎧',
    link:
        'https://open.spotify.com/intl-es/track/2OBaoP7DfWvlm4gc0QPkgg?si=6816a30bf8934395',
  ),
];

LovePhrase getRandomLovePhrase() {
  final random = Random();
  return kLovePhrases[random.nextInt(kLovePhrases.length)];
}
