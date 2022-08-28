// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/configs.dart';
import 'package:fmatch/fmatch.dart';
import 'package:test/test.dart';

Future<void> main() async {
  Paths.list = 'test/env1/list.csv';
  Paths.db = 'test/env1/db.csv';
  Paths.idb = 'test/env1/idb.json';

  var matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  await matcher.buildDb();

  test('AT&T Inc.', () {
    var q = r'AT&T INC.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, 0);
  });
  test('Li Na', () {
    var q = r'Li Na';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('MAT (VIETNAM) CO., LTD.', () {
    var q = r'MAT (VIETNAM) CO., LTD.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('JSC TECMASH', () {
    var q = r'JSC TECMASH';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('GRUPO GRYTSA, S.A. DE C.V.', () {
    var q = r'GRUPO GRYTSA, S.A. DE C.V.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MAMMORAD S.A.DE.C.V', () {
    var q = r'MAMMORAD S.A.DE.C.V.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MEDICA AZUL S.A. DE C.V.', () {
    var q = r'MEDICA AZUL S.A. DE C.V.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('NISSAN MEXICANA, S.A. DE C.V.', () {
    var q = r'NISSAN MEXICANA, S.A. DE C.V.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('YAMAZEN MEXICANA  S.A. DE C.V.', () {
    var q = r'YAMAZEN MEXICANA  S.A. DE C.V.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('E-COM TECHNOLOGY LIMITED', () {
    var q = r'E-COM TECHNOLOGY LIMITED';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('ABB Inc', () {
    var q = r'ABB Inc';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('T.R.S. SPA', () {
    var q = r'T.R.S. SPA';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('R PROJECT', () {
    var q = r'R PROJECT';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('CIT LLC', () {
    var q = r'CIT LLC';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('CIT Co Ltd', () {
    var q = r'CIT Co Ltd';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('USI CORPORATION', () {
    var q = r'USI CORPORATION';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('SURA', () {
    var q = r'SURA';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(55)); // 1語のノイズはやむを得ない
  });
  test('S T MEDIC SA DE CV', () {
    var q = r'S T MEDIC SA DE CV';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('LAC Co., Ltd.', () {
    var q = r'LAC Co., Ltd.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('Medical d o o', () {
    var q = r'Medical d o o';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1));
    expect(r.cachedResult.matchedEntiries.length, lessThan(60));
  });
  test('H Medical', () {
    var q = r'H Medical';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('MASS co Ltd', () {
    var q = r'MASS co Ltd';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('TOTO(SHANGHAI) CO.,LTD.', () {
    var q = r'TOTO(SHANGHAI) CO.,LTD.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('Nets A/S', () {
    var q = r'Nets A/S';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('ELES, D.O.O.', () {
    var q = r'ELES, D.O.O.';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('K LINE (THAILAND) LIMITED', () {
    var q = r'K LINE (THAILAND) LIMITED';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('P.S.G MEDICAL S.R.L.', () {
    var q = r'P.S.G MEDICAL S.R.L.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MED KHAN', () {
    var q = r'MED KHAN';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('M-ASTER', () {
    var q = r'M-ASTER';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(15));
  });
  test('M ASTER', () {
    var q = r'M ASTER';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MINO (THAILAND) CO., LTD.', () {
    var q = r'MINO (THAILAND) CO., LTD.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('ICL (Thailand) Co., Ltd.', () {
    var q = r'ICL (Thailand) Co., Ltd.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('HHA', () {
    var q = r'HHA';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('OOO IPS ', () {
    var q = r'OOO IPS ';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('IPS S A ', () {
    var q = r'IPS S A ';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('IPS OOO', () {
    var q = r'IPS OOO';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('RUS-EXP', () {
    var q = r'RUS-EXP';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('Abdul Qadir', () {
    var q = r'Abdul Qadir';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(20)); // マッチするのが妥当な名前ばかり
  });
  test('PCI', () {
    var q = r'PCI';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('Northwestern University', () {
    var q = r'Northwestern University';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('RENO (THAILAND) COMPANY LIMITED', () {
    var q = r'RENO (THAILAND) COMPANY LIMITED';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('SYSTEM DESIGN Co., Ltd.', () {
    var q = r'SYSTEM DESIGN Co., Ltd.';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('Kao (Hong Kong) Ltd.', () {
    var q = r'Kao (Hong Kong) Ltd.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('LLC Orman', () {
    var q = r'LLC Orman';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(100));
  });
  test('DOCTOR AZ Ltd ', () {
    var q = r'DOCTOR AZ Ltd ';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('CO-Sol Canada Inc.', () {
    var q = r'CO-Sol Canada Inc.';
    var r = matcher.fmatch(q);
    expect(r.queryTerms, ['CO-SOL','CANADA','INC']);
  });
  test('Re-Teck Co., Ltd.', () {
    var q = r'Re-Teck Co., Ltd.';
    var r = matcher.fmatch(q);
    expect(r.queryTerms, ['RE-TECK','CO_LTD']);
  });
  test('A&D Company, Limited', () {
    var q = r'A&D Company, Limited';
    var r = matcher.fmatch(q);
    expect(r.queryTerms, ['A&D', 'CO_LTD']);
  });
  test('HONG CO TECHNOLOGY COMPANY LIMITED', () {
    var q = r'HONG CO TECHNOLOGY COMPANY LIMITED';
    var r = matcher.fmatch(q);
    expect(r.queryTerms, ['HONG','CO','TECHNOLOGY','CO_LTD']);
  });
  test('MUJI U.S.A. Limited', () {
    var q = r'MUJI U.S.A. Limited';
    var r = matcher.fmatch(q);
    expect(r.queryTerms, ['MUJI','USA','LTD']);
  });
  test('Terna S.p.A', () {
    var q = r'Terna S.p.A';
    var r = matcher.fmatch(q);
    expect(r.queryTerms, ['TERNA','SPA']);
  });
  test('BANK OF KESHAVARZI', () {
    var q = r'BANK OF KESHAVARZI';
    var r = matcher.fmatch(q).cachedResult.matchedEntiries.map((e) => e.rawEntry).toList();
    expect(r, ['BANK KESHAVARZI', 'BANK KESHAVARZI IRAN', 'BANK TAAVON KESHAVARZI IRAN']);
  });
  test('HARBIN INSTITUTE OF TECHNOLOGY', () {
    var q = r'HARPIN INSTITUTE OF TECHNOLOGY';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'HARBIN INSTITUTE OF TECHNOLOGY (HIT)');
  });
  test('NOVOKUIBYSHEVSK REFYNERY', () {
    var q = r'NOVOKUIBYSHEVSK REFYNERY';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('NOVOKUYBYSHEVSK REFINERY', () {
    var q = r'NOVOKUYBYSHEVSK REFINERY';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('NOVOKUIBYSHEVSK REFINEYR', () {
    var q = r'NOVOKUIBYSHEVSK REFINEYR';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('NOVOKUYBYSHEVSK REFINRY', () {
    var q = r'NOVOKUYBYSHEVSK REFINRY';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('CJS NOVOKUIBYSHEVSK REFINERY', () {
    var q = r'CJS NOVOKUIBYSHEVSK REFINERY';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry,'NOVOKUIBYSHEVSK REFINERY');
  });
  test('ASTRONAUTICS SYSTEMS RESEARCH CENTRE', () {
    var q = r'ASTRONAUTICS SYSTEMS RESEARCH CENTRE';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'ASTRONAUTICS SYSTEMS RESEARCH CENTER');
  });
  test('BIMEH IRAN INSURANCE COMPANY(UK)LIMITED', () {
    var q = r'BIMEH IRAN INSURANCE COMPANY(UK)LIMITED';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'BIMEH IRAN INSURANCE COMPANY (U.K.) LIMITED');
  });
  test('OBRONPROM', () {
    var q = r'OBRONPROM';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, greaterThan(0));
  });
  test('SIRIUS CO LTD', () {
    var q = r'SIRIUS CO LTD';
    var r = matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1)); // SIRIUSに曖昧一致するエントリが多く、JSC SIRIUS等のスコアが低い。なお、SIRIUS CO LTDはJSC SIRIUSと無関係。
    expect(r.cachedResult.matchedEntiries.length, lessThan(70));
  });
  test('D-Link Electronic Co., Ltd.', () {
    var q = r'D-Link Electronic Co., Ltd.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });

  test('D.I.T. Co., Ltd.', () {
    var q = r'D.I.T. Co., Ltd.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('K&S KOREA', () {
    var q = r'K&R KOREA';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('N C&C Co., Ltd.', () {
    var q = r'N C&C Co., Ltd.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('Gazpromneft Moscow Refinery Joint Stock Company', () {
    var q = r'Gazpromneft Moscow Refinery Joint Stock Company';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, equals(1));
  });
  test('Gazpromneft-MNPZ, AO', () {
    var q = r'Gazpromneft-MNPZ, AO';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, equals(2));
  });
  test('Lukoil Permneftneorgstintez', () {
    var q = r'Lukoil Permneftneorgstintez';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, equals(1));
  });
  test('Lukoil Europe Holdings BV', () {
    var q = r'Lukoil Europe Holdings BV';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].rawEntry, 'LUKOIL EUROPE HOLDINGS B.V.');
  });
  test('D.I.T. CO., LTD.', () {
    var q = r'D.I.T. CO., LTD.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(2));
  });
  test('I&I CO., LTD.', () {
    var q = r'I&I CO., LTD.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries, <MatchedEntry>[]);
  });
  test('K&S KOREA', () {
    var q = r'K&S KOREA';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries, <MatchedEntry>[]);
  });
  test('N C&C CO., LTD.', () {
    var q = r'N C&C CO., LTD.';
    var r = matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries, <MatchedEntry>[]);
  });
}
