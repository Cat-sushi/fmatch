// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';
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
  if (!queryPath.endsWith('.csv')) {
    print('Invalid input file name: $queryPath');
    exit(1);
  }
  var queries = StreamQueue<String>(openQueryListStream(queryPath));
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultPath = '${trank}_results.csv';
  var logPath = '${trank}_log.txt';
  var resultFile = File(resultPath);
  resultSink = resultFile.openWrite()..write(utf8Bom);
  logSink = File(logPath).openWrite();
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  await Dispatcher(matcher, queries).dispatch();
}

class Dispatcher {
  Dispatcher(this.matcher, this.queries);
  final FMatcher matcher;
  final StreamQueue<String> queries;
  final results = <int, QueryResult>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  var cacheHits = 0;
  var cacheHits2 = 0;
  Future<void> dispatch() async {
    var futures = List<Future>.generate(serverCount, (i) => sendReceve());
    await Future.wait<void>(futures);
    print('Max result buffer length: $maxResultsLength');
    await logSink.close();
    await resultSink.close();
  }

  Future<void> sendReceve() async {
    while (true) {
      var queryRef = await queries.take(1);
      if (queryRef.isEmpty) {
        break;
      }
      var query = queryRef[0];
      var ix = ixS;
      ixS++;
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
        logSink.writeln(result.message);
        continue;
      }
      if (result.message != '') {
        cacheHits++;
        cacheHits2++;
      }
      resultSink.write(formatOutput(ixO + 1, result));
      if (((ixO + 1) % 100) == 0) {
        currentLap = DateTime.now();
        print('${ixO + 1}\t${currentLap.difference(startTime).inMilliseconds}'
            '\t${currentLap.difference(lastLap).inMilliseconds}'
            '\t\t$cacheHits2\t$cacheHits');
        cacheHits2 = 0;
        lastLap = currentLap;
      }
      results.remove(ixO);
    }
  }
}
