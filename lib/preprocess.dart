// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'configs.dart';
import 'util.dart';

enum LetType {
  na,
  postfix,
  prefix;

  factory LetType.fromJson(String json) => LetType.values.byName(json);
  String toJson() => name;
}

class Term implements Comparable<Term> {
  static final _canonicalized = <String, Term>{};
  final String string; // redundant for performance optimization
  final Int32List runes;
  factory Term(String s, {bool canonicalizing = false}) {
    if (canonicalizing == false) {
      return Term._(s);
    }
    return _canonicalize(s);
  }
  Term._(this.string) : runes = Int32List.fromList(string.runes.toList());
  static Term _canonicalize(String s) {
    var ret = _canonicalized[s];
    if (ret != null) {
      return ret;
    }
    return _canonicalized[s] = Term._(s);
  }

  static Term canonicalize(Term t) => _canonicalize(t.string);
  int get length => runes.length;
  String toJson() => string;
  @override
  int compareTo(dynamic other) => string.compareTo((other as Term).string);
  @override
  int get hashCode => string.hashCode;
  @override
  operator ==(Object other) => string == (other as Term).string;
}

class Entry implements Comparable<Entry> {
  static final _canonicalized = <String, Entry>{};
  final String string;
  factory Entry(String s, {bool canonicalizing = false}) {
    if (canonicalizing == false) {
      return Entry._(s);
    }
    return _canonicalize(s);
  }
  Entry._(this.string);
  static Entry _canonicalize(String s) {
    var ret = _canonicalized[s];
    if (ret != null) {
      return ret;
    }
    return _canonicalized[s] = Entry._(s);
  }

  static Entry canonicalize(Entry e) => _canonicalize(e.string);
  int get length => string.length;
  String toJson() => string;
  @override
  int compareTo(dynamic other) => string.compareTo((other as Entry).string);
  @override
  int get hashCode => string.hashCode;
  @override
  operator ==(Object other) => string == (other as Entry).string;
}

class Preprocessed {
  final LetType letType;
  final List<Term> terms;
  Preprocessed(this.letType, this.terms);
}

class LetReplaced {
  final String name;
  final LetType letType;
  const LetReplaced(this.name, this.letType);
}

class Preprocessor with Configs {
  bool hasIllegalCharacter(String name) {
    var m = legalChars.firstMatch(name);
    if (m == null) {
      return false;
    }
    return m.end != name.length;
  }

  final _htSpaces = regExp(r'^\s+|\s+$');
  final _mSpaces = regExp(r'\s+');

  String normalizeAndCapitalize(String checked) {
    var uNormalized = unorm.nfkd(checked);
    var uwNormalized = uNormalized.replaceAll(_htSpaces, '');
    var normalized = uwNormalized.replaceAll(_mSpaces, ' ');
    var capitalized = normalized.toUpperCase();
    return capitalized;
  }

  Preprocessed preprocess(String capitalized, [bool canonicalizing = false]) {
    var characterReplaced = replaceCharacters(capitalized);
    var stringReplaced = replaceStrings(characterReplaced);
    var letReplaced = replaceLegalEntiyTypes(stringReplaced);
    var wordized = wordize(letReplaced);
    return replaceWords(wordized, canonicalizing);
  }

  String replaceCharacters(String capitalized) {
    return capitalized.runes.map((r) {
      var c = String.fromCharCodes([r]);
      return characterRreplacements[c] ?? c;
    }).join();
  }

  String replaceStrings(String capitalized) {
    var stringReplaced = capitalized;
    for (var strRepl in stringRreplacements) {
      stringReplaced =
          stringReplaced.replaceAll(strRepl.regexp, strRepl.replacement);
    }
    return stringReplaced;
  }

  LetReplaced replaceLegalEntiyTypes(String stringReplaced) {
    String letReplaced;
    for (var letRepl in legalEntryTypeReplacements) {
      letReplaced =
          stringReplaced.replaceFirstMapped(letRepl.regexpPostfix, (match) {
        var gs = (match as RegExpMatch).namedGroup('s');
        if (gs != null) {
          return '$gs${letRepl.replacement}';
        }
        return letRepl.replacement;
      });
      if (letReplaced != stringReplaced) {
        return LetReplaced(letReplaced, LetType.postfix);
      }
    }
    for (var letRepl in legalEntryTypeReplacements) {
      letReplaced = stringReplaced.replaceFirst(
          letRepl.regexpPrefix, letRepl.replacement);
      if (letReplaced != stringReplaced) {
        return LetReplaced(letReplaced, LetType.prefix);
      }
    }
    return LetReplaced(stringReplaced, LetType.na);
  }

  Preprocessed wordize(LetReplaced letReplaced) {
    return Preprocessed(
        letReplaced.letType,
        words
            .allMatches(letReplaced.name)
            .map((m) => Term(m.group(0)!))
            .toList(growable: false));
  }

  static final _r = [
    regExp(r'\$0'),
    regExp(r'\$1'),
    regExp(r'\$2'),
    regExp(r'\$3'),
    regExp(r'\$4'),
    regExp(r'\$5'),
    regExp(r'\$6'),
    regExp(r'\$7'),
    regExp(r'\$8'),
    regExp(r'\$9'),
  ];

  static String _replacement(Match m, String replacement) {
    var ret = replacement;
    for (var i = 0; i <= m.groupCount && i <= 9; i++) {
      var replacement = m[i] ?? '';
      ret = ret.replaceAll(_r[i], replacement);
    }
    return ret;
  }

  Preprocessed replaceWords(Preprocessed wordized, bool canonicalizing) {
    var replaceds = <String>[];
    var letType = wordized.letType;
    for (var i = 0; i < wordized.terms.length; i++) {
      var term = wordized.terms[i].string;
      var replaced = term;
      for (var repl in wordReplacements) {
        replaced = term.replaceAllMapped(
            repl.regexps, (m) => _replacement(m, repl.replacement));
        if (replaced != term) {
          break;
        }
      }
      if (replaced == '') {
        if (wordized.letType == LetType.postfix &&
                i == wordized.terms.length - 1 ||
            wordized.letType == LetType.prefix && i == 0) {
          letType = LetType.na;
        }
        continue;
      }
      replaceds.add(replaced);
    }
    return Preprocessed(
        letType,
        replaceds
            .map((e) => Term(e, canonicalizing: canonicalizing))
            .toList(growable: false));
  }
}
