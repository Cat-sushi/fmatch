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
    'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss ttt '
    'uuu vvv www xxx',
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  ];
  var rawEntries = list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  matcher.db = await Db.fromStringStream(matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test('query 1', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii';
    var r = matcher.fmatch(q);
    expect(r.queryTerms.length, 9);
  });
  test('query 2', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj';
    var r = matcher.fmatch(q);
    expect(r.queryTerms.length, 10);
  });
  test('query 3', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk';
    var r = matcher.fmatch(q);
    expect(r.queryTerms.length, 11);
  });
  test('query 4', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss';
    var r = matcher.fmatch(q);
    expect(r.queryTerms.length, 19);
  });
  test('query 5', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss ttt';
    var r = matcher.fmatch(q);
    expect(r.queryTerms.length, 20);
  });
  test('query 6', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss ttt '
    'uuu';
    var r = matcher.fmatch(q);
    expect(r.queryTerms.length, 21);
  });
}
