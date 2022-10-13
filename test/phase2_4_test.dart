// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/configs.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/fmclasses.dart';
import 'package:test/test.dart';

Future<void> main() async {
  Pathes.list = 'test/env1/list.csv';
  Pathes.db = 'test/env1/db.csv';
  Pathes.idb = 'test/env1/idb.json';

  var matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  await matcher.buildDb();

  test('AT&T Inc.', () async {
    var q = r'AT&T INC.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, 0);
  });
  test('Li Na', () async {
    var q = r'Li Na';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(15));
  });
  test('MAT (VIETNAM) CO., LTD.', () async {
    var q = r'MAT (VIETNAM) CO., LTD.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('JSC TECMASH', () async {
    var q = r'JSC TECMASH';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('GRUPO GRYTSA, S.A. DE C.V.', () async {
    var q = r'GRUPO GRYTSA, S.A. DE C.V.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MAMMORAD S.A.DE.C.V', () async {
    var q = r'MAMMORAD S.A.DE.C.V.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MEDICA AZUL S.A. DE C.V.', () async {
    var q = r'MEDICA AZUL S.A. DE C.V.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('NISSAN MEXICANA, S.A. DE C.V.', () async {
    var q = r'NISSAN MEXICANA, S.A. DE C.V.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('YAMAZEN MEXICANA  S.A. DE C.V.', () async {
    var q = r'YAMAZEN MEXICANA  S.A. DE C.V.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('E-COM TECHNOLOGY LIMITED', () async {
    var q = r'E-COM TECHNOLOGY LIMITED';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('ABB Inc', () async {
    var q = r'ABB Inc';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('T.R.S. SPA', () async {
    var q = r'T.R.S. SPA';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('R PROJECT', () async {
    var q = r'R PROJECT';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(8));
  });
  test('CIT LLC', () async {
    var q = r'CIT LLC';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('CIT Co Ltd', () async {
    var q = r'CIT Co Ltd';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('USI CORPORATION', () async {
    var q = r'USI CORPORATION';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('SURA', () async {
    var q = r'SURA';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(55)); // 1語のノイズはやむを得ない
  });
  test('S T MEDIC SA DE CV', () async {
    var q = r'S T MEDIC SA DE CV';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('LAC Co., Ltd.', () async {
    var q = r'LAC Co., Ltd.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('Medical d o o', () async {
    var q = r'Medical d o o';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1));
    expect(r.cachedResult.matchedEntiries.length, lessThan(60));
  });
  test('H Medical', () async {
    var q = r'H Medical';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('MASS co Ltd', () async {
    var q = r'MASS co Ltd';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('TOTO(SHANGHAI) CO.,LTD.', () async {
    var q = r'TOTO(SHANGHAI) CO.,LTD.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('Nets A/S', () async {
    var q = r'Nets A/S';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('ELES, D.O.O.', () async {
    var q = r'ELES, D.O.O.';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1));
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
  test('K LINE (THAILAND) LIMITED', () async {
    var q = r'K LINE (THAILAND) LIMITED';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('P.S.G MEDICAL S.R.L.', () async {
    var q = r'P.S.G MEDICAL S.R.L.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MED KHAN', () async {
    var q = r'MED KHAN';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('M-ASTER', () async {
    var q = r'M-ASTER';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(15));
  });
  test('M ASTER', () async {
    var q = r'M ASTER';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('MINO (THAILAND) CO., LTD.', () async {
    var q = r'MINO (THAILAND) CO., LTD.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('ICL (Thailand) Co., Ltd.', () async {
    var q = r'ICL (Thailand) Co., Ltd.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('HHA', () async {
    var q = r'HHA';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('OOO IPS ', () async {
    var q = r'OOO IPS ';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('IPS S A ', () async {
    var q = r'IPS S A ';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('IPS OOO', () async {
    var q = r'IPS OOO';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('RUS-EXP', () async {
    var q = r'RUS-EXP';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('Abdul Qadir', () async {
    var q = r'Abdul Qadir';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(20)); // マッチするのが妥当な名前ばかり
  });
  test('PCI', () async {
    var q = r'PCI';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('Northwestern University', () async {
    var q = r'Northwestern University';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('RENO (THAILAND) COMPANY LIMITED', () async {
    var q = r'RENO (THAILAND) COMPANY LIMITED';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('SYSTEM DESIGN Co., Ltd.', () async {
    var q = r'SYSTEM DESIGN Co., Ltd.';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('Kao (Hong Kong) Ltd.', () async {
    var q = r'Kao (Hong Kong) Ltd.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('LLC Orman', () async {
    var q = r'LLC Orman';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(5));
    expect(r.cachedResult.matchedEntiries.length, lessThan(100));
  });
  test('DOCTOR AZ Ltd ', () async {
    var q = r'DOCTOR AZ Ltd ';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('CO-Sol Canada Inc.', () async {
    var q = r'CO-Sol Canada Inc.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.map((e)=>e.string), ['CO-SOL','CANADA','INC']);
  });
  test('Re-Teck Co., Ltd.', () async {
    var q = r'Re-Teck Co., Ltd.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.map((e)=>e.string), ['RE-TECK','CO_LTD']);
  });
  test('A&D Company, Limited', () async {
    var q = r'A&D Company, Limited';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.map((e)=>e.string), ['A', 'AND', 'D', 'CO_LTD']);
  });
  test('HONG CO TECHNOLOGY COMPANY LIMITED', () async {
    var q = r'HONG CO TECHNOLOGY COMPANY LIMITED';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.map((e)=>e.string), ['HONG','CO','TECHNOLOGY','CO_LTD']);
  });
  test('MUJI U.S.A. Limited', () async {
    var q = r'MUJI U.S.A. Limited';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.map((e)=>e.string), ['MUJI','USA','LTD']);
  });
  test('Terna S.p.A', () async {
    var q = r'Terna S.p.A';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.cachedQuery.terms.map((e)=>e.string), ['TERNA','SPA']);
  });
  test('BANK OF KESHAVARZI', () async {
    var q = r'BANK OF KESHAVARZI';
    var r = (await matcher.fmatch(q)).cachedResult.matchedEntiries.map((e) => e.entry.string).toList();
    expect(r, ['BANK KESHAVARZI', 'BANK KESHAVARZI IRAN']);
  });
  test('HARBIN INSTITUTE OF TECHNOLOGY', () async {
    var q = r'HARPIN INSTITUTE OF TECHNOLOGY';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string, 'HARBIN INSTITUTE OF TECHNOLOGY');
  });
  test('NOVOKUIBYSHEVSK REFYNERY', () async {
    var q = r'NOVOKUIBYSHEVSK REFYNERY';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('NOVOKUYBYSHEVSK REFINERY', () async {
    var q = r'NOVOKUYBYSHEVSK REFINERY';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('NOVOKUIBYSHEVSK REFINEYR', () async {
    var q = r'NOVOKUIBYSHEVSK REFINEYR';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('NOVOKUYBYSHEVSK REFINRY', () async {
    var q = r'NOVOKUYBYSHEVSK REFINRY';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string, 'NOVOKUIBYSHEVSK REFINERY');
  });
  test('CJS NOVOKUIBYSHEVSK REFINERY', () async {
    var q = r'CJS NOVOKUIBYSHEVSK REFINERY';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string,'NOVOKUIBYSHEVSK REFINERY');
  });
  test('ASTRONAUTICS SYSTEMS RESEARCH CENTRE', () async {
    var q = r'ASTRONAUTICS SYSTEMS RESEARCH CENTRE';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string, 'ASTRONAUTICS SYSTEMS RESEARCH CENTER');
  });
  test('BIMEH IRAN INSURANCE COMPANY(UK)LIMITED', () async {
    var q = r'BIMEH IRAN INSURANCE COMPANY(UK)LIMITED';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries[0].entry.string, 'BIMEH IRAN INSURANCE COMPANY (U.K.) LIMITED');
  });
  test('OBRONPROM', () async {
    var q = r'OBRONPROM';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, greaterThan(0));
  });
  test('SIRIUS CO LTD', () async {
    var q = r'SIRIUS CO LTD';
    var r = await matcher.fmatch(q);
    // expect(r.matchedEntries.length, lessThan(1)); // SIRIUSに曖昧一致するエントリが多く、JSC SIRIUS等のスコアが低い。なお、SIRIUS CO LTDはJSC SIRIUSと無関係。
    expect(r.cachedResult.matchedEntiries.length, lessThan(70));
  });
  test('D-Link Electronic Co., Ltd.', () async {
    var q = r'D-Link Electronic Co., Ltd.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });

  test('D.I.T. Co., Ltd.', () async {
    var q = r'D.I.T. Co., Ltd.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('K&S KOREA', () async {
    var q = r'K&R KOREA';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(1));
  });
  test('N C&C Co., Ltd.', () async {
    var q = r'N C&C Co., Ltd.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('Gazpromneft Moscow Refinery Joint Stock Company', () async {
    var q = r'Gazpromneft Moscow Refinery Joint Stock Company';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('Gazpromneft-MNPZ, AO', () async {
    var q = r'Gazpromneft-MNPZ, AO';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('Lukoil Permneftneorgstintez', () async {
    var q = r'Lukoil Permneftneorgstintez';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(10));
  });
  test('Lukoil Europe Holdings BV', () async {
    var q = r'Lukoil Europe Holdings BV';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('D.I.T. CO., LTD.', () async {
    var q = r'D.I.T. CO., LTD.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(2));
  });
  test('I&I CO., LTD.', () async {
    var q = r'I&I CO., LTD.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('K&S KOREA', () async {
    var q = r'K&S KOREA';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(5));
  });
  test('N C&C CO., LTD.', () async {
    var q = r'N C&C CO., LTD.';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries, <MatchedEntry>[]);
  });
  test('13th Research Institute, 9th Academy, China Aerospace Science and Technology Corporation (CASC) (中国航天科技集団公司第九研究院第十三研究所)', () async {
    var q = r'13th Research Institute, 9th Academy, China Aerospace Science and Technology Corporation (CASC) (中国航天科技集団公司第九研究院第十三研究所)';
    var r = await matcher.fmatch(q);
    expect(r.cachedResult.matchedEntiries.length, lessThan(20));
  });
}
