import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http_server/http_server.dart';

Future<String> getFileData(String path) async {
  return await rootBundle.loadString(path);
}

class PreviewServer {
  int port;
  File preview;
  VirtualDirectory staticServer;

  PreviewServer({ this.port }) {
    staticServer = new VirtualDirectory('.');
  }

  start() {
    HttpServer.bind(InternetAddress.anyIPv6, port).then((server) {
      server.listen(handleRequest);
    });
  }

  handleRequest(HttpRequest request) async {
    var url = request.uri.path;

    if (url.contains("preview")) {
      if (preview == null) {
        request.response.statusCode = 200;
        request.response.close();
      } else {
        staticServer.serveFile(preview, request);
      }
    } else {
      request.response.statusCode = 200;
      request.response.headers.set("Content-Type", ContentType.html.mimeType);
      request.response.write("""
        <h1>Webcam Flutter</h1>

        <img src="" id="preview" />
        
        <script type="text/javascript">
            var preview = document.getElementById("preview");
            setInterval(function() {
                preview.src = "http://localhost:$port/preview/?hash=" + Math.random();
            }, 100);
        </script>
      """);
      request.response.close();
    }
  }
}