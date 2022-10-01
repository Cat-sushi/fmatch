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
        'AL-AL', // 0
        'MUORWEL MALUAL, MALUAL DHAL', // 1
        'AL-TAL, MOHAMMAD ISMAIL', // 2
        'AL-TAL, MOHAMMED', // 3
        'ALKALA ASOCIADOS S.A.', // 4
        'BAYT AL-MAL', // 5
        'BAYT AL-MAL LIL MUSLIMEEN', // 6
        'HAMID, AL-ALI', // 7
        'JAISH AL-ADL', // 8
        'JAYSH AL-ADL', // 9
        'JEISH AL-ADL', // 10
        'JEYSH AL-ADL', // 11
        'LOUAY AL-ALI,', // 12
        "LU'AI AL-ALI,", // 13
        'MUORWEL, MALUAL DHAL', // 14
        'NASER AL-ALI,', // 15
        'NASR AL-ALI,', // 16
        'NASSER AL-ALI,', // 17
        'SAYF AL-ADL,', // 18
  ];
  var rawEntries = list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  rawEntries.forEach(print);
  var preprocessed = list.map((e) => matcher.preper.normalizeAndCapitalize(e).string).toList();
  matcher.db = await Db.fromStringStream(matcher.preper, Stream.fromIterable(rawEntries));
  matcher.idb = IDb.fromDb(matcher.db);
  
  test('AL AL AL', () async {
    var q = r'AL AL AL';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[5],
      preprocessed[8],
      preprocessed[9],
      preprocessed[10],
      preprocessed[11],
      preprocessed[16],
      preprocessed[18],
      preprocessed[7],
      preprocessed[12],
      preprocessed[13],
      preprocessed[15],
      preprocessed[17],
      preprocessed[3],
      preprocessed[14],
      preprocessed[4],
      preprocessed[2],
      preprocessed[6],
      preprocessed[1],
    ]);
  });
  test(r'AL AL AL AL AL AL AL AL', () async {
    var q = r'AL AL AL AL AL AL AL AL';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
      preprocessed[1],
    ]);
  });
  test(r'AL AL AL AL AL AL AL AL AL', () async {
    var q = r'AL AL AL AL AL AL AL AL AL';
    var results = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(results, <String>[
    ]);
  });
}
