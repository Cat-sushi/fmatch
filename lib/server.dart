// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'fmatch.dart';
import 'fmclasses.dart';

class Server {
  final FMatcher matcher;
  final CacheServer cacheServer;
  final crp = ReceivePort();
  late final StreamIterator<dynamic> cri;
  late final SendPort csp;
  late final Isolate isolate;
  Server(this.matcher, this.cacheServer) {
    cri = StreamIterator<dynamic>(crp);
  }
  Future<void> spawn(int id) async {
    isolate = await Isolate.spawn<List<dynamic>>(
        main, <dynamic>[crp.sendPort, matcher, cacheServer.csp]);
    await cri.moveNext();
    csp = cri.current as SendPort;
  }

  static Future<void> main(List<dynamic> message) async {
    var ssp = message[0] as SendPort;
    var matcher = message[1] as FMatcher;
    var ccsp = message[2] as SendPort;
    matcher.resultCache = CacheClient(ccsp);
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
  final crp = ReceivePort();
  late final SendPort csp;
  late final Isolate isolate;
  Future<void> spawn(int size) async {
    isolate =
        await Isolate.spawn<List<dynamic>>(main, <dynamic>[crp.sendPort, size]);
    csp = await crp.first as SendPort;
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
  final ccrp = ReceivePort();
  late final StreamIterator ccri;
  final SendPort ccsp;

  CacheClient(this.ccsp) {
    ccri = StreamIterator<dynamic>(ccrp);
  }

  @override
  Future<CachedResult?> get(CachedQuery query) async {
    ccsp.send([query, ccrp.sendPort]);
    await ccri.moveNext();
    return ccri.current as CachedResult?;
  }

  @override
  void put(CachedQuery query, CachedResult result) {
    ccsp.send([query, result]);
  }
}
