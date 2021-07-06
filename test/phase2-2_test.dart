// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/configs.dart';
import 'package:fmatch/database.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/preprocess.dart';
import 'package:test/test.dart';

Future<void> main() async {
  await Settings.read();
  await Configs.read();
  crossTransactionalWhiteList = {};
  var list = [
    r'company',
    r'company abc',
    r'def company',
    r'def ghi co.',
    r'jkl co. lmn',
    r'mno <*co*>',
    r'pqr <*co*> stu',
    'zza zzb zzc zzd zze zzf zzg zzh zzi zzj',
    'zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz '
    'aaa aaa aaa aaa aaa aaa aaa aaa aaa aaa '
    'bbb bbb bbb bbb bbb bbb bbb bbb bbb bbb '
    'ccc ccc ccc ccc ccc ccc ccc ccc ccc ccc '
    'ddd ddd ddd ddd ddd ddd ddd ddd ddd ddd '
    'eee eee eee eee eee eee eee eee eee eee',
  ];
  var rawEntries = list.map((e) => normalizeAndCapitalize(e)).toList();
  rawEntries.forEach((e) => print(e));
  db = await Db.fromStringStream(Stream.fromIterable(rawEntries));
  idb = IDb.fromDb(db);

  test('query 1', () {
    var q = r'co';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[0],
      rawEntries[1],
      rawEntries[2],
      rawEntries[3],
    ]);
  });
  test('query 2', () {
    var q = r'def';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[2],
      rawEntries[3],
    ]);
  });
  test('query 3', () {
    var q = r'def co.';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[2],
      rawEntries[3],
      rawEntries[0],
      rawEntries[1],
    ]);
  });
  test('query 4', () {
    var q = r'def ghi co.';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[3],
      rawEntries[2],
    ]);
  });
  test('query 5', () {
    var q = r'abc co.';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[1],
      rawEntries[0],
      rawEntries[2],
      rawEntries[3],
    ]);
  });
  test('query 6', () {
    var q = r'ghi def co.';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[3],
      rawEntries[2],
    ]);
  });
  test('query 7', () {
    var q = r'zzz zzz zzz';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[8],
    ]);
  });
  test('query 8', () {
    var q = r'zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, <String>[]); // 組み合わせ爆発防止対策によりヒットせず
  });
  test('query 9', () {
    var q = r'zzz zzz zzzz aaa aaa aaa bbb bbb ccc ccc ccc ddd ddd ddd eee eee eee';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[8],
    ]);
  });
  test('query 10', () {
    var q = r'zzz zzz aaa aaa bbb bbb ccc ccc ddd ddd eee eee';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[8],
    ]);
  });
  test('query 11', () {
    var q = r'zzj zzi zzh zzg zzf zze zzd zzc zzb zza';
    var r = fmatch(q);
    var results = r.matchedEntries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[7],
    ]);
  });
  test('query 12', () {
    var q = r'zzz zzz zzz zzz zzz zzz zzz zzz zzz';
    var r = fmatch(q);
    expect(r.queryTerms.length, 9);
  });
  test('query 13', () {
    var q = r'zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz';
    var r = fmatch(q);
    expect(r.queryTerms.length, 10);
  });
  test('query 14', () {
    var q = r'zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz';
    var r = fmatch(q);
    expect(r.queryTerms.length, 10);
  });
}
