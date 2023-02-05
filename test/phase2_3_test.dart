// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/src/configs.dart';
import 'package:fmatch/src/database.dart';
import 'package:fmatch/src/fmatch_impl.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var matcher = FMatcherImpl();
  await matcher.readSettings(Paths.configDir);
  await matcher.preper.readConfigs(Paths.configDir);
  var list = [
    'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
        'kkk lll mmm nnn ooo ppp qqq rrr sss ttt '
        'uuu vvv www xxx',
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  ];
  var rawEntries =
      list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  rawEntries.forEach(print);
  matcher.db = await Db.fromStringStream(
      matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);

  test(r'aaa ... iii', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 9);
  });
  test(r'aaa .. jjj', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 10);
  });
  test(r'aaa ... kkk', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 11);
  });
  test(r'aaa ... lll', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 12);
  });
  test(r'aaa ... mmm', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 13);
  });
  test(r'aaa ... nnn', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 14);
  });
  test(r'aaa ... ooo', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 15);
  });
  test(r'aaa ... ppp', () async {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 16);
  });
  test(r'aaa ... qqq', () async {
    var q =
        r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 17);
  });
  test(r'aaa ... rrr', () async {
    var q =
        r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 18);
  });
  test(r'aaa ... sss', () async {
    var q =
        r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 19);
  });
  test(r'aaa ... ttt', () async {
    var q =
        r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 20);
  });
  test(r'aaa ... uuu', () async {
    var q =
        r'aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn ooo ppp qqq rrr sss ttt uuu';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.length, 21);
  });
}
