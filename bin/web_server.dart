// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

import 'package:fmatch/fmatch.dart';
// import 'package:fmatch/pbatch.dart';
import 'package:fmatch/server.dart';
import 'package:fmatch/util.dart';

String _host = InternetAddress.loopbackIPv4.host;

class Command {
  final HttpRequest request;
  final String query;
  Command(this.request, this.query);
}

var commandStreamController = StreamController<Command>();
var commandStreamQueue = StreamQueue(commandStreamController.stream);
var josonEncoderWithIdent = JsonEncoder.withIndent('  ');
var servers = <Server>[];

Future main(List<String> args) async {
  print('Start Server');
  var matcher = FMatcher();
  await time(() => matcher.readSettings(null), 'Settings.read');
  if (args.isNotEmpty) {
    matcher.queryResultCacheSize =
        int.tryParse(args[0]) ?? matcher.queryResultCacheSize;
  }
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  print('Min Score: ${matcher.minScore}');

  final cacheServer = CacheServer();
  await cacheServer.spawn(matcher.queryResultCacheSize);
  for (var id = 0; id < matcher.serverCount; id++) {
    var server = Server(matcher, cacheServer);
    await server.spawn(id);
    servers.add(server);
    sendReceiveResponse(id);
  }

  var httpServer = await HttpServer.bind(_host, 4049);
  await for (var req in httpServer) {
    var contentType = req.headers.contentType;
    var response = req.response;

    if (req.method == 'GET') {
      try {
        var inputString = req.uri.queryParameters['q']!;
        commandStreamController.add(Command(req, inputString));
      } catch (e) {
        response
          ..statusCode = HttpStatus.internalServerError
          ..write('Parameter missing: $e.');
        await response.close();
      }
    } else if (req.method == 'POST' &&
        contentType?.mimeType == 'application/json') {
      response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${req.method}.');
      await response.close();
    } else {
      response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${req.method}.');
      await response.close();
    }
  }
}

Future<void> sendReceiveResponse(int id) async {
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
    var responseContent = josonEncoderWithIdent.convert(result);
    req.response
      ..statusCode = HttpStatus.ok
      ..write(responseContent);
    await response.close();
  }
}

// Future<void> pbatch(FMatcher matcher, HttpRequest request) async {
//   var batchResultPath = 'batch/results.csv';
//   var batchLogPath = 'batch/log.txt';
//   var resultFile = File(batchResultPath);
//   resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
//   resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
//   logSink = File(batchLogPath).openWrite(encoding: utf8);
//   startTime = DateTime.now();
//   lastLap = startTime;
//   currentLap = lastLap;
//   var queries = StreamQueue<String>(Stream.fromIterable([]) /* request.transform<String>() */);
//   // queries = StreamQueue<String>((await request.first);
//   final servers = <Server>[];
//   for (var id = 0; id < matcher.serverCount; id++) {
//     var server = Server(matcher);
//     await server.spawn(id);
//     servers.add(server);
//   }
//   await Dispatcher(servers, queries).dispatch();
// }
