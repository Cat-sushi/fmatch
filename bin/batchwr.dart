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
import 'package:fmatch/src/bparts.dart';
import 'package:fmatch/src/configs.dart';
import 'package:fmatch/src/fmatch_impl.dart';
import 'package:fmatch/src/fmclasses.dart';
import 'package:fmatch/src/util.dart';

late IOSink resultSink;
late IOSink logSink;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

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

Future<void> wbatch([String path = 'batch']) async {
  var batchResultPath = '$path/results.csv';
  var batchLogPath = '$path/log.txt';
  var resultFile = File(batchResultPath);
  resultSink = resultFile.openWrite()..add(utf8Bom);
  logSink = File(batchLogPath).openWrite();
  startTime = DateTime.now();
  lastLap = startTime;
  currentLap = lastLap;
  var matcher = FMatcherImpl();
  await matcher.readSettings(Pathes.configDir);
  await matcher.preper.readConfigs(Pathes.configDir);
  await matcher.buildDb(Pathes.configDir, Pathes.dbDir);
  var terms = matcher.idb.keys.map((e) => e.term.string).toList();
  var queries = StreamQueue<String>(randomQuery(terms));
  await Dispatcher(queries).dispatch();
}

Stream<String> randomQuery(List<String> terms) async* {
  var termc = terms.length;
  var rand = Random();
  while (true) {
    yield [
      terms[rand.nextInt(termc)],
      terms[rand.nextInt(termc)],
      terms[rand.nextInt(termc)],
      terms[rand.nextInt(termc)],
      terms[rand.nextInt(termc)],
    ].join(' ');
  }
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
  List<bool> cacheHits2Buffer = [];
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
      var request = await httpClient.get('localhost', 4049, '/?q=$path');
      var response = await request.close();
      var jsonString = await response.transform(utf8.decoder).join();
      var result =
          QueryResult.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
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
        print(result.message);
        continue;
      }
      if (result.message != '') {
        cacheHits++;
        cacheHits2++;
        cacheHits2Buffer.add(true);
        if (cacheHits2Buffer.length > 100) {
          if (cacheHits2Buffer.removeAt(0)) {
            cacheHits2--;
          }
        }
      }
      print(
          '$cacheHits2 $cacheHits ${formatOutput(ixO + 1, result).trimRight()}');
      results.remove(ixO);
    }
  }
}
