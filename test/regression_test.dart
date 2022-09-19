// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:fmatch/batch.dart';
import 'package:fmatch/configs.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/util.dart';
import 'package:test/test.dart';

late FMatcher matcher;
late List<String> queries;
late List<String> results;
var env = 'test/env0';

Future<void> main() async {
  Pathes.list = '$env/list.csv';
  Pathes.db = '$env/db.csv';
  Pathes.idb = '$env/idb.json';

  test('Regression 1', () async {
    try {
      File(Pathes.idb).deleteSync();
    // ignore: empty_catches
    } catch (e) {}
    await initMatcher();
    await doBatch();
    expect(results, equals(queries));
  });
  test('Regression 2', () async {
    await initMatcher();
    await doBatch();
    expect(results, equals(queries));
  });
}

Future<void> initMatcher() async {
  matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  await matcher.buildDb();
  queries = [];
  await for (var l in readCsvLines(Pathes.list)) {
    if (l.isEmpty || l[0] == null) {
      continue;
    }
    if (matcher.preper.hasIllegalCharacter(l[0]!)) {
      continue;
    }
    queries.add(matcher.preper.normalizeAndCapitalize(l[0]!).string);
  }
}

Future<void> doBatch() async {
  await batch(matcher, env);
  results = <String>[];
  await for (var l in readCsvLines('$env/results.csv')) {
    if (l.length < 7) {
      continue;
    }
    if (l[5] == l[6]) {
      results.add(l[5]!);
    }
  }
}
