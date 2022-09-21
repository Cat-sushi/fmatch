// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

RegExp regExp(String pattern) => RegExp(pattern, unicode: true);

RegExp _escapedDoubleQuate = RegExp(r'""');
RegExp _mlDetecter = regExp(r'^(("(""|[^"])*"|[^",]+|),)*"(""|[^"])*$');
RegExp _csvParser = regExp(r'(?:"((?:""|[^"])*)"|([^",]+)|())(?:,|$)');

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
    if (_mlDetecter.firstMatch(row) != null) {
      continue;
    }
    var ret = <String?>[];
    var start = 0;
    for (Match? m; true; start = m.end) {
      m = _csvParser.matchAsPrefix(row, start);
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
        ret.add(m.group(1)!.replaceAll(_escapedDoubleQuate, r'"'));
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

Future<void> time(FutureOr<void> Function() func, String name) async {
  var start = DateTime.now();
  await func();
  var end = DateTime.now();
  print('$name : ${end.difference(start).inMilliseconds}');
}

const bufferSize = 128 * 1024;

class FileChankSink implements Sink<List<int>> {
  final RandomAccessFile raFile;
  FileChankSink.fromRaFile(this.raFile);
  @override
  void add(List<int> data) {
    raFile.writeFromSync(data);
  }

  @override
  void close() {
    raFile.closeSync();
  }
}
