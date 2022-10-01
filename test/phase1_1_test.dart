// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/preprocess.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var cntxt = Preprocessor();
  await cntxt.readConfigs();

  group('Illegal Chateacter Cheking', () {
    test('char1', () {
      expect(
          cntxt.hasIllegalCharacter(
              'abcABC12345	!"#(= ~| []{}*+ ;):\\/Ca féẞẞ"\'fk lsj'),
          false);
    });
    test('char2', () {
      expect(
          cntxt.hasIllegalCharacter(
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789éẞ !"#\$%&\'()*+,-./;:<=>?@[\\]^_`{|}~'),
          false);
    });
    test('char3', () {
      expect(
          cntxt.hasIllegalCharacter(
              'abcdefghijkＡＢＣlmnop日本語qrst	uvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789éẞ !"#\$%&\'()*+,-./;:<=>?@[\\]^_`{|}~'),
          false);
    });
    test('char4', () {
      expect(
          cntxt.hasIllegalCharacter(
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          false);
    });
    test('char5', () {
      expect(
          cntxt.hasIllegalCharacter(
              'ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ'),
          false);
    });
    test('char6', () {
      expect(
          cntxt.hasIllegalCharacter( ' !"#\$%&\'()*+,-./;:<=>?@[\\]^_`{|}~'), false);
    });
    test('char7', () {
      expect(cntxt.hasIllegalCharacter( '　！”＃＄％＆’（）＋＊、－．・；：＜＝＞？＠［＼］＾＿｀｛｜｝～'), true);
    });
    test('char8', () {
      expect(cntxt.hasIllegalCharacter( 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ'), false);
    });
    test('char9', () {
      expect(cntxt.hasIllegalCharacter( 'ÐÑÒÓÔÕÖ ØÙÚÛÜÝÞß'), false);
    });
    test('char10', () {
      expect(cntxt.hasIllegalCharacter( 'àáâãäåæçèéêëìíîï'), false);
    });
    test('char11', () {
      expect(cntxt.hasIllegalCharacter( 'ðñòóôõö øùúûüýþÿ'), false);
    });
    test('char12', () {
      expect(cntxt.hasIllegalCharacter( 'ĀāĂăĄąĆćĈĉĊċČčĎď'), false);
    });
    test('char13', () {
      expect(cntxt.hasIllegalCharacter( 'ĐđĒēĔĕĖėĘęĚěĜĝĞğ'), false);
    });
    test('char14', () {
      expect(cntxt.hasIllegalCharacter( 'ĠġĢģĤĥĦħĨĩĪīĬĭĮį'), false);
    });
    test('char15', () {
      expect(cntxt.hasIllegalCharacter( 'İıĲĳĴĵĶķĸĹĺĻļĽľĿ'), false);
    });
    test('char16', () {
      expect(cntxt.hasIllegalCharacter( 'ŀŁłŃńŅņŇňŉŊŋŌōŎŏ'), false);
    });
    test('char17', () {
      expect(cntxt.hasIllegalCharacter( 'ŐőŒœŔŕŖŗŘřŚśŜŝŞş'), false);
    });
    test('char18', () {
      expect(cntxt.hasIllegalCharacter( 'ŠšŢţŤťŦŧŨũŪūŬŭŮů'), false);
    });
    test('char19', () {
      expect(cntxt.hasIllegalCharacter( 'ŰűŲųŴŵŶŷŸŹźŻżŽžſ'), false);
    });
    test('char20', () {
      expect(cntxt.hasIllegalCharacter( ' ̀ ́ ̂ ̃ ̄ ̅ ̆ ̇ ̈ ̉ ̊ ̋ ̌ ̍ ̎ ̏'), false);
    });
    test('char21', () {
      expect(cntxt.hasIllegalCharacter( ' ̐ ̑ ̒ ̓ ̔ ̕ ̖ ̗ ̘ ̙ ̚ ̛ ̜ ̝ ̞ ̟'), false);
    });
    test('char22', () {
      expect(cntxt.hasIllegalCharacter( ' ̠ ̡ ̢ ̣ ̤ ̥ ̦ ̧ ̨ ̩ ̪ ̫ ̬ ̭ ̮ ̯'), false);
    });
    test('char23', () {
      expect(cntxt.hasIllegalCharacter( ' ̰ ̱ ̲ ̳ ̴ ̵ ̶ ̷ ̸ ̹ ̺ ̻ ̼ ̽ ̾ ̿'), false);
    });
    test('char24', () {
      expect(cntxt.hasIllegalCharacter( ' ̀ ́ ͂ ̓ ̈́ ͅ ͆ ͇ ͈ ͉ ͊ ͋ ͌ ͍ ͎'), false);
    });
    test('char25', () {
      expect(cntxt.hasIllegalCharacter( ' ͐ ͑ ͒ ͓ ͔ ͕ ͖ ͗ ͘ ͙ ͚ ͛ ͜ ͝ ͞ ͟'), false);
    });
    test('char26', () {
      expect(cntxt.hasIllegalCharacter( ' ͠ ͡ ͢'), false);
    });
    test('char27', () {
      expect(cntxt.hasIllegalCharacter( 'ÀÁÂÄÅ'), false);
    });
    test('char28', () {
      expect(cntxt.hasIllegalCharacter( 'ÈÉÊË'), false);
    });
    test('char29', () {
      expect(cntxt.hasIllegalCharacter( 'ÌÍÎÏ'), false);
    });
    test('char30', () {
      expect(cntxt.hasIllegalCharacter( 'ÒÓÔÕÖ'), false);
    });
    test('char31', () {
      expect(cntxt.hasIllegalCharacter( 'ÙÚÛÜ'), false);
    });
    test('char32', () {
      expect(cntxt.hasIllegalCharacter( 'ÝŸ'), false);
    });
    test('char33', () {
      expect(cntxt.hasIllegalCharacter( 'àáâäå'), false);
    });
    test('char34', () {
      expect(cntxt.hasIllegalCharacter( 'èéêë'), false);
    });
    test('char35', () {
      expect(cntxt.hasIllegalCharacter( 'ìíîï'), false);
    });
    test('char36', () {
      expect(cntxt.hasIllegalCharacter( 'òóôõö'), false);
    });
    test('char37', () {
      expect(cntxt.hasIllegalCharacter( 'ùúûü'), false);
    });
    test('char38', () {
      expect(cntxt.hasIllegalCharacter( 'ýÿ'), false);
    });
    test('char39', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abcＡdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          false);
    });
    test('char40', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abc＋defghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char41', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abc１defghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char42', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abcあdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char43', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abcアdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char44', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abcｱdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char45', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abc亜defghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          false);
    });
    test('char46', () {
      expect(cntxt.hasIllegalCharacter( 'abc def ghi jkl'), false);
    });
    test('char47', () {
      expect(cntxt.hasIllegalCharacter( 'abc def012 34.5ghi jkl6.7.8mno'), false);
    });
    test('char48', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abc def Caféghi caféjkl hoßgeÞhoÆgeØho hoægeøhoþhoŒgeœ'),
          false);
    });
    test('char49', () {
      expect(
          cntxt.hasIllegalCharacter( 
              'abc def-ghi jkl\'mn&qrs/tuv - a & b / c \' d -e &f /g \'h i- j& k/ l\' n'),
          false);
    });
    test('char50', () {
      expect(cntxt.hasIllegalCharacter( 'abc. def.gih .klm hoge-hage.'), false);
    });
    test('char51', () {
      expect(
          cntxt.hasIllegalCharacter( 'ABC @DEF_GHI @IJK LM@NO PQR@ @STU@ @_VW @XY_ Z'),
          false);
    });
    test('char52', () {
      expect(cntxt.hasIllegalCharacter( 'abc%def(ghi(jkl)mno[pqr#stu'), false);
    });
  });

  group('Preprocess1', () {
    test('prep1-1', () {
      expect(cntxt.normalizeAndCapitalize('abcdef').string, 'ABCDEF');
    });
    test('prep1-2', () {
      expect(cntxt.normalizeAndCapitalize('  abc  def  ').string, 'ABC DEF');
    });
  });

  group('replaceStrings', () {
    test('replaceStrings1', () {
      expect(cntxt.replaceStrings('AEÆAE'), 'AEAEAE');
    });
    test('replaceStrings2', () {
      expect(cntxt.replaceStrings('OEŒOE'), 'OEOEOE');
    });
    test('replaceStrings3', () {
      expect(cntxt.replaceStrings('SSẞSS'), 'SSSSSS');
    });
  });

  group('replaceLET', () {
    test('replaceLET1', () {
      expect(cntxt.replaceLegalEntityTypes(r'AAA CO., LTD.').name, r'AAA <*CO_LTD*>');
    });
    test('replaceLET2', () {
      expect(cntxt.replaceLegalEntityTypes(r'CO., LTD. AAA').name, r'<*CO_LTD*> AAA');
    });
    test('replaceLET3', () {
      expect(cntxt.replaceLegalEntityTypes(r'AAA CO., LTD. AAA').name, r'AAA CO., LTD. AAA');
    });
  });

  group('preprocess2', () {
    test('prep2-1', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r'abc def012 34.5ghi jkl6.7.8mno')).terms.map((e) => e.string).toList(),
      ['ABC', 'DEF012', '34.5GHI', 'JKL6.7.8MNO']);
    });
    test('prep2-2', () { // 定義変更が必要 → 修正済み
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r'abc def Caféghi caféjkl hoßgeÞhoÆgeØho hoægeøhoþhoŒgeœ')).terms.map((e) => e.string).toList(),
      ['ABC','DEF','CAFEGHI','CAFEJKL','HOSSGEYHOAEGEOHO','HOAEGEOHOYHOOEGEOE']);
    });
    test('prep2-3', () { // ????
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('abc def-ghi jkl\'mn&qrs/tuv - a & b / c \' d -e &f /g \'h i- j& k/ l\' n')).terms.map((e) => e.string).toList(),
      ['ABC','DEF-GHI','JKL\'MN', 'AND', 'QRS', 'TUV','A','AND','B','C','D','E','AND','F','G','H', '1','J','AND','K','L','N']);
    });
    test('prep2-4', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('abc. def.ghi .klm hoge-hage.')).terms.map((e) => e.string).toList(),
      ['ABC.', 'DEF.GHI', 'KLM', 'HOGE-HAGE']);
    });
    test('prep2-5', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('ABC <*DEF_GHI*> <*IJK*> LM@NO PQR@ @STU@ <*_VW> <*XY_ Z*>')).terms.map((e) => e.string).toList(),
      ['ABC','*','DEF','GHI','*','*','IJK','*','LM','AT','NO.','PQR','AT','AT','STU','AT','*','VW','*','XY','Z','*']);
    });
    test('prep2-6', () { // ????
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('abc%def(ghi(jkl)mno[pqr#stu')).terms.map((e) => e.string).toList(),
      ['ABC','%','DEF','GHI','JKL','MNO','PQR','NO.','STU']);
    });
    test('prep2-7', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ')).terms.map((e) => e.string).toList(),
      ['AAAAAAAECEEEEIIII']);
    });
    test('prep2-8', () { // 定義変更が必要 → 修正済み
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('ÐÑÒÓÔÕÖ ØÙÚÛÜÝÞß')).terms.map((e) => e.string).toList(),
      ['DNOOOOO','OUUUUYYSS']);
    });
    test('prep2-9', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('àáâãäåæçèéêëìíîï')).terms.map((e) => e.string).toList(),
      ['AAAAAAAECEEEEIIII']);
    });
    test('prep2-10', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('ÀÁÂÄÅ')).terms.map((e) => e.string).toList(),
      ['AAAAA']);
    });
    test('prep2-11', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('ÈÉÊË')).terms.map((e) => e.string).toList(),
      ['EEEE']);
    });
    test('prep2-12', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('ABC ̀ ́ ̂ ̃ ̄ ̅ ̆ ̇ ̈ ̉ ̊ ̋ ̌ ̍ ̎ ̏ABC')).terms.map((e) => e.string).toList(),
      ['ABC','ABC']);
    });
    test('prep2-13', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C.')).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-14', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('A B C ABC A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A.B.C. A B C')).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-15', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('A.B.C. A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A.B.C.')).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-16', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('A.B.C A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A.B.C')).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-17', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('A. B. C. .A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A. B. C.')).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-18', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('A. B. C A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A. B. C')).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-19', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('A. ABC. )ABC. ABC.( ABC.ABC.ABC.)ABC. ABC. .ABC .ABC.')).terms.map((e) => e.string).toList(),
      ['A.', 'ABC.', 'ABC.', 'ABC.', 'ABC.ABC.ABC', 'ABC.', 'ABC.', 'ABC', 'ABC']);
    });
    test('prep2-20', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r"ABC A&BC A-BC A/BC A+BC A'BC")).terms.map((e) => e.string).toList(),
      ['ABC','A', 'AND', 'BC','A-BC','A', 'BC','A', '+', 'BC',"A'BC"]);
    });
    test('prep2-21', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r"ABC A&BC&DE A-BC/DE A/BC+DE A+BC'DE A'BC&DE")).terms.map((e) => e.string).toList(),
      ['ABC','A', 'AND', 'BC', 'AND', 'DE','A-BC', 'DE','A', 'BC', '+', 'DE','A', '+', "BC'DE","A'BC", 'AND', 'DE']);
    });
    test('prep2-22', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r"'ABC' &ABC& -ABC ABC/ +A+BC+ ABC'")).terms.map((e) => e.string).toList(),
      [r'ABC','AND',r'ABC', 'AND',r'ABC',r'ABC','+',r'A', '+', 'BC', '+',r'ABC',]);
    });
    test('prep2-23', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize('123/456 123.456/123 123/456.123 123.456.789 123.456.789.')).terms.map((e) => e.string).toList(),
      ['123/456', '123.456','123', '123/456', '123', '123.456.789', '123.456.789']);
    });
    test('prep2-24', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize("<ABC>(ABC) 'ABC <ABC> <ABC,ABC> 'ABC A'BC ABC' ABC' <ABC><ABC>")).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC',"A'BC",'ABC','ABC','ABC','ABC']);
    });
    test('prep2-25', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize("<ABC>ABC 'ABC <ABC> <ABC,ABC> 'ABC A'BC ABC' ABC' ABC<ABC>")).terms.map((e) => e.string).toList(),
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC',"A'BC",'ABC','ABC','ABC','ABC']);
    });
    test('prep2-26', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r"ABC !A&BC# $A-BC% &A/BC* +A+BC? @A'BC^ &A&BC!A&BC#A+BC?A'BC@ABC^ABC")).terms.map((e) => e.string).toList(),
      ['ABC','!','A','AND','BC','NO.',r'$','A-BC','%','AND','A','BC','*','+','A','+','BC','?','AT',"A'BC",'^','AND','A','AND','BC','!','A', 'AND', 'BC','NO.','A', '+', 'BC','?',"A'BC",'AT','ABC','^','ABC']);
    });
    test('prep2-27', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r"SA'B, ILYAS")).terms.map((e) => e.string).toList(),
      ['SA','B', 'ILYAS']);
    });
    test('prep2-28', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r'a b c d e f g h i j.k.l.m.n.o.p.q.r s. t. u. v. w. x. y. z. a a b c d e f g h i.j.k.l.m.n.o.p. q. r. s. t. u. v. w. x.')).terms.map((e) => e.string).toList(),
      ['ABCDEFGH I','JKLMNOPQ.R', 'STUVWXYZ. A', 'ABCDEFGH', 'IJKLMNOP', 'QRSTUVWX']);
    });
    test('prep2-29', () {
      expect(cntxt.preprocess(cntxt.normalizeAndCapitalize(r'N C&C CO., LTD.')).terms.map((e) => e.string).toList(),
      ['N','C', 'AND', 'C', 'CO_LTD']);
    });
  });
}
