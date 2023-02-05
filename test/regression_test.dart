// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:fmatch/src/configs.dart';
import 'package:fmatch/src/fmatch_impl.dart';
import 'package:fmatch/src/util.dart';
import 'package:test/test.dart';

import '../bin/batch.dart';

late FMatcherImpl matcher;
late List<String> queries;
late List<String> results;
var env = 'test/env0';

Future<void> main() async {
  test('Regression 1', () async {
    try {
      File('$env/${Pathes.idb}').deleteSync();
      // ignore: empty_catches
    } catch (e) {}
    await initMatcher();
    await doBatch();
    expect(results, equals(queries));
  }, timeout: Timeout(Duration(minutes: 2)));
  test('Regression 2', () async {
    await initMatcher();
    await doBatch();
    expect(results, equals(queries));
  }, timeout: Timeout(Duration(minutes: 5)));
}

Future<void> initMatcher() async {
  matcher = FMatcherImpl();
  await matcher.readSettings(Pathes.configDir);
  await matcher.preper.readConfigs(Pathes.configDir);
  await matcher.buildDb(Pathes.configDir, env);
  queries = [];
  await for (var l in readCsvLines('$env/${Pathes.list}')) {
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
  await batch(matcher, '$env/queries.csv');
  results = <String>[];
  await for (var l in readCsvLines('$env/queries_results.csv')) {
    if (l.length < 7) {
      continue;
    }
    if (l[6] == l[7]) {
      results.add(l[6]!);
    }
  }
}
