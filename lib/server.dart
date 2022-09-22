// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'fmatch.dart';
import 'fmclasses.dart';

class Client {
  final FMatcher _matcher;
  final CacheServer _cacheServer;
  final _crp = ReceivePort();
  late final StreamIterator<dynamic> _cri;
  late final SendPort _csp;
  Client(this._matcher, this._cacheServer) {
    _cri = StreamIterator<dynamic>(_crp);
  }
  Future<void> spawnServer() async {
    await Isolate.spawn<List<dynamic>>(
        serverMain, <dynamic>[_crp.sendPort, _matcher, _cacheServer._csp]);
    await _cri.moveNext();
    _csp = _cri.current as SendPort;
  }

  Future<QueryResult> fmatch(String query) async {
    _csp.send(query);
    await _cri.moveNext();
    return _cri.current as QueryResult;
  }

  void closeServer() {
    _csp.send(null);
  }

  static Future<void> serverMain(List<dynamic> message) async {
    var ssp = message[0] as SendPort;
    var matcher = message[1] as FMatcher;
    var ccsp = message[2] as SendPort;
    matcher.resultCache = CacheClient(ccsp); // overwriting local cache
    final srp = ReceivePort();
    ssp.send(srp.sendPort);
    await for (dynamic query in srp) {
      if (query == null) {
        break;
      }
      var result = await matcher.fmatch(query as String);
      ssp.send(result);
    }
  }
}

class CacheServer {
  final _crp = ReceivePort();
  late final SendPort _csp;
  Future<void> spawn(int size) async {
    await Isolate.spawn<List<dynamic>>(main, <dynamic>[_crp.sendPort, size]);
    _csp = await _crp.first as SendPort;
  }

  static Future<void> main(List<dynamic> message) async {
    var ssp = message[0] as SendPort;
    var size = message[1] as int;
    final cache = ResultCache(size);
    final srp = ReceivePort();
    ssp.send(srp.sendPort);
    await for (dynamic message in srp) {
      if (message == null) {
        break;
      }
      var args = message as List<dynamic>;
      var key = args[0] as CachedQuery;
      dynamic arg1 = args[1];
      if (arg1 is SendPort) {
        var result = await cache.get(key);
        arg1.send(result);
      } else if (arg1 is CachedResult) {
        cache.put(key, arg1);
      }
    }
  }
}

class CacheClient implements ResultCache {
  final _ccrp = ReceivePort();
  late final StreamIterator _ccri;
  final SendPort _ccsp;

  CacheClient(this._ccsp) {
    _ccri = StreamIterator<dynamic>(_ccrp);
  }

  @override
  Future<CachedResult?> get(CachedQuery query) async {
    _ccsp.send([query, _ccrp.sendPort]);
    await _ccri.moveNext();
    return _ccri.current as CachedResult?;
  }

  @override
  void put(CachedQuery query, CachedResult result) {
    _ccsp.send([query, result]);
  }
}
