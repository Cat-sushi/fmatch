// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'database.dart';
import 'fmatch.dart';
import 'util.dart';

Future<void> batch(FMatcher matcher, [String path = 'lib/batch']) async {
  var batchQueryPath = '$path/queries.csv';
  var batchResultPath = '$path/results.csv';
  var batchLogPath = '$path/Log.txt';
  var resultFile = File(batchResultPath);
  resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
  var resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
  var logSink = File(batchLogPath).openWrite(encoding: utf8);
  var lc = 0;
  var startTime = DateTime.now();
  var lastLap = startTime;
  var currentLap = lastLap;

  await for (var query in openQueryListStream(batchQueryPath)) {
    var result = matcher.fmatch(query);
    if (result.error != '') {
      logSink.writeln(result.error);
      continue;
    }
    resultSink.write(formatOutput(lc, result));
    ++lc;
    if ((lc % 100) == 0) {
      currentLap = DateTime.now();
      print(
          '$lc: ${currentLap.difference(lastLap).inMilliseconds} ${currentLap.difference(startTime).inMilliseconds}');
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
    result = QueryResult.fromCachedResult(
      result.cachedResult,
      result.dateTime,
      result.dateTime
          .add(Duration(milliseconds: result.durationInMilliseconds)),
      result.inputString,
      result.rawQuery,
      Preprocessed(result.letType, result.queryTerms),
    );
  }
  for (var e in result.cachedResult.matchedEntiries) {
    csvLine.write(ix);
    csvLine.write(r',');
    csvLine.write(
        (result.durationInMilliseconds.toDouble() / 1000.0).toStringAsFixed(3));
    csvLine.write(r',');
    csvLine.write((e.score / result.cachedResult.perfScore).toStringAsFixed(2));
    csvLine.write(r',');
    csvLine.write(result.cachedResult.matchedEntiries.length);
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(result.rawQuery));
    csvLine.write(r',');
    csvLine.write(quoteCsvCell(e.rawEntry));
    csvLine.write(r',');
    csvLine.write(result.letType.toString().substring(8));
    for (var e in result.queryTerms) {
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(e));
    }
    csvLine.write('\r\n');
  }
  return csvLine.toString();
}
