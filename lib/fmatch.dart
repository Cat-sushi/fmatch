// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'configs.dart';
import 'database.dart';
import 'fmclasses.dart';
import 'fmtools.dart';
import 'preprocess.dart';
import 'util.dart';

class FMatcher with Settings, Tools {
  static final _perfMatchQuery = RegExp(r'^"(.+)"$');

  Future<QueryResult> fmatch(String inputString) async {
    var start = DateTime.now();

    if (preper.hasIllegalCharacter(inputString)) {
      return QueryResult.fromError(
          inputString, 'Illegal characters in query: "$inputString"');
    }

    var rawQuery = preper.normalizeAndCapitalize(inputString);

    bool perfectMatching = false;
    var perfMatchQueryMatcher = _perfMatchQuery.firstMatch(rawQuery.string);
    if (perfMatchQueryMatcher != null) {
      perfectMatching = true;
      rawQuery = Entry(perfMatchQueryMatcher[1]!);
    }

    var preprocessed = preper.preprocess(rawQuery);
    if (preprocessed.terms.isEmpty) {
      return QueryResult.fromError(
          inputString, 'No valid terms in query: "$inputString"');
    }

    var cachedQuery =
        CachedQuery.fromPreprocessed(preprocessed, perfectMatching);
    if (!perfectMatching && whiteQueries.contains(cachedQuery)) {
      return QueryResult.fromCachedResult(
        CachedResult(cachedQuery, 0, false, []),
        start,
        DateTime.now(),
        inputString,
        rawQuery,
        'White query: "${preprocessed.terms.map((e) => e.string).join(' ')}"',
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
    var queryTermsMatchMap = queryTermsMatch(query);

    var maxMissedTC =
        query.perfectMatching ? 0 : maxMissedTermCount(query.terms.length);
    bool queryFallenBack = false;
    if (estimateCombination(query, queryTermsMatchMap, maxMissedTC) >
        fallbackThresholdCombinations) {
      queryFallenBack = true;
      reduceQueryTerms(query, queryTermsMatchMap);
      maxMissedTC = maxMissedTermCount(query.terms.length);
    }

    caliculateQueryTermWeight(query);

    var result = queryMatch(query, queryTermsMatchMap, maxMissedTC);

    result.sort();

    var ret = QueryResult.fromQueryOccurrences(
      result,
      start,
      DateTime.now(),
      inputString,
      rawQuery,
      query,
      queryFallenBack,
    );
    resultCache.put(cachedQuery, ret.cachedResult);
    return ret;
  }

  Future<void> buildDb() async {
    initWhiteQueries();
    var idbFile = File(Pathes.idb);
    var idbFileExists = idbFile.existsSync();
    late DateTime idbTimestamp;
    if (idbFileExists) {
      idbTimestamp = File(Pathes.idb).lastModifiedSync();
    }
    if (!idbFileExists ||
        File(Pathes.list).lastModifiedSync().isAfter(idbTimestamp) ||
        File(Pathes.legalCaharacters)
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File(Pathes.characterReplacement)
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File(Pathes.stringReplacement)
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File(Pathes.legalEntryType).lastModifiedSync().isAfter(idbTimestamp) ||
        File(Pathes.words).lastModifiedSync().isAfter(idbTimestamp) ||
        File(Pathes.wordReplacement).lastModifiedSync().isAfter(idbTimestamp)) {
      await time(() async {
        db = await Db.readList(preper, Pathes.list);
      }, 'Db.readList');
      await time(() async {
        idb = IDb.fromDb(db);
      }, 'IDb.fromDb');
      await time(() => db.write(Pathes.db), 'Db.write'); // for debug configs
      await time(() => idb.write(Pathes.idb), 'IDb.write');
    } else {
      await time(() async {
        idb = await IDb.read(Pathes.idb);
      }, 'IDb.read');
      await time(() => db = Db.fromIDb(idb), 'Db.fromIDb');
      if (!File(Pathes.db).existsSync()) {
        await time(() => db.write(Pathes.db), 'Db.write'); // for debug reproduction
      }
    }
  }

  void initWhiteQueries() {
    for (var inputString in preper.rawWhiteQueries) {
      if (preper.hasIllegalCharacter(inputString)) {
        print('Illegal characters in white query: $inputString');
        continue;
      }
      var rawQuery = preper.normalizeAndCapitalize(inputString);
      var preprocessed = preper.preprocess(rawQuery, canonicalizing: true);
      if (preprocessed.terms.isEmpty) {
        print('No valid terms in white query: $inputString');
        continue;
      }
      whiteQueries.add(CachedQuery.fromPreprocessed(preprocessed, false));
    }
    preper.rawWhiteQueries.clear();
  }
}
