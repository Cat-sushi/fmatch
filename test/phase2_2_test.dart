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
  var rawEntries = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  matcher.db = await Db.fromStringStream(matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test('query 1', () async {
    var q = r'co';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[0],
      rawEntries[1],
      rawEntries[2],
      rawEntries[3],
    ]);
  });
  test('query 2', () async {
    var q = r'def';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[2],
      rawEntries[3],
    ]);
  });
  test('query 3', () async {
    var q = r'def co.';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[2],
      rawEntries[3],
      rawEntries[0],
      rawEntries[1],
    ]);
  });
  test('query 4', () async {
    var q = r'def ghi co.';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[3],
      rawEntries[2],
    ]);
  });
  test('query 5', () async {
    var q = r'abc co.';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[1],
      rawEntries[0],
      rawEntries[2],
      rawEntries[3],
    ]);
  });
  test('query 6', () async {
    var q = r'ghi def co.';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[3],
      rawEntries[2],
    ]);
  });
  test('query 7', () async {
    var q = r'zzz zzz zzz';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[8],
    ]);
  });
  test('query 8', () async {
    var q = r'zzz zzz zzz zzz zzz zzz zzz zzz zzz zzz';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[8],
    ]);
  });
  test('query 9', () async {
    var q = r'zzz zzz zzzz aaa aaa aaa bbb bbb ccc ccc ccc ddd ddd ddd eee eee eee';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[8],
    ]);
  });
  test('query 10', () async {
    var q = r'zzz zzz aaa aaa bbb bbb ccc ccc ddd ddd eee eee';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[8],
    ]);
  });
  test('query 11', () async {
    var q = r'zzj zzi zzh zzg zzf zze zzd zzc zzb zza';
    var r = await matcher.fmatch(q);
    var results = r.cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, [
      rawEntries[7],
    ]);
  });
  test('query 12', () async {
    var q = r'zzz zzz zzz zzz zzz';
    var r = await matcher.fmatch(q);
    expect(r.queryTerms.length, 5);
  });
  test('query 13', () async {
    var q = r'zzz zzz zzz zzz zzz zzz';
    var r = await matcher.fmatch(q);
    expect(r.queryTerms.length, 6);
  });
  test('query 14', () async {
    var q = r'zzz zzz zzz zzz zzz zzz zzz';
    var r = await matcher.fmatch(q);
    expect(r.queryTerms.length, 6);
  });
}
