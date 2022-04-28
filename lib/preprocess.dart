// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'configs.dart';
import 'database.dart';
import 'util.dart';

bool hasIllegalCharacter(String name) {
  var m = Configs.legalChars.firstMatch(name);
  if (m == null) {
    return false;
  }
  return m.end != name.length;
}

final _htSpaces = RegExp(r'^\s+|\s+$');
final _mSpaces = RegExp(r'\s+');

String normalizeAndCapitalize(String checked, [bool canonRegistering = false]) {
  var uNormalized = unorm.nfkd(checked);
  var uwNormalized = uNormalized.replaceAll(_htSpaces, '');
  var normalized = uwNormalized.replaceAll(_mSpaces, ' ');
  var capitalized = normalized.toUpperCase();
  var canonicalized = canonicalize(capitalized, canonRegistering);
  return canonicalized;
}

Preprocessed preprocess(String capitalized, [bool canonRegistering = false]) {
  var stringReplaced = replaceStrings(capitalized);
  var letReplaced = replaceLegalEntiyTypes(stringReplaced);
  var wordized = wordize(letReplaced);
  return replaceWords(wordized, canonRegistering);
}

String replaceStrings(String captalized) {
  var stringReplaced = captalized;
  for (var strRepl in Configs.stringRreplacements) {
    stringReplaced =
        stringReplaced.replaceAll(strRepl.regexp, strRepl.replacement);
  }
  return stringReplaced;
}

class LetReplaced {
  final String name;
  final LetType letType;
  const LetReplaced(this.name, this.letType);
}

LetReplaced replaceLegalEntiyTypes(String stringReplaced) {
  String letReplaced;
  for (var letRepl in Configs.legalEntryTypeReplacements) {
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
  for (var letRepl in Configs.legalEntryTypeReplacements) {
    letReplaced =
        stringReplaced.replaceFirst(letRepl.regexpPrefix, letRepl.replacement);
    if (letReplaced != stringReplaced) {
      return LetReplaced(letReplaced, LetType.prefix);
    }
  }
  return LetReplaced(stringReplaced, LetType.na);
}

Preprocessed wordize(LetReplaced letReplaced) {
  return Preprocessed(
      letReplaced.letType,
      Configs.words
          .allMatches(letReplaced.name)
          .map((m) => m.group(0)!)
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
    var term = wordized.terms[i];
    var replaced = term;
    for (var repl in Configs.wordRreplacements) {
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
    replaceds.add(canonicalize(replaced, canonRegisting));
  }
  replaceds = replaceds.toList(growable: false);
  return Preprocessed(letType, replaceds);
}
