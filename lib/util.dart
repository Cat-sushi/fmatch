// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

RegExp regExp(String pattern) => RegExp(pattern, unicode: true);

RegExp escapedDoubleQuate = RegExp(r'""');
RegExp mlDetecter = regExp(r'^(("(""|[^"])*"|[^",]+|),)*"(""|[^"])*$');
RegExp csvParser = regExp(r'(?:"((?:""|[^"])*)"|([^",]+)|())(?:,|$)');

Stream<List<String?>> readCsvLines(String filepath) async* {
  var row = '';
  var lineStream = File(filepath)
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (var line in lineStream) {
    if (row != '') {
      row += '\n';
    }
    row += line;
    if (mlDetecter.firstMatch(row) != null) {
      continue;
    }
    var ret = <String?>[];
    var start = 0;
    for (Match? m; true; start = m.end) {
      m = csvParser.matchAsPrefix(row, start);
      if (m == null) {
        if (start != row.length) {
          print('Illegal CSV line: $row');
        }
        break;
      }
      if (m.start == m.end) {
        break;
      }
      if (m.group(1) != null) {
        ret.add(m.group(1)!.replaceAll(escapedDoubleQuate, r'"'));
        continue;
      }
      if (m.group(2) != null) {
        ret.add(m.group(2));
        continue;
      }
      if (m.group(3) != null) {
        ret.add(null);
        continue;
      }
    }
    yield ret;
    row = '';
  }
  if (row != '') {
    print('Illegal CSV line: $row');
  }
}

String quoteCsvCell(String cell) => r'"' + cell.replaceAll(r'"', r'""') + r'"';

final _stringMap = <String, String>{};
String canonicalize(String s, [bool registering = true]) {
  var ret = _stringMap[s];
  if (ret != null) {
    return ret;
  }
  if (registering) {
    _stringMap[s] = s;
  }
  return s;
}

Future<void> time(FutureOr<void> Function() func, String name) async {
  var start = DateTime.now();
  await func();
  var end = DateTime.now();
  print('$name : ${end.difference(start).inMilliseconds}');
}
