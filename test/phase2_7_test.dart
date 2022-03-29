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
        'AL-AL',
        'MUORWEL MALUAL, MALUAL DHAL',
        'AL-TAL, MOHAMMAD ISMAIL',
        'AL-TAL, MOHAMMED',
        'ALKALA ASOCIADOS S.A.',
        'BAYT AL-MAL',
        'BAYT AL-MAL LIL MUSLIMEEN',
        'HAMID, AL-ALI',
        'JAISH AL-ADL',
        'JAYSH AL-ADL',
        'JEISH AL-ADL',
        'JEYSH AL-ADL',
        'LOUAY AL-ALI,',
        "LU'AI AL-ALI,",
        'MUORWEL, MALUAL DHAL',
        'NASER AL-ALI,',
        'NASR AL-ALI,',
        'NASSER AL-ALI,',
        'SAYF AL-ADL,',
  ];
  var rawEntries = list.map((e) => normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  var preprocessed = list.map((e) => normalizeAndCapitalize(e)).toList();
  db = await Db.fromStringStream(Stream.fromIterable(rawEntries));
  idb = IDb.fromDb(db);
  test('AL AL AL', () {
    var q = r'AL AL AL';
    var results = fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
      preprocessed[2],
      preprocessed[3],
      preprocessed[4],
      preprocessed[5],
      preprocessed[6],
      preprocessed[7],
      preprocessed[8],
      preprocessed[9],
      preprocessed[10],
      preprocessed[11],
      preprocessed[12],
      preprocessed[13],
      preprocessed[1],
      preprocessed[14],
      preprocessed[15],
      preprocessed[16],
      preprocessed[17],
      preprocessed[18],
    ]);
  });
  test(r'AL AL AL AL AL AL AL AL', () {
    var q = r'AL AL AL AL AL AL AL AL';
    var results = fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[1],
    ]);
  });
  test(r'AL AL AL AL AL AL AL AL AL', () {
    var q = r'AL AL AL AL AL AL AL AL AL';
    var results = fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
    ]);
  });
}
