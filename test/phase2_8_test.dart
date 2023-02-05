// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/src/configs.dart';
import 'package:fmatch/src/database.dart';
import 'package:fmatch/src/fmatch_impl.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var matcher = FMatcherImpl();
  await matcher.readSettings(Pathes.configDir);
  await matcher.preper.readConfigs(Pathes.configDir);
  var list = [
    r'ABCDEFGHI ABCDEFGHI',
    r'ABCDEFGHI ABCJKLMNO',
    r'PQRSTU UVWXYZ',
  ];
  var rawEntries =
      list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  rawEntries.forEach(print);
  var preprocessed =
      list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  matcher.db = await Db.fromStringStream(
      matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test('ABCD EFGH', () async {
    var q = r'ABCD, EFGH';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('ABC DEF GHI', () async {
    var q = r'ABC DEF GHI';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('ABCD DE GHI', () async {
    var q = r'ABCD DE GHI';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('ABC LMNO', () async {
    var q = r'ABC LMNO';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      preprocessed[1],
    ]);
  });
  test('PQR STU UVW XYZ ABC DEF', () async {
    var q = r'PQR STU UVW XYZ ABC DEF';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      preprocessed[2],
    ]);
  });
  test('AB DE GH', () async {
    var q = r'AB DE GH';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[1],
    ]);
  });
  test('AB GH DE', () async {
    var q = r'AB GH DE';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[]);
  });
  test('ABCDEFGHI AB GH ABCJKLMNO', () async {
    var q = r'ABCDEFGHI AB GH ABCJKLMNO';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      preprocessed[1],
    ]);
  });
}
