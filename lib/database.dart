// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'fmatch.dart';
import 'preprocess.dart';
import 'util.dart';

const bufferSize = 128 * 1024;

enum LetType {
  na,
  postfix,
  prefix;

  factory LetType.fromJson(String json) => LetType.values.byName(json);
  String toJson() => name;
}

class Preprocessed {
  final LetType letType;
  final List<String> terms;
  Preprocessed(this.letType, this.terms);
}

class Db {
  final Map<String, Preprocessed> _map = {};
  Db();
  Db.fromIDb(IDb idb) {
    var entryTermTable = <String, Map<int, String>>{};
    var entryLetPosition = <String, int>{};
    for (var me in idb.entries) {
      var isLet = me.key.isLet;
      var os = me.value.occurrences;
      for (var o in os) {
        var rawEntry = o.rawEntry;
        var position = o.position;
        if (!entryTermTable.containsKey(rawEntry)) {
          entryTermTable[rawEntry] = <int, String>{};
          entryLetPosition[rawEntry] = -1;
        }
        entryTermTable[rawEntry]![position] = me.key.term;
        if (isLet) {
          entryLetPosition[rawEntry] = position;
        }
      }
    }
    for (var me in entryTermTable.entries) {
      var rawEntry = me.key;
      var entryTermMap = me.value;
      var entryTermCount = entryTermMap.length;
      var terms = List<String>.generate(
          entryTermCount, (qti) => entryTermMap[qti]!,
          growable: false);
      LetType letType;
      if (entryLetPosition[rawEntry] == -1) {
        letType = LetType.na;
      } else if (entryLetPosition[rawEntry] == entryTermCount - 1) {
        letType = LetType.postfix;
      } else if (entryLetPosition[rawEntry] == 0) {
        letType = LetType.prefix;
      } else {
        throw Exception();
      }
      this[rawEntry] = Preprocessed(letType, terms);
    }
    assert(length >= 2);
  }
  static Future<Db> fromStringStream(
      Preprocessor preper, Stream<String> entries) async {
    var ret = Db();
    await entries.where((var entry) => entry != '').forEach((var entry) {
      var rawEntry = preper.normalizeAndCapitalize(entry, true);
      if (!ret.containsKey(rawEntry)) {
        ret[rawEntry] = preper.preprocess(rawEntry, true);
      }
    });
    assert(ret.length >= 2);
    return ret;
  }

  Preprocessed? operator [](Object? key) => _map[key];
  operator []=(String key, Preprocessed value) => _map[key] = value;
  Iterable<String> get keys => _map.keys;
  int get length => _map.length;
  bool containsKey(Object? key) => _map.containsKey(key);

  static Future<Db> readList(Preprocessor preper, String path) async {
    var plainEntries = readCsvLines(path)
        .where((l) => l.isNotEmpty && l[0] != null)
        .map((l) => l[0]!);
    return Db.fromStringStream(preper, plainEntries);
  }

  Future<void> write(String path) async {
    var csvLine = StringBuffer();
    var f = File(path);
    f.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
    var fs = f.openWrite(mode: FileMode.append, encoding: utf8);
    var keys = this.keys.toList(growable: false);
    keys.sort();
    for (var key in keys) {
      csvLine.write(quoteCsvCell(key));
      csvLine.write(r',');
      var v = this[key]!;
      csvLine.write(v.letType.toString().substring(8));
      for (var t in v.terms) {
        csvLine.write(r',');
        csvLine.write(quoteCsvCell(t));
      }
      csvLine.write('\r\n');
      if (csvLine.length > bufferSize) {
        fs.write(csvLine);
        csvLine.clear();
      }
    }
    fs.write(csvLine);
    await fs.close();
  }
}

class IDbEntryKey implements Comparable<IDbEntryKey> {
  final String term;
  final bool isLet;
  final int _hashCode;
  @override
  int compareTo(IDbEntryKey other) {
    var tc = term.compareTo(other.term);
    if (tc != 0) {
      return tc;
    }
    if (isLet == false) {
      return -1;
    }
    return 1;
  }

  @override
  bool operator ==(dynamic other) =>
      identical(this, other) ||
      other is IDbEntryKey && term == other.term && isLet == other.isLet;
  @override
  int get hashCode => _hashCode;
  IDbEntryKey(this.term, this.isLet) : _hashCode = Object.hash(term, isLet);
  IDbEntryKey.fromJson(Map<String, dynamic> json)
      : this(canonicalize(json['term'] as String), json['isLet'] as bool);
  Map<String, dynamic> toJson() => <String, dynamic>{
        'term': term,
        'isLet': isLet,
      };
}

class IDbTermOccurrence {
  final String rawEntry;
  final int position;
  IDbTermOccurrence(this.rawEntry, this.position);
  IDbTermOccurrence.fromJson(Map<String, dynamic> json)
      : this(canonicalize(json['rawEntry'] as String), json['position'] as int);
  Map<String, dynamic> toJson() => <String, dynamic>{
        'rawEntry': rawEntry,
        'position': position,
      };
}

class IDbEntryValue {
  final int df;
  final List<IDbTermOccurrence> occurrences;
  IDbEntryValue()
      : df = 0,
        occurrences = [];
  IDbEntryValue.of(this.df, IDbEntryValue o)
      : occurrences = o.occurrences.toList(growable: false);
  IDbEntryValue.fromJson(Map<String, dynamic> json)
      : df = json['df'] as int,
        occurrences = (json['occurrences'] as List)
            .map((dynamic e) =>
                IDbTermOccurrence.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
  Map<String, dynamic> toJson() => <String, dynamic>{
        'df': df,
        'occurrences':
            occurrences.map((o) => o.toJson()).toList(growable: false),
      };
}

class JsonChankSink implements Sink<List<int>> {
  final RandomAccessFile raFile;
  JsonChankSink.fromRaFile(this.raFile);
  @override
  void add(List<int> data) {
    raFile.writeFromSync(data);
  }

  @override
  void close() {
    raFile.closeSync();
  }
}

class IDb {
  final _map = <IDbEntryKey, IDbEntryValue>{};
  late final int maxTermLength;
  late final List<MapEntry<IDbEntryKey, IDbEntryValue>> list;
  late final List<int> listIndicesOfTermLength;
  IDb();
  IDb.fromDb(Db db) {
    var tmpMap = <IDbEntryKey, IDbEntryValue>{};
    var dbKeys = db.keys.toList(growable: false);
    dbKeys.sort();
    for (var dbKey in dbKeys) {
      var dbValue = db[dbKey]!;
      var termCount = dbValue.terms.length;
      for (var i = 0; i < termCount; i++) {
        var term = dbValue.terms[i];
        var isLte = false;
        var letType = dbValue.letType;
        if (letType == LetType.postfix && i == termCount - 1 ||
            letType == LetType.prefix && i == 0) {
          isLte = true;
        }
        var idbKey = IDbEntryKey(term, isLte);
        if (!tmpMap.containsKey(idbKey)) {
          tmpMap[idbKey] = IDbEntryValue();
        }
        tmpMap[idbKey]!.occurrences.add(IDbTermOccurrence(dbKey, i));
      }
    }
    for (var mentry in tmpMap.entries) {
      var value = mentry.value;
      var df = 0;
      var lastRawEntry = '';
      for (var o in value.occurrences) {
        if (o.rawEntry != lastRawEntry) {
          lastRawEntry = o.rawEntry;
          df++;
        }
      }
      this[mentry.key] = IDbEntryValue.of(df, value);
    }
    _initList();
  }

  IDbEntryValue? operator [](Object? key) => _map[key];
  operator []=(IDbEntryKey key, IDbEntryValue value) => _map[key] = value;
  Iterable<MapEntry<IDbEntryKey, IDbEntryValue>> get entries => _map.entries;
  Iterable<IDbEntryKey> get keys => _map.keys;

  static Future<IDb> read(String path) async {
    var ret = IDb();
    var decoder = JsonDecoder();
    var fs = File(path).openRead().transform<String>(utf8.decoder);
    var json = (await decoder.bind(fs).first)! as List;
    for (var me in json) {
      ret[IDbEntryKey.fromJson(me['key'] as Map<String, dynamic>)] =
          IDbEntryValue.fromJson(me['value'] as Map<String, dynamic>);
    }
    ret._initList();
    return ret;
  }

  void _initList() {
    list = entries.where((e) => !e.key.isLet).toList(growable: false);
    list.sort((a, b) {
      var ta = a.key.term;
      var tb = b.key.term;
      if (ta.length < tb.length) {
        return -1;
      } else if (ta.length > tb.length) {
        return 1;
      } else {
        return ta.compareTo(tb);
      }
    });
    _initListIndices();
  }

  void _initListIndices() {
    // `l` of `listIndicesOfTermLength[l]` is the length of the terms
    // `listIndicesOfTermLength[l] == listIndicesOfTermLength[l+1]` unless term with length `l` exists
    // `listIndicesOfTermLength[0]` isn't used
    // `listIndicesOfTermLength[maxTermLength + 1]` is index of `list.last` + 1
    maxTermLength = list.last.key.term.length;
    listIndicesOfTermLength =
        List<int>.filled(maxTermLength + 2, 0, growable: false);
    var nextLen = list.first.key.term.length;
    var firstIx = 0;
    var ix = 0;
    for (var ln = 0; ln <= maxTermLength; ln++) {
      if (ln <= nextLen) {
        listIndicesOfTermLength[ln] = firstIx;
        continue;
      }
      for (; ix < list.length; ix++) {
        var idbeln = list[ix].key.term.length;
        if (idbeln >= ln) {
          listIndicesOfTermLength[ln] = ix;
          nextLen = idbeln;
          firstIx = ix;
          break;
        }
      }
    }
    listIndicesOfTermLength[maxTermLength + 1] = list.length;
  }

  void write(String path) {
    var jcs =
        JsonChankSink.fromRaFile(File(path).openSync(mode: FileMode.write));
    var encoder = JsonUtf8Encoder('  ', null, bufferSize);
    var ccs = encoder.startChunkedConversion(jcs);
    ccs.add(this);
  }

  List<Map<String, dynamic>> toJson() {
    var mapKeys = keys.toList(growable: false);
    mapKeys.sort();
    return mapKeys
        .map((mk) => {'key': mk.toJson(), 'value': this[mk]!.toJson()})
        .toList(growable: false);
  }
}

Future<Set<CachedQuery>> readWhiteQueries(
    Preprocessor preper, String path) async {
  var ret = <CachedQuery>{};
  await for (var line in readCsvLines(path)) {
    if (line.isEmpty) {
      continue;
    }
    var inputString = line[0];
    if (inputString == null || inputString == '') {
      continue;
    }
    if (preper.hasIllegalCharacter(inputString)) {
      print('Illegal characters in white query: $inputString');
      continue;
    }
    var rawQuery = preper.normalizeAndCapitalize(inputString);
    var preprocessed = preper.preprocess(rawQuery, true);
    if (preprocessed.terms.isEmpty) {
      print('No valid terms in white query: $inputString');
      continue;
    }
    ret.add(CachedQuery.fromPreprocessed(preprocessed, false));
  }
  return ret;
}
