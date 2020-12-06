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
  crossTransactionalWhiteList = {};
  var list = [
    r'abc def ghi co.',
    r'abc defghi company',
    r'abc defghi jkl corp.',
    r'P.T. hogehoge hagehage',
    r'xxx yyy zzz co., ltd.',
  ];
  var rawEntries = list.map((e) => normalizeAndCapitalize(e)).toList();
  rawEntries.forEach((e) => print(e));
  db = await Db.fromStringStream(Stream.fromIterable(rawEntries));
  idb = IDb.fromDb(db);

  test('query 1', () {
    var q = r'abc def ghi';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[0],
      rawEntries[1],
      rawEntries[2],
    ]);
  });
  test('query 2', () {
    var q = r'company';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[0],
      rawEntries[1],
    ]);
  });
  test('query 3', () {
    var q = r'hogehoge pt';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[3],
    ]);
  });
  test('query 4', () {
    var q = r'yyy co ltd';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[4],
    ]);
  });
  test('query 5', () {
    var q = r'yyy jjj kkk co ltd';
    var results = fmatch(q).matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      rawEntries[4],
    ]);
  });
}
