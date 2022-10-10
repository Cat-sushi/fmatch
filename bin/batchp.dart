// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:fmatch/bparts.dart';

import 'package:fmatch/fmatch.dart';
import 'package:fmatch/fmclasses.dart';
import 'package:fmatch/server.dart';
import 'package:fmatch/util.dart';

late IOSink resultSink;
late IOSink logSink;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

late SendPort cacheServer;
int serverCount = Platform.numberOfProcessors;

final serverPoolController = StreamController<Client>();
final serverPool = StreamQueue(serverPoolController.stream);

void main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print tis help')
    ..addOption('server', abbr: 's', valueHelp: 'number of servers')
    ..addOption('cache', abbr: 'c', valueHelp: 'size of result cache')
    ..addOption('input', abbr: 'i', valueHelp: 'input file');
  var options = argParser.parse(args);
  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }
  var matcher = FMatcher();
  print('Start Parallel Batch');
  await time(() => matcher.readSettings(null), 'settings.read');
  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache']! as String) ??
        matcher.queryResultCacheSize;
  }
  if (options['server'] != null) {
    serverCount =
        max(int.tryParse(options['server'] as String) ?? serverCount, 1);
  }
  var queryPath = options['input'] as String? ?? 'batch/queries.csv';
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');

  cacheServer = await CacheServer.spawn(matcher.queryResultCacheSize);

  for (var id = 0; id < serverCount; id++) {
    var c = Client(id);
    await c.spawnServer(matcher, cacheServer);
    serverPoolController.add(c);
  }

  await time(() => pbatch(matcher, queryPath), 'pbatch');

  CacheServer.close(cacheServer);
  for (var i = 0; i < serverCount; i++) {
    (await serverPool.next).closeServer();
  }

  exit(0);
}

Future<void> pbatch(FMatcher matcher, String queryPath) async {
  if(! queryPath.endsWith('.csv')) {
    print('Invalid input file name: $queryPath');
    exit(1);
  }
  var queries = StreamQueue<String>(openQueryListStream(queryPath));
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultPath = '${trank}_results.csv';
  var logPath = '${trank}_log.txt';  var resultFile = File(resultPath);
  resultSink = resultFile.openWrite()..write(utf8Bom);
  logSink = File(logPath).openWrite();
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  await Dispatcher(matcher, queries).dispatch();
}

class Dispatcher {
  final FMatcher matcher;
  final StreamQueue<String> queries;
  final results = <int, QueryResult>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  Dispatcher(this.matcher, this.queries);
  Future<void> dispatch() async {
    var futures = List<Future>.generate(serverCount, (i) => sendReceve());
    await Future.wait<void>(futures);
    print('Max result buffer length: $maxResultsLength');
    await logSink.close();
    await resultSink.close();
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

  Future<void> printResultsInOrder() async {
    for (; ixO < ixS; ixO++) {
      var result = results[ixO];
      if (result == null) {
        return;
      }
      if (result.cachedResult.cachedQuery.terms.isEmpty) {
        continue;
      }
      if (result.message != '') {
        logSink.writeln(result.message);
      }
      resultSink.write(formatOutput(ixO + 1, result));
      if (((ixO + 1) % 100) == 0) {
        currentLap = DateTime.now();
        print('${ixO + 1}: ${currentLap.difference(startTime).inMilliseconds} '
            '${currentLap.difference(lastLap).inMilliseconds}');
        lastLap = currentLap;
      }
      results.remove(ixO);
    }
  }
}
