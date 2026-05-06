import 'dart:io';
import 'dart:convert';

void main() async {
  // Bind to all interfaces to ensure visibility
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server running on http://localhost:${server.port}');
  print('Updating database.json in: ${Directory.current.path}');

  await for (HttpRequest request in server) {
    // Handle CORS preflight request
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    if (request.method == 'POST') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final File file = File('database.json');
        await file.writeAsString(content);
        
        print('SUCCESS: database.json updated at ${DateTime.now().hour}:${DateTime.now().minute}');
        
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'status': 'ok'}))
          ..close();
      } catch (e) {
        print('ERROR: $e');
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      }
    } else {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
    }
  }
}
