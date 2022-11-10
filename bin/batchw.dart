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

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:fmatch/bparts.dart';

import 'package:fmatch/fmclasses.dart';
import 'package:fmatch/util.dart';

late IOSink resultSink;
late IOSink logSink;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

var multiplicity = 1;

void main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print tis help')
    ..addOption('multiplicity', abbr: 'm', valueHelp: 'multiplicity of request')
    ..addOption('input', abbr: 'i', valueHelp: 'input file');
  var options = argParser.parse(args);
  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }
  print('Start Web Batch: ${DateTime.now()}');
  if (options['multiplicity'] != null) {
    multiplicity =
        max(int.tryParse(options['multiplicity'] as String) ?? multiplicity, 1);
  }
  var queryPath = options['input'] as String? ?? 'batch/queries.csv';
  await time(() => wbatch(queryPath), 'wbatch');
  print('End Web Batch: ${DateTime.now()}');
}

Future<void> wbatch(String queryPath) async {
  if (!queryPath.endsWith('.csv')) {
    print('Invalid input file name: $queryPath');
    exit(1);
  }
  var queries = StreamQueue<String>(openQueryListStream(queryPath));
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultPath = '${trank}_results.csv';
  var logPath = '${trank}_log.txt';
  var resultFile = File(resultPath);
  resultSink = resultFile.openWrite()..add(utf8Bom);
  logSink = File(logPath).openWrite();
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  await Dispatcher(queries).dispatch();
}

class Dispatcher {
  Dispatcher(this.queries);
  final StreamQueue<String> queries;
  final results = <int, QueryResult>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  var cacheHits = 0;
  var cacheHits2 = 0;
  Future<void> dispatch() async {
    var futures = List<Future>.generate(multiplicity, (i) => sendReceve());
    await Future.wait<void>(futures);
    print('Max result buffer length: $maxResultsLength');
    await logSink.close();
    await resultSink.close();
  }

  Future<void> sendReceve() async {
    var httpClient = HttpClient();
    while (await queries.hasNext) {
      var ix = ixS;
      ixS++;
      var query = await queries.next;
      var path = Uri.encodeQueryComponent(query);
      var request = await httpClient.get('localhost', 4049, '/?q=$path');
      var response = await request.close();
      var jsonString = await response.transform(utf8.decoder).join();
      var result =
          QueryResult.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
      results[ix] = result;
      maxResultsLength = max(results.length, maxResultsLength);
      outputResultsInOrder();
    }
    httpClient.close();
  }

  Future<void> outputResultsInOrder() async {
    for (; ixO < ixS; ixO++) {
      var result = results[ixO];
      if (result == null) {
        return;
      }
      if (result.cachedResult.cachedQuery.terms.isEmpty) {
        logSink.writeln(result.message);
        continue;
      }
      if (result.message != '') {
        cacheHits++;
        cacheHits2++;
      }
      resultSink.write(formatOutput(ixO + 1, result));
      if (((ixO + 1) % 100) == 0) {
        currentLap = DateTime.now();
        print('${ixO + 1}\t${currentLap.difference(startTime).inMilliseconds}'
            '\t${currentLap.difference(lastLap).inMilliseconds}'
            '\t\t$cacheHits2\t$cacheHits');
        cacheHits2 = 0;
        lastLap = currentLap;
      }
      results.remove(ixO);
    }
  }
}
