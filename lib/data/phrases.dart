// lib/data/love_phrases_data.dart
import 'dart:math';
import '../models/phrase.dart';

// Emoticones de ejemplo (¡CAMBIA ESTOS POR LOS ANIMALES FAVORITOS DE TU NOVIA!)
// Ejemplos: 🐶 (perro), 🐱 (gato), 🐻 (oso), 🐰 (conejo), 🦋 (mariposa), 🐧 (pingüino)
const List<String> favoriteAnimalEmojis = [
  '🐶', // Perro
  '🐱', // Gato
  '🐰', // Conejo
  '🐧', // Pingüino
  '🐨', // Koala
];

const List<LovePhrase> lovePhrases = [
  LovePhrase(
    text: "Mi amor por ti es como el universo, infinito e inmenso.",
    emoji: '✨',
  ),
  LovePhrase(text: "Cada día a tu lado es mi día favorito.", emoji: '❤️'),
  LovePhrase(
    text: "Eres mi persona favorita en todo el mundo, hoy y siempre.",
    emoji: '🥰',
  ),
  LovePhrase(
    text: "Contigo, cada momento se convierte en un hermoso recuerdo.",
    emoji: '📸',
  ),
  LovePhrase(
    text: "No sabía lo que era el amor verdadero hasta que te conocí.",
    emoji: '💖',
  ),
  LovePhrase(
    text: "Tu sonrisa es la melodía más hermosa que mis ojos han visto.",
    emoji: '😊',
  ),
  LovePhrase(text: "Mi lugar favorito en el mundo es a tu lado.", emoji: '🏡'),
  LovePhrase(
    text: "Eres la respuesta a todas mis oraciones y el deseo de mi corazón.",
    emoji: '🙏',
  ),
  LovePhrase(
    text: "Quiero pasar el resto de mi vida descubriendo el resto de ti.",
    emoji: '🔎',
  ),
  LovePhrase(
    text: "Incluso en mis sueños, tu eres mi dulce realidad.",
    emoji: '💭',
  ),
  LovePhrase(text: "Gracias por existir y por hacerme tan feliz.", emoji: '🥳'),
  LovePhrase(
    text: "Eres mi inspiración, mi fortaleza y mi mayor alegría.",
    emoji: '💪',
  ),
  LovePhrase(
    text:
        "Solo necesito tres cosas en la vida: el sol para el día, la luna para la noche y tú para siempre.",
    emoji: '☀️🌙',
  ),
  LovePhrase(
    text: "Cada historia de amor es hermosa, pero la nuestra es mi favorita.",
    emoji: '📖',
  ),
  LovePhrase(
    text: "Desde que estás en mi vida, cada día es una aventura emocionante.",
    emoji: '🚀',
  ),
  // ¡Añade más frases personales aquí!
  LovePhrase(text: "Eres la razón por la que creo en la magia.", emoji: '💫'),
  LovePhrase(text: "Mi corazón te pertenece por completo.", emoji: '💘'),
  LovePhrase(text: "Tu amor es el tesoro más grande que tengo.", emoji: '💎'),
  LovePhrase(text: "Amo cada pequeño detalle de ti.", emoji: '🤩'),
  LovePhrase(text: "Estar contigo es mi fantasía hecha realidad.", emoji: '🌈'),
  LovePhrase(
    text: "Mi amor, eres mi sol, mi luna y todas mis estrellas.",
    emoji: '🌟',
  ),
  LovePhrase(
    text: "Prometo amarte y cuidarte cada día de mi vida.",
    emoji: '💍',
  ),
  LovePhrase(text: "Solo quiero envejecer a tu lado.", emoji: '👴👵'),
  LovePhrase(text: "Cada momento contigo es un regalo.", emoji: '🎁'),
  LovePhrase(text: "Eres mi refugio, mi paz y mi alegría.", emoji: '🧘‍♀️'),
  LovePhrase(text: "Tu amor es la melodía que alegra mi alma.", emoji: '🎶'),
  LovePhrase(text: "Contigo, la vida es una obra de arte.", emoji: '🎨'),
  LovePhrase(
    text: "Eres la persona que ilumina mis días más oscuros.",
    emoji: '💡',
  ),
  LovePhrase(text: "Mi amor por ti crece con cada amanecer.", emoji: '🌅'),
  LovePhrase(text: "Gracias por ser mi cómplice en cada locura.", emoji: '😈'),
];

// Función para obtener una frase de amor aleatoria con un emoticón de animal favorito
LovePhrase getRandomLovePhrase() {
  final random = Random();
  final int phraseIndex = random.nextInt(lovePhrases.length);
  final int emojiIndex = random.nextInt(favoriteAnimalEmojis.length);

  return LovePhrase(
    text: lovePhrases[phraseIndex].text,
    emoji:
        favoriteAnimalEmojis[emojiIndex], // Usa un emoticón de animal aleatorio
  );
}
