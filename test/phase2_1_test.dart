// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/src/database.dart';
import 'package:fmatch/src/fmatch_impl.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var matcher = FMatcherImpl();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();

  var list = [
    r'abc def ghi co.',
    r'abc defghi company',
    r'abc defghi jkl corp.',
    r'P.T. hogehoge hagehage',
    r'xxx yyy zzz co., ltd.',
  ];
  var rawEntries =
      list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  rawEntries.forEach(print);
  matcher.db = await Db.fromStringStream(
      matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test('query 1', () async {
    var q = r'abc def ghi';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, [
      rawEntries[0],
      rawEntries[1],
      rawEntries[2],
    ]);
  });
  test('query 2', () async {
    var q = r'company';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, [
      rawEntries[0],
      rawEntries[1],
    ]);
  });
  test('query 3', () async {
    var q = r'hogehoge pt';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, [
      rawEntries[3],
    ]);
  });
  test('query 4', () async {
    var q = r'yyy co ltd';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, [
      rawEntries[4],
    ]);
  });
  test('query 5', () async {
    var q = r'yyy jjj kkk co ltd';
    var results = (await matcher.fmatch(q))
        .cachedResult
        .matchedEntiries
        .map((e) => e.entry.string)
        .toList();
    expect(results, <String>[
      rawEntries[4],
    ]);
  });
}
