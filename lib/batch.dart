// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'fmatch.dart';
import 'fmclasses.dart';
import 'preprocess.dart';
import 'util.dart';

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

Stream<String> openQueryListStream(String batchQueryPath) async* {
  await for (var line in readCsvLines(batchQueryPath)) {
    if (line.isEmpty) {
      continue;
    }
    var query = line[0];
    if (query == null || query == '') {
      continue;
    }
    yield query;
  }
}

String formatOutput(int ix, QueryResult result) {
  var csvLine = StringBuffer();
  if (result.cachedResult.matchedEntiries.isEmpty) {
    result.cachedResult.matchedEntiries.add(MatchedEntry(Entry(''), 0.0));
  }
  for (var e in result.cachedResult.matchedEntiries) {
    csvLine.write(result.serverId);
    csvLine.write(r',');
    csvLine.write(
        (result.durationInMilliseconds.toDouble() / 1000.0).toStringAsFixed(3));
    csvLine.write(r',');
    csvLine.write(ix);
    csvLine.write(r',');
    csvLine
        .write((e.score / result.cachedResult.queryScore).toStringAsFixed(2));
    csvLine.write(r',');
    csvLine.write(result.cachedResult.matchedEntiries.length);
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(result.rawQuery.string));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.entry.string));
    csvLine.write(r',');
    csvLine.write(result.cachedResult.cachedQuery.letType.name);
    for (var e in result.cachedResult.cachedQuery.terms) {
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e.string));
    }
    csvLine.write('\r\n');
  }
  return csvLine.toString();
}
