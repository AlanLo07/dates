import 'dart:io';

void main(List<String> args) {
  final outPath = args.isNotEmpty ? args[0] : 'web/custom_index.html';
  final title = args.length > 1 ? args[1] : 'Página estática generada';
  final content =
      '''<!doctype html>
<html lang="es">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>$title</title>
  </head>
  <body>
    <h1>$title</h1>
    <p>Generado por <code>tool/generate_index.dart</code>.</p>
  </body>
</html>
''';

  final file = File(outPath);
  file.createSync(recursive: true);
  file.writeAsStringSync(content);
  stdout.writeln('Archivo generado: $outPath');
}
