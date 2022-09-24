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
final commandStreamController = StreamController<HttpRequest>();
final commandStreamQueue = StreamQueue(commandStreamController.stream);
var commandQueueLength = 0;
var maxCommandQueueLength = 10;
var josonEncoderWithIdent = JsonEncoder.withIndent('  ');

final batchStreamController = StreamController<HttpRequest>();
final batchStreamQueue = StreamQueue(batchStreamController.stream);
var batchQueueLength = 0;
var maxBatchQueueLength = 10;

final serverPoolController = StreamController<Client>();
final serverPool = StreamQueue(serverPoolController.stream);

final matcher = FMatcher();
late final SendPort cacheServer;

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
    maxBatchQueueLength = maxCommandQueueLength;
  }
  
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  print('Min Score: ${matcher.minScore}');

  cacheServer = await CacheServer.spawn(matcher.queryResultCacheSize);

  for (var id = 0; id < serverCount; id++) {
    var c = Client(id);
    await c.spawnServer(matcher, cacheServer);
    serverPoolController.add(c);
  }

  for (var i = 0; i < serverCount; i++) {
    sendReceiveResponseOne();
  }

  sendReceiveResponseMulti();

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
      commandQueueLength++;
      commandStreamController.add(req);
    } else if (req.method == 'POST' &&
        contentType?.mimeType == 'application/json') {
      if (batchQueueLength >= maxBatchQueueLength) {
        response
          ..statusCode = HttpStatus.serviceUnavailable
          ..write('Batch server busiy');
        await response.close();
        continue;
      }
      batchQueueLength++;
      batchStreamController.add(req);
    } else {
      response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${req.method}.');
      await response.close();
    }
  }
}

Future<void> sendReceiveResponseOne() async {
  while (await commandStreamQueue.hasNext) {
    var req = await commandStreamQueue.next;
    try {
      var query = req.uri.queryParameters['q']!;
      var client = await serverPool.next;
      var result = await client.fmatch(query);
      serverPoolController.add(client);
      var responseContent = josonEncoderWithIdent.convert(result);
      req.response
        ..statusCode = HttpStatus.ok
        ..write(responseContent);
    } catch (e) {
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal Server Error: $e.');
    } finally {
      req.response.close();
      commandQueueLength--;
    }
  }
}

Future<void> sendReceiveResponseMulti() async {
  while (await batchStreamQueue.hasNext) {
    var req = await batchStreamQueue.next;
    try {
      var jsonString =
          await req.cast<List<int>>().transform(utf8.decoder).join();
      var queryList = (jsonDecode(jsonString) as List<dynamic>).cast<String>();
      var queries = StreamQueue<String>(Stream.fromIterable(queryList));
      await Dispatcher(queries, req.response).dispatch();
    } catch (e) {
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal Server Error: $e.');
      req.response.close();
    } finally {
      batchQueueLength--;
    }
  }
}

class Dispatcher {
  final StreamQueue<String> queries;
  final HttpResponse response;
  final results = <int, QueryResult>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  var first = true;
  Dispatcher(this.queries, this.response);
  
  Future<void> dispatch() async {
    response.write('[');
    var futures = <Future>[];
    for (var i = 0; i < serverCount; i++) {
      futures.add(sendReceve());
    }
    await Future.wait<void>(futures);
    response.write(']');
    response.close();
  }

  Future<void> sendReceve() async {
    while (await queries.hasNext) {
      var ix = ixS;
      ixS++;
      var query = await queries.next;
      var client = await serverPool.next;
      var result = await client.fmatch(query);
      serverPoolController.add(client);
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
      if (first) {
        first = false;
      } else {
        response.write(',');
      }
      response.write(jsonEncode(result));
      results.remove(ixO);
    }
  }
}
