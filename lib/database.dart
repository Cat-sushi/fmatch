// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'preprocess.dart';
import 'util.dart';

class Db {
  final Map<Entry, Preprocessed> _map = {};
  Db();
  Db.fromIDb(IDb idb) {
    var entryTermTable = <Entry, Map<int, Term>>{};
    var entryLetPosition = <Entry, int>{};
    for (var me in idb.entries) {
      var isLet = me.key.isLet;
      var os = me.value.occurrences;
      for (var o in os) {
        var entry = o.entry;
        var position = o.position;
        if (!entryTermTable.containsKey(entry)) {
          entryTermTable[entry] = <int, Term>{};
          entryLetPosition[entry] = -1;
        }
        entryTermTable[entry]![position] = me.key.term;
        if (isLet) {
          entryLetPosition[entry] = position;
        }
      }
    }
    for (var me in entryTermTable.entries) {
      var entry = me.key;
      var entryTermMap = me.value;
      var entryTermCount = entryTermMap.length;
      var terms = List<Term>.generate(
          entryTermCount, (qti) => entryTermMap[qti]!,
          growable: false);
      LetType letType;
      if (entryLetPosition[entry] == -1) {
        letType = LetType.na;
      } else if (entryLetPosition[entry] == entryTermCount - 1) {
        letType = LetType.postfix;
      } else if (entryLetPosition[entry] == 0) {
        letType = LetType.prefix;
      } else {
        throw Exception();
      }
      _map[entry] = Preprocessed(letType, terms);
    }
    if (length < 2) {
      throw "Too small database";
    }
  }

  static Future<Db> fromStringStream(
      Preprocessor preper, Stream<String> entries) async {
    var ret = Db();
    await entries.where((s) => s != '').forEach((e) {
      var entry = preper.normalizeAndCapitalize(e, canonicalizing: true);
      if (!ret.containsKey(entry)) {
        ret._map[entry] = preper.preprocess(entry, canonicalizing: true);
      }
    });
    if (ret.length < 2) {
      throw "Too small database";
    }
    return ret;
  }

  Preprocessed? operator [](Entry key) => _map[key];
  Iterable<Entry> get keys => _map.keys;
  int get length => _map.length;
  bool containsKey(Entry key) => _map.containsKey(key);

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
      csvLine.write(quoteCsvCell(key.string));
      csvLine.write(r',');
      var v = this[key]!;
      csvLine.write(v.letType.name);
      for (var t in v.terms) {
        csvLine.write(r',');
        csvLine.write(quoteCsvCell(t.string));
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
  final Term term;
  final bool isLet;
  @override
  final int hashCode;
  @override
  int compareTo(IDbEntryKey other) {
    var tc = term.compareTo(other.term);
    if (tc != 0) {
      return tc;
    }
    if (isLet == other.isLet) {
      return 0;
    }
    if (isLet == false) {
      return -1;
    }
    return 1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IDbEntryKey && term == other.term && isLet == other.isLet;
  IDbEntryKey(this.term, this.isLet) : hashCode = Object.hash(term, isLet);
  IDbEntryKey.fromJson(Map<String, dynamic> json)
      : this(Term(json['term'] as String, canonicalizing: true),
            json['isLet'] as bool);
  Map<String, dynamic> toJson() => <String, dynamic>{
        'term': term,
        'isLet': isLet,
      };
}

class IDbTermOccurrence {
  final Entry entry;
  final int position;
  IDbTermOccurrence(this.entry, this.position);
  IDbTermOccurrence.fromJson(Map<String, dynamic> json)
      : this(Entry(json['entry'] as String, canonicalizing: true),
            json['position'] as int);
  Map<String, dynamic> toJson() => <String, dynamic>{
        'entry': entry,
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
        occurrences = (json['occurrences'] as List<dynamic>)
            .map((dynamic e) =>
                IDbTermOccurrence.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
  Map<String, dynamic> toJson() => <String, dynamic>{
        'df': df,
        'occurrences': occurrences,
      };
}

class IDb {
  final _map = <IDbEntryKey, IDbEntryValue>{};
  late final int maxTermLength;
  late final List<List<MapEntry<IDbEntryKey, IDbEntryValue>>?>
      listsByTermLength;
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
      var lastEntry = Entry('');
      for (var o in value.occurrences) {
        if (o.entry != lastEntry) {
          lastEntry = o.entry;
          df++;
        }
      }
      _map[mentry.key] = IDbEntryValue.of(df, value);
    }
    _initLists();
  }

  IDbEntryValue? operator [](IDbEntryKey key) => _map[key];
  Iterable<MapEntry<IDbEntryKey, IDbEntryValue>> get entries => _map.entries;
  Iterable<IDbEntryKey> get keys => _map.keys;

  static Future<IDb> read(String path) async {
    var ret = IDb();
    var decoder = JsonDecoder();
    var fs = File(path).openRead().transform<String>(utf8.decoder);
    var json = (await decoder.bind(fs).first)! as List;
    for (var me in json) {
      ret._map[IDbEntryKey.fromJson(me['key'] as Map<String, dynamic>)] =
          IDbEntryValue.fromJson(me['value'] as Map<String, dynamic>);
    }
    ret._initLists();
    return ret;
  }

  void _initLists() {
    var list = entries.where((e) => !e.key.isLet).toList(growable: false);
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
    // `l` of `listsByTermLength[l]` is the length of the terms
    // `listsByTermLength[0]` isn't used
    maxTermLength = list.last.key.term.length;
    listsByTermLength =
        List<List<MapEntry<IDbEntryKey, IDbEntryValue>>?>.filled(
            maxTermLength + 1, null,
            growable: false);
    var len = list.first.key.term.length;
    var start = 0;
    int end;
    for (end = 0; end < list.length; end++) {
      var idbeln = list[end].key.term.length;
      if (idbeln != len) {
        listsByTermLength[len] = list.sublist(start, end);
        len = idbeln;
        start = end;
      }
    }
    listsByTermLength[len] = list.sublist(start, end);
  }

  void write(String path) {
    var jcs =
        FileChankSink.fromRaFile(File(path).openSync(mode: FileMode.write));
    var encoder = JsonUtf8Encoder('  ', null, bufferSize);
    var ccs = encoder.startChunkedConversion(jcs);
    ccs.add(this);
  }

  List<Map<String, dynamic>> toJson() {
    var mapKeys = keys.toList(growable: false);
    mapKeys.sort();
    return mapKeys.map((mk) => {'key': mk, 'value': this[mk]!}).toList();
  }
}
