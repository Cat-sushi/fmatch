// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2020, 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'util.dart';

class Pathes {
  static var setting = 'assets/config/settings.csv';
  static var legalCaharacters = 'assets/config/legal_characters.csv';
  static var characterReplacement = 'assets/config/character_replacement.csv';
  static var stringReplacement = 'assets/config/string_replacement.csv';
  static var legalEntryType = 'assets/config/legal_entity_types.csv';
  static var words = 'assets/config/words.csv';
  static var wordReplacement = 'assets/config/word_replacement.csv';
  static var whiteQueries = 'assets/config/white_queries.csv';
  static var list = 'assets/database/list.csv';
  static var db = 'assets/database/db.csv';
  static var idb = 'assets/database/idb.json';
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
  late double fallbackThresholdCombinations = 117649;
  int fallbackMaxQueryTerms = 6;
  int fallbackMaxQueryTermMobility = 6;
  double queryMatchingTermOrderCoefficent = 0.5;
  int queryResultCacheSize = 100000;

  Future<void> readSettings([String? path]) async {
    path ??= Pathes.setting;
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
  StringReplacement(this.regexp, this.replacement);
  final RegExp regexp;
  final String replacement;
}

class LegalEntityTypeReplacement {
  LegalEntityTypeReplacement(
      this.regexpPostfix, this.regexpPrefix, this.replacement);
  final RegExp regexpPostfix;
  final RegExp regexpPrefix;
  final String replacement;
}

class WordReplacement {
  WordReplacement(this.regexps, this.replacement);
  final RegExp regexps;
  final String replacement;
}

mixin Configs {
  late final RegExp legalChars;
  late final Map<String, String> characterRreplacements;
  late final List<StringReplacement> stringRreplacements;
  late final List<LegalEntityTypeReplacement> legalEntryTypeReplacements;
  late final RegExp words;
  late final List<WordReplacement> wordReplacements;
  late final List<String> rawWhiteQueries;
  Future<void> readConfigs() async {
    await _readLegalCharConf(Pathes.legalCaharacters);
    await _readCharacterReplacementConf(Pathes.characterReplacement);
    await _readStringReplacementConf(Pathes.stringReplacement);
    await _readLegalEntityTypesConf(Pathes.legalEntryType);
    await _readWordsConf(Pathes.words);
    await _readWordReplacementConf(Pathes.wordReplacement);
    await _readWhiteQueries(Pathes.whiteQueries);
  }

  Future<void> _readLegalCharConf(String path) async {
    var pattern = StringBuffer('(');
    await for (var l in readCsvLines(path)) {
      if (l.isEmpty || l[0] == null) {
        continue;
      }
      for (var p in l) {
        if (p == null || p == '') {
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

  Future<void> _readCharacterReplacementConf(String path) async {
    characterRreplacements = {};
    await for (var l in readCsvLines(path)) {
      if (l.length < 2) {
        continue;
      }
      var replacement = l.removeAt(0);
      if (replacement == null) {
        continue;
      }
      if (replacement.runes.length != 1) {
        print('error: bad replacement $replacement');
        continue;
      }
      for (var p in l) {
        if (p == null || p == '') {
          break;
        }
        if (p.runes.length != 1) {
          print('error: bad character $p');
          continue;
        }
        var r = characterRreplacements[p];
        if (r != null && r != replacement) {
          print('error: conflicted replacements: $r $replacement <= $p');
          continue;
        }
        if (r == p) {
          print('warning: useless conversion: $r <= $p');
          continue;
        }
        characterRreplacements[p] = replacement;
      }
    }
    for (var k in characterRreplacements.values) {
      var v = characterRreplacements[k];
      if (v == null) {
        continue;
      }
      print('error: transitive conversion $v <= $k');
    }
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
    String targetString;
    var wordRpl = <WordReplacement>[];
    await for (var l in readCsvLines(path)) {
      if (l.length < 2 || l[0] == null) {
        continue;
      }
      targetString = l.removeAt(0)!;
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
      wordRpl.add(WordReplacement(regExp(pattern.toString()), targetString));
    }
    wordReplacements = wordRpl.toList(growable: false);
  }

  Future<void> _readWhiteQueries(String path) async {
    rawWhiteQueries = <String>[];
    await for (var line in readCsvLines(path)) {
      if (line.isEmpty) {
        continue;
      }
      var inputString = line[0];
      if (inputString == null || inputString == '') {
        continue;
      }
      rawWhiteQueries.add(inputString);
    }
  }
}
