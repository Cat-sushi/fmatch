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

  test('query 1', () async {
    var q = r'def co';
    var jsonString = JsonEncoder().convert(await matcher.fmatch(q));
    print(jsonString);
    expect(
        jsonString,
        endsWith('"inputString":"def co","rawQuery":"DEF CO",'
            '"cachedResult":{"cachedQuery":{"letType":"postfix","terms":["DEF","CO"],'
            '"perfectMatching":false},"queryScore":0.4628958000823221,"matchedEntiries":['
            '{"rawEntry":"DEF COMPANY","score":0.4628958000823221},'
            '{"rawEntry":"DEF GHI CO.","score":0.4628958000823221},'
            '{"rawEntry":"COMPANY","score":0.006317690713281352},'
            '{"rawEntry":"COMPANY ABC","score":0.006317690713281352}]},"error":""}'));
  });
  test('query 2', () async {
    var q = r'def co';
    var jsonString = JsonEncoder().convert(await matcher.fmatch(q));
    print(jsonString);
    var decorder = JsonDecoder();
    var resultJson = decorder.convert(jsonString) as Map<String, dynamic>;
    print(resultJson);
    var result = QueryResult.fromJson(resultJson);
    var jsonString2 = JsonEncoder().convert(result);
    expect(jsonString, equals(jsonString2));
  });
}
