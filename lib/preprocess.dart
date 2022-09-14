// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'configs.dart';

enum LetType {
  na,
  postfix,
  prefix;

  factory LetType.fromJson(String json) => LetType.values.byName(json);
  String toJson() => name;
}

class RString implements Comparable<RString> {
  static final cannonicalized = <String, RString>{};
  final String string;
  final Int32List runes;
  factory RString(String s, [bool registering = false]) {
    if (registering == false) {
      return RString._(s);
    }
    var ret = cannonicalized[s];
    if (ret != null) {
      return ret;
    }
    return cannonicalized[s] = RString._(s);
  }
  RString._(this.string) : runes = Int32List.fromList(string.runes.toList());
  int get length => runes.length;
  @override
  String toString() => string;
  @override
  int compareTo(dynamic other) => string.compareTo((other as RString).string);
  @override
  int get hashCode => string.hashCode;
  @override
  operator ==(Object? other) {
    if (other is! RString) {
      return false;
    }
    return string == other.string;
  }
}

class Preprocessed {
  final LetType letType;
  final List<RString> terms;
  Preprocessed(this.letType, this.terms);
}

class LetReplaced {
  final String name;
  final LetType letType;
  const LetReplaced(this.name, this.letType);
}

class CachedQuery {
  final LetType letType;
  final List<String> terms;
  final bool perfectMatching;
  final int _hashCode;
  CachedQuery(this.letType, this.terms, this.perfectMatching)
      : _hashCode = Object.hashAll([letType, perfectMatching, ...terms]);
  CachedQuery.fromPreprocessed(Preprocessed preped, bool perfectMatching)
      : this(preped.letType, preped.terms.map((e) => e.string).toList(),
            perfectMatching);
  CachedQuery.fromJson(Map<String, dynamic> json)
      : this(
          LetType.fromJson(json['letType'] as String),
          (json['terms'] as List<dynamic>)
              .map<String>((dynamic e) => e as String)
              .toList(growable: false),
          json['perfectMatching'] as bool,
        );
  Map<String, dynamic> toJson() => <String, dynamic>{
        'letType': letType.toJson(),
        'terms': [...terms],
        'perfectMatching': perfectMatching ? true : false
      };
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! CachedQuery) {
      return false;
    }
    if (letType != other.letType) {
      return false;
    }
    if (perfectMatching != other.perfectMatching) {
      return false;
    }
    if (terms.length != other.terms.length) {
      return false;
    }
    for (var i = 0; i < terms.length; i++) {
      if (terms[i] != other.terms[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => _hashCode;
}

class Preprocessor with Configs {
  late final Set<CachedQuery> whiteQueries;

  @override
  Future<void> readConfigs() async {
    await super.readConfigs();
    whiteQueries = <CachedQuery>{};
    for (var inputString in rawWhiteQueries) {
      if (hasIllegalCharacter(inputString)) {
        print('Illegal characters in white query: $inputString');
        continue;
      }
      var rawQuery = normalizeAndCapitalize(inputString);
      var preprocessed = preprocess(rawQuery, true);
      if (preprocessed.terms.isEmpty) {
        print('No valid terms in white query: $inputString');
        continue;
      }
      whiteQueries.add(CachedQuery.fromPreprocessed(preprocessed, false));
    }
    rawWhiteQueries.clear();
  }

  bool hasIllegalCharacter(String name) {
    var m = legalChars.firstMatch(name);
    if (m == null) {
      return false;
    }
    return m.end != name.length;
  }

  final _htSpaces = RegExp(r'^\s+|\s+$');
  final _mSpaces = RegExp(r'\s+');

  String normalizeAndCapitalize(String checked) {
    var uNormalized = unorm.nfkd(checked);
    var uwNormalized = uNormalized.replaceAll(_htSpaces, '');
    var normalized = uwNormalized.replaceAll(_mSpaces, ' ');
    var capitalized = normalized.toUpperCase();
    return capitalized;
  }

  Preprocessed preprocess(String capitalized, [bool canonRegistering = false]) {
    var characterReplaced = replaceCharacters(capitalized);
    var stringReplaced = replaceStrings(characterReplaced);
    var letReplaced = replaceLegalEntiyTypes(stringReplaced);
    var wordized = wordize(letReplaced);
    return replaceWords(wordized, canonRegistering);
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
            .map((m) => RString(m.group(0)!))
            .toList(growable: false));
  }

  final _r = [
    RegExp(r'\$0'),
    RegExp(r'\$1'),
    RegExp(r'\$2'),
    RegExp(r'\$3'),
    RegExp(r'\$4'),
    RegExp(r'\$5'),
    RegExp(r'\$6'),
    RegExp(r'\$7'),
    RegExp(r'\$8'),
    RegExp(r'\$9'),
  ];

  String _replacement(Match m, String replacement) {
    var ret = replacement;
    for (var i = 0; i <= m.groupCount && i <= 9; i++) {
      var replacement = m[i] ?? '';
      ret = ret.replaceAll(_r[i], replacement);
    }
    return ret;
  }

  Preprocessed replaceWords(Preprocessed wordized, bool canonRegisting) {
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
            .map((e) => RString(e, canonRegisting))
            .toList(growable: false));
  }
}
