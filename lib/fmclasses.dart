// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'preprocess.dart';

class QueryTerm {
  QueryTerm(this.term, this.df, this.weight);
  final Term term;
  double df;
  double weight;
}

class Query {
  Query.fromPreprocessed(Preprocessed preped, this.perfectMatching)
      : letType = preped.letType,
        terms = preped.terms
            .map((e) => QueryTerm(e, 0.0, 0.0))
            .toList(growable: false),
        queryScore = 0;
  LetType letType;
  List<QueryTerm> terms;
  bool perfectMatching;
  double queryScore;
}

typedef QueryTermsOccurrencesInEntryMap = Map<Entry, List<List<QueryTermOccurrence>>>;

class QueryTermOccurrence {
  QueryTermOccurrence(this.position, this.termSimilarity, this.partial);
  final int position;
  final double termSimilarity;
  final bool partial;
}

class QueryTermInQueryOccurrnece {
  QueryTermInQueryOccurrnece.of(QueryTermInQueryOccurrnece o)
      : position = o.position,
        sequenceNo = o.sequenceNo,
        termSimilarity = o.termSimilarity,
        partial = o.partial;
  QueryTermInQueryOccurrnece.fromQueryTermOccurrence(QueryTermOccurrence qto)
      : position = qto.position,
        sequenceNo = 0,
        termSimilarity = qto.termSimilarity,
        partial = qto.partial;
  QueryTermInQueryOccurrnece()
      : position = -1,
        sequenceNo = 0,
        termSimilarity = 0.0,
        partial = false;
  int position;
  int sequenceNo;
  double termSimilarity;
  bool partial;
}

class QueryOccurrence implements Comparable<QueryOccurrence> {
  QueryOccurrence(this.entry, this.queryTerms);
  final Entry entry;
  final List<QueryTermInQueryOccurrnece> queryTerms;
  double score = 0.0;
  @override
  int compareTo(QueryOccurrence other) {
    var c = -score.compareTo(other.score);
    if (c != 0) {
      return c;
    }
    c = entry.length.compareTo(other.entry.length);
    if (c != 0) {
      return c;
    }
    return entry.compareTo(other.entry);
  }
}

class MatchedEntry {
  MatchedEntry.fromJson(Map<String, dynamic> json)
      : entry = Entry(json['entry'] as String),
        score = json['score'] as double;
  MatchedEntry(this.entry, this.score);
  final Entry entry;
  final double score;
  Map toJson() => <String, dynamic>{
        'entry': entry,
        'score': score,
      };
}

class CachedQuery {
  CachedQuery.fromJson(Map<String, dynamic> json)
      : this(
          LetType.fromJson(json['letType'] as String),
          (json['terms'] as List<dynamic>)
              .map<Term>((dynamic e) => Term(e as String))
              .toList(growable: false),
          json['perfectMatching'] as bool,
        );
  CachedQuery.fromPreprocessed(Preprocessed preped, bool perfectMatching)
      : this(preped.letType, preped.terms, perfectMatching);
  CachedQuery(this.letType, this.terms, this.perfectMatching)
      : hashCode = Object.hashAll([letType, perfectMatching, ...terms]);
  final LetType letType;
  final List<Term> terms;
  final bool perfectMatching;
  @override
  final int hashCode;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'letType': letType,
        'terms': terms,
        'perfectMatching': perfectMatching,
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
}

class CachedResult {
  CachedResult.fromJson(Map<String, dynamic> json)
      : this(
          CachedQuery.fromJson(json['cachedQuery'] as Map<String, dynamic>),
          json['queryScore'] as double,
          json['queryFallenBack'] as bool,
          (json['matchedEntiries'] as List<dynamic>)
              .map<MatchedEntry>((dynamic e) =>
                  MatchedEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
  CachedResult(this.cachedQuery, this.queryScore, this.queryFallenBack,
      this.matchedEntiries);
  final CachedQuery cachedQuery;
  final double queryScore;
  final bool queryFallenBack;
  final List<MatchedEntry> matchedEntiries;
  Map toJson() => <String, dynamic>{
        'cachedQuery': cachedQuery,
        'queryScore': queryScore,
        'queryFallenBack': queryFallenBack,
        'matchedEntiries': matchedEntiries,
      };
}

class QueryResult {
  QueryResult.fromJson(Map<String, dynamic> json)
      : serverId = json['serverId'] as int,
        dateTime = DateTime.parse(json['start'] as String),
        durationInMilliseconds = json['durationInMilliseconds'] as int,
        inputString = json['inputString'] as String,
        rawQuery = Entry(json['rawQuery'] as String),
        cachedResult =
            CachedResult.fromJson(json['cachedResult'] as Map<String, dynamic>),
        message = json['message'] as String;
  QueryResult.fromError(this.inputString, this.message)
      : dateTime = DateTime.now(),
        durationInMilliseconds = 0,
        rawQuery = Entry(''),
        cachedResult =
            CachedResult(CachedQuery(LetType.na, [], false), 0, false, []);
  QueryResult.fromQueryOccurrences(
    List<QueryOccurrence> queryOccurrences,
    DateTime start,
    DateTime end,
    this.inputString,
    this.rawQuery,
    Query query,
    bool queryFallenBack,
  )   : dateTime = start,
        durationInMilliseconds = end.difference(start).inMilliseconds,
        cachedResult = CachedResult(
            CachedQuery(
                query.letType,
                query.terms.map((e) => e.term).toList(growable: false),
                query.perfectMatching),
            query.queryScore,
            queryFallenBack,
            queryOccurrences
                .map((e) => MatchedEntry(e.entry, e.score))
                .toList()),
        message = '';
  QueryResult.fromCachedResult(this.cachedResult, DateTime start, DateTime end,
      this.inputString, this.rawQuery,
      [this.message = ''])
      : dateTime = start,
        durationInMilliseconds = end.difference(start).inMilliseconds;
  int serverId = 0;
  final DateTime dateTime;
  final int durationInMilliseconds;
  final String inputString;
  final Entry rawQuery;
  final CachedResult cachedResult;
  final String message;
  Map toJson() => <String, dynamic>{
        'serverId': serverId,
        'start': dateTime.toUtc().toIso8601String(),
        'durationInMilliseconds': durationInMilliseconds,
        'inputString': inputString,
        'rawQuery': rawQuery,
        'cachedResult': cachedResult,
        'message': message,
      };
}

class ResultCache {
  ResultCache(int size) : _queryResultCacheSize = size;
  final int _queryResultCacheSize;
  // ignore: prefer_collection_literals
  final _map = LinkedHashMap<CachedQuery, CachedResult>();

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
    var rce = _map.remove(query) ?? result;
    _map[query] = rce;
    if (_map.length > _queryResultCacheSize) {
      _map.remove(_map.keys.first);
    }
  }
}
