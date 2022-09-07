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
  matcher.preper.initWhiteQueries();
  var list = [
    r'ABCDEFGHI ABCDEFGHI',
    r'ABCDEFGHI ABCJKLMNO',
    r'PQRSTU UVWXYZ',
  ];
  var rawEntries = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  var preprocessed = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  matcher.db = await Db.fromStringStream(matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test('ABCD EFGH', () {
    var q = r'ABCD, EFGH';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('ABC DEF GHI', () {
    var q = r'ABC DEF GHI';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('ABCD DE GHI', () {
    var q = r'ABCD DE GHI';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('ABC LMNO', () {
    var q = r'ABC LMNO';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[1],
    ]);
  });
  test('PQR STU UVW XYZ ABC DEF', () {
    var q = r'PQR STU UVW XYZ ABC DEF';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[2],
    ]);
  });
  test('AB DE GH', () {
    var q = r'AB DE GH';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('AB GH DE', () {
    var q = r'AB GH DE';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('ABCDEFGHI AB GH ABCJKLMNO', () {
    var q = r'ABCDEFGHI AB GH ABCJKLMNO';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[1],
    ]);
  });
}
