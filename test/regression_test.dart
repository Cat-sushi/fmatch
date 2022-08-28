// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/batch.dart';
import 'package:fmatch/configs.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/util.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var env = 'test/env0';
  Paths.list = '$env/list.csv';
  Paths.db = '$env/db.csv';
  Paths.idb = '$env/idb.json';

  var matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  await matcher.buildDb();
  await batch(matcher, env);

  var queries = <String>[];
  await for (var l in readCsvLines( Paths.list)) {
    if (l.isEmpty || l[0] == null) {
      continue;
    }
    if(matcher.preper.hasIllegalCharacter(l[0]!)){
      continue;
    }
    queries.add(matcher.preper.normalizeAndCapitalize(l[0]!));
  }

  var results = <String>[];
  await for (var l in readCsvLines('$env/results.csv')) {
    if (l.length < 5) {
      continue;
    }
    if(l[3] == l[4]){
      results.add(l[3]!);
    }
  }

  test('Regression', () {
    expect(results, equals(queries));
  });
}
