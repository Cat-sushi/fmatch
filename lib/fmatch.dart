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

import 'package:fmatch/src/fmatcchp.dart';

import 'src/fmatch_impl.dart';
import 'src/fmclasses.dart';

export 'src/fmclasses.dart'
    show QueryResult, CachedQuery, CachedResult, MatchedEntry;
export 'src/preprocess.dart' show Term, Entry, LetType;
export 'src/preprocess.dart' show normalize;

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
  late int queryResultCacheSize;

  /// Initialize the matcher.
  /// 
  /// Call this before calling [fmatch()].
  Future<void> init();
  
  /// The matching method.
  /// 
  /// Regardless of the return type, this works synchronously.
  Future<QueryResult> fmatch(String query);
}

/// Parallel fuzzy text matacher.
/// 
/// This has resident internal servers(Isolates) to process queries parallel.
/// 
/// Usage
/// ```dart
/// matcher = FMatcher();
/// await matcher.init();
/// matcherp = FMatcherP.fromFMatcher(matcher, 4);
/// await matcherp.startServers();
/// results = matcherp.fmatchb('abc', 'def');
/// ```
abstract class FMatcherP {
  factory FMatcherP.fromFMatcher(FMatcher fmatcher, [int serverCount = 1]) {
    return FMatcherPImpl.fromFMatcher(fmatcher, serverCount);
  }

  /// This invokes the internal servers.
  Future<void> startServers();

  /// This stops the internal servers.
  Future<void> stopServers();

  /// The text matching method.
  /// 
  /// This version can be called parallel.
  Future<QueryResult> fmatch(String query, [bool activateCache = true]);

  /// The text matching method
  /// 
  /// This receive multiple queries and process them parallel.
  Future<List<QueryResult>> fmatchb(List<String> queries,
      [bool activateCache = true]);
}
