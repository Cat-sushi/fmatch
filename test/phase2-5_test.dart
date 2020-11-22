// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9

import 'package:fmatch/preprocess.dart';
import 'package:test/test.dart';
import 'package:fmatch/configs.dart';
import 'package:fmatch/database.dart';
import 'package:fmatch/fmatch.dart';

void main() async {
  await Settings.read();
  await Configs.read();
  var list = [
    r'abc defg hijkl mnopqr',
    r'xxxxxxxxxxxxxxxxxxxxxxxxxxS',
  ];
  var rawEntries = list.map((e) => normalizeAndCapitalize(e)).toList();
  rawEntries.forEach((e) => print(e));
  var preprocessed = list.map((e) => normalizeAndCapitalize(e)).toList();
  db = await Db.fromStringStream(Stream.fromIterable(rawEntries));
  idb = IDb.fromDb(db);
  test('ab', () {
    var q = r'ab';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('abcd', () {
    var q = r'abcd';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('abcde', () {
    var q = r'abcde';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('de', () {
    var q = r'de';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('def', () {
    var q = r'def';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('defgh', () {
    var q = r'defgh';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('defghi', () {
    var q = r'defghi';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hij', () {
    var q = r'hij';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('hijk', () {
    var q = r'hijk';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklm', () {
    var q = r'hijklm';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklmn', () {
    var q = r'hijklmn';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hijklmno', () {
    var q = r'hijklmno';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('mno', () {
    var q = r'mno';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('mnop', () {
    var q = r'mnop';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopq', () {
    var q = r'mnopq';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrs', () {
    var q = r'mnopqrs';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrst', () {
    var q = r'mnopqrst';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrstu', () {
    var q = r'mnopqrstu';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('mnopqrstuv', () {
    var q = r'mnopqrstuv';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('ab c', () {
    var q = r'ab c';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('ab bc', () {
    var q = r'ab bc';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
  test('de fg', () {
    var q = r'de fg';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hi jkl', () {
    var q = r'hi jkl';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hi kl', () {
    var q = r'hi kl';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('hij jkl', () {
    var q = r'hij jkl';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
}
