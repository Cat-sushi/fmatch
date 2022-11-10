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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:fmatch/bparts.dart';
import 'package:fmatch/fmatch.dart';
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
  print('Start Web Batch');
  if (options['multiplicity'] != null) {
    multiplicity =
        max(int.tryParse(options['multiplicity'] as String) ?? multiplicity, 1);
  }
  var queryPath = options['input'] as String? ?? 'batch/queries.csv';

  await time(() => wbatch(queryPath), 'wbatch');
}

Future<void> wbatch(String queryPath) async {
  if (!queryPath.endsWith('.csv')) {
    print('Invalid input file name: $queryPath');
    exit(1);
  }
  var queries = StreamQueue<String>(openQueryListStream(queryPath));
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var batchResultPath = '${trank}_norm.csv';
  var batchLogPath = '${trank}_log.txt';
  var resultFile = File(batchResultPath);
  resultSink = resultFile.openWrite()..add(utf8Bom);
  logSink = File(batchLogPath).openWrite();
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  var matcher = FMatcher();
  await matcher.readSettings(null);
  await matcher.preper.readConfigs();
  await matcher.buildDb();
  await Dispatcher(queries).dispatch();
}

class Result {
  final String from;
  final String to;
  Result(this.from, this.to);
}

class Dispatcher {
  Dispatcher(this.queries);
  final StreamQueue<String> queries;
  final results = <int, Result>{};
  var maxResultsLength = 0;
  var ixS = 0;
  var ixO = 0;
  Future<void> dispatch() async {
    var futures = List<Future>.generate(multiplicity, (i) => sendReceve());
    await Future.wait<void>(futures);
    print('Max result buffer length: $maxResultsLength');
    await logSink.close();
    await resultSink.close();
  }

  Future<void> sendReceve() async {
    var httpClient = HttpClient();
    while (true) {
      var queryRef = await queries.take(1);
      if (queryRef.isEmpty) {
        break;
      }
      var query = queryRef[0];
      var ix = ixS;
      ixS++;
      var path = Uri.encodeQueryComponent(query);
      var request =
          await httpClient.get('localhost', 4049, '/normalize?q=$path');
      var response = await request.close();
      var jsonString = await response.transform(utf8.decoder).join();
      var result = jsonDecode(jsonString) as String;
      results[ix] = Result(query, result);
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
      resultSink
          .write('${quoteCsvCell(result.from)},${quoteCsvCell(result.to)}\r\n');
      if (((ixO + 1) % 100) == 0) {
        currentLap = DateTime.now();
        print('${ixO+ 1}\t${currentLap.difference(startTime).inMilliseconds}'
            '\t${currentLap.difference(lastLap).inMilliseconds}');
        lastLap = currentLap;
      }
      results.remove(ixO);
    }
  }
}
