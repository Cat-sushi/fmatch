// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'fmclasses.dart';
import 'preprocess.dart';
import 'util.dart';

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
