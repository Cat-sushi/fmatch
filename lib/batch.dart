// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'util.dart';
import 'database.dart';
import 'fmatch.dart';

Future<void> batch([String path = 'lib/batch']) async {
  var batchQueryPath = '$path/queries.csv';
  var batchResultPath = '$path/results.csv';
  var batchLogPath = '$path/Log.txt';
  var resultFile = File(batchResultPath);
  resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
  var resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
  var logSink = File(batchLogPath).openWrite(encoding: utf8);
  var lc = 0;
  var lastLap = DateTime.now();
  var currentLap = lastLap;
  var csvLine = StringBuffer();
  await for (var line in readCsvLines(batchQueryPath)) {
    var query = line[0];
    if (query == null || query == '') {
      continue;
    }
    var result = fmatch(query);
    if (result.error != '') {
      logSink.writeln(result.error);
      continue;
    }
    if (result.matchedEntryCount == 0) {
      result = QueryResult.fromMatchedEntries(
          [MatchedEntry('', 0.0)],
          result.dateTime,
          result.dateTime
              .add(Duration(milliseconds: result.durationInMilliseconds)),
          result.inputString,
          result.rawQuery,
          Preprocessed(result.letType, result.queryTerms));
    }
    for (var e in result.matchedEntries) {
      csvLine.write(result.durationInMilliseconds);
      csvLine.write(r',');
      csvLine.write(result.matchedEntries.length);
      csvLine.write(r',');
      csvLine.write(quoteCsvCell(result.rawQuery));
      csvLine.write(r',');
      csvLine.write(e.score);
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
    ++lc;
    if ((lc % 100) == 0) {
      currentLap = DateTime.now();
      print('$lc: ${currentLap.difference(lastLap).inMilliseconds}');
      lastLap = currentLap;
      resultSink.write(csvLine);
      csvLine.clear();
      await resultSink.flush();
      await logSink.flush();
    }
  }
  resultSink.write(csvLine);
  await logSink.close();
  await resultSink.close();
}
