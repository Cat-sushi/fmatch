// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import 'package:fmatch/bparts.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/util.dart';

Future<void> main(List<String> args) async {
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
  print('Start Batch');
  var matcher = FMatcher();
  await time(() => matcher.readSettings(null), 'settings.read');
  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache']! as String) ??
        matcher.queryResultCacheSize;
  }
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  await time(() => batch(matcher), 'batch');
}

Future<void> batch(FMatcher matcher, [String path = 'batch']) async {
  var batchQueryPath = '$path/queries.csv';
  var batchResultPath = '$path/results.csv';
  var batchLogPath = '$path/log.txt';
  var resultFile = File(batchResultPath);
  resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
  var resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
  var logSink = File(batchLogPath).openWrite(encoding: utf8);
  var lc = 0;
  var startTime = DateTime.now();
  var lastLap = startTime;
  var currentLap = lastLap;

  await for (var query in openQueryListStream(batchQueryPath)) {
    ++lc;
    var result = await matcher.fmatch(query);
    if (result.cachedResult.cachedQuery.terms.isEmpty) {
      continue;
    }
    if (result.message != '') {
      logSink.writeln(result.message);
    }
    resultSink.write(formatOutput(lc, result));
    if ((lc % 100) == 0) {
      currentLap = DateTime.now();
      print('$lc: ${currentLap.difference(lastLap).inMilliseconds} '
          '${currentLap.difference(startTime).inMilliseconds}');
      lastLap = currentLap;
      await resultSink.flush();
      await logSink.flush();
    }
  }
  await logSink.close();
  await resultSink.close();
}