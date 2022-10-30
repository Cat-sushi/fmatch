// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'configs.dart';
import 'database.dart';
import 'distance.dart';
import 'fmclasses.dart';
import 'preprocess.dart';

mixin Tools on Settings {
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

  QueryTermsOccurrencesInEntryMap queryTermsMatch(Query query) {
    QueryTermsOccurrencesInEntryMap queryTermsMatchMap = {};
    for (var qti = 0; qti < query.terms.length; qti++) {
      var qterm = query.terms[qti];
      var isLet = isLetByQueryTerm(query, qti);
      if (isLet ||
          query.perfectMatching ||
          qterm.term.length < termMatchingMinLetters &&
              qterm.term.length < termPartialMatchingMinLetters) {
        var idbv = idb[IDbEntryKey(qterm.term, isLet)];
        if (idbv == null) {
          continue;
        }
        qterm.df += idbv.df * 1.0;
        for (var o in idbv.occurrences) {
          if (queryTermsMatchMap[o.entry] == null) {
            queryTermsMatchMap[o.entry] =
                List<List<QueryTermOccurrence>>.generate(
                    query.terms.length, (i) => []);
          }
          queryTermsMatchMap[o.entry]![qti]
              .add(QueryTermOccurrence(o.position, 1.0, false));
        }
        continue;
      }
      var lqt = qterm.term.length.toDouble();
      var ls1 = (lqt * termMatchingMinLetterRatio).ceil();
      var ls2 = (lqt * termPartialMatchingMinLetterRatio).ceil();
      var ls3 = min<int>(termMatchingMinLetters, termPartialMatchingMinLetters);
      var ls = min<int>(max<int>(min<int>(ls1, ls2), ls3), idb.maxTermLength);
      var le1 = (lqt / termPartialMatchingMinLetterRatio).truncate();
      var le2 = (lqt / termMatchingMinLetterRatio).truncate();
      var le = min<int>(max<int>(le1, le2), idb.maxTermLength);
      for (var l = ls; l <= le; l++) {
        var list = idb.listByTermLength(l);
        for (var idbe in list) {
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
          for (var o in idbe.value.occurrences) {
            if (queryTermsMatchMap[o.entry] == null) {
              queryTermsMatchMap[o.entry] =
                  List<List<QueryTermOccurrence>>.generate(
                      query.terms.length, (i) => []);
            }
            queryTermsMatchMap[o.entry]![qti]
                .add(QueryTermOccurrence(o.position, sim, partial));
          }
        }
      }
    }
    for (var e in queryTermsMatchMap.entries) {
      for (var qtos in e.value) {
        qtos.sort((a, b) => -a.termSimilarity.compareTo(b.termSimilarity));
      }
    }
    return queryTermsMatchMap;
  }

  double similarity(Term dbTerm, Term queryTerm) {
    if (dbTerm == queryTerm) {
      return 1.0;
    }
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
      QueryTermsOccurrencesInEntryMap queryTermsMatchMap,
      int maxMissedTermCount) {
    var qtc = query.terms.length;
    var maxCombi = 1.0;
    for (var e in queryTermsMatchMap.entries) {
      var queryTermsOccurrences = e.value;
      var etmcs = entryTermsQueryTermMatchCount(e.key, queryTermsMatchMap);
      var combi = 1.0;
      QueryTerms:
      for (var qti = 0; qti < qtc; qti++) {
        var queryTermOccurrences = queryTermsOccurrences[qti];
        if (queryTermOccurrences.isEmpty) {
          continue;
        }
        for (var i = 0; i < queryTermOccurrences.length; i++) {
          var qto = queryTermOccurrences[i];
          if (qto.partial) {
            continue;
          }
          if (etmcs[qto.position] == 1) {
            combi *= queryTermOccurrences.length;
            continue QueryTerms;
          }
        }
        combi *= (queryTermOccurrences.length + 1);
      }
      maxCombi = max<double>(maxCombi, combi);
    }
    return maxCombi;
  }

  void reduceQueryTerms(
      Query query, QueryTermsOccurrencesInEntryMap queryTermMatchMap) {
    var queryTermIndices = List<int>.generate(query.terms.length, (i) => i);
    if (queryTermIndices.length > fallbackMaxQueryTerms) {
      queryTermIndices
          .sort((a, b) => query.terms[a].df.compareTo(query.terms[b].df));
      queryTermIndices = queryTermIndices.sublist(0, fallbackMaxQueryTerms);
      queryTermIndices.sort();
      var newLetType = LetType.na;
      var newTerms =
          List<QueryTerm>.generate(queryTermIndices.length, (newQti) {
        var qti = queryTermIndices[newQti];
        if (query.letType == LetType.postfix && qti == query.terms.length - 1) {
          newLetType = LetType.na;
        } else if (query.letType == LetType.prefix && qti == 0) {
          newLetType = LetType.na;
        }
        return query.terms[queryTermIndices[newQti]];
      });
      query.terms = newTerms;
      query.letType = newLetType;
    }
    for (var e in queryTermMatchMap.entries.toList()) {
      var queryTermsOccurrences = e.value;
      var newQueryTermMatchesInEntry = List<List<QueryTermOccurrence>>.generate(
          query.terms.length,
          (newQti) => queryTermsOccurrences[queryTermIndices[newQti]]);
      for (var qti = 0; qti < newQueryTermMatchesInEntry.length; qti++) {
        var queryTermOccurrences = newQueryTermMatchesInEntry[qti];
        queryTermOccurrences
            .sort(((a, b) => -a.termSimilarity.compareTo(b.termSimilarity)));
        if (queryTermOccurrences.length > fallbackMaxQueryTermMobility) {
          newQueryTermMatchesInEntry[qti] =
              queryTermOccurrences.sublist(0, fallbackMaxQueryTermMobility);
        }
      }
      queryTermMatchMap[e.key] = newQueryTermMatchesInEntry;
    }
  }

  void caliculateQueryTermWeight(Query query) {
    var total = 0.0;
    var maxti = 0.0;
    var ambg = 1.0;
    QueryTerm? let;
    if (query.letType == LetType.postfix) {
      let = query.terms.last;
    } else if (query.letType == LetType.prefix) {
      let = query.terms.first;
    }
    for (var qt in query.terms) {
      qt.weight = absoluteTermImportance(qt.df) / tidfz; // term importance, yet
      ambg *= (1.0 - qt.weight * 1.0);
      total += qt.weight;
      if (qt != let) {
        maxti = max(maxti, qt.weight);
      }
    }
    query.queryScore = 1.0 - ambg;
    if (let != null) {
      total -= let.weight;
      let.weight *= maxti;
      total += let.weight;
    }
    if (total == 0.0) {
      for (var qt in query.terms) {
        qt.weight = 1.0 / query.terms.length;
      }
      return;
    }
    for (var qt in query.terms) {
      qt.weight /= total; // normalize as weight
    }
  }

  List<QueryOccurrence> queryMatch(
      Query query,
      QueryTermsOccurrencesInEntryMap queryTermsMatchMap,
      int maxMissedTermCount) {
    var qtc = query.terms.length;
    var ret = <QueryOccurrence>[];
    for (var e in queryTermsMatchMap.entries) {
      var entry = e.key;
      var queryTermOccurrences = e.value;
      var etmcs = entryTermsQueryTermMatchCount(entry, queryTermsMatchMap);
      var wqtso = List<QueryTermInQueryOccurrnece>.generate(
          qtc, (i) => QueryTermInQueryOccurrnece(),
          growable: false);
      var qo = joinQueryTermOccurrencesRecursively(query, entry,
          queryTermOccurrences, etmcs, maxMissedTermCount, 0, 0, wqtso, null);
      if (qo != null) {
        ret.add(qo);
      }
    }
    return ret;
  }

  List<int> entryTermsQueryTermMatchCount(Entry entry,
      Map<Entry, List<List<QueryTermOccurrence>>> queryTermsMatchMap) {
    var matchedQueryTermCounts = List<int>.filled(db[entry]!.terms.length, 0);
    var queryTermsOccurrences = queryTermsMatchMap[entry]!;
    for (var queryTermOccurrences in queryTermsOccurrences) {
      for (var queryTermOccurrence in queryTermOccurrences) {
        matchedQueryTermCounts[queryTermOccurrence.position]++;
      }
    }
    return matchedQueryTermCounts;
  }

  QueryOccurrence? joinQueryTermOccurrencesRecursively(
      Query query,
      Entry entry,
      List<List<QueryTermOccurrence>> queryTermsOccurrences,
      List<int> matchedQueryTermCounts,
      int maxMissedTermCount,
      int missedTermCount,
      int qti,
      List<QueryTermInQueryOccurrnece> workQueryTermsInQueryOccurrence,
      QueryOccurrence? retCandidate) {
    if (qti == queryTermsOccurrences.length) {
      var newQueryTermsInQueryOccurrence =
          List<QueryTermInQueryOccurrnece>.generate(
              workQueryTermsInQueryOccurrence.length,
              (i) => QueryTermInQueryOccurrnece.of(
                  workQueryTermsInQueryOccurrence[i]),
              growable: false);
      if (!checkDevidedMatch(query, entry, newQueryTermsInQueryOccurrence)) {
        return retCandidate;
      }
      var qo = QueryOccurrence(entry, newQueryTermsInQueryOccurrence);
      caliulateScore(qo, query);
      if (query.perfectMatching && qo.score == query.queryScore ||
          !query.perfectMatching &&
              (qo.score >= minScore || missedTermCount == 0)) {
        if (retCandidate == null || retCandidate.score < qo.score) {
          return qo;
        }
      }
      return retCandidate;
    }
    QueryTermOccurrence:
    for (var i = 0; i < queryTermsOccurrences[qti].length; i++) {
      var qto = queryTermsOccurrences[qti][i];
      for (var qtj = 0; qtj < qti; qtj++) {
        if (qto.partial && workQueryTermsInQueryOccurrence[qtj].partial) {
          continue;
        }
        if (workQueryTermsInQueryOccurrence[qtj].position == qto.position) {
          continue QueryTermOccurrence; // collision
        }
        if (workQueryTermsInQueryOccurrence[qtj].position > qto.position &&
            query.terms[qti].term == query.terms[qtj].term) {
          continue QueryTermOccurrence;
        }
      }
      workQueryTermsInQueryOccurrence[qti]
        ..position = qto.position
        ..partial = qto.partial
        ..termSimilarity = qto.termSimilarity;
      retCandidate = joinQueryTermOccurrencesRecursively(
          query,
          entry,
          queryTermsOccurrences,
          matchedQueryTermCounts,
          maxMissedTermCount,
          missedTermCount,
          qti + 1,
          workQueryTermsInQueryOccurrence,
          retCandidate);
    }
    if (missedTermCount == maxMissedTermCount) {
      return retCandidate;
    }
    for (var i = 0; i < queryTermsOccurrences[qti].length; i++) {
      var qto = queryTermsOccurrences[qti][i];
      if (qto.partial) {
        continue;
      }
      if (matchedQueryTermCounts[qto.position] == 1) {
        return retCandidate;
      }
    }
    workQueryTermsInQueryOccurrence[qti]
      ..position = -1
      ..termSimilarity = 0.0
      ..sequenceNo = 0;
    return joinQueryTermOccurrencesRecursively(
        query,
        entry,
        queryTermsOccurrences,
        matchedQueryTermCounts,
        maxMissedTermCount,
        missedTermCount + 1,
        qti + 1,
        workQueryTermsInQueryOccurrence,
        retCandidate);
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
      var ti = absoluteTermImportance(query.terms[qti].df) / tidfz;
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
      if (isLetByQueryTerm(query, qti)) {
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
}
