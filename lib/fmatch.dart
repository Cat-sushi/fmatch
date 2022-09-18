// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'configs.dart';
import 'database.dart';
import 'preprocess.dart';
import 'util.dart';

class QueryTerm {
  Term term;
  double df;
  double weight;
  QueryTerm(this.term, this.df, this.weight);
}

class Query {
  LetType letType;
  List<QueryTerm> terms;
  bool perfectMatching;
  double queryScore;
  Query.fromPreprocessed(Preprocessed preped, this.perfectMatching)
      : letType = preped.letType,
        terms = preped.terms
            .map((e) => QueryTerm(e, 0.0, 0.0))
            .toList(growable: false),
        queryScore = 0;
}

class QueryTermOccurrence {
  final Entry entry;
  final int position;
  final int df;
  final double termSimilarity;
  final bool partial;
  QueryTermOccurrence(
      this.entry, this.position, this.df, this.termSimilarity, this.partial);
}

class QueryTermInQueryOccurrnece {
  int position;
  int sequenceNo;
  int df;
  double termSimilarity;
  bool partial;
  QueryTermInQueryOccurrnece()
      : position = -1,
        sequenceNo = 0,
        df = 0,
        termSimilarity = 0.0,
        partial = false;
  QueryTermInQueryOccurrnece.fromQueryTermOccurrence(QueryTermOccurrence qto)
      : position = qto.position,
        sequenceNo = 0,
        df = 0,
        termSimilarity = qto.termSimilarity,
        partial = qto.partial;
  QueryTermInQueryOccurrnece.of(QueryTermInQueryOccurrnece o)
      : position = o.position,
        sequenceNo = o.sequenceNo,
        df = o.df,
        termSimilarity = o.termSimilarity,
        partial = o.partial;
}

class QueryOccurrence implements Comparable<QueryOccurrence> {
  final Entry entry;
  double score;
  final List<QueryTermInQueryOccurrnece> queryTerms;
  QueryOccurrence(this.entry, this.score, this.queryTerms);
  @override
  int compareTo(QueryOccurrence other) => -score.compareTo(other.score);
}

class MatchedEntry {
  final Entry entry;
  final double score;
  MatchedEntry(this.entry, this.score);
  MatchedEntry.fromJson(Map<String, dynamic> json)
      : entry = Entry(json['entry'] as String),
        score = json['score'] as double;
  Map toJson() => <String, Object>{
        'entry': entry.string,
        'score': score,
      };
}

class CachedQuery {
  final LetType letType;
  final List<Term> terms;
  final bool perfectMatching;
  final int _hashCode;
  CachedQuery(this.letType, this.terms, this.perfectMatching)
      : _hashCode = Object.hashAll([letType, perfectMatching, ...terms]);
  CachedQuery.fromPreprocessed(Preprocessed preped, bool perfectMatching)
      : this(preped.letType, preped.terms, perfectMatching);
  CachedQuery.fromJson(Map<String, dynamic> json)
      : this(
          LetType.fromJson(json['letType'] as String),
          (json['terms'] as List<dynamic>)
              .map<Term>((dynamic e) => Term(e as String))
              .toList(growable: false),
          json['perfectMatching'] as bool,
        );
  Map<String, dynamic> toJson() => <String, dynamic>{
        'letType': letType.toJson(),
        'terms': [...terms.map((e) => e.string)],
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

class CachedResult {
  CachedQuery cachedQuery;
  double queryScore;
  List<MatchedEntry> matchedEntiries;
  CachedResult(this.cachedQuery, this.queryScore, this.matchedEntiries);
  CachedResult.fromJson(Map<String, dynamic> json)
      : this(
          CachedQuery.fromJson(json['cachedQuery'] as Map<String, dynamic>),
          json['queryScore'] as double,
          (json['matchedEntiries'] as List<dynamic>)
              .map<MatchedEntry>((dynamic e) =>
                  MatchedEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
  Map toJson() => <String, Object>{
        'cachedQuery': cachedQuery,
        'queryScore': queryScore,
        'matchedEntiries': matchedEntiries.map((e) => e.toJson()).toList(),
      };
}

class QueryResult {
  int serverId = 0;
  final DateTime dateTime;
  final int durationInMilliseconds;
  final String inputString;
  final String rawQuery;
  final CachedResult cachedResult;
  final String message;
  QueryResult.fromCachedResult(this.cachedResult, DateTime start, DateTime end,
      this.inputString, this.rawQuery,
      [this.message = ''])
      : dateTime = start,
        durationInMilliseconds = end.difference(start).inMilliseconds;
  QueryResult.fromQueryOccurrences(
    List<QueryOccurrence> queryOccurrences,
    DateTime start,
    DateTime end,
    this.inputString,
    this.rawQuery,
    Query query,
  )   : dateTime = start,
        durationInMilliseconds = end.difference(start).inMilliseconds,
        cachedResult = CachedResult(
            CachedQuery(
                query.letType,
                query.terms.map((e) => e.term).toList(growable: false),
                query.perfectMatching),
            query.queryScore,
            queryOccurrences
                .map((e) => MatchedEntry(e.entry, e.score))
                .toList()),
        message = '';
  QueryResult.fromError(this.message)
      : dateTime = DateTime.now(),
        durationInMilliseconds = 0,
        inputString = '',
        rawQuery = '',
        cachedResult = CachedResult(CachedQuery(LetType.na, [], false), 0, []);
  QueryResult.fromJson(Map<String, dynamic> json)
      : serverId = json['serverId'] as int,
        dateTime = DateTime.parse(json['start'] as String),
        durationInMilliseconds = json['durationInMilliseconds'] as int,
        inputString = json['inputString'] as String,
        rawQuery = json['rawQuery'] as String,
        cachedResult =
            CachedResult.fromJson(json['cachedResult'] as Map<String, dynamic>),
        message = json['message'] as String;
  Map toJson() => <String, Object>{
        'serverId': serverId,
        'start': dateTime.toUtc().toIso8601String(),
        'durationInMilliseconds': durationInMilliseconds,
        'inputString': inputString,
        'rawQuery': rawQuery,
        'cachedResult': cachedResult.toJson(),
        'message': message,
      };
}

class ResultCache {
  final int _queryResultCacheSize;
  // ignore: prefer_collection_literals
  final _map = LinkedHashMap<CachedQuery, CachedResult>();
  ResultCache(int size) : _queryResultCacheSize = size;
  Future<CachedResult?> get(CachedQuery query) async {
    if (_queryResultCacheSize == 0) {
      return null;
    }
    var rce = _map.remove(query);
    if (rce == null) {
      return null;
    }
    _map[query] = rce;
    return rce;
  }

  void put(CachedQuery query, CachedResult result) {
    if (_queryResultCacheSize == 0) {
      return;
    }
    var rce = _map.remove(query) ??
        CachedResult(
            result.cachedQuery, result.queryScore, result.matchedEntiries);
    _map[query] = rce;
    if (_map.length > _queryResultCacheSize) {
      _map.remove(_map.keys.first);
    }
  }
}

class RangeIndices {
  int start = -1;
  int end = 0;
}

class FMatcher with Settings {
  final preper = Preprocessor();
  late final Db db;
  late final IDb idb;
  late final whiteQueries = <CachedQuery>{};
  late var resultCache = ResultCache(queryResultCacheSize);
  late final nd = db.length.toDouble(); // nd >= 2.0
  static const dfz = 1.0;
  late final idfm = scoreIdfMagnifier;
  late final double tidfz = absoluteTermImportance(dfz);
  late final double dfx = min<double>(queryMatchingTypicalProperNounDf, nd);
  late final tix = absoluteTermImportance(dfx) / tidfz;
  late final tsox = queryMatchingMinTermOrderSimilarity;
  late final minScore = (1.0 - (1.0 - tix)) * tsox;
  static final _perfMatchQuery = RegExp(r'^"(.+)"$');

  Future<void> buildDb() async {
    initWhiteQueries();
    var idbFile = File(Paths.idb);
    var idbFileExists = idbFile.existsSync();
    late DateTime idbTimestamp;
    if (idbFileExists) {
      idbTimestamp = File(Paths.idb).lastModifiedSync();
    }
    if (!idbFileExists ||
        File(Paths.list).lastModifiedSync().isAfter(idbTimestamp) ||
        File(Paths.legalCaharacters).lastModifiedSync().isAfter(idbTimestamp) ||
        File(Paths.characterReplacement)
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File(Paths.stringReplacement)
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File(Paths.legalEntryType).lastModifiedSync().isAfter(idbTimestamp) ||
        File(Paths.words).lastModifiedSync().isAfter(idbTimestamp) ||
        File(Paths.wordReplacement).lastModifiedSync().isAfter(idbTimestamp)) {
      await time(() async {
        db = await Db.readList(preper, Paths.list);
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
  }

  void initWhiteQueries() {
    for (var inputString in preper.rawWhiteQueries) {
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
      whiteQueries.add(CachedQuery.fromPreprocessed(preprocessed, false));
    }
    preper.rawWhiteQueries.clear();
  }

  double absoluteTermImportance(double df) =>
      pow(log(nd / min<double>(max<double>(df, 1.0), nd)) / ln10, idfm)
          .toDouble();

  static bool isLetByQueryTerm(Query query, int qti) =>
      query.letType == LetType.postfix && qti == query.terms.length - 1 ||
      query.letType == LetType.prefix && qti == 0;

  int maxMissedTermCount(int qtc) {
    var minMatchedTC = (qtc.toDouble() * queryMatchingMinTermRatio).ceil();
    minMatchedTC = max<int>(minMatchedTC, queryMatchingMinTerms);
    minMatchedTC = min<int>(minMatchedTC, qtc);
    return qtc - minMatchedTC;
  }

  Future<QueryResult> fmatch(String inputString) async {
    var start = DateTime.now();
    if (preper.hasIllegalCharacter(inputString)) {
      return QueryResult.fromError('Illegal characters in query: $inputString');
    }
    var rawQuery = preper.normalizeAndCapitalize(inputString);
    bool perfectMatching = false;
    var perfMatchQueryMatcher = _perfMatchQuery.firstMatch(rawQuery);
    if (perfMatchQueryMatcher != null) {
      perfectMatching = true;
      rawQuery = perfMatchQueryMatcher[1]!;
    }
    var preprocessed = preper.preprocess(rawQuery);
    if (preprocessed.terms.isEmpty) {
      return QueryResult.fromError('No valid terms in query: $inputString');
    }
    var cachedQuery =
        CachedQuery.fromPreprocessed(preprocessed, perfectMatching);
    if (!perfectMatching && whiteQueries.contains(cachedQuery)) {
      return QueryResult.fromCachedResult(
        CachedResult(cachedQuery, 0, []),
        start,
        DateTime.now(),
        inputString,
        rawQuery,
        'Safe Customer: ${preprocessed.terms.join(' ')}',
      );
    }
    var cachedResult = await resultCache.get(cachedQuery);
    if (cachedResult != null) {
      return QueryResult.fromCachedResult(
        cachedResult,
        start,
        DateTime.now(),
        inputString,
        rawQuery,
        'Cached result',
      );
    }
    var query = Query.fromPreprocessed(preprocessed, perfectMatching);
    var resultUnsorted = matchWithoutSort(query);
    var sorted = sortAndDedupResults(resultUnsorted);
    var ret = QueryResult.fromQueryOccurrences(
      sorted,
      start,
      DateTime.now(),
      inputString,
      rawQuery,
      query,
    );
    resultCache.put(cachedQuery, ret.cachedResult);
    return ret;
  }

  List<QueryOccurrence> matchWithoutSort(Query query) {
    var queryTermOccurrences = <List<QueryTermOccurrence>>[];
    for (var qti = 0; qti < query.terms.length; qti++) {
      var qterm = query.terms[qti];
      var isLet = isLetByQueryTerm(query, qti);
      var qto = queryTermMatch(qterm, isLet, query.perfectMatching);
      queryTermOccurrences.add(qto);
    }
    queryTermOccurrences = queryTermOccurrences.toList(growable: false);
    var qtc = query.terms.length;
    int maxMissedTC;
    if (query.perfectMatching) {
      maxMissedTC = 0;
    } else {
      maxMissedTC = maxMissedTermCount(qtc);
    }
    if (estimateCombination(query, queryTermOccurrences, maxMissedTC) >
        fallbackThresholdCombinations) {
      queryTermOccurrences = reduceQueryTerms(query, queryTermOccurrences);
      for (var i = 0; i < queryTermOccurrences.length; i++) {
        queryTermOccurrences[i] =
            reduceQueryTermOccurrences(queryTermOccurrences[i], query);
      }
      qtc = query.terms.length;
      maxMissedTC = maxMissedTermCount(qtc);
    }
    caliculateQueryTermWeight(query);
    return queryMatch(query, queryTermOccurrences, maxMissedTC);
  }

  List<QueryTermOccurrence> queryTermMatch(
      QueryTerm qterm, bool isLet, bool perfectMatching) {
    if (isLet ||
        perfectMatching ||
        qterm.term.length < termMatchingMinLetters &&
            qterm.term.length < termPartialMatchingMinLetters) {
      var idbv = idb[IDbEntryKey(qterm.term, isLet)];
      if (idbv == null) {
        return <QueryTermOccurrence>[];
      }
      qterm.df += idbv.df * 1.0;
      var os = idbv.occurrences
          .map((o) =>
              QueryTermOccurrence(o.entry, o.position, idbv.df, 1.0, false))
          .toList(growable: false);
      return os;
    }
    var occurrences = <QueryTermOccurrence>[];
    var lqt = qterm.term.length.toDouble();
    var ls1 = (lqt * termMatchingMinLetterRatio).ceil();
    var ls2 = (lqt * termPartialMatchingMinLetterRatio).ceil();
    var ls3 = min<int>(termMatchingMinLetters, termPartialMatchingMinLetters);
    var ls = min<int>(max<int>(min<int>(ls1, ls2), ls3), idb.maxTermLength);
    var ixs = idb.listIndicesOfTermLength[ls];
    var le1 = (lqt / termPartialMatchingMinLetterRatio).truncate();
    var le2 = (lqt / termMatchingMinLetterRatio).truncate();
    var le = min<int>(max<int>(le1, le2), idb.maxTermLength);
    var ixe = idb.listIndicesOfTermLength[le + 1];
    for (var i = ixs; i < ixe; i++) {
      var idbe = idb.list[i];
      bool partial;
      var sim = similarity(idbe.key.term, qterm.term);
      if (sim > 0) {
        partial = false;
        qterm.df += idbe.value.df * sim;
      } else {
        sim = partialSimilarity(idbe.key.term, qterm.term);
        if (sim == 0) {
          continue;
        }
        partial = true;
        qterm.df += 0;
      }
      var os = idbe.value.occurrences.map((o) => QueryTermOccurrence(
          o.entry, o.position, idbe.value.df, sim, partial));
      occurrences.addAll(os);
    }
    occurrences = occurrences.toList(growable: false);
    occurrences.sort((a, b) {
      var c = a.entry.compareTo(b.entry);
      if (c != 0) {
        return c;
      }
      c = b.termSimilarity.compareTo(a.termSimilarity);
      if (c != 0) {
        return c;
      }
      return a.position.compareTo(b.position);
    });
    return occurrences;
  }

  static int distance(Term s1, Term s2) {
    int min(int a, int b) => a < b ? a : b;
    if (s1.string == s2.string) {
      return 0;
    }
    var l1 = s1.length;
    var l2 = s2.length;
    if (l1 == 0) {
      return l2;
    }
    if (l2 == 0) {
      return l1;
    }
    Int32List r1;
    Int32List r2;
    if (l2 > l1) {
      r1 = s2.runes;
      r2 = s1.runes;
      var lt = l1;
      l1 = l2;
      l2 = lt;
    } else {
      r1 = s1.runes;
      r2 = s2.runes;
    }
    var size2 = l2 + 1;
    var v0 = Int32List(size2);
    var v1 = Int32List(size2);
    Int32List vtemp;
    for (var i = 0; i < size2; i++) {
      v0[i] = i;
    }
    int cost;
    for (var i = 0; i < l1; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < l2; j++) {
        cost = (r1[i] == r2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      vtemp = v0;
      v0 = v1;
      v1 = vtemp;
    }
    return v0[l2];
  }

  double similarity(Term dbTerm, Term queryTerm) {
    var lenDt = dbTerm.length;
    var lenQt = queryTerm.length;
    int lenMax;
    int lenMin;
    if (lenDt < lenQt) {
      lenMin = lenDt;
      lenMax = lenQt;
    } else {
      lenMin = lenQt;
      lenMax = lenDt;
    }
    if (dbTerm == queryTerm) {
      return 1.0;
    }
    if (lenMin < termMatchingMinLetters) {
      return 0.0;
    }
    if (lenMin.toDouble() / lenMax < termMatchingMinLetterRatio) {
      return 0.0;
    }
    var matched = lenMax - distance(dbTerm, queryTerm);
    if (matched < termMatchingMinLetters) {
      return 0.0;
    }
    var sim = matched.toDouble() / lenMax;
    if (sim < termMatchingMinLetterRatio) {
      return 0.0;
    }
    return sim;
  }

  double partialSimilarity(Term dbTerm, Term queryTerm) {
    var dtlen = dbTerm.length;
    var qtlen = queryTerm.length;
    if (dtlen < qtlen) {
      return 0.0;
    }
    if (qtlen < termPartialMatchingMinLetters) {
      return 0.0;
    }
    var sim = qtlen.toDouble() / dtlen.toDouble();
    if (sim < termPartialMatchingMinLetterRatio) {
      return 0.0;
    }
    if (!dbTerm.string.contains(queryTerm.string)) {
      return 0.0;
    }
    return sim;
  }

  double estimateCombination(
      Query query,
      List<List<QueryTermOccurrence>> queryTermOccurrences,
      int maxMissedTermCount) {
    var qtc = queryTermOccurrences.length;
    var ris = List<RangeIndices>.generate(qtc, (i) => RangeIndices(),
        growable: false);
    var etmc = <int>[];
    var etmcr = <List<int>>[[]];
    var maxCombi = 1.0;
    for (var currentEntry = setRangeIndices(Entry(''), query,
            queryTermOccurrences, ris, maxMissedTermCount, etmcr);
        currentEntry.string != '';
        currentEntry = setRangeIndices(currentEntry, query,
            queryTermOccurrences, ris, maxMissedTermCount, etmcr)) {
      etmc = etmcr[0];
      var combi = 1.0;
      for (var qti = 0; qti < qtc; qti++) {
        var e = ris[qti];
        if (e.end == e.start) {
          continue;
        }
        if (e.end == e.start + 1 &&
            etmc[queryTermOccurrences[qti][e.start].position] == 1) {
          continue;
        }
        combi *= (e.end - e.start + 1);
      }
      maxCombi = max<double>(maxCombi, combi);
    }
    return maxCombi;
  }

  List<List<QueryTermOccurrence>> reduceQueryTerms(
      Query query, List<List<QueryTermOccurrence>> queryTermOccurrences) {
    var ret = <List<QueryTermOccurrence>>[];
    if (query.terms.length <= fallbackMaxQueryTerms) {
      return queryTermOccurrences;
    }
    var tqts = <QueryTerm>[];
    var tqti = <QueryTerm, int>{};
    for (var i = 0; i < query.terms.length; i++) {
      tqts.add(query.terms[i]);
      tqti[query.terms[i]] = i;
    }
    tqts.sort((a, b) => a.df.compareTo(b.df));
    tqts = tqts.sublist(0, fallbackMaxQueryTerms).toList(growable: false);
    tqts.sort((a, b) => tqti[a]!.compareTo(tqti[b]!));
    var tLetType = LetType.na;
    for (var e in tqts) {
      var qti = tqti[e]!;
      ret.add(queryTermOccurrences[qti]);
      if (isLetByQueryTerm(query, qti)) {
        tLetType = query.letType;
      }
    }
    query.terms = tqts;
    query.letType = tLetType;
    return ret.toList(growable: false);
  }

  List<QueryTermOccurrence> reduceQueryTermOccurrences(
      List<QueryTermOccurrence> queryTermOccurrences, Query query) {
    var ose = <QueryTermOccurrence>[];
    var ret = <QueryTermOccurrence>[];
    var currentEntry = Entry('');
    for (var o in queryTermOccurrences) {
      if (currentEntry.string == '') {
        ose = [o];
        currentEntry = o.entry;
        continue;
      }
      if (currentEntry == o.entry) {
        ose.add(o);
        continue;
      }
      if (ose.length > fallbackMaxQueryTermMobility) {
        ose = ose.sublist(0, fallbackMaxQueryTermMobility);
      }
      ret.addAll(ose);
      ose = [o];
      currentEntry = o.entry;
    }
    if (ose.length > fallbackMaxQueryTermMobility) {
      ose.sort((a, b) => -a.termSimilarity.compareTo(b.termSimilarity));
      ose = ose.sublist(0, fallbackMaxQueryTermMobility);
    }
    ret.addAll(ose);
    return ret.toList(growable: false);
  }

  void caliculateQueryTermWeight(Query query) {
    var total = 0.0;
    var max = 0.0;
    var ambg = 1.0;
    for (var qt in query.terms) {
      qt.weight = absoluteTermImportance(qt.df);
      total += qt.weight;
      if (query.letType == LetType.postfix && qt != query.terms.last ||
          query.letType == LetType.prefix && qt != query.terms.first) {
        max = qt.weight > max ? qt.weight : max;
      }
      var ti = absoluteTermImportance(qt.df.toDouble()) / tidfz;
      var tsc = ti * 1.0;
      ambg *= (1.0 - tsc);
    }
    query.queryScore = 1.0 - ambg;
    if (query.letType != LetType.na && query.terms.length >= 2) {
      QueryTerm qt;
      if (query.letType == LetType.postfix) {
        qt = query.terms.last;
      } else {
        qt = query.terms.first;
      }
      total -= qt.weight;
      qt.weight *= max / tidfz;
      total += qt.weight;
    }
    if (total == 0.0) {
      for (var qt in query.terms) {
        qt.weight = 1.0 / query.terms.length;
      }
      return;
    }
    for (var qt in query.terms) {
      qt.weight /= total;
    }
  }

  List<QueryOccurrence> queryMatch(
      Query query,
      List<List<QueryTermOccurrence>> queryTermOccurrences,
      int maxMissedTermCount) {
    var qtc = queryTermOccurrences.length;
    var ris = List<RangeIndices>.generate(qtc, (i) => RangeIndices(),
        growable: false);
    var ret = <QueryOccurrence>[];
    var etmc = <int>[];
    var etmcr = <List<int>>[[]];
    for (var currentEntry = setRangeIndices(Entry(''), query,
            queryTermOccurrences, ris, maxMissedTermCount, etmcr);
        currentEntry.string != '';
        currentEntry = setRangeIndices(currentEntry, query,
            queryTermOccurrences, ris, maxMissedTermCount, etmcr)) {
      etmc = etmcr[0];
      var tqto = List<QueryTermInQueryOccurrnece>.generate(
          qtc, (i) => QueryTermInQueryOccurrnece(),
          growable: false);
      ret = joinQueryTermOccurrencesRecursively(query, currentEntry,
          queryTermOccurrences, ris, etmc, maxMissedTermCount, 0, 0, tqto, ret);
    }
    return ret;
  }

  Entry setRangeIndices(
      Entry currentEntry,
      Query query,
      List<List<QueryTermOccurrence>> queryTermOccurrences,
      List<RangeIndices> rangeIndices,
      int maxMissedTermCount,
      List<List<int>> matchedQueryTermCountsRef) {
    var nextEntry = Entry('');
    var qtc = queryTermOccurrences.length;
    while (true) {
      for (var qti = 0; qti < qtc; qti++) {
        rangeIndices[qti].start = rangeIndices[qti].end;
        if (queryTermOccurrences[qti] == <QueryTermOccurrence>[]) {
          continue;
        }
        if (rangeIndices[qti].start >= queryTermOccurrences[qti].length) {
          continue;
        }
        var qtse = queryTermOccurrences[qti][rangeIndices[qti].start].entry;
        if (nextEntry.string == '') {
          nextEntry = qtse;
          continue;
        }
        if (nextEntry.compareTo(qtse) > 0) {
          nextEntry = qtse;
        }
      }
      if (nextEntry.string == '') {
        return Entry('');
      }
      var etc = db[nextEntry]!.terms.length;
      matchedQueryTermCountsRef[0] = List<int>.filled(etc, 0, growable: false);
      var matchedQueryTermCounts = matchedQueryTermCountsRef[0];
      var matchedQueryTerms = 0;
      for (var qti = 0; qti < qtc; qti++) {
        int j;
        for (j = rangeIndices[qti].start;
            j < queryTermOccurrences[qti].length;
            j++) {
          if (queryTermOccurrences[qti][j].entry != nextEntry) {
            break;
          }
          matchedQueryTermCounts[queryTermOccurrences[qti][j].position]++;
        }
        rangeIndices[qti].end = j;
        if (rangeIndices[qti].start != j) {
          matchedQueryTerms++;
        }
      }
      if (qtc - matchedQueryTerms > maxMissedTermCount) {
        currentEntry = nextEntry;
        nextEntry = Entry('');
        continue;
      }
      break;
    }
    return nextEntry;
  }

  List<QueryOccurrence> joinQueryTermOccurrencesRecursively(
      Query query,
      Entry entry,
      List<List<QueryTermOccurrence>> queryTermOccurrences,
      List<RangeIndices> rangeIndices,
      List<int> matchedQueryTermCounts,
      int maxMissedTermCount,
      int missedTermCount,
      int qti,
      List<QueryTermInQueryOccurrnece> tmpQueryTermsInQueryOccurrence,
      List<QueryOccurrence> ret) {
    if (qti == queryTermOccurrences.length) {
      var tmpTmpQueryTermsInQueryOccurrence =
          List<QueryTermInQueryOccurrnece>.generate(
              tmpQueryTermsInQueryOccurrence.length,
              (i) => QueryTermInQueryOccurrnece.of(
                  tmpQueryTermsInQueryOccurrence[i]),
              growable: false);
      if (!checkDevidedMatch(query, entry, tmpTmpQueryTermsInQueryOccurrence)) {
        return ret;
      }
      var qo = QueryOccurrence(entry, 0.0, tmpTmpQueryTermsInQueryOccurrence);
      caliulateScore(qo, query);
      if (query.perfectMatching && qo.score == query.queryScore ||
          !query.perfectMatching &&
              (qo.score >= minScore || missedTermCount == 0)) {
        ret.add(qo);
      }
      return ret;
    }
    if (missedTermCount < maxMissedTermCount &&
        (rangeIndices[qti].end == rangeIndices[qti].start ||
            rangeIndices[qti].end > rangeIndices[qti].start + 1 ||
            queryTermOccurrences[qti][rangeIndices[qti].start].partial ==
                true ||
            matchedQueryTermCounts[queryTermOccurrences[qti]
                        [rangeIndices[qti].start]
                    .position] >
                1)) {
      tmpQueryTermsInQueryOccurrence[qti]
        ..position = -1
        ..df = 0
        ..termSimilarity = 0.0
        ..sequenceNo = 0;
      joinQueryTermOccurrencesRecursively(
          query,
          entry,
          queryTermOccurrences,
          rangeIndices,
          matchedQueryTermCounts,
          maxMissedTermCount,
          missedTermCount + 1,
          qti + 1,
          tmpQueryTermsInQueryOccurrence,
          ret);
    }
    for (var i = rangeIndices[qti].start; i < rangeIndices[qti].end; i++) {
      var qto = queryTermOccurrences[qti][i];
      var collision = false;
      for (var qtj = 0; qtj < qti; qtj++) {
        if (tmpQueryTermsInQueryOccurrence[qtj].position != qto.position) {
          continue;
        }
        if (qto.partial && tmpQueryTermsInQueryOccurrence[qtj].partial) {
          continue;
        }
        collision = true;
        break;
      }
      if (collision) {
        continue;
      }
      tmpQueryTermsInQueryOccurrence[qti]
        ..position = qto.position
        ..partial = qto.partial
        ..termSimilarity = qto.termSimilarity
        ..df = qto.df;
      joinQueryTermOccurrencesRecursively(
          query,
          entry,
          queryTermOccurrences,
          rangeIndices,
          matchedQueryTermCounts,
          maxMissedTermCount,
          missedTermCount,
          qti + 1,
          tmpQueryTermsInQueryOccurrence,
          ret);
    }
    return ret;
  }

  bool checkDevidedMatch(Query query, Entry entry,
      List<QueryTermInQueryOccurrnece> tmpQueryTermsInQueryOccurrence) {
    var joinedTermQtis = <int, List<int>>{};
    for (var qti = 0; qti < tmpQueryTermsInQueryOccurrence.length; qti++) {
      var position = tmpQueryTermsInQueryOccurrence[qti].position;
      if (position == -1) {
        continue;
      }
      if (!tmpQueryTermsInQueryOccurrence[qti].partial) {
        continue;
      }
      if (joinedTermQtis[position] == null) {
        joinedTermQtis[position] = [qti];
      } else {
        if (joinedTermQtis[position]!.last != qti - 1) {
          return false;
        }
        joinedTermQtis[position]!.add(qti);
      }
    }
    for (var me in joinedTermQtis.entries) {
      if (me.value.length < 2) {
        return false;
      }
      var position = me.key;
      var joinedTerm = Term(
          me.value.map((var qti) => query.terms[qti].term.string).join(' '));
      var dbterm = db[entry]!.terms[position];
      var sim = similarity(dbterm, joinedTerm);
      if (sim == 0.0) {
        return false;
      }
      for (var qti in me.value) {
        tmpQueryTermsInQueryOccurrence[qti].termSimilarity = sim;
      }
    }
    return true;
  }

  void caliulateScore(QueryOccurrence queryOccurrence, Query query) {
    var qtc = queryOccurrence.queryTerms.length;
    var ambg = 1.0;
    for (var qti = 0; qti < query.terms.length; qti++) {
      var e = queryOccurrence.queryTerms[qti];
      if (e.position == -1) {
        continue;
      }
      var ti = absoluteTermImportance(query.terms[qti].df.toDouble()) / tidfz;
      var tsc = ti * e.termSimilarity;
      ambg *= (1.0 - tsc);
    }
    var scro = 1.0 - ambg;
    var qts = <QueryTermInQueryOccurrnece>[];
    for (var qti = 0; qti < qtc; qti++) {
      var e = queryOccurrence.queryTerms[qti];
      if (e.position == -1) {
        continue;
      }
      if (query.letType == LetType.postfix && qti == qtc - 1 ||
          query.letType == LetType.prefix && qti == 0) {
        continue;
      }
      qts.add(e);
    }
    qts.sort((a, b) => a.position.compareTo(b.position));
    var sqno = -1;
    var lastPosition = -1;
    for (var e in qts) {
      if (e.position != lastPosition) {
        lastPosition = e.position;
        sqno++;
      }
      e.sequenceNo = sqno;
    }
    var qsqsno = 0;
    var totalNormDistance = 0.0;
    for (var qti = 0; qti < qtc; qti++) {
      var e = queryOccurrence.queryTerms[qti];
      var distance = 0.0;
      if (e.position == -1) {
        distance = qtc.toDouble();
      } else if (query.letType == LetType.postfix && qti == qtc - 1 ||
          query.letType == LetType.prefix && qti == 0) {
        distance = 0.0;
      } else {
        distance =
            (e.sequenceNo - qsqsno).abs() * queryMatchingTermOrderCoefficent;
        qsqsno++;
      }
      var normDistance = distance.toDouble() * query.terms[qti].weight;
      totalNormDistance += normDistance;
    }
    var termOrderSimilarity = 1.0 - (totalNormDistance / qtc.toDouble());
    queryOccurrence.score = scro * termOrderSimilarity;
  }

  List<QueryOccurrence> sortAndDedupResults(
      List<QueryOccurrence> resultUnsorted) {
    var ret = <QueryOccurrence>[];
    if (resultUnsorted.isEmpty) {
      return ret;
    }
    var topO = resultUnsorted.first;
    for (var e in resultUnsorted) {
      if (e == topO) {
        continue;
      }
      if (e.entry == topO.entry) {
        if (e.score > topO.score) {
          topO = e;
        }
        continue;
      }
      ret.add(topO);
      topO = e;
    }
    ret.add(topO);
    ret.sort();
    return ret;
  }
}
