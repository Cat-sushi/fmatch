// Copyright (c) 2023, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:async/async.dart';

import 'package:fmatch/batch.dart';
import 'package:fmatch/fmatch.dart';

late File resultFile;
late IOSink resultSink;
late IOSink logSink;
late int lc;
late DateTime currentLap;
late DateTime lastLap;

late DateTime startTime;
late DateTime endTime;

Future<void> pbatch(FMatcher matcher, [String path = 'lib/batch']) async {
  var batchQueryPath = '$path/queries.csv';
  var batchResultPath = '$path/results.csv';
  var batchLogPath = '$path/Log.txt';
  var resultFile = File(batchResultPath);
  resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
  resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
  logSink = File(batchLogPath).openWrite(encoding: utf8);
  lc = 0;
  lastLap = DateTime.now();
  currentLap = lastLap;
  var queries = StreamQueue<String>(openQueryListStream(batchQueryPath));
  final servers = <Server>[];
  for (var id = 0; id < matcher.serverCount; id++) {
    var server = Server(matcher);
    await server.spawn(id);
    servers.add(server);
  }
  await Dispatcher(servers, queries).dispatch();
}

class Server {
  final FMatcher matcher;
  final ReceivePort crp;
  late final Stream crb;
  late final SendPort csp;
  late final Isolate isolate;
  Server(this.matcher) : crp = ReceivePort() {
    crb = crp.asBroadcastStream();
  }
  Future<void> spawn(int id) async {
    isolate = await Isolate.spawn<List<dynamic>>(
        main, <dynamic>[crp.sendPort, matcher]);
    csp = await crb.first as SendPort;
  }

  static Future<void> main(List<dynamic> message) async {
    var ssp = message[0] as SendPort;
    var matcher = message[1] as FMatcher;
    final srp = ReceivePort();
    ssp.send(srp.sendPort);
    await for (dynamic query in srp) {
      if (query == null) {
        break;
      }
      var result = matcher.fmatch(query as String);
      ssp.send(result);
    }
  }
}

class Dispatcher {
  final List<Server> servers;
  final StreamQueue<String> queries;
  final results = <QueryResult?>[];
  var ixS = 0;
  var ixO = 0;
  Dispatcher(this.servers, this.queries);
  Future<void> dispatch() async {
    var futures = <Future>[];
    for (var id = 0; id < servers.length; id++) {
      futures.add(sendReceve(servers[id]));
    }
    await Future.wait<void>(futures);
    await logSink.close();
    await resultSink.close();
  }

  Future<void> sendReceve(Server server) async {
    while (await queries.hasNext) {
      var ix = ixS;
      ixS++;
      results.add(null);
      var query = await queries.next;
      server.csp.send(query);
      var result = await server.crb.first as QueryResult;
      results[ix] = result;
      printResultsInOrder();
    }
    server.csp.send(null);
  }

  void printResultsInOrder() {
    for (; ixO < ixS; ixO++) {
      var result = results[ixO];
      if (result == null) {
        return;
      }
      if (result.error != '') {
        logSink.writeln(result.error);
        continue;
      }
      resultSink.write(formatOutput(lc, result));
      ++lc;
      if ((lc % 100) == 0) {
        currentLap = DateTime.now();
        print('$lc: ${currentLap.difference(lastLap).inMilliseconds}');
        lastLap = currentLap;
      }
      results[ixO] = null;
    }
  }
}
