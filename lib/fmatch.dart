// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2020, 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';

import 'configs.dart';
import 'database.dart';
import 'fmclasses.dart';
import 'fmtools.dart';
import 'preprocess.dart';
import 'util.dart';

final _perfMatchQuery = RegExp(r'^"(.+)"$');

class FMatcher with Settings, Tools {
  Future<QueryResult> fmatch(String inputString,
      [bool activateCache = true]) async {
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
        CachedResult(cachedQuery, 0.0, false, []),
        start,
        DateTime.now(),
        inputString,
        rawQuery,
        'White query: "${preprocessed.terms.map((e) => e.string).join(' ')}"',
      );
    }

    if (activateCache) {
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

    var queryOccurrences = queryMatch(query, queryTermsMatchMap, maxMissedTC);

    queryOccurrences.sort();

    var ret = QueryResult.fromQueryOccurrences(
      queryOccurrences,
      start,
      DateTime.now(),
      inputString,
      rawQuery,
      query,
      queryFallenBack,
    );

    if (activateCache) {
      resultCache.put(cachedQuery, ret.cachedResult);
    }

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
        await time(
            () => db.write(Pathes.db), 'Db.write'); // for debug reproduction
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
