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
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';

import '../fmatch.dart';
import 'fmatch_impl.dart';
import 'server.dart';

class FMatcherPImpl implements FMatcherP {
  @override
  final FMatcher fmatcher;
  final bool isInitialized;
  final int _serverCount;
  final int serverCount;
  late final SendPort cacheServer;
  late final StreamController<Client> serverPoolController;
  late final StreamQueue<Client> serverPool;

  FMatcherPImpl({this.serverCount = 0})
      : fmatcher = FMatcher(),
        isInitialized = false,
        _serverCount =
            serverCount > 0 ? serverCount : Platform.numberOfProcessors;

  FMatcherPImpl.fromFMatcher(this.fmatcher, {this.serverCount = 0})
      : isInitialized = true,
        _serverCount =
            serverCount > 0 ? serverCount : Platform.numberOfProcessors;

  @override
  Future<void> startServers() async {
    if (!isInitialized) {
      await fmatcher.init();
    }
    serverPoolController = StreamController<Client>();
    serverPool = StreamQueue(serverPoolController.stream);
    cacheServer = await CacheServer.spawn(fmatcher.queryResultCacheSize);

    for (var id = 0; id < _serverCount; id++) {
      var c = Client(id);
      await c.spawnServer(fmatcher as FMatcherImpl, cacheServer);
      serverPoolController.add(c);
    }
  }

  @override
  Future<void> stopServers() async {
    for (var id = 0; id < _serverCount; id++) {
      var c = await serverPool.next;
      c.closeServer();
    }
    CacheServer.close(cacheServer);
  }

  @override
  Future<QueryResult> fmatch(String query, [bool activateCache = true]) async {
    var client = await serverPool.next;
    var result = await client.fmatch(query, activateCache);
    serverPoolController.add(client);
    return result;
  }

  @override
  Future<List<QueryResult>> fmatchb(List<String> queries,
      [bool activateCache = true]) async {
    var result = await Dispatcher(queries, serverPoolController, serverPool,
            _serverCount, activateCache)
        .dispatch();
    return result;
  }
}

class Dispatcher {
  Dispatcher(this.queries, this.serverPoolController, this.serverPool,
      this.serverCount, this.activateCache)
      : queryCount = queries.length,
        queryQueue = StreamQueue(Stream.fromIterable(queries));
  final List<String> queries;
  final StreamQueue<String> queryQueue;
  final int queryCount;
  final StreamController<Client> serverPoolController;
  final StreamQueue<Client> serverPool;
  final int serverCount;
  final bool activateCache;
  late final List<QueryResult?> results;
  var ixS = 0;
  var first = true;

  Future<List<QueryResult>> dispatch() async {
    results = List<QueryResult?>.filled(queryCount, null, growable: false);
    var futures = List<Future<void>>.generate(serverCount, (i) => sendReceve(),
        growable: false);
    await Future.wait<void>(futures);
    return results.cast<QueryResult>();
  }

  Future<void> sendReceve() async {
    while (true) {
      var queryRef = await queryQueue.take(1);
      if (queryRef.isEmpty) {
        break;
      }
      var query = queryRef[0];
      var ix = ixS;
      ixS++;
      var client = await serverPool.next;
      var result = await client.fmatch(query, activateCache);
      serverPoolController.add(client);
      results[ix] = result;
    }
  }
}
