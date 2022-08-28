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
  matcher.whiteQueries = {};
  var list = [
    r'abc defg hijkl mnopqr',
    r'xxxxxxxxxxxxxxxxxxxxxxxxxxS',
  ];
  var rawEntries = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  var preprocessed = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  matcher.db = await Db.fromStringStream(matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);
  matcher.initIdbIndices();

  test('ab', () {
    var q = r'ab';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('abcd', () {
    var q = r'abcd';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('abcde', () {
    var q = r'abcde';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('de', () {
    var q = r'de';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('def', () {
    var q = r'def';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('defgh', () {
    var q = r'defgh';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('defghi', () {
    var q = r'defghi';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hij', () {
    var q = r'hij';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('hijk', () {
    var q = r'hijk';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklm', () {
    var q = r'hijklm';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklmn', () {
    var q = r'hijklmn';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklmno', () {
    var q = r'hijklmno';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('mno', () {
    var q = r'mno';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('mnop', () {
    var q = r'mnop';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopq', () {
    var q = r'mnopq';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrs', () {
    var q = r'mnopqrs';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrst', () {
    var q = r'mnopqrst';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrstu', () {
    var q = r'mnopqrstu';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrstuv', () {
    var q = r'mnopqrstuv';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('ab c', () {
    var q = r'ab c';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('ab bc', () {
    var q = r'ab bc';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('de fg', () {
    var q = r'de fg';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hi jkl', () {
    var q = r'hi jkl';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hi kl', () {
    var q = r'hi kl';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hij jkl', () {
    var q = r'hij jkl';
    var results = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
}
