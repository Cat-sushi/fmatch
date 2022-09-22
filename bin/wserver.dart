// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:args/args.dart';
import 'package:async/async.dart';

import 'package:fmatch/fmatch.dart';
import 'package:fmatch/server.dart';
import 'package:fmatch/util.dart';

String _host = InternetAddress.loopbackIPv4.host;
int serverCount = Platform.numberOfProcessors;

class Command {
  final HttpResponse response;
  final String query;
  Command(this.response, this.query);
}

var commandStreamController = StreamController<Command>();
var commandStreamQueue = StreamQueue(commandStreamController.stream);
var commandQueueLength = 0;
var maxCommandQueueLength = 10;
var josonEncoderWithIdent = JsonEncoder.withIndent('  ');

Future main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print tis help')
    ..addOption('server', abbr: 's', valueHelp: 'number of servers')
    ..addOption('queue', abbr: 'q', valueHelp: 'length of command queue')
    ..addOption('cache', abbr: 'c', valueHelp: 'size of result cache');
  var options = argParser.parse(args);
  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }
  print('Start Server');
  var matcher = FMatcher();
  await time(() => matcher.readSettings(null), 'Settings.read');
  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache']! as String) ??
        matcher.queryResultCacheSize;
  }
  if (options['server'] != null) {
    serverCount = max(
        int.tryParse(options['server'] as String) ?? serverCount, 1);
  }
  if (options['queue'] != null) {
    maxCommandQueueLength = max(
        int.tryParse(options['queue'] as String) ?? maxCommandQueueLength,
        serverCount);
  }
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  print('Min Score: ${matcher.minScore}');

  final cacheServer = await CacheServer.spawn(matcher.queryResultCacheSize);
  for (var id = 0; id < serverCount; id++) {
    sendReceiveResponse(id, matcher, cacheServer);
  }

  var httpServer = await HttpServer.bind(_host, 4049);
  await for (var req in httpServer) {
    var contentType = req.headers.contentType;
    var response = req.response;

    if (req.method == 'GET') {
      if (commandQueueLength >= maxCommandQueueLength) {
        response
          ..statusCode = HttpStatus.serviceUnavailable
          ..write('Server busiy');
        await response.close();
        continue;
      }
      try {
        var inputString = req.uri.queryParameters['q']!;
        commandStreamController.add(Command(req.response, inputString));
        commandQueueLength++;
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

Future<void> sendReceiveResponse(
    int id, FMatcher matcher, SendPort cacheServer) async {
  var client = Client();
  await client.spawnServer(matcher, cacheServer);
  while (await commandStreamQueue.hasNext) {
    var command = await commandStreamQueue.next;
    var result = await client.fmatch(command.query);
    commandQueueLength--;
    result.serverId = id;
    var responseContent = josonEncoderWithIdent.convert(result);
    command.response
      ..statusCode = HttpStatus.ok
      ..write(responseContent);
    command.response.close();
  }
  client.closeServer();
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
