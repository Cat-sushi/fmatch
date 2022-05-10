// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/configs.dart';
import 'package:fmatch/preprocess.dart';
import 'package:test/test.dart';

Future<void> main() async {
  await Settings.read();
  await Configs.read();

  group('Illegal Chateacter Cheking', () {
    test('char1', () {
      expect(
          hasIllegalCharacter(
              'abcABC12345	!"#(= ~| []{}*+ ;):\\/Ca féẞẞ"\'fk lsj'),
          false);
    });
    test('char2', () {
      expect(
          hasIllegalCharacter(
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789éẞ !"#\$%&\'()*+,-./;:<=>?@[\\]^_`{|}~'),
          false);
    });
    test('char3', () {
      expect(
          hasIllegalCharacter(
              'abcdefghijkＡＢＣlmnop日本語qrst	uvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789éẞ !"#\$%&\'()*+,-./;:<=>?@[\\]^_`{|}~'),
          false);
    });
    test('char4', () {
      expect(
          hasIllegalCharacter(
              'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          false);
    });
    test('char5', () {
      expect(
          hasIllegalCharacter(
              'ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ'),
          false);
    });
    test('char6', () {
      expect(
          hasIllegalCharacter(' !"#\$%&\'()*+,-./;:<=>?@[\\]^_`{|}~'), false);
    });
    test('char7', () {
      expect(hasIllegalCharacter('　！”＃＄％＆’（）＋＊、－．・；：＜＝＞？＠［＼］＾＿｀｛｜｝～'), true);
    });
    test('char8', () {
      expect(hasIllegalCharacter('ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ'), false);
    });
    test('char9', () {
      expect(hasIllegalCharacter('ÐÑÒÓÔÕÖ ØÙÚÛÜÝÞß'), false);
    });
    test('char10', () {
      expect(hasIllegalCharacter('àáâãäåæçèéêëìíîï'), false);
    });
    test('char11', () {
      expect(hasIllegalCharacter('ðñòóôõö øùúûüýþÿ'), false);
    });
    test('char12', () {
      expect(hasIllegalCharacter('ĀāĂăĄąĆćĈĉĊċČčĎď'), false);
    });
    test('char13', () {
      expect(hasIllegalCharacter('ĐđĒēĔĕĖėĘęĚěĜĝĞğ'), false);
    });
    test('char14', () {
      expect(hasIllegalCharacter('ĠġĢģĤĥĦħĨĩĪīĬĭĮį'), false);
    });
    test('char15', () {
      expect(hasIllegalCharacter('İıĲĳĴĵĶķĸĹĺĻļĽľĿ'), false);
    });
    test('char16', () {
      expect(hasIllegalCharacter('ŀŁłŃńŅņŇňŉŊŋŌōŎŏ'), false);
    });
    test('char17', () {
      expect(hasIllegalCharacter('ŐőŒœŔŕŖŗŘřŚśŜŝŞş'), false);
    });
    test('char18', () {
      expect(hasIllegalCharacter('ŠšŢţŤťŦŧŨũŪūŬŭŮů'), false);
    });
    test('char19', () {
      expect(hasIllegalCharacter('ŰűŲųŴŵŶŷŸŹźŻżŽžſ'), false);
    });
    test('char20', () {
      expect(hasIllegalCharacter(' ̀ ́ ̂ ̃ ̄ ̅ ̆ ̇ ̈ ̉ ̊ ̋ ̌ ̍ ̎ ̏'), false);
    });
    test('char21', () {
      expect(hasIllegalCharacter(' ̐ ̑ ̒ ̓ ̔ ̕ ̖ ̗ ̘ ̙ ̚ ̛ ̜ ̝ ̞ ̟'), false);
    });
    test('char22', () {
      expect(hasIllegalCharacter(' ̠ ̡ ̢ ̣ ̤ ̥ ̦ ̧ ̨ ̩ ̪ ̫ ̬ ̭ ̮ ̯'), false);
    });
    test('char23', () {
      expect(hasIllegalCharacter(' ̰ ̱ ̲ ̳ ̴ ̵ ̶ ̷ ̸ ̹ ̺ ̻ ̼ ̽ ̾ ̿'), false);
    });
    test('char24', () {
      expect(hasIllegalCharacter(' ̀ ́ ͂ ̓ ̈́ ͅ ͆ ͇ ͈ ͉ ͊ ͋ ͌ ͍ ͎'), false);
    });
    test('char25', () {
      expect(hasIllegalCharacter(' ͐ ͑ ͒ ͓ ͔ ͕ ͖ ͗ ͘ ͙ ͚ ͛ ͜ ͝ ͞ ͟'), false);
    });
    test('char26', () {
      expect(hasIllegalCharacter(' ͠ ͡ ͢'), false);
    });
    test('char27', () {
      expect(hasIllegalCharacter('ÀÁÂÄÅ'), false);
    });
    test('char28', () {
      expect(hasIllegalCharacter('ÈÉÊË'), false);
    });
    test('char29', () {
      expect(hasIllegalCharacter('ÌÍÎÏ'), false);
    });
    test('char30', () {
      expect(hasIllegalCharacter('ÒÓÔÕÖ'), false);
    });
    test('char31', () {
      expect(hasIllegalCharacter('ÙÚÛÜ'), false);
    });
    test('char32', () {
      expect(hasIllegalCharacter('ÝŸ'), false);
    });
    test('char33', () {
      expect(hasIllegalCharacter('àáâäå'), false);
    });
    test('char34', () {
      expect(hasIllegalCharacter('èéêë'), false);
    });
    test('char35', () {
      expect(hasIllegalCharacter('ìíîï'), false);
    });
    test('char36', () {
      expect(hasIllegalCharacter('òóôõö'), false);
    });
    test('char37', () {
      expect(hasIllegalCharacter('ùúûü'), false);
    });
    test('char38', () {
      expect(hasIllegalCharacter('ýÿ'), false);
    });
    test('char39', () {
      expect(
          hasIllegalCharacter(
              'abcＡdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          false);
    });
    test('char40', () {
      expect(
          hasIllegalCharacter(
              'abc＋defghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char41', () {
      expect(
          hasIllegalCharacter(
              'abc１defghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char42', () {
      expect(
          hasIllegalCharacter(
              'abcあdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char43', () {
      expect(
          hasIllegalCharacter(
              'abcアdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char44', () {
      expect(
          hasIllegalCharacter(
              'abcｱdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          true);
    });
    test('char45', () {
      expect(
          hasIllegalCharacter(
              'abc亜defghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),
          false);
    });
    test('char46', () {
      expect(hasIllegalCharacter('abc def ghi jkl'), false);
    });
    test('char47', () {
      expect(hasIllegalCharacter('abc def012 34.5ghi jkl6.7.8mno'), false);
    });
    test('char48', () {
      expect(
          hasIllegalCharacter(
              'abc def Caféghi caféjkl hoßgeÞhoÆgeØho hoægeøhoþhoŒgeœ'),
          false);
    });
    test('char49', () {
      expect(
          hasIllegalCharacter(
              'abc def-ghi jkl\'mn&qrs/tuv - a & b / c \' d -e &f /g \'h i- j& k/ l\' n'),
          false);
    });
    test('char50', () {
      expect(hasIllegalCharacter('abc. def.gih .klm hoge-hage.'), false);
    });
    test('char51', () {
      expect(
          hasIllegalCharacter('ABC @DEF_GHI @IJK LM@NO PQR@ @STU@ @_VW @XY_ Z'),
          false);
    });
    test('char52', () {
      expect(hasIllegalCharacter('abc%def(ghi(jkl)mno[pqr#stu'), false);
    });
  });

  group('Preprocess1', () {
    test('prep1-1', () {
      expect(normalizeAndCapitalize('abcdef'), 'ABCDEF');
    });
    test('prep1-2', () {
      expect(normalizeAndCapitalize('  abc  def  '), 'ABC DEF');
    });
  });

  group('replaceStrings', () {
    test('replaceStrings1', () {
      expect(replaceStrings('AEÆAE'), 'AEAEAE');
    });
    test('replaceStrings2', () {
      expect(replaceStrings('OEŒOE'), 'OEOEOE');
    });
    test('replaceStrings3', () {
      expect(replaceStrings('SSẞSS'), 'SSSSSS');
    });
  });

  group('replaceLET', () {
    test('replaceLET1', () {
      expect(replaceLegalEntiyTypes(r'AAA CO., LTD.').name, r'AAA <*CO_LTD*>');
    });
    test('replaceLET2', () {
      expect(replaceLegalEntiyTypes(r'CO., LTD. AAA').name, r'<*CO_LTD*> AAA');
    });
    test('replaceLET3', () {
      expect(replaceLegalEntiyTypes(r'AAA CO., LTD. AAA').name, r'AAA CO., LTD. AAA');
    });
  });

  group('preprocess2', () {
    test('prep2-1', () {
      expect(preprocess(normalizeAndCapitalize(r'abc def012 34.5ghi jkl6.7.8mno')).terms,
      ['ABC', 'DEF012', '34.5GHI', 'JKL6.7.8MNO']);
    });
    test('prep2-2', () { // 定義変更が必要 → 修正済み
      expect(preprocess(normalizeAndCapitalize(r'abc def Caféghi caféjkl hoßgeÞhoÆgeØho hoægeøhoþhoŒgeœ')).terms,
      ['ABC','DEF','CAFEGHI','CAFEJKL','HOSSGEYHOAEGEOHO','HOAEGEOHOYHOOEGEOE']);
    });
    test('prep2-3', () { // ????
      expect(preprocess(normalizeAndCapitalize('abc def-ghi jkl\'mn&qrs/tuv - a & b / c \' d -e &f /g \'h i- j& k/ l\' n')).terms,
      ['ABC','DEF-GHI','JKL\'MN&QRS/TUV','A','AND','B','C','D','E','AND','F','G','H', '1','J','AND','K','L','N']);
    });
    test('prep2-4', () {
      expect(preprocess(normalizeAndCapitalize('abc. def.ghi .klm hoge-hage.')).terms,
      ['ABC.', 'DEF.GHI', 'KLM', 'HOGE-HAGE']);
    });
    test('prep2-5', () {
      expect(preprocess(normalizeAndCapitalize('ABC <*DEF_GHI*> <*IJK*> LM@NO PQR@ @STU@ <*_VW> <*XY_ Z*>')).terms,
      ['ABC','*','DEF','GHI','*','*','IJK','*','LM','AT','NO.','PQR','AT','AT','STU','AT','*','VW','*','XY','Z','*']);
    });
    test('prep2-6', () { // ????
      expect(preprocess(normalizeAndCapitalize('abc%def(ghi(jkl)mno[pqr#stu')).terms,
      ['ABC','%','DEF','GHI','JKL','MNO','PQR','NO.','STU']);
    });
    test('prep2-7', () {
      expect(preprocess(normalizeAndCapitalize('ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ')).terms,
      ['AAAAAAAECEEEEIIII']);
    });
    test('prep2-8', () { // 定義変更が必要 → 修正済み
      expect(preprocess(normalizeAndCapitalize('ÐÑÒÓÔÕÖ ØÙÚÛÜÝÞß')).terms,
      ['DNOOOOO','OUUUUYYSS']);
    });
    test('prep2-9', () {
      expect(preprocess(normalizeAndCapitalize('àáâãäåæçèéêëìíîï')).terms,
      ['AAAAAAAECEEEEIIII']);
    });
    test('prep2-10', () {
      expect(preprocess(normalizeAndCapitalize('ÀÁÂÄÅ')).terms,
      ['AAAAA']);
    });
    test('prep2-11', () {
      expect(preprocess(normalizeAndCapitalize('ÈÉÊË')).terms,
      ['EEEE']);
    });
    test('prep2-12', () {
      expect(preprocess(normalizeAndCapitalize('ABC ̀ ́ ̂ ̃ ̄ ̅ ̆ ̇ ̈ ̉ ̊ ̋ ̌ ̍ ̎ ̏ABC')).terms,
      ['ABC','ABC']);
    });
    test('prep2-13', () {
      expect(preprocess(normalizeAndCapitalize('A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C.')).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-14', () {
      expect(preprocess(normalizeAndCapitalize('A B C ABC A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A.B.C. A B C')).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-15', () {
      expect(preprocess(normalizeAndCapitalize('A.B.C. A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A.B.C.')).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-16', () {
      expect(preprocess(normalizeAndCapitalize('A.B.C A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A.B.C')).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-17', () {
      expect(preprocess(normalizeAndCapitalize('A. B. C. .A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A. B. C.')).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-18', () {
      expect(preprocess(normalizeAndCapitalize('A. B. C A B C A.B.C A.B.C. A. B. C A. B. C A. B. C(A. B. C)A. B. C.(A.B.C.ABC A B C ABC A.B.C.(A. B. C. A.B.C. A. B. C')).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC','ABC']);
    });
    test('prep2-19', () {
      expect(preprocess(normalizeAndCapitalize('A. ABC. )ABC. ABC.( ABC.ABC.ABC.)ABC. ABC. .ABC .ABC.')).terms,
      ['A.', 'ABC.', 'ABC.', 'ABC.', 'ABC.ABC.ABC', 'ABC.', 'ABC.', 'ABC', 'ABC']);
    });
    test('prep2-20', () {
      expect(preprocess(normalizeAndCapitalize(r"ABC A&BC A-BC A/BC A+BC A'BC")).terms,
      ['ABC','A&BC','A-BC','A/BC','A+BC',"A'BC"]);
    });
    test('prep2-21', () {
      expect(preprocess(normalizeAndCapitalize(r"ABC A&BC&DE A-BC/DE A/BC+DE A+BC'DE A'BC&DE")).terms,
      ['ABC','A&BC&DE','A-BC/DE','A/BC+DE',"A+BC'DE","A'BC&DE"]);
    });
    test('prep2-22', () {
      expect(preprocess(normalizeAndCapitalize(r"'ABC' &ABC& -ABC ABC/ +A+BC+ ABC'")).terms,
      [r'ABC','AND',r'ABC', 'AND',r'ABC',r'ABC','+',r'A+BC', '+',r'ABC',]);
    });
    test('prep2-23', () {
      expect(preprocess(normalizeAndCapitalize('123/456 123.456/123 123/456.123 123.456.789 123.456.789.')).terms,
      ['123/456', '123.456/123', '123/456.123', '123.456.789', '123.456.789']);
    });
    test('prep2-24', () {
      expect(preprocess(normalizeAndCapitalize("<ABC>(ABC) 'ABC <ABC> <ABC,ABC> 'ABC A'BC ABC' ABC' <ABC><ABC>")).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC',"A'BC",'ABC','ABC','ABC','ABC']);
    });
    test('prep2-25', () {
      expect(preprocess(normalizeAndCapitalize("<ABC>ABC 'ABC <ABC> <ABC,ABC> 'ABC A'BC ABC' ABC' ABC<ABC>")).terms,
      ['ABC','ABC','ABC','ABC','ABC','ABC','ABC',"A'BC",'ABC','ABC','ABC','ABC']);
    });
    test('prep2-26', () {
      expect(preprocess(normalizeAndCapitalize(r"ABC !A&BC# $A-BC% &A/BC* +A+BC? @A'BC^ &A&BC!A&BC#A+BC?A'BC@ABC^ABC")).terms,
      ['ABC','!','A&BC','NO.',r'$','A-BC','%', 'AND','A/BC','*','+','A+BC','?','AT',"A'BC",'^','AND','A&BC','!','A&BC','NO.','A+BC','?',"A'BC",'AT','ABC','^','ABC']);
    });
    test('prep2-27', () {
      expect(preprocess(normalizeAndCapitalize(r"SA'B, ILYAS")).terms,
      ['SA','B', 'ILYAS']);
    });
    test('prep2-28', () {
      expect(preprocess(normalizeAndCapitalize(r'a b c d e f g h i j.k.l.m.n.o.p.q.r s. t. u. v. w. x. y. z. a a b c d e f g h i.j.k.l.m.n.o.p. q. r. s. t. u. v. w. x.')).terms,
      ['ABCDEFGH I','JKLMNOPQ.R', 'STUVWXYZ. A', 'ABCDEFGH', 'IJKLMNOP', 'QRSTUVWX']);
    });
    test('prep2-29', () {
      expect(preprocess(normalizeAndCapitalize(r'N C&C CO., LTD.')).terms,
      ['N','C&C', 'CO_LTD']);
    });
  });
}
