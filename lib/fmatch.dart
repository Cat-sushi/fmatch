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

import 'package:fmatch/src/configs.dart';
import 'package:fmatch/src/fmatcchp_impl.dart';

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
abstract class FMatcher with Settings {
  factory FMatcher() {
    return FMatcherImpl();
  }

  int databaseVersion = 0;

  /// Initialize the matcher.
  ///
  /// Reads settings and configs, loads the denial lists to the DB.
  ///
  /// Call this before calling [fmatch()].
  Future<void> init(
      {String configDir = Pathes.configDir, String dbDir = Pathes.dbDir});

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
abstract class FMatcherP {
  FMatcher get fmatcher;

  /// A standard constructor. See usage.
  ///
  /// When [serverCount] == 0, `Platform.numberOfProcessors` will be used.
  ///
  /// If you will [stopServers] asynchronously, pass [mutex] `true`.
  ///
  /// Usage
  /// ```dart
  /// fmatcherp = FMatcherP();
  /// await fmatcherp.startServers();
  /// results = fmatcherp.fmatchb('abc', 'def');
  /// ```
  factory FMatcherP({int serverCount = 0, bool mutex = false}) {
    return FMatcherPImpl(serverCount: serverCount, mutex: mutex);
  }

  /// Construt from PMatcher. See usage.
  ///
  /// When [serverCount] == 0, `Platform.numberOfProcessors` will be used.
  ///
  /// If you will [stopServers] asynchronously, pass [mutex] `true`.
  ///
  /// Usage
  /// ```dart
  /// fmatcher = FMatcher();
  /// await fmatcher.init();
  /// fmatcherp = FMatcherP.fromFMatcher(fmatcher, 4);
  /// await fmatcherp.startServers();
  /// results = fmatcherp.fmatchb('abc', 'def');
  /// ```
  factory FMatcherP.fromFMatcher(FMatcher fmatcher,
      {int serverCount = 0, bool mutex = false}) {
    return FMatcherPImpl.fromFMatcher(fmatcher,
        serverCount: serverCount, mutex: mutex);
  }

  /// This spawns the internal serve idsolatess.
  Future<void> startServers();

  /// This stops the internal servers.
  void stopServers();

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
