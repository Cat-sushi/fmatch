// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:fmatch/database.dart';
import 'package:fmatch/fmatch.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  matcher.whiteQueries = {};
  var list = [
    r'company',
    r'company abc',
    r'def company',
    r'def ghi co.',
    r'jkl co. lmn',
    r'mno <*co*>',
    r'pqr <*co*> stu',
  ];
  var rawEntries =
      list.map((e) => matcher.preper.normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  matcher.db = await Db.fromStringStream(
      matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);
  matcher.initIdbIndices();

  test('query 1', () {
    var q = r'def co';
    var jsonString = JsonEncoder().convert(matcher.fmatch(q));
    print(jsonString);
    expect(
        jsonString,
        endsWith(
            '"inputString":"def co","rawQuery":"DEF CO","letType":"postfix","queryTerms":["DEF","CO"],'
            '"cachedResult":{"perfectScore":0.4628958000823221,"matchedEntiries":['
            '{"rawEntry":"DEF COMPANY","score":0.4628958000823221},'
            '{"rawEntry":"DEF GHI CO.","score":0.4628958000823221},'
            '{"rawEntry":"COMPANY","score":0.006317690713281352},'
            '{"rawEntry":"COMPANY ABC","score":0.006317690713281352}]},"error":""}'));
  });
  test('query 2', () {
    var q = r'def co';
    var jsonString = JsonEncoder().convert(matcher.fmatch(q));
    print(jsonString);
    var decorder = JsonDecoder();
    var resultJson = decorder.convert(jsonString) as Map<String, dynamic>;
    print(resultJson);
    var result = QueryResult.fromJson(resultJson);
    var jsonString2 = JsonEncoder().convert(result);
    expect(jsonString, equals(jsonString2));
  });
}
