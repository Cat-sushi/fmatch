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
  whiteQueries = {};
  var list = [
    r'LI, LI',
    r'AL-LAJNA AL-KHAYRIYYA LIL MUNASARA AL-AQSA',
    r'OSAMA BIN LADEN-ORGANISATION',
    r"ANSAR AL-SHARI'A IN TUNISIA (AAS-T)",
  ];
  var rawEntries = list.map((e) => normalizeAndCapitalize(e)).toList();
  rawEntries.forEach(print);
  var preprocessed = list.map((e) => normalizeAndCapitalize(e)).toList();
  db = await Db.fromStringStream(Stream.fromIterable(rawEntries));
  idb = IDb.fromDb(db);
  test('Li, Li', () {
    var q = r'Li, Li';
    var results = fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[0],
    ]);
  });
  test('OSAMA BIN LADIN', () {
    var q = r'ASAMA BIN LADEN NETWORK';
    var results = fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[2],
    ]);
  });
  test("ANSAR AL-SHARI'A (AAS)", () {
    var q = r"ANSAR AL-SHARI'A (AAS)";
    var results = fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(results, <String>[
      preprocessed[3],
    ]);
  });
}
