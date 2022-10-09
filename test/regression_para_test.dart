// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/configs.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/server.dart';
import 'package:fmatch/util.dart';
import 'package:test/test.dart';

import '../bin/batchp.dart';

Future<void> main() async {
  var env = 'test/env0';
  Pathes.list = '$env/list.csv';
  Pathes.db = '$env/db.csv';
  Pathes.idb = '$env/idb.json';
  var queriesPath = '$env/queries.csv';

  var matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  await matcher.buildDb();

  cacheServer = await CacheServer.spawn(matcher.queryResultCacheSize);

  for (var id = 0; id < serverCount; id++) {
    var c = Client(id);
    await c.spawnServer(matcher, cacheServer);
    serverPoolController.add(c);
  }

  await pbatch(matcher, queriesPath);

  var queries = <String>[];
  await for (var l in readCsvLines( Pathes.list)) {
    if (l.isEmpty || l[0] == null) {
      continue;
    }
    if(matcher.preper.hasIllegalCharacter(l[0]!)){
      continue;
    }
    queries.add(matcher.preper.normalizeAndCapitalize(l[0]!).string);
  }

  var results = <String>[];
  await for (var l in readCsvLines('$env/results.csv')) {
    if (l.length < 7) {
      continue;
    }
    if(l[5] == l[6]){
      results.add(l[5]!);
    }
  }

  test('Regression', () {
    expect(results, equals(queries));
  });
}
