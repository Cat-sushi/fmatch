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
    'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss ttt '
    'uuu vvv www xxx',
    'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  ];
  var rawEntries = list.map((e) => normalizeAndCapitalize(e)).toList();
  rawEntries.forEach((e) => print(e));
  db = await Db.fromStringStream(Stream.fromIterable(rawEntries));
  idb = IDb.fromDb(db);

  test('query 1', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii';
    var r = fmatch(q);
    expect(r.queryTerms.length, 9);
  });
  test('query 2', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj';
    var r = fmatch(q);
    expect(r.queryTerms.length, 10);
  });
  test('query 3', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk';
    var r = fmatch(q);
    expect(r.queryTerms.length, 11);
  });
  test('query 4', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss';
    var r = fmatch(q);
    expect(r.queryTerms.length, 19);
  });
  test('query 5', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss ttt';
    var r = fmatch(q);
    expect(r.queryTerms.length, 20);
  });
  test('query 6', () {
    var q = r'aaa bbb ccc ddd eee fff ggg hhh iii jjj '
    'kkk lll mmm nnn ooo ppp qqq rrr sss ttt '
    'uuu';
    var r = fmatch(q);
    expect(r.queryTerms.length, 21);
  });
}
