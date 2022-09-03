// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

import 'batch.dart';
import 'fmatch.dart';
import 'server.dart';

late File resultFile;
late IOSink resultSink;
late IOSink logSink;
late int lc;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

Future<void> pbatch(FMatcher matcher, [String path = 'lib/batch']) async {
  var batchQueryPath = '$path/queries.csv';
  var batchResultPath = '$path/results.csv';
  var batchLogPath = '$path/log.txt';
  var resultFile = File(batchResultPath);
  resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
  resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
  logSink = File(batchLogPath).openWrite(encoding: utf8);
  lc = 0;
  startTime = DateTime.now();
  lastLap = startTime;
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

class Dispatcher {
  final List<Server> servers;
  final StreamQueue<String> queries;
  final results = <int, QueryResult>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  Dispatcher(this.servers, this.queries);
  Future<void> dispatch() async {
    var futures = <Future>[];
    for (var id = 0; id < servers.length; id++) {
      futures.add(sendReceve(id));
    }
    await Future.wait<void>(futures);
    print('Max result buffer length: $maxResultsLength');
    await logSink.close();
    await resultSink.close();
  }

  Future<void> sendReceve(int id) async {
    var server = servers[id];
    while (await queries.hasNext) {
      var ix = ixS;
      ixS++;
      var query = await queries.next;
      server.csp.send(query);
      await server.cri.moveNext();
      var result = server.cri.current as QueryResult;
      result.serverId = id;
      results[ix] = result;
      maxResultsLength =
          results.length > maxResultsLength ? results.length : maxResultsLength;
      printResultsInOrder();
    }
    servers[id].csp.send(null);
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
        print('$lc: ${currentLap.difference(lastLap).inMilliseconds} '
            '${currentLap.difference(startTime).inMilliseconds}');
        lastLap = currentLap;
      }
      results.remove(ixO);
    }
  }
}
