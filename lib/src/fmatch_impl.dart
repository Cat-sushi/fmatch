// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2020, 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';

import '../fmatch.dart';
import 'configs.dart';
import 'database.dart';
import 'fmclasses.dart';
import 'fmtools.dart';
import 'util.dart';

final _perfMatchQuery = RegExp(r'^"(.+)"$');

class FMatcherImpl with Settings, Tools implements FMatcher {
  final int? _cacheSize;

  @override
  int databaseVersion = 0;

  FMatcherImpl({int? cacheSize}) : _cacheSize = cacheSize;

  @override
  Future<QueryResult> fmatch(String inputString,
      [bool activateCache = true]) async {
    var start = DateTime.now();

    if (preper.hasIllegalCharacter(inputString)) {
      return QueryResult.fromMessage(
          inputString, 'Illegal character(s) in the query: "$inputString"');
    }

    var rawQuery = normalize(inputString);

    bool perfectMatching = false;
    var perfMatchQueryMatcher = _perfMatchQuery.firstMatch(rawQuery);
    if (perfMatchQueryMatcher != null) {
      perfectMatching = true;
      rawQuery = perfMatchQueryMatcher[1]!.trim();
    }

    var preprocessed = preper.preprocess(rawQuery);
    if (preprocessed.terms.isEmpty) {
      return QueryResult.fromMessage(inputString, 'No valid term in the query');
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
        'White query',
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

    bool queryFallenBack = false;
    if (estimateCombination(query, queryTermsMatchMap) >
        fallbackThresholdCombinations) {
      queryFallenBack = true;
      reduceQueryTerms(query, queryTermsMatchMap);
    }

    var maxMissedTC =
        maxMissedTermCount(query.terms.length, query.perfectMatching);

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

  @override
  Future<void> init(
      {String configDir = Paths.configDir, String dbDir = Paths.dbDir}) async {
    await readSettings(configDir);
    queryResultCacheSize = _cacheSize ?? queryResultCacheSize;
    await preper.readConfigs(configDir);
    initWhiteQueries();
    await buildDb(configDir, dbDir);
  }

  Future<void> buildDb(String configDir, String dbDir) async {
    var idbFile = File('$dbDir/${Paths.idb}');
    var idbFileExists = idbFile.existsSync();
    late DateTime idbTimestamp;
    if (idbFileExists) {
      idbTimestamp = File('$dbDir/${Paths.idb}').lastModifiedSync();
    }
    if (!idbFileExists ||
        File('$dbDir/${Paths.list}').lastModifiedSync().isAfter(idbTimestamp) ||
        File('$configDir/${Paths.legalCaharacters}')
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File('$configDir/${Paths.characterReplacement}')
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File('$configDir/${Paths.stringReplacement}')
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File('$configDir/${Paths.legalEntryType}')
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File('$configDir/${Paths.words}')
            .lastModifiedSync()
            .isAfter(idbTimestamp) ||
        File('$configDir/${Paths.wordReplacement}')
            .lastModifiedSync()
            .isAfter(idbTimestamp)) {
      await time(() async {
        db = await Db.readList(preper, '$dbDir/${Paths.list}');
      }, 'Db.readList');
      await time(() async {
        idb = IDb.fromDb(db);
      }, 'IDb.fromDb');
      await time(() => db.write('$dbDir/${Paths.db}'),
          'Db.write'); // for debug configs
      await time(() => idb.write('$dbDir/${Paths.idb}'), 'IDb.write');
    } else {
      await time(() async {
        idb = await IDb.read('$dbDir/${Paths.idb}');
      }, 'IDb.read');
      await time(() => db = Db.fromIDb(idb), 'Db.fromIDb');
      if (!File('$dbDir/${Paths.db}').existsSync()) {
        await time(() => db.write('$dbDir/${Paths.db}'),
            'Db.write'); // for debug reproduction
      }
    }
    idbTimestamp = File('$dbDir/${Paths.idb}').lastModifiedSync();
    databaseVersion = idbTimestamp.millisecondsSinceEpoch;
  }

  void initWhiteQueries() {
    for (var inputString in preper.rawWhiteQueries) {
      if (preper.hasIllegalCharacter(inputString)) {
        print('Illegal characters in white query: $inputString');
        continue;
      }
      var rawQuery = normalize(inputString);
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
