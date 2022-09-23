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
import 'package:fmatch/fmclasses.dart';
import 'package:fmatch/server.dart';
import 'package:fmatch/util.dart';

String _host = InternetAddress.loopbackIPv4.host;
int serverCount = Platform.numberOfProcessors;
var commandStreamController = StreamController<Command>();
var commandStreamQueue = StreamQueue(commandStreamController.stream);
var commandQueueLength = 0;
var maxCommandQueueLength = 10;
var josonEncoderWithIdent = JsonEncoder.withIndent('  ');
var batchQueueLength = 0;
var maxBatchQueueLength = 1;

late final FMatcher matcher;
late final SendPort cacheServer;
final serverPool = <Client>[];

class Command {
  final HttpResponse response;
  final String query;
  Command(this.response, this.query);
}

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
  matcher = FMatcher();
  await time(() => matcher.readSettings(null), 'Settings.read');
  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache']! as String) ??
        matcher.queryResultCacheSize;
  }
  if (options['server'] != null) {
    serverCount =
        max(int.tryParse(options['server'] as String) ?? serverCount, 1);
  }
  if (options['queue'] != null) {
    maxCommandQueueLength = max(
        int.tryParse(options['queue'] as String) ?? maxCommandQueueLength,
        serverCount);
  }
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  print('Min Score: ${matcher.minScore}');

  cacheServer = await CacheServer.spawn(matcher.queryResultCacheSize);
  for (var id = 0; id < serverCount; id++) {
    sendReceiveResponseOne(id, matcher, cacheServer);
  }

  for (var id = 0; id < serverCount; id++) {
    // for batch
    var c = Client();
    await c.spawnServer(matcher, cacheServer);
    serverPool.add(c);
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
      if (batchQueueLength >= maxBatchQueueLength) {
        response
          ..statusCode = HttpStatus.serviceUnavailable
          ..write('Batch server busiy');
        await response.close();
        continue;
      }
      try {
        pbatch(req);
      } catch (e) {
        response
          ..statusCode = HttpStatus.methodNotAllowed
          ..write('Unsupported request: ${req.method}.');
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

Future<void> sendReceiveResponseOne(
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

Future<void> pbatch(HttpRequest req) async {
  batchQueueLength++;
  var jsonString = await req.cast<List<int>>().transform(utf8.decoder).join();
  var queryList = (jsonDecode(jsonString) as List<dynamic>).cast<String>();
  var queries = StreamQueue<String>(Stream.fromIterable(queryList));
  await Dispatcher(matcher, queries, req.response).dispatch();
  batchQueueLength--;
}

class Dispatcher {
  final FMatcher matcher;
  final StreamQueue<String> queries;
  final HttpResponse response;
  final results = <int, QueryResult>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  var first = true;
  Dispatcher(this.matcher, this.queries, this.response);
  Future<void> dispatch() async {
    response.write('[');
    var futures = <Future>[];
    for (var id = 0; id < serverCount; id++) {
      futures.add(sendReceve(id));
    }
    await Future.wait<void>(futures);
    response.write(']');
    response.close();
  }

  Future<void> sendReceve(int id) async {
    var client = serverPool[id];
    while (await queries.hasNext) {
      var ix = ixS;
      ixS++;
      var query = await queries.next;
      var result = await client.fmatch(query);
      result.serverId = id;
      results[ix] = result;
      maxResultsLength = max(results.length, maxResultsLength);
      printResultsInOrder();
    }
 }

  void printResultsInOrder() {
    for (; ixO < ixS; ixO++) {
      var result = results[ixO];
      if (result == null) {
        return;
      }
      if(first){
        first = false;
      } else {
        response.write(',');
      }
      response.write(jsonEncode(result));
      results.remove(ixO);
    }
  }
}
