// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9

import 'dart:convert';
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
    r'company',
    r'company abc',
    r'def company',
    r'def ghi co.',
    r'jkl co. lmn',
    r'mno <*co*>',
    r'pqr <*co*> stu',
  ];
  var rawEntries = list.map((e) => normalizeAndCapitalize(e)).toList();
  rawEntries.forEach((e) => print(e));
  db = await Db.fromStringStream(Stream.fromIterable(rawEntries));
  idb = IDb.fromDb(db);

  test('query 1', () {
    var q = r'def co';
    var jsonString = JsonEncoder().convert(fmatch(q));
    print(jsonString);
    expect(
        jsonString, endsWith(
        '"inputString":"def co","rawQuery":"DEF CO","letType":"postfix","queyTerms":["DEF","CO"],"matchedEntryCount":4,"matchedEntries":['
        '{"rawEntry":"DEF COMPANY","score":0.4628958000823221},{"rawEntry":"DEF GHI CO.","score":0.4628958000823221},'
        '{"rawEntry":"COMPANY","score":0.013758139210378627},{"rawEntry":"COMPANY ABC","score":0.013758139210378627}],"error":""}'));
  });
}
