// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:fmatch/bparts.dart';

import 'package:fmatch/fmclasses.dart';
import 'package:fmatch/util.dart';

var multiplicity = 1;

void main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print tis help')
    ..addOption('multiplicity',
        abbr: 'm', valueHelp: 'multiplicity of request');
  var options = argParser.parse(args);
  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }
  print('Start Web Batch');
  if (options['multiplicity'] != null) {
    multiplicity =
        max(int.tryParse(options['multiplicity'] as String) ?? multiplicity, 1);
  }
  await time(() => wbatch(), 'wbatch');
}

late IOSink resultSink;
late IOSink logSink;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

Future<void> wbatch([String path = 'batch']) async {
  var batchQueryPath = '$path/queries.csv';
  var batchResultPath = '$path/results.csv';
  var batchLogPath = '$path/log.txt';
  var resultFile = File(batchResultPath);
  resultFile.writeAsBytesSync([0xEF, 0xBB, 0xBF]);
  resultSink = resultFile.openWrite(mode: FileMode.append, encoding: utf8);
  logSink = File(batchLogPath).openWrite(encoding: utf8);
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  var queries = StreamQueue<String>(openQueryListStream(batchQueryPath));
  await Dispatcher(queries).dispatch();
}

class Dispatcher {
  final StreamQueue<String> queries;
  final results = <int, QueryResult>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  Dispatcher(this.queries);
  Future<void> dispatch() async {
    var futures = <Future>[];
    for (var id = 0; id < multiplicity; id++) {
      futures.add(sendReceve(id));
    }
    await Future.wait<void>(futures);
    print('Max result buffer length: $maxResultsLength');
    await logSink.close();
    await resultSink.close();
  }

  Future<void> sendReceve(int id) async {
    var httpClient = HttpClient();
    while (await queries.hasNext) {
      var ix = ixS;
      ixS++;
      var query = await queries.next;
      var path = Uri.encodeQueryComponent(query);
      var request =
          await httpClient.get('localhost', 4049, '/?q=$path');
      var response = await request.close();
      var jsonString = await response.transform(utf8.decoder).join();
      var result =
          QueryResult.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
      result.serverId = id;
      results[ix] = result;
      maxResultsLength = max(results.length, maxResultsLength);
      printResultsInOrder();
    }
    httpClient.close();
  }

  void printResultsInOrder() {
    for (; ixO < ixS; ixO++) {
      var result = results[ixO];
      if (result == null) {
        return;
      }
      if (result.cachedResult.cachedQuery.terms.isEmpty) {
        continue;
      }
      if (result.message != '') {
        logSink.writeln(result.message);
      }
      resultSink.write(formatOutput(ixO + 1, result));
      if (((ixO + 1) % 100) == 0) {
        currentLap = DateTime.now();
        print('${ixO + 1}: ${currentLap.difference(lastLap).inMilliseconds} '
            '${currentLap.difference(startTime).inMilliseconds}');
        lastLap = currentLap;
      }
      results.remove(ixO);
    }
  }
}
