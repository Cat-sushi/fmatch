// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'util.dart';

class Paths {
  static var setting = 'lib/config/Settings.csv';
  static var legalCaharacters = 'lib/config/LegalCharacters.csv';
  static var stringReplacement = 'lib/config/StringReplacement.csv';
  static var legalEntryType = 'lib/config/LegalEntityTypes.csv';
  static var words = 'lib/config/Words.csv';
  static var wordReplacement = 'lib/config/WordReplacement.csv';
  static var list = 'lib/database/list.csv';
  static var db = 'lib/database/db.csv';
  static var idb = 'lib/database/idb.json';
  static var crossTransactionalWhiteList = 'lib/database/white_list.csv';
}

class Settings {
  static double termMatchingMinLetterRatio = 0.6666;
  static int termMatchingMinLetters = 3;
  static double termPartialMatchingMinLetterRatio = 0.2;
  static int termPartialMatchingMinLetters = 2;
  static double queryMatchingMinTermRatio = 0.5;
  static int queryMatchingMinTerms = 1;
  static double queryMatchingTypicalProperNounDf = 10.0;
  static double queryMatchingMinTermOrderSimilarity = 0.4444;
  static double scoreIdfMagnifier = 2.0;
  // 以下メンバはPoCで追加
  static double fallbackThresholdCombinations =
      pow(fallbackMaxQueryTermMobility + 1, fallbackMaxQueryTerms).toDouble();
  static int fallbackMaxQueryTerms = 10;
  static int fallbackMaxQueryTermMobility = 3;
  static double queryMatchingTermOrderCoefficent = 0.5;
  static int queryResultCacheSize = 10000;
  static Future<void> read() async {
    await readSettings(Paths.setting);
  }

  static Future<void> readSettings(String path) async {
    await for (var l in readCsvLines(path)) {
      if (l.length < 2 || l[0] == null || l[1] == null) {
        continue;
      }
      var val = double.parse(l[1]!);
      switch (l[0]!) {
        case 'termMatchingMinLetterRatio':
          termMatchingMinLetterRatio = val;
          break;
        case 'termMatchingMinLetters':
          termMatchingMinLetters = val.toInt();
          break;
        case 'termPartialMatchingMinLetterRatio':
          termPartialMatchingMinLetterRatio = val;
          break;
        case 'termPartialMatchingMinLetters':
          termPartialMatchingMinLetters = val.toInt();
          break;
        case 'queryMatchingMinTermRatio':
          queryMatchingMinTermRatio = val;
          break;
        case 'queryMatchingMinTerms':
          queryMatchingMinTerms = val.toInt();
          break;
        case 'queryMatchingTypicalProperNounDf':
          queryMatchingTypicalProperNounDf = val;
          break;
        case 'queryMatchingMinTermOrderSimilarity':
          queryMatchingMinTermOrderSimilarity = val;
          break;
        case 'scoreIdfMagnifier':
          scoreIdfMagnifier = val;
          break;
        case 'fallbackThresholdCombinations':
          fallbackThresholdCombinations = val;
          break;
        case 'fallbackMaxQueryTerms':
          fallbackMaxQueryTerms = val.toInt();
          break;
        case 'fallbackMaxQueryTermMobility':
          fallbackMaxQueryTermMobility = val.toInt();
          break;
        case 'queryMatchingTermOrderCoefficent':
          queryMatchingTermOrderCoefficent = val.toDouble();
          break;
        case 'queryResultCacheSize':
          queryResultCacheSize = val.toInt();
          break;
        default:
          break;
      }
    }
  }
}

class StringReplacement {
  final RegExp regexp;
  final String replacement;
  StringReplacement(this.regexp, this.replacement);
}

class LegalEntityTypeReplacement {
  final RegExp regexpPostfix;
  final RegExp regexpPrefix;
  final String replacement;
  LegalEntityTypeReplacement(
      this.regexpPostfix, this.regexpPrefix, this.replacement);
}

class WordReplacement {
  final RegExp regexps;
  final String replacement;
  WordReplacement(this.regexps, this.replacement);
}

class Configs {
  static late RegExp legalChars;
  static late List<StringReplacement> stringRreplacements;
  static late List<LegalEntityTypeReplacement> legalEntryTypeReplacements;
  static late RegExp words;
  static late List<WordReplacement> wordRreplacements;
  static Future<void> read() async {
    legalChars = await _readLegalCharConf(Paths.legalCaharacters);
    stringRreplacements =
        await _readStringReplacementConf(Paths.stringReplacement);
    legalEntryTypeReplacements =
        await _readLegalEntityTypesConf(Paths.legalEntryType);
    words = await _readWordsConf(Paths.words);
    wordRreplacements = await _readWordReplacementConf(Paths.wordReplacement);
  }

  static Future<RegExp> _readLegalCharConf(String path) async {
    var pattern = StringBuffer('(');
    await for (var l in readCsvLines(path)) {
      if (l.isEmpty || l[0] == null) {
        continue;
      }
      for (var p in l) {
        if (p == '') {
          break;
        }
        if (pattern.length > 1) {
          pattern.write('|');
        }
        pattern.write(p);
      }
    }
    pattern.write(')*');
    return regExp(pattern.toString());
  }

  static Future<List<StringReplacement>> _readStringReplacementConf(
      String path) async {
    var pattern = StringBuffer();
    String replacement;
    stringRreplacements = <StringReplacement>[];
    await for (var l in readCsvLines(path)) {
      if (l.length < 2 || l[0] == null) {
        continue;
      }
      replacement = l.removeAt(0)!;
      pattern.clear();
      for (var p in l) {
        if (p == '') {
          break;
        }
        if (pattern.isNotEmpty) {
          pattern.write('|');
        }
        pattern.write(p);
      }
      stringRreplacements
          .add(StringReplacement(regExp(pattern.toString()), replacement));
    }
    return stringRreplacements.toList(growable: false);
  }

  static Future<List<LegalEntityTypeReplacement>> _readLegalEntityTypesConf(
      String path) async {
    var pattern = StringBuffer();
    RegExp regexpPostfix;
    RegExp regexpPrefix;
    String replacement;
    legalEntryTypeReplacements = <LegalEntityTypeReplacement>[];
    await for (var l in readCsvLines(path)) {
      if (l.length < 2 || l[0] == null) {
        continue;
      }
      replacement = l.removeAt(0)!;
      pattern.clear();
      pattern.write(r'(');
      for (var p in l) {
        if (p == '') {
          break;
        }
        if (pattern.length > 1) {
          pattern.write('|');
        }
        pattern.write(p);
      }
      pattern.write(r')');
      regexpPostfix = regExp(r'(?<=\W|\b|^)' + pattern.toString() + r' ?(?<s>\(.*\))?$');
      regexpPrefix = regExp(r'^' + pattern.toString() + r'(?=\W|\b|$)');
      legalEntryTypeReplacements.add(
          LegalEntityTypeReplacement(regexpPostfix, regexpPrefix, replacement));
    }
    return legalEntryTypeReplacements.toList(growable: false);
  }

  static Future<RegExp> _readWordsConf(String path) async {
    var pattern = StringBuffer();
    await for (var l in readCsvLines(path)) {
      if (l.isEmpty || l[0] == null) {
        continue;
      }
      for (var p in l) {
        if (p == '') {
          break;
        }
        if (pattern.isNotEmpty) {
          pattern.write('|');
        }
        pattern.write(p);
      }
    }
    return regExp(pattern.toString());
  }

  static Future<List<WordReplacement>> _readWordReplacementConf(
      String path) async {
    var pattern = StringBuffer();
    String toString;
    wordRreplacements = <WordReplacement>[];
    await for (var l in readCsvLines(path)) {
      if (l.length < 2 || l[0] == null) {
        continue;
      }
      toString = l.removeAt(0)!;
      pattern.clear();
      for (var p in l) {
        if (p == '') {
          break;
        }
        if (pattern.isNotEmpty) {
          pattern.write('|');
        }
        pattern.write(r'^');
        pattern.write(p);
        pattern.write(r'$');
      }
      wordRreplacements
          .add(WordReplacement(regExp(pattern.toString()), toString));
    }
    return wordRreplacements.toList(growable: false);
  }
}
