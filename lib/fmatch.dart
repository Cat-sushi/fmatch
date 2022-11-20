// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2022, Yako.
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

import 'dart:async';

import 'package:fmatch/src/fmatcchp_impl.dart';

import 'src/fmatch_impl.dart';
import 'src/fmclasses.dart';

export 'src/fmclasses.dart'
    show QueryResult, CachedQuery, CachedResult, MatchedEntry;
export 'src/preprocess.dart' show Term, Entry, LetType;
export 'src/preprocess.dart' show normalize;

/// Mutex for server restart.
///
/// This is useful if fmatch()/ fmatchb() is called asynchronously.
///
/// Usage
/// ```dart
/// late FMatcher fmatcher;
/// late FMatcherp fmatcherp;
/// final mutex = Mutex();
/// ```
/// ```dart
/// fmatcher = FMatcher();
/// await fmatcher.init();
/// fmatcherp = FMatcherP.fromFMatcher(fmatcher, 4);
/// fmatcherp.startServers();
/// ```
/// ```dart
/// await mutex.lock();
/// await fmatcherp.stopServers();
/// fmatcher = FMatcher();
/// await fmatcher.init();
/// fmatcherp = FMatcherP.fromFMatcher(matcher, 4);
/// await fmatcherp.startServers();
/// mutex.unlock();
/// ```
/// ```dart
/// await mutex.lockShared();
/// result = fmatcherp.fmatchb('abc', 'def');
/// mutex.unlockShared();
/// ```
class Mutex {
  var _excluded = Completer<void>()..complete();
  var _shared = Completer<void>()..complete();
  int _sharedCount = 0;
  Mutex();

  Future<void> lock() async {
    while (!_excluded.isCompleted) {
      await Future.wait([_excluded.future]);
    }
    _excluded = Completer<void>();
    while (!_shared.isCompleted) {
      await Future.wait([_shared.future]);
    }
  }

  void unlock() {
    _excluded.complete();
  }

  Future<void> lockShared() async {
    while (!_excluded.isCompleted) {
      await Future.wait([_excluded.future]);
    }
    if (_sharedCount == 0) {
      _shared = Completer<void>();
    }
    _sharedCount++;
  }

  void unlockShared() {
    _sharedCount--;
    if (_sharedCount == 0) {
      _shared.complete();
    }
  }
}

/// Fuzzy text matching engine.
///
/// Usage
/// ```dart
/// matcher = FMatcher();
/// await matcher.init();
/// result = await matcher.fmatch('abc');
/// ```
abstract class FMatcher {
  factory FMatcher() {
    return FMatcherImpl();
  }
  double termMatchingMinLetterRatio = 0.6666;
  int termMatchingMinLetters = 3;
  double termPartialMatchingMinLetterRatio = 0.2;
  int termPartialMatchingMinLetters = 2;
  double queryMatchingMinTermRatio = 0.5;
  int queryMatchingMinTerms = 1;
  double queryMatchingTypicalProperNounDf = 10.0;
  double queryMatchingMinTermOrderSimilarity = 0.4444;
  double scoreIdfMagnifier = 2.0;
  double fallbackThresholdCombinations = 117649;
  int fallbackMaxQueryTerms = 6;
  int fallbackMaxQueryTermMobility = 6;
  double queryMatchingTermOrderCoefficent = 0.5;
  int queryResultCacheSize = 100000;

  int databaseVersion = 0;

  /// Initialize the matcher.
  ///
  /// Reads settings and configs, loads the denial lists to the DB.
  ///
  /// Call this before calling [fmatch()].
  Future<void> init();

  /// The matching method.
  ///
  /// Regardless of the return type, this works synchronously.
  ///
  /// When the whole query is enclosed with double quates,
  /// it perfect matches with DB entries.
  Future<QueryResult> fmatch(String query, [bool activateCache = true]);
}

/// Parallel fuzzy text matacher.
///
/// This has resident internal servers(Isolates) to process queries parallel.
///
/// Usage
/// ```dart
/// fmatcher = FMatcher();
/// await fmatcher.init();
/// fmatcherp = FMatcherP.fromFMatcher(fmatcher, 4);
/// await fmatcherp.startServers();
/// results = fmatcherp.fmatchb('abc', 'def');
/// ```
abstract class FMatcherP {
  /// When [serverCount] == 0, `Platform.numberOfProcessors` will be used.
  factory FMatcherP.fromFMatcher(FMatcher fmatcher, [int serverCount = 0]) {
    return FMatcherPImpl.fromFMatcher(fmatcher, serverCount);
  }

  /// This spawns the internal serve idsolatess.
  Future<void> startServers();

  /// This stops the internal servers.
  Future<void> stopServers();

  /// The text matching method.
  ///
  /// This can work parallel, in contrast with `FMatcher.fmatch()`.
  ///
  /// When the whole query is enclosed with double quates,
  /// it perfect matches with DB entries.
  Future<QueryResult> fmatch(String query, [bool activateCache = true]);

  /// The text matching method.
  ///
  /// This receive multiple queries and process them parallel.
  ///
  /// When every whole query is enclosed with double quates,
  /// it perfect matches with DB entries.
  Future<List<QueryResult>> fmatchb(List<String> queries,
      [bool activateCache = true]);
}
