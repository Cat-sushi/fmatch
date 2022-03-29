// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math';

import 'package:edit_distance/edit_distance.dart';

import 'configs.dart';
import 'database.dart';
import 'preprocess.dart';

final nd = db.map.length.toDouble(); // nd >= 2.0
final idfm = Settings.scoreIdfMagnifier;
const dfz = 1.0;
final tidfz = absoluteTermImportance(dfz);
final dfx = min<double>(Settings.queryMatchingTypicalProperNounDf, nd);
final tix = absoluteTermImportance(dfx) / tidfz;
final tsox = Settings.queryMatchingMinTermOrderSimilarity;
final minScore = (1.0 - (1.0 - tix)) * tsox;

double absoluteTermImportance(double df) =>
    pow(log(nd / min<double>(max<double>(df, 1.0), nd)) / ln10, idfm)
        .toDouble();

bool isLetByQueryTerm(Query query, int qti) =>
    query.letType == LetType.postfix && qti == query.terms.length - 1 ||
    query.letType == LetType.prefix && qti == 0;

int maxMissedTermCount(int qtc) {
  var minMatchedTC =
      (qtc.toDouble() * Settings.queryMatchingMinTermRatio).ceil();
  minMatchedTC = max<int>(minMatchedTC, Settings.queryMatchingMinTerms);
  minMatchedTC = min<int>(minMatchedTC, qtc);
  return qtc - minMatchedTC;
}

final levenshtein = Levenshtein();

class QueryTerm {
  String term;
  double df;
  double weight;
  QueryTerm(this.term, this.df, this.weight);
}

class CachedQuery {
  final LetType letType;
  final List<String> terms;
  final bool perfectMatching;
  final int _hashCode;
  CachedQuery.fromPreprocessed(Preprocessed preped, this.perfectMatching)
      : letType = preped.letType,
        terms = preped.terms,
        _hashCode =
            Object.hashAll([preped.letType, perfectMatching, ...preped.terms]);
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

class Query {
  LetType letType;
  List<QueryTerm> terms;
  bool perfectMatching;
  double capScore;
  Query.fromPreprocessed(Preprocessed preped, this.perfectMatching)
      : letType = preped.letType,
        terms = preped.terms
            .map((e) => QueryTerm(e, 0.0, 0.0))
            .toList(growable: false),
        capScore = 0;
}

class QueryTermOccurrence {
  final String rawEntry;
  final int position;
  final double termSimilarity;
  final bool partial;
  QueryTermOccurrence(
      this.rawEntry, this.position, this.termSimilarity, this.partial);
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

class QueryOccurrence with Comparable<QueryOccurrence> {
  final String rawEntry;
  double score;
  final List<QueryTermInQueryOccurrnece> queryTerms;
  QueryOccurrence(this.rawEntry, this.score, this.queryTerms);
  @override
  int compareTo(QueryOccurrence other) => -score.compareTo(other.score);
}

class MatchedEntry {
  final String rawEntry;
  final double score;
  MatchedEntry(this.rawEntry, this.score);
  Map toJson() => <String, Object>{
        'rawEntry': rawEntry,
        'score': score,
      };
}

class CachedResult {
  List<MatchedEntry> matchedEntiries;
  double capScore;
  CachedResult(this.matchedEntiries, this.capScore);
  Map toJson() => <String, Object>{
    'matchedEntries': matchedEntiries.map((e) => e.toJson()).toList(),
    'capScore': capScore,
  };
}

class QueryResult {
  final DateTime dateTime;
  final int durationInMilliseconds;
  final String inputString;
  final String rawQuery;
  final LetType letType;
  final bool perfectMatching;
  final List<String> queryTerms;
  final CachedResult cachedResult;
  final String error;
  QueryResult.fromCachedResult(
    this.cachedResult,
    DateTime start,
    DateTime end,
    this.inputString,
    this.rawQuery,
    Preprocessed preprocessed,
  )   : dateTime = start,
        durationInMilliseconds = end.difference(start).inMilliseconds,
        letType = preprocessed.letType,
        queryTerms = preprocessed.terms,
        perfectMatching = false,
        error = '';
  QueryResult.fromQueryOccurrences(
    List<QueryOccurrence> queryOccurrences,
    DateTime start,
    DateTime end,
    this.inputString,
    this.rawQuery,
    Query query,
  )   : dateTime = start,
        durationInMilliseconds = end.difference(start).inMilliseconds,
        letType = query.letType,
        perfectMatching = query.perfectMatching,
        queryTerms = query.terms.map((e) => e.term).toList(growable: false),
        cachedResult = CachedResult(queryOccurrences
            .map((e) => MatchedEntry(e.rawEntry, e.score))
            .toList(growable: false), query.capScore),
        error = '';
  QueryResult.fromError(this.error)
      : dateTime = DateTime.now(),
        durationInMilliseconds = 0,
        inputString = '',
        rawQuery = '',
        letType = LetType.na,
        perfectMatching = false,
        queryTerms = [],
        cachedResult = CachedResult([], 0);
  Map toJson() => <String, Object>{
        'start': dateTime.toUtc().toIso8601String(),
        'durationInMilliseconds': durationInMilliseconds,
        'inputString': inputString,
        'rawQuery': rawQuery,
        'letType': letType.toString().substring(8),
        'queyTerms': queryTerms,
        'cachedResult': cachedResult.toJson(),
        'error': error,
      };
}

class ResultCache {
  // ignore: prefer_collection_literals
  final map = LinkedHashMap<CachedQuery, CachedResult>();
  ResultCache();
  CachedResult? operator [](CachedQuery query) {
    if (Settings.queryResultCacheSize == 0) {
      return null;
    }
    var rce = map.remove(query);
    if (rce == null) {
      return null;
    }
    map[query] = rce;
    return rce;
  }

  void operator []=(CachedQuery query, CachedResult result) {
    if (Settings.queryResultCacheSize == 0) {
      return;
    }
    map.remove(query);
    map[query] = result;
    if (map.length > Settings.queryResultCacheSize) {
      map.remove(map.keys.first);
    }
  }
}

var resultCache = ResultCache();
final _perfMatchTerm = RegExp(r'^"(.+)"$');

QueryResult fmatch(String inputString) {
  var start = DateTime.now();
  if (hasIllegalCharacter(inputString)) {
    return QueryResult.fromError('Illegal characters in query: $inputString');
  }
  var rawQuery = normalizeAndCapitalize(inputString);
  bool perfectMatching;
  Preprocessed preprocessed;
  var perfMatchTermMatcher = _perfMatchTerm.firstMatch(rawQuery);
  if (perfMatchTermMatcher != null) {
    perfectMatching = true;
    preprocessed = preprocess(perfMatchTermMatcher[1]!);
    if (preprocessed.letType != LetType.na ||
        preprocessed.terms.length != 1 ||
        preprocessed.terms[0] != perfMatchTermMatcher[1]) {
      return QueryResult.fromError(
          'Query is not suitable for perfect matching: $inputString');
    }
  } else {
    perfectMatching = false;
    preprocessed = preprocess(rawQuery);
    if (preprocessed.terms.isEmpty) {
      return QueryResult.fromError('No valid terms in query: $inputString');
    }
  }
  var cachedQuery = CachedQuery.fromPreprocessed(preprocessed, perfectMatching);
  if (crossTransactionalWhiteList.contains(cachedQuery)) {
    return QueryResult.fromError('Safe Customer: $inputString');
  }
  var cachedResult = resultCache[cachedQuery];
  if (cachedResult != null) {
    var end = DateTime.now();
    var ret = QueryResult.fromCachedResult(cachedResult, start, end,
        inputString, rawQuery, preprocessed);
    return ret;
  }
  var query = Query.fromPreprocessed(preprocessed, perfectMatching);
  var resultUnsorted = matchWithoutSort(query);
  var sorted = sortAndDedupResults(resultUnsorted);
  var end = DateTime.now();
  var ret = QueryResult.fromQueryOccurrences(
      sorted, start, end, inputString, rawQuery, query);
  resultCache[cachedQuery] = CachedResult(ret.cachedResult.matchedEntiries, query.capScore);
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
  var maxMissedTC = maxMissedTermCount(qtc);
  if (estimateCombination(query, queryTermOccurrences, maxMissedTC) >
      Settings.fallbackThresholdCombinations) {
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
      qterm.term.length < Settings.termMatchingMinLetters &&
          qterm.term.length < Settings.termPartialMatchingMinLetters) {
    var idbv = idb.map[IDbEntryKey(qterm.term, isLet)];
    if (idbv == null) {
      return <QueryTermOccurrence>[];
    }
    qterm.df += idbv.occurrences.length * 1.0;
    var os = idbv.occurrences
        .map((o) => QueryTermOccurrence(o.rawEntry, o.position, 1.0, false))
        .toList(growable: false);
    return os;
  }
  var occurrences = <QueryTermOccurrence>[];
  var lqt = qterm.term.length.toDouble();
  var ls = (lqt * Settings.termMatchingMinLetterRatio).ceil();
  var ixs = idb.indeces[ls];
  var le1 = (lqt / Settings.termPartialMatchingMinLetterRatio).truncate();
  var le2 = (lqt / Settings.termMatchingMinLetterRatio).truncate();
  var le = min<int>(max<int>(le1, le2), idb.maxTermLength);
  var ixe = idb.indeces[le + 1];
  for (var i = ixs; i < ixe; i++) {
    var idbe = idb.list[i];
    bool partial;
    var sim = similarity(idbe.key.term, qterm.term);
    if (sim > 0) {
      partial = false;
      qterm.df += idbe.value.occurrences.length * sim;
    } else {
      sim = partialSimilarity(idbe.key.term, qterm.term);
      if (sim == 0) {
        continue;
      }
      partial = true;
      qterm.df += 0;
    }
    var os = idbe.value.occurrences
        .map((o) => QueryTermOccurrence(o.rawEntry, o.position, sim, partial));
    occurrences.addAll(os);
  }
  occurrences = occurrences.toList(growable: false);
  occurrences.sort((a, b) => a.rawEntry.compareTo(b.rawEntry));
  return occurrences;
}

double similarity(String dbTerm, String queryTerm) {
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
  if (lenMin < Settings.termMatchingMinLetters) {
    return 0.0;
  }
  if (lenMin.toDouble() / lenMax < Settings.termMatchingMinLetterRatio) {
    return 0.0;
  }
  var matched = lenMax - levenshtein.distance(dbTerm, queryTerm);
  if (matched < Settings.termMatchingMinLetters) {
    return 0.0;
  }
  var sim = matched.toDouble() / lenMax;
  if (sim < Settings.termMatchingMinLetterRatio) {
    return 0.0;
  }
  return sim;
}

double partialSimilarity(String dbTerm, String queryTerm) {
  var dtlen = dbTerm.length;
  var qtlen = queryTerm.length;
  if (dtlen < qtlen) {
    return 0.0;
  }
  if (qtlen < Settings.termPartialMatchingMinLetters) {
    return 0.0;
  }
  var sim = qtlen.toDouble() / dtlen.toDouble();
  if (sim < Settings.termPartialMatchingMinLetterRatio) {
    return 0.0;
  }
  if (!dbTerm.contains(queryTerm)) {
    return 0.0;
  }
  return sim;
}

double estimateCombination(
    Query query,
    List<List<QueryTermOccurrence>> queryTermOccurrences,
    int maxMissedTermCount) {
  var qtc = queryTermOccurrences.length;
  var ris =
      List<RangeIndex>.generate(qtc, (i) => RangeIndex(), growable: false);
  var etmc = <int>[];
  var etmcr = <List<int>>[[]];
  var maxCombi = 1.0;
  for (var currentEntry = setRangeIndices(
          '', query, queryTermOccurrences, ris, maxMissedTermCount, etmcr);
      currentEntry != '';
      currentEntry = setRangeIndices(currentEntry, query, queryTermOccurrences,
          ris, maxMissedTermCount, etmcr)) {
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
  if (query.terms.length <= Settings.fallbackMaxQueryTerms) {
    return queryTermOccurrences;
  }
  var tqts = <QueryTerm>[];
  var tqti = <QueryTerm, int>{};
  for (var i = 0; i < query.terms.length; i++) {
    tqts.add(query.terms[i]);
    tqti[query.terms[i]] = i;
  }
  tqts.sort((a, b) => a.df.compareTo(b.df));
  tqts =
      tqts.sublist(0, Settings.fallbackMaxQueryTerms).toList(growable: false);
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
  var currentEntry = '';
  for (var o in queryTermOccurrences) {
    if (currentEntry == '') {
      ose = [o];
      currentEntry = o.rawEntry;
      continue;
    }
    if (currentEntry == o.rawEntry) {
      ose.add(o);
      continue;
    }
    if (ose.length > Settings.fallbackMaxQueryTermMobility) {
      ose.sort((a, b) => -a.termSimilarity.compareTo(b.termSimilarity));
      ose = ose.sublist(0, Settings.fallbackMaxQueryTermMobility);
    }
    ret.addAll(ose);
    ose = [o];
    currentEntry = o.rawEntry;
  }
  if (ose.length > Settings.fallbackMaxQueryTermMobility) {
    ose.sort((a, b) => -a.termSimilarity.compareTo(b.termSimilarity));
    ose = ose.sublist(0, Settings.fallbackMaxQueryTermMobility);
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
  query.capScore = 1.0 - ambg;
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
  var ris =
      List<RangeIndex>.generate(qtc, (i) => RangeIndex(), growable: false);
  var ret = <QueryOccurrence>[];
  var etmc = <int>[];
  var etmcr = <List<int>>[[]];
  for (var currentEntry = setRangeIndices(
          '', query, queryTermOccurrences, ris, maxMissedTermCount, etmcr);
      currentEntry != '';
      currentEntry = setRangeIndices(currentEntry, query, queryTermOccurrences,
          ris, maxMissedTermCount, etmcr)) {
    etmc = etmcr[0];
    var tqto = List<QueryTermInQueryOccurrnece>.generate(
        qtc, (i) => QueryTermInQueryOccurrnece(),
        growable: false);
    ret = joinQueryTermOccurrencesRecursively(query, currentEntry,
        queryTermOccurrences, ris, etmc, maxMissedTermCount, 0, 0, tqto, ret);
  }
  return ret;
}

class RangeIndex {
  int start = -1;
  int end = 0;
}

String setRangeIndices(
    String currentEntry,
    Query query,
    List<List<QueryTermOccurrence>> queryTermOccurrences,
    List<RangeIndex> rangeIndices,
    int maxMissedTermCount,
    List<List<int>> matchedQueryTermCountsRef) {
  var nextEntry = '';
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
      var qtse = queryTermOccurrences[qti][rangeIndices[qti].start].rawEntry;
      if (nextEntry == '') {
        nextEntry = qtse;
        continue;
      }
      if (nextEntry.compareTo(qtse) > 0) {
        nextEntry = qtse;
      }
    }
    if (nextEntry == '') {
      return '';
    }
    var etc = db.map[nextEntry]!.terms.length;
    matchedQueryTermCountsRef[0] = List<int>.filled(etc, 0, growable: false);
    var matchedQueryTermCounts = matchedQueryTermCountsRef[0];
    var matchedQueryTerms = 0;
    for (var qti = 0; qti < qtc; qti++) {
      int j;
      for (j = rangeIndices[qti].start;
          j < queryTermOccurrences[qti].length;
          j++) {
        if (queryTermOccurrences[qti][j].rawEntry != nextEntry) {
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
      nextEntry = '';
      continue;
    }
    break;
  }
  return nextEntry;
}

List<QueryOccurrence> joinQueryTermOccurrencesRecursively(
    Query query,
    String rawEntry,
    List<List<QueryTermOccurrence>> queryTermOccurrences,
    List<RangeIndex> rangeIndices,
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
    if (!checkDevidedMatch(
        query, rawEntry, tmpTmpQueryTermsInQueryOccurrence)) {
      return ret;
    }
    var qo = QueryOccurrence(rawEntry, 0.0, tmpTmpQueryTermsInQueryOccurrence);
    caliulateScore(qo, query);
    if (qo.score >= minScore || missedTermCount == 0) {
      ret.add(qo);
    }
    return ret;
  }
  if (missedTermCount < maxMissedTermCount &&
      (rangeIndices[qti].end == rangeIndices[qti].start ||
          rangeIndices[qti].end > rangeIndices[qti].start + 1 ||
          queryTermOccurrences[qti][rangeIndices[qti].start].partial == true ||
          matchedQueryTermCounts[
                  queryTermOccurrences[qti][rangeIndices[qti].start].position] >
              1)) {
    tmpQueryTermsInQueryOccurrence[qti]
      ..position = -1
      ..df = 0
      ..termSimilarity = 0.0
      ..sequenceNo = 0;
    joinQueryTermOccurrencesRecursively(
        query,
        rawEntry,
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
    var dbterm = db.map[qto.rawEntry]!.terms[qto.position];
    var isLet = isLetByQueryTerm(query, qti);
    tmpQueryTermsInQueryOccurrence[qti]
      ..position = qto.position
      ..partial = qto.partial
      ..termSimilarity = qto.termSimilarity
      ..df = idb.map[IDbEntryKey(dbterm, isLet)]!.df;
    joinQueryTermOccurrencesRecursively(
        query,
        rawEntry,
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

bool checkDevidedMatch(Query query, String rawEntry,
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
    var joinedTerm = me.value.map((var qti) => query.terms[qti].term).join(' ');
    var dbterm = db.map[rawEntry]!.terms[position];
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
      distance = (e.sequenceNo - qsqsno).abs() *
          Settings.queryMatchingTermOrderCoefficent;
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
    if (e.rawEntry == topO.rawEntry) {
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
