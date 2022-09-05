// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'util.dart';

class Paths {
  static var setting = 'lib/config/settings.csv';
  static var legalCaharacters = 'lib/config/legal_characters.csv';
  static var stringReplacement = 'lib/config/string_replacement.csv';
  static var legalEntryType = 'lib/config/legal_entity_types.csv';
  static var words = 'lib/config/words.csv';
  static var wordReplacement = 'lib/config/word_replacement.csv';
  static var list = 'lib/database/list.csv';
  static var db = 'lib/database/db.csv';
  static var idb = 'lib/database/idb.json';
  static var whiteQueries = 'lib/database/white_queries.csv';
}

mixin Settings {
  double termMatchingMinLetterRatio = 0.6666;
  int termMatchingMinLetters = 3;
  double termPartialMatchingMinLetterRatio = 0.2;
  int termPartialMatchingMinLetters = 2;
  double queryMatchingMinTermRatio = 0.5;
  int queryMatchingMinTerms = 1;
  double queryMatchingTypicalProperNounDf = 10.0;
  double queryMatchingMinTermOrderSimilarity = 0.4444;
  double scoreIdfMagnifier = 2.0;
  // 以下メンバはPoCで追加
  late double fallbackThresholdCombinations =
      pow(fallbackMaxQueryTermMobility + 1, fallbackMaxQueryTerms).toDouble();
  int fallbackMaxQueryTerms = 6;
  int fallbackMaxQueryTermMobility = 6;
  double queryMatchingTermOrderCoefficent = 0.5;
  int queryResultCacheSize = 10000;
  int serverCount = Platform.numberOfProcessors;

  Future<void> readSettings(String? path) async {
    path ??= Paths.setting;
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
        case 'serverCount':
          serverCount = val.toInt();
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

mixin Configs {
  late final RegExp legalChars;
  late final List<StringReplacement> stringRreplacements;
  late final List<LegalEntityTypeReplacement> legalEntryTypeReplacements;
  late final RegExp words;
  late final List<WordReplacement> wordReplacements;
  Future<void> readConfigs() async {
    await _readLegalCharConf(Paths.legalCaharacters);
    await _readStringReplacementConf(Paths.stringReplacement);
    await _readLegalEntityTypesConf(Paths.legalEntryType);
    await _readWordsConf(Paths.words);
    await _readWordReplacementConf(Paths.wordReplacement);
  }

  Future<void> _readLegalCharConf(String path) async {
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
    legalChars = regExp(pattern.toString());
  }

  Future<void> _readStringReplacementConf(String path) async {
    var pattern = StringBuffer();
    String replacement;
    var strRpl = <StringReplacement>[];
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
      strRpl.add(StringReplacement(regExp(pattern.toString()), replacement));
    }
    stringRreplacements = strRpl.toList(growable: false);
  }

  Future<void> _readLegalEntityTypesConf(String path) async {
    var pattern = StringBuffer();
    RegExp regexpPostfix;
    RegExp regexpPrefix;
    String replacement;
    var letRepl = <LegalEntityTypeReplacement>[];
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
      regexpPostfix =
          regExp(r'(?<=\W|\b|^)' + pattern.toString() + r' ?(?<s>\(.*\))?$');
      regexpPrefix = regExp(r'^' + pattern.toString() + r'(?=\W|\b|$)');
      letRepl.add(
          LegalEntityTypeReplacement(regexpPostfix, regexpPrefix, replacement));
    }
    legalEntryTypeReplacements = letRepl.toList(growable: false);
  }

  Future<void> _readWordsConf(String path) async {
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
    words = regExp(pattern.toString());
  }

  Future<void> _readWordReplacementConf(String path) async {
    var pattern = StringBuffer();
    String toString;
    var wordRpl = <WordReplacement>[];
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
      wordRpl.add(WordReplacement(regExp(pattern.toString()), toString));
    }
    wordReplacements = wordRpl.toList(growable: false);
  }
}
