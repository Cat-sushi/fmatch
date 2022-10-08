// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:fmatch/bparts.dart';

import 'package:fmatch/fmclasses.dart';
import 'package:fmatch/util.dart';

late IOSink resultSink;
late IOSink logSink;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

var bulkSize = 100;
var lc = 0;

void main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print tis help')
    ..addOption('bulk', abbr: 'b', valueHelp: 'bulk size of request')
    ..addOption('input', abbr: 'i', valueHelp: 'input file');
  var options = argParser.parse(args);
  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }

  print('Start Web Bulk Batch');

  if (options['bulk'] != null) {
    bulkSize = max(int.tryParse(options['bulk'] as String) ?? bulkSize, 1);
  }
  var queryPath = options['input'] as String? ?? 'batch/queries.csv';

  await time(() => wbatch(queryPath), 'wbatch');
}

Future<void> wbatch(String queryPath) async {
  if(! queryPath.endsWith('.csv')) {
    print('Invalid input file name: $queryPath');
    exit(1);
  }
  var queries = StreamQueue<String>(openQueryListStream(queryPath));
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultPath = '${trank}_results.csv';
  var logPath = '${trank}_log.txt';
  var resultFile = File(resultPath);
  resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
  resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
  logSink = File(logPath).openWrite(encoding: utf8);
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  var httpClient = HttpClient();
  var jsonEnc = JsonUtf8Encoder();

  while (await queries.hasNext) {
    var bulk = jsonEnc.convert(await queries.take(bulkSize));
    var request = await httpClient.post('localhost', 4049, '');
    request.headers.contentType = ContentType('application', 'json');
    request.add(bulk);
    var response = await request.close();
    var jsonString = await response.transform(utf8.decoder).join();
    var jsons = (jsonDecode(jsonString) as List);
    var results = jsons
        .map<QueryResult>(
            (dynamic e) => QueryResult.fromJson(e as Map<String, dynamic>))
        .toList();
    outputResults(results);
  }
  httpClient.close();
  await logSink.close();
  await resultSink.close();
}

Future<void> outputResults(Iterable<QueryResult> results) async {
  for (var result in results) {
    ++lc;
    if (result.cachedResult.cachedQuery.terms.isEmpty) {
      continue;
    }
    if (result.message != '') {
      logSink.writeln(result.message);
    }
    resultSink.write(formatOutput(lc, result));
    if ((lc % 100) == 0) {
      currentLap = DateTime.now();
      print('$lc: ${currentLap.difference(startTime).inMilliseconds} '
          '${currentLap.difference(lastLap).inMilliseconds}');
      lastLap = currentLap;
    }
  }
}
