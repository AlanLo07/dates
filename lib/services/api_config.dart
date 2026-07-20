// lib/services/api_config.dart

class ApiConfig {
  static const String baseUrl =
      'https://ujq4e9csj9.execute-api.us-east-2.amazonaws.com/';

  // Rutas de cada recurso
  static const String citasPath = '/planes';
  static const String eventosPath = '/citas';
  static const String phrases = '/love-phrases';
  static const String kamaPath = '/kamasutra';
  static const String dicePath = '/dice';
  static const String challengesPath = '/challenges';
  static const String mascotImagesPath = '/images/home-mascot-images';
  static const String uploadPath = '/images/upload-url';
  // Agrega aquí las rutas que necesites en el futuro
}
