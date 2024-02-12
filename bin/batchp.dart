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
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/src/bparts.dart';
import 'package:fmatch/src/util.dart';

late IOSink resultSink;
late IOSink logSink;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

late SendPort cacheServer;
int serverCount = Platform.numberOfProcessors;

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
  await matcher.init();
  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache']! as String) ??
        matcher.queryResultCacheSize;
  }
  if (options['server'] != null) {
    serverCount =
        max(int.tryParse(options['server'] as String) ?? serverCount, 1);
  }
  var queryPath = options['input'] as String? ?? 'batch/queries.csv';

  var matcherp = FMatcherP.fromFMatcher(matcher, serverCount: serverCount);
  await matcherp.startServers();

  await time(() => pbatch(matcherp, queryPath), 'pbatch');

  await matcherp.stopServers();
}

Future<void> pbatch(FMatcherP matcherp, String queryPath) async {
  if (!queryPath.endsWith('.csv')) {
    print('Invalid input file name: $queryPath');
    exit(1);
  }
  var queries = StreamQueue<String>(openQueryListStream(queryPath));
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultPath = '${trank}_results.csv';
  var logPath = '${trank}_log.txt';
  var resultFile = File(resultPath);
  resultSink = resultFile.openWrite()..add(utf8Bom);
  logSink = File(logPath).openWrite();
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;

  var lc = 0;
  var cacheHits = 0;
  var cacheHits2 = 0;
  while (true) {
    var bulk = await queries.take(100);
    if (bulk.isEmpty) {
      break;
    }
    var results = await matcherp.fmatchb(bulk);
    for (var result in results) {
      lc++;
      if (result.cachedResult.cachedQuery.terms.isEmpty) {
        logSink.writeln(result.message);
        continue;
      }
      if (result.message != '') {
        cacheHits++;
        cacheHits2++;
      }
      resultSink.write(formatOutput(lc, result));
    }
    currentLap = DateTime.now();
    print('$lc\t${currentLap.difference(startTime).inMilliseconds}'
        '\t${currentLap.difference(lastLap).inMilliseconds}'
        '\t\t$cacheHits2\t$cacheHits');
    cacheHits2 = 0;
    lastLap = currentLap;
    await resultSink.flush();
    await logSink.flush();
  }
  await resultSink.flush();
  await logSink.flush();
}
