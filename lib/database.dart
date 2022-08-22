// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'configs.dart';
import 'fmatch.dart';
import 'preprocess.dart';
import 'util.dart';

const bufferSize = 128 * 1024;

late Db db;
late IDb idb;
late Set<CachedQuery> whiteQueries;

enum LetType { na, postfix, prefix }

class Preprocessed {
  final LetType letType;
  final List<String> terms;
  Preprocessed(this.letType, this.terms);
}

class Db extends MapBase<String, Preprocessed> {
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
  static Future<Db> fromStringStream(Stream<String> entries) async {
    var ret = Db();
    await entries.where((var entry) => entry != '').forEach((var entry) {
      var rawEntry = normalizeAndCapitalize(entry, true);
      if (!ret.containsKey(rawEntry)) {
        ret[rawEntry] = preprocess(rawEntry, true);
      }
    });
    assert(ret.length >= 2);
    return ret;
  }

  @override
  Preprocessed? operator [](Object? key) => _map[key];
  @override
  operator []=(String key, Preprocessed value) => _map[key] = value;
  @override
  Iterable<String> get keys => _map.keys;
  @override
  void clear() => _map.clear();
  @override
  Preprocessed? remove(Object? key) => _map.remove(key);

  static Future<Db> readList(String path) async {
    var plainEntries = readCsvLines(path)
        .where((l) => l.isNotEmpty && l[0] != null)
        .map((l) => l[0]!);
    return Db.fromStringStream(plainEntries);
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
  late final int df;
  late final List<IDbTermOccurrence> occurrences;
  IDbEntryValue() : occurrences = [];
  IDbEntryValue.of(IDbEntryValue o)
      : df = o.df,
        occurrences = o.occurrences.toList(growable: false);
  IDbEntryValue.fromJson(Map<String, dynamic> json) {
    df = json['df'] as int;
    occurrences = (json['occurrences'] as List)
        .map((dynamic e) =>
            IDbTermOccurrence.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
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

class IDb extends MapBase<IDbEntryKey, IDbEntryValue> {
  final _map = <IDbEntryKey, IDbEntryValue>{};
  late final List<MapEntry<IDbEntryKey, IDbEntryValue>> list;
  late final List<int> indeces;
  late final int maxTermLength;
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
      value.df = df;
      this[mentry.key] = IDbEntryValue.of(value);
    }
    _list();
  }

  @override
  IDbEntryValue? operator [](Object? key) => _map[key];
  @override
  operator []=(IDbEntryKey key, IDbEntryValue value) => _map[key] = value;
  @override
  Iterable<IDbEntryKey> get keys => _map.keys;
  @override
  void clear() => _map.clear();
  @override
  IDbEntryValue? remove(Object? key) => _map.remove(key);

  static Future<IDb> read(String path) async {
    var ret = IDb();
    var decoder = JsonDecoder();
    var fs = File(path).openRead().transform<String>(utf8.decoder);
    var json = (await decoder.bind(fs).first)! as List;
    for (var me in json) {
      ret[IDbEntryKey.fromJson(me['key'] as Map<String, dynamic>)] =
          IDbEntryValue.fromJson(me['value'] as Map<String, dynamic>);
    }
    ret._list();
    return ret;
  }

  void _list() {
    list = entries
        .where((e) => !(e.key.isLet ||
            (e.key.term.length < Settings.termPartialMatchingMinLetters &&
                e.key.term.length < Settings.termMatchingMinLetters)))
        .toList(growable: false);
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
    maxTermLength = list.last.key.term.length;
    indeces = List<int>.filled(maxTermLength + 2, 0, growable: false);
    var lastLen = 0;
    for (var i = 0; i < list.length; i++) {
      var l = list[i].key.term.length;
      if (l == lastLen) {
        continue;
      }
      for (var j = lastLen + 1; j <= l; j++) {
        indeces[j] = i;
      }
      indeces[l] = i;
      lastLen = l;
    }
    indeces.last = list.length;
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

Future<Set<CachedQuery>> readWhiteQueries(String path) async {
  var ret = <CachedQuery>{};
  await for (var line in readCsvLines(path)) {
    if (line.isEmpty) {
      continue;
    }
    var inputString = line[0];
    if (inputString == null || inputString == '') {
      continue;
    }
    if (hasIllegalCharacter(inputString)) {
      print(
          'Illegal characters in white query: $inputString');
      continue;
    }
    var rawQuery = normalizeAndCapitalize(inputString);
    var preprocessed = preprocess(rawQuery, true);
    if (preprocessed.terms.isEmpty) {
      print('No valid terms in white query: $inputString');
      continue;
    }
    ret.add(CachedQuery.fromPreprocessed(preprocessed, false));
  }
  return ret;
}

Future<void> buildDb() async {
  var idbFile = File(Paths.idb);
  var idbFileExists = idbFile.existsSync();
  late DateTime idbTimestamp;
  if (idbFileExists) {
    idbTimestamp = File(Paths.idb).lastModifiedSync();
  }
  if (!idbFileExists ||
      File(Paths.list).lastModifiedSync().isAfter(idbTimestamp) ||
      File(Paths.legalCaharacters).lastModifiedSync().isAfter(idbTimestamp) ||
      File(Paths.stringReplacement).lastModifiedSync().isAfter(idbTimestamp) ||
      File(Paths.legalEntryType).lastModifiedSync().isAfter(idbTimestamp) ||
      File(Paths.words).lastModifiedSync().isAfter(idbTimestamp) ||
      File(Paths.wordReplacement).lastModifiedSync().isAfter(idbTimestamp)) {
    await time(() async {
      db = await Db.readList(Paths.list);
    }, 'Db.readList');
    await time(() async {
      idb = IDb.fromDb(db);
    }, 'IDb.fromDb');
    await time(() => db.write(Paths.db), 'Db.write');
    await time(() => idb.write(Paths.idb), 'IDb.write');
  } else {
    await time(() async {
      idb = await IDb.read(Paths.idb);
    }, 'IDb.read');
    await time(() => db = Db.fromIDb(idb), 'Db.fromIDb');
    await time(() => db.write(Paths.db), 'Db.write');
  }
  await time(() async {
    whiteQueries = await readWhiteQueries(
        Paths.whiteQueries);
  }, 'readWhiteQuery');
}
