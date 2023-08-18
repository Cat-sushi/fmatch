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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';

import 'package:fmatch/fmatch.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

int serverCount = Platform.numberOfProcessors;

late ArgResults options;
late FMatcher matcher;
late FMatcherP matcherp;

// Configure routes.
final _router = Router()
  ..get('/', _singleHandler)
  ..post('/', _multiHandler)
  ..get('/normalize', _normalizeHandler)
  ..get('/restart', _restartHandler);

Future<Response> _singleHandler(Request request) async {
  var q = request.requestedUri.queryParameters['q'];
  if (q == null) {
    return Response.badRequest(body: 'Query is not specified');
  }
  var c = request.requestedUri.queryParameters['c'];
  var cache = true;
  if (c != null && c == '0') {
    cache = false;
  }
  var result = await matcherp.fmatch(q, cache);
  var jsonObject = result.toJson();
  var jsonString = jsonEncode(jsonObject);
  return Response.ok(jsonString,
      headers: {'content-type': 'application/json; charset=utf-8'});
}

Future<Response> _multiHandler(Request request) async {
  var c = request.requestedUri.queryParameters['c'];
  var cache = true;
  if (c != null && c == '0') {
    cache = false;
  }
  String queriesJsonString;
  try {
    queriesJsonString = await request.readAsString();
  } catch (e) {
    return Response.badRequest(body: 'Posted data is not string');
  }
  var queries = <String>[];
  try {
    queries = (jsonDecode(queriesJsonString) as List<dynamic>).cast<String>();
  } catch (e) {
    return Response.badRequest(body: 'Invalid posted data format: $e');
  }
  var result = await matcherp.fmatchb(queries, cache);
  var jsonObject = result.map((e) => e.toJson()).toList();
  var jsonString = jsonEncode(jsonObject);
  return Response.ok(jsonString,
      headers: {'content-type': 'application/json; charset=utf-8'});
}

Future<Response> _normalizeHandler(Request request) async {
  var q = request.requestedUri.queryParameters['q'];
  if (q == null) {
    return Response.badRequest(body: 'Query is not sepecified');
  }
  var normalizingResult = normalize(q);
  var jsonString = jsonEncode(normalizingResult);
  return Response.ok(jsonString,
      headers: {'content-type': 'application/json; charset=utf-8'});
}

Future<Response> _restartHandler(Request request) async {
  var newMatcher = FMatcher();
  var newMatcherp = await readSettingsAndConfigs(newMatcher);
  await newMatcherp.startServers();
  var oldMatcherp = matcherp;
  matcher = newMatcher;
  matcherp = newMatcherp;
  oldMatcherp.stopServers();
  return Response.ok('Server restartd: ${DateTime.now()}\n');
}

Future<FMatcherP> readSettingsAndConfigs(FMatcher matcher) async {
  await matcher.init();

  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache'] as String) ??
        matcher.queryResultCacheSize;
  }
  if (options['server'] != null) {
    serverCount =
        max(int.tryParse(options['server'] as String) ?? serverCount, 1);
  }

  return FMatcherP.fromFMatcher(matcher, serverCount: serverCount, mutex: true);
}

Future<void> main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print this help')
    ..addOption('server', abbr: 's', valueHelp: 'number of servers')
    ..addOption('cache', abbr: 'c', valueHelp: 'size of result cache');
  options = argParser.parse(args);

  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  matcher = FMatcher();
  matcherp = await readSettingsAndConfigs(matcher);
  await matcherp.startServers();
  print('Servers started: ${DateTime.now()}');

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '4049');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
