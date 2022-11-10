// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2022, Yako.
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

import 'dart:async';
import 'dart:isolate';

import 'fmatch.dart';
import 'fmclasses.dart';

class Client {
  final int serverId;
  late final StreamIterator<dynamic> _cri;
  late final SendPort _csp;

  Client(this.serverId);

  Future<void> spawnServer(FMatcher matcher, SendPort cacheServer) async {
    var crp = ReceivePort();
    _cri = StreamIterator<dynamic>(crp);
    await Isolate.spawn<List<dynamic>>(
        serverMain, <dynamic>[crp.sendPort, matcher, cacheServer]);
    await _cri.moveNext();
    _csp = _cri.current as SendPort;
  }

  Future<QueryResult> fmatch(String query, [bool activateCache = true]) async {
    _csp.send(<dynamic>[query, activateCache]);
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
    await for (dynamic args in srp) {
      if (args == null) {
        break;
      }
      var query = (args as List<dynamic>)[0] as String;
      var activateCache = args[1] as bool;
      var result = await matcher.fmatch(query, activateCache);
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

  static void close(SendPort ccsp) {
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
  final SendPort _cssp;
  final StreamIterator _ccri;
  final SendPort _ccsp;

  CacheClient._(this._cssp, this._ccri, this._ccsp);
  factory CacheClient(SendPort ccsp) {
    var ccrp = ReceivePort();
    var ccri = StreamIterator<dynamic>(ccrp);
    return CacheClient._(ccrp.sendPort, ccri, ccsp);
  }

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
