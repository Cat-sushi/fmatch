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

import 'dart:typed_data';

import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'configs.dart';
import 'util.dart';

/// Type of legal entity type.
enum LetType {
  none,
  postfix,
  prefix;

  factory LetType.fromJson(String json) => LetType.values.byName(json);
  String toJson() => name;
}

/// Term in database entry.
///
/// This is a entry of the text mathching database.
/// It does't mean a item of denial lists such as legal entity/ natural person.
class Term implements Comparable<Term> {
  static final _canonicalized = <String, Term>{};
  final String string; // redundant for performance optimization
  final Int32List runes;

  Term._(this.string) : runes = Int32List.fromList(string.runes.toList());
  factory Term(String s, {bool canonicalizing = false}) {
    if (canonicalizing == false) {
      return Term._(s);
    }
    return Term._canonicalize(s);
  }
  factory Term.canonicalize(Term t) => Term._canonicalize(t.string);
  factory Term._canonicalize(String s) {
    var ret = _canonicalized[s];
    if (ret != null) {
      return ret;
    }
    return _canonicalized[s] = Term._(s);
  }

  int get length => runes.length;
  String toJson() => string;
  @override
  int compareTo(dynamic other) => string.compareTo((other as Term).string);
  @override
  int get hashCode => string.hashCode;
  @override
  operator ==(Object other) => string == (other as Term).string;
}

/// Normalized entry of the database created from the denial lists.
class Entry implements Comparable<Entry> {
  static final _canonicalized = <String, Entry>{};
  final String string;

  Entry._(this.string);
  factory Entry(String s, {bool canonicalizing = false}) {
    if (canonicalizing == false) {
      return Entry._(s);
    }
    return Entry._canonicalize(s);
  }
  factory Entry.canonicalize(Entry e) => Entry._canonicalize(e.string);
  factory Entry._canonicalize(String s) {
    var ret = _canonicalized[s];
    if (ret != null) {
      return ret;
    }
    return _canonicalized[s] = Entry._(s);
  }

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
  final String replaced;
  final LetType letType;
  LetReplaced(this.replaced, this.letType);
}

final _htSpaces = regExp(r'^\s+|\s+$');
final _mSpaces = regExp(r'\s+');

/// Normalilze Unicode, trim white spaces, and capitalize the input.
///
/// This is useful for prepareing outer larger systems which join results with the denial lists.
///
/// Note that results from this subsystem are normalized in the same way.
String normalize(String checked) {
  var uNormalized = unorm.nfkd(checked);
  var uwNormalized = uNormalized.replaceAll(_htSpaces, '');
  var normalized = uwNormalized.replaceAll(_mSpaces, ' ');
  var capitalized = normalized.toUpperCase();
  return capitalized;
}

class Preprocessor with Configs {
  bool hasIllegalCharacter(String name) {
    if (name == '') {
      return false;
    }
    var m = legalChars.firstMatch(name);
    if (m == null) {
      return true;
    }
    return m.end != name.length;
  }

  Entry normalizeAndCapitalize(String checked, {bool canonicalizing = false}) {
    return Entry(normalize(checked), canonicalizing: canonicalizing);
  }

  Preprocessed preprocess(String capitalized, {bool canonicalizing = false}) {
    var characterReplaced = replaceCharacters(capitalized);
    var stringReplaced = replaceStrings(characterReplaced);
    var letReplaced = replaceLegalEntityTypes(stringReplaced);
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

  LetReplaced replaceLegalEntityTypes(String stringReplaced) {
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
    return LetReplaced(stringReplaced, LetType.none);
  }

  Preprocessed wordize(LetReplaced letReplaced) {
    return Preprocessed(
        letReplaced.letType,
        words
            .allMatches(letReplaced.replaced)
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
          letType = LetType.none;
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
