// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9

import 'dart:io';
import 'dart:convert';
import 'package:fmatch/util.dart';
import 'package:fmatch/configs.dart';
import 'package:fmatch/database.dart';
import 'package:fmatch/fmatch.dart';

String _host = InternetAddress.loopbackIPv4.host;

Future main() async {
  print('Start Server');
  await time(() => Settings.read(), 'Settings.read');
  await time(() => Configs.read(), 'Configs.read');
  await time(() => buildDb(), 'buildDb');
  print('Min Score: $minScore');

  var josonEncoderWithIdent = JsonEncoder.withIndent('  ');

  var server = await HttpServer.bind(_host, 4049);
  await for (var req in server) {
    var contentType = req.headers.contentType;
    var response = req.response;

    if (req.method == 'POST' && contentType?.mimeType == 'application/json') {
      try {
        var content = await utf8.decoder.bind(req).join();
        var inputStrings = jsonDecode(content) as List<String>;
        var results = inputStrings.map((q) => fmatch(q)).toList(growable: false);
        var responseContent = jsonEncode(results);
        req.response
          ..statusCode = HttpStatus.ok
          ..write(responseContent);
      } catch (e) {
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('Exception during file I/O: $e.');
      }
    // } else if(req.method == 'GET' && contentType?.mimeType == 'application/text') {
    } else if(req.method == 'GET') {
      try {
        var inputString = req.uri.queryParameters['q'];
        var result = fmatch(inputString);
        var responseContent = josonEncoderWithIdent.convert([result]);
        req.response
          ..statusCode = HttpStatus.ok
          ..write(responseContent);
      } catch (e) {
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('Exception during file I/O: $e.');
      }
    } else {
      response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${req.method}.');
      continue;
    }
    await response.close();
  }
}