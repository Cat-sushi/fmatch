// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'package:quiver/core.dart';
import 'configs.dart';
import 'preprocess.dart';
import 'util.dart';

const bufferSize = 128 * 1024;

late Db db;
late IDb idb;

enum LetType { na, postfix, prefix }

class Preprocessed {
  final LetType letType;
  final List<String> terms;
  Preprocessed(this.letType, this.terms);
}

class Db {
  late Map<String, Preprocessed> map;
  Db();
  Db.fromIDb(IDb idb) {
    map = {};
    var entryTermTable = <String, Map<int, String>>{};
    var entryLetPosition = <String, int>{};
    for (var me in idb.map.entries) {
      var isLet = me.key.isLet;
      for (var o in me.value.occurrences) {
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
      var entryTermCount = me.value.length;
      var terms =
          List<String>.generate(entryTermCount, (qti) => me.value[qti]!);
      var letType = LetType.na;
      if (entryLetPosition[rawEntry] == entryTermCount - 1) {
        letType = LetType.postfix;
      } else if (entryLetPosition[rawEntry] == 0) {
        letType = LetType.prefix;
      }
      map[rawEntry] = Preprocessed(letType, terms);
    }
    assert(map.length >= 2);
  }
  static Future<Db> fromStringStream(Stream<String> entries) async {
    var ret = Db();
    ret.map = {};
    await entries.where((var entry) => entry != '').forEach((var entry) {
      var rawEntry = canonicalize(normalizeAndCapitalize(entry));
      if (!ret.map.containsKey(rawEntry)) {
        ret.map[rawEntry] = preprocess(rawEntry);
      }
    });
    assert(ret.map.length >= 2);
    return ret;
  }

  static Future<Db> readList(String path) async {
    var plainEntries =
        readCsvLines(path).where((l) => l.isNotEmpty && l[0] != null).map((l) => l[0]!);
    return Db.fromStringStream(plainEntries);
  }

  void write(String path) async {
    var csvLine = StringBuffer();
    var f = File(path);
    f.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
    var fs = f.openWrite(mode: FileMode.append, encoding: utf8);
    var keys = map.keys.toList();
    keys.sort();
    for (var key in keys) {
      csvLine.write(quoteCsvCell(key));
      csvLine.write(r',');
      var v = map[key]!;
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
  int get hashCode => hash2(term, isLet);
  IDbEntryKey(this.term, this.isLet);
  IDbEntryKey.fromJson(Map<String, Object> json)
      : this(json['term'] as String, json['isLet'] as bool);
  Map<String, Object> toJson() => {
        'term': term,
        'isLet': isLet,
      };
}

class DbTermOccurrence {
  final String rawEntry;
  final int position;
  DbTermOccurrence(this.rawEntry, this.position);
  DbTermOccurrence.fromJson(Map<String, Object> json)
      : this(canonicalize(json['rawEntry'] as String), json['position'] as int);
  Map<String, Object> toJson() => {
        'rawEntry': rawEntry,
        'position': position,
      };
}

class IDbEntryValue {
  late int df;
  late List<DbTermOccurrence> occurrences;
  IDbEntryValue()
      : df = 0,
        occurrences = [];
  IDbEntryValue.fromJson(Map<String, Object> json) {
    df = json['df'] as int;
    occurrences = (json['occurrences'] as List)
        .map((dynamic e) => DbTermOccurrence.fromJson(e as Map<String, Object>))
        .toList();
  }
  Map<String, Object> toJson() => {
        'df': df,
        'occurrences': occurrences.map((o) => o.toJson()).toList(),
      };
}

class JsonChankSink implements Sink<List<int>> {
  final RandomAccessFile raFile;
  JsonChankSink.RAFile(this.raFile);
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
  late Map<IDbEntryKey, IDbEntryValue> map;
  IDb();
  IDb.fromDb(Db db) {
    map = {};
    var dbKeys = db.map.keys.toList();
    dbKeys.sort();
    for (var dbKey in dbKeys) {
      var dbValue = db.map[dbKey]!;
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
        if (!map.containsKey(idbKey)) {
          map[idbKey] = IDbEntryValue();
        }
        map[idbKey]!.occurrences.add(DbTermOccurrence(dbKey, i));
      }
    }
    for (var mentry in map.entries) {
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
    }
  }
  static Future<IDb> read(String path) async {
    var ret = IDb();
    var decoder = JsonDecoder();
    var fs = File(path).openRead().transform<String>(utf8.decoder);
    var json = (await decoder.bind(fs).first) as List;
    ret.map = {};
    json.forEach((dynamic me) {
      ret.map[IDbEntryKey.fromJson(me['key'] as Map<String, Object>)] =
          IDbEntryValue.fromJson(me['value'] as Map<String, Object>);
    });
    return ret;
  }

  void write(String path) {
    var jcs = JsonChankSink.RAFile(File(path).openSync(mode: FileMode.write));
    var encoder = JsonUtf8Encoder('  ', null, bufferSize);
    var ccs = encoder.startChunkedConversion(jcs);
    ccs.add(this);
  }

  List<Map<String, Object>> toJson() {
    var mapKeys = map.keys.toList();
    mapKeys.sort();
    return mapKeys
        .map((mk) => {'key': mk.toJson(), 'value': map[mk]!.toJson()})
        .toList();
  }
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
      idb = await IDb.fromDb(db);
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
}
