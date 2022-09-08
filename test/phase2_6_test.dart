// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/database.dart';
import 'package:fmatch/fmatch.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  var list = [
    r'LI, LI',
    r'AL-LAJNA AL-KHAYRIYYA LIL MUNASARA AL-AQSA',
    r'OSAMA BIN LADEN-ORGANISATION',
    r"ANSAR AL-SHARI'A IN TUNISIA (AAS-T)",
  ];
  var rawEntries = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  var preprocessed = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  matcher.db = await Db.fromStringStream(matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test('Li, Li', () {
    var q = r'Li, Li';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('OSAMA BIN LADIN', () {
    var q = r'ASAMA BIN LADEN NETWORK';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[2],
    ]);
  });
  test("ANSAR AL-SHARI'A (AAS)", () {
    var q = r"ANSAR AL-SHARI'A (AAS)";
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[3],
    ]);
  });
}
