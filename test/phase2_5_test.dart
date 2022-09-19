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
    r'abc defg hijkl mnopqr',
    r'xxxxxxxxxxxxxxxxxxxxxxxxxxS',
  ];
  var rawEntries = list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  rawEntries.forEach(print);
  var preprocessed = list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  matcher.db = await Db.fromStringStream(matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test('ab', () async {
    var q = r'ab';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('abcd', () async {
    var q = r'abcd';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('abcde', () async {
    var q = r'abcde';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('de', () async {
    var q = r'de';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('def', () async {
    var q = r'def';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('defgh', () async {
    var q = r'defgh';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('defghi', () async {
    var q = r'defghi';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hij', () async {
    var q = r'hij';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('hijk', () async {
    var q = r'hijk';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklm', () async {
    var q = r'hijklm';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklmn', () async {
    var q = r'hijklmn';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklmno', () async {
    var q = r'hijklmno';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('mno', () async {
    var q = r'mno';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('mnop', () async {
    var q = r'mnop';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopq', () async {
    var q = r'mnopq';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrs', () async {
    var q = r'mnopqrs';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrst', () async {
    var q = r'mnopqrst';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrstu', () async {
    var q = r'mnopqrstu';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrstuv', () async {
    var q = r'mnopqrstuv';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('ab c', () async {
    var q = r'ab c';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('ab bc', () async {
    var q = r'ab bc';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
  test('de fg', () async {
    var q = r'de fg';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hi jkl', () async {
    var q = r'hi jkl';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hi kl', () async {
    var q = r'hi kl';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hij jkl', () async {
    var q = r'hij jkl';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
}
