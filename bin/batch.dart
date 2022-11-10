// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2020, 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';

import 'package:args/args.dart';

import 'package:fmatch/bparts.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/util.dart';

Future<void> main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print tis help')
    ..addOption('server', abbr: 's', valueHelp: 'number of servers')
    ..addOption('queue', abbr: 'q', valueHelp: 'length of command queue')
    ..addOption('cache', abbr: 'c', valueHelp: 'size of result cache')
    ..addOption('input', abbr: 'i', valueHelp: 'input file');
  var options = argParser.parse(args);
  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }
  print('Start Batch');
  var matcher = FMatcher();
  await time(() => matcher.readSettings(null), 'settings.read');
  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache']! as String) ??
        matcher.queryResultCacheSize;
  }
  var queryPath = options['input'] as String? ?? 'batch/queries.csv';
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  await time(() => batch(matcher, queryPath), 'batch');
}

Future<void> batch(FMatcher matcher, String queryPath) async {
  if (!queryPath.endsWith('.csv')) {
    print('Invalid input file name: $queryPath');
    exit(1);
  }
  var queries = openQueryListStream(queryPath);
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultPath = '${trank}_results.csv';
  var logPath = '${trank}_log.txt';
  var resultFile = File(resultPath);
  var resultSink = resultFile.openWrite()..add(utf8Bom);
  var logSink = File(logPath).openWrite();
  var lc = 0;
  var cacheHits = 0;
  var cacheHits2 = 0;
  var startTime = DateTime.now();
  var lastLap = startTime;
  var currentLap = lastLap;

  await for (var query in queries) {
    ++lc;
    var result = await matcher.fmatch(query);
    if (result.cachedResult.cachedQuery.terms.isEmpty) {
      logSink.writeln(result.message);
      continue;
    }
    if (result.message != '') {
      cacheHits++;
      cacheHits2++;
    }
    resultSink.write(formatOutput(lc, result));
    if ((lc % 100) == 0) {
      currentLap = DateTime.now();
      print('$lc\t${currentLap.difference(startTime).inMilliseconds}'
          '\t${currentLap.difference(lastLap).inMilliseconds}'
          '\t\t$cacheHits2\t$cacheHits');
      cacheHits2 = 0;
      lastLap = currentLap;
      await resultSink.flush();
      await logSink.flush();
    }
  }
  await logSink.close();
  await resultSink.close();
}
