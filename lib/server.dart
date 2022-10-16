// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'fmatch.dart';
import 'fmclasses.dart';

class Client {
  Client(this.serverId);
  final int serverId;
  late final StreamIterator<dynamic> _cri;
  late final SendPort _csp;

  Future<void> spawnServer(FMatcher matcher, SendPort cacheServer) async {
    var crp = ReceivePort();
    _cri = StreamIterator<dynamic>(crp);
    await Isolate.spawn<List<dynamic>>(
        serverMain, <dynamic>[crp.sendPort, matcher, cacheServer]);
    await _cri.moveNext();
    _csp = _cri.current as SendPort;
  }

  Future<QueryResult> fmatch(String query) async {
    _csp.send(query);
    await _cri.moveNext();
    return (_cri.current as QueryResult)..serverId = serverId;
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
  static Future<SendPort> spawn(int size) async {
    var crp = ReceivePort();
    await Isolate.spawn<List<dynamic>>(main, <dynamic>[crp.sendPort, size]);
    return await crp.first as SendPort;
  }

  static void close(SendPort ccsp){
    ccsp.send(null);
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
  factory CacheClient(SendPort ccsp) {
    var ccrp = ReceivePort();
    var ccri = StreamIterator<dynamic>(ccrp);
    return CacheClient._(ccrp.sendPort, ccri, ccsp);
  }

  CacheClient._(this._cssp, this._ccri, this._ccsp);
  final SendPort _cssp;
  final StreamIterator _ccri;
  final SendPort _ccsp;

  @override
  Future<CachedResult?> get(CachedQuery query) async {
    _ccsp.send([query, _cssp]);
    await _ccri.moveNext();
    return _ccri.current as CachedResult?;
  }

  @override
  void put(CachedQuery query, CachedResult result) {
    _ccsp.send([query, result]);
  }
}
