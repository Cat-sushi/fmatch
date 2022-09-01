// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

import 'package:fmatch/fmatch.dart';
import 'package:fmatch/server.dart';
import 'package:fmatch/util.dart';

String _host = InternetAddress.loopbackIPv4.host;

class Command {
  final HttpRequest request;
  final String query;
  Command(this.request, this.query);
}

var matcher = FMatcher();
var commandStreamController = StreamController<Command>();
var commandStreamQueue = StreamQueue(commandStreamController.stream);
var josonEncoderWithIdent = JsonEncoder.withIndent('  ');
var servers = <Server>[];

Future main() async {
  print('Start Server');
  await time(() => matcher.readSettings(null), 'Settings.read');
  matcher.queryResultCacheSize = 0;
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  print('Min Score: ${matcher.minScore}');

  for (var id = 0; id < matcher.serverCount; id++) {
    servers.add(Server(matcher)..spawn(id));
    sendReceive(id);
  }

  var httpServer = await HttpServer.bind(_host, 4049);
  await for (var req in httpServer) {
    var contentType = req.headers.contentType;
    var response = req.response;

    if (req.method == 'POST' && contentType?.mimeType == 'application/json') {
      response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${req.method}.');
      await response.close();
      // try {
      //   var content = await utf8.decoder.bind(req).join();
      //   commandQueue.add(Command(req, content));
      //   var inputStrings = jsonDecode(content) as List<String>;
      //   var results =
      //       inputStrings.map((q) => matcher.fmatch(q)).toList(growable: false);
      //   var responseContent = jsonEncode(results);
      //   req.response
      //     ..statusCode = HttpStatus.ok
      //     ..write(responseContent);
      // } catch (e) {
      //   response
      //     ..statusCode = HttpStatus.internalServerError
      //     ..write('Exception during file I/O: $e.');
      // }
    } else if (req.method == 'GET') {
      try {
        var inputString = req.uri.queryParameters['q']!;
        commandStreamController.add(Command(req, inputString));
      } catch (e) {
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('hogehoge: $e.');
        await response.close();
      }
    } else {
      response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${req.method}.');
      await response.close();
    }
  }
}

Future<void> sendReceive(int id) async {
  var server = servers[id];
  while (await commandStreamQueue.hasNext) {
    var command = await commandStreamQueue.next;
    var query = command.query;
    var req = command.request;
    var response = req.response;
    server.csp.send(query);
    await server.cri.moveNext();
    var result = server.cri.current as QueryResult;
    result.serverId = id;
    var responseContent = josonEncoderWithIdent.convert([result]);
    req.response
      ..statusCode = HttpStatus.ok
      ..write(responseContent);
    await response.close();
  }
  print('Server $id exited');
}
