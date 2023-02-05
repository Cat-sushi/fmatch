// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/fmatch.dart';
import 'package:fmatch/src/fmatch_impl.dart';
import 'package:fmatch/src/util.dart';
import 'package:test/test.dart';

import '../bin/batchp.dart';

Future<void> main() async {
  var env = 'test/env0';
  var queriesPath = '$env/queries.csv';

  var matcher = FMatcherImpl();
  await matcher.init(dbDir: env);
  var matcherp = FMatcherP.fromFMatcher(matcher);
  await matcherp.startServers();

  await pbatch(matcherp, queriesPath);

  var queries = <String>[];
  await for (var l in readCsvLines('$env/${Paths.list}')) {
    if (l.isEmpty || l[0] == null) {
      continue;
    }
    if (matcher.preper.hasIllegalCharacter(l[0]!)) {
      continue;
    }
    queries.add(matcher.preper.normalizeAndCapitalize(l[0]!).string);
  }

  var results = <String>[];
  await for (var l in readCsvLines('$env/queries_results.csv')) {
    if (l.length < 7) {
      continue;
    }
    if (l[6] == l[7]) {
      results.add(l[6]!);
    }
  }

  test('Regression', () {
    expect(results, equals(queries));
  });
}
