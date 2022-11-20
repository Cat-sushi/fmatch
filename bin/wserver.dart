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
import 'dart:isolate';
import 'dart:math';

import 'package:args/args.dart';
import 'package:async/async.dart';

import 'package:fmatch/fmatch.dart';

final _host = InternetAddress.loopbackIPv4.host;
const _port = 4049;

int serverCount = Platform.numberOfProcessors;
final commandStreamController = StreamController<HttpRequest>();
final commandStreamQueue = StreamQueue(commandStreamController.stream);
var commandQueueLength = 0;
var maxCommandQueueLength = 10;
var josonEncoderWithIdent = JsonEncoder.withIndent('  ');

final batchStreamController = StreamController<HttpRequest>();
final batchStreamQueue = StreamQueue(batchStreamController.stream);
var batchQueueLength = 0;
var maxBatchQueueLength = serverCount * 2;

late FMatcher matcher;
late FMatcherP matcherp;
late SendPort cacheServer;
final mutex = Mutex();

Future main(List<String> args) async {
  var argParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'print this help')
    ..addOption('server', abbr: 's', valueHelp: 'number of servers')
    ..addOption('queue', abbr: 'q', valueHelp: 'length of command queue')
    ..addOption('cache', abbr: 'c', valueHelp: 'size of result cache');
  var options = argParser.parse(args);

  if (options['help'] == true) {
    print(argParser.usage);
    exit(0);
  }

  await readSettingsAndConfigs(options);
  await matcherp.startServers();
  print('Servers started: ${DateTime.now()}');

  for (var i = 0; i < serverCount; i++) {
    unawaited(sendReceiveResponseOne());
  }

  unawaited(sendReceiveResponseBulk());

  var httpServer = await HttpServer.bind(_host, _port);
  await for (var req in httpServer) {
    var contentType = req.headers.contentType;
    var response = req.response;

    if (req.method == 'GET' && req.uri.path == '/') {
      if (commandQueueLength >= maxCommandQueueLength) {
        response
          ..statusCode = HttpStatus.serviceUnavailable
          ..write('Server busiy');
        await response.close();
        continue;
      }
      commandQueueLength++;
      commandStreamController.add(req);
    } else if (req.method == 'POST' &&
        contentType?.mimeType == 'application/json') {
      if (batchQueueLength >= maxBatchQueueLength) {
        response
          ..statusCode = HttpStatus.serviceUnavailable
          ..write('Batch server busiy');
        await response.close();
        continue;
      }
      batchQueueLength++;
      batchStreamController.add(req);
    } else if (req.method == 'GET' && req.uri.path == '/normalize') {
      try {
        var query = req.uri.queryParameters['q']!;
        var result = normalize(query);
        var responseContent = josonEncoderWithIdent.convert(result);
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType =
              ContentType('application', 'json', charset: 'utf-8')
          ..write(responseContent);
      } catch (e) {
        req.response
          ..statusCode = HttpStatus.internalServerError
          ..headers.contentType =
              ContentType('application', 'json', charset: 'utf-8')
          ..write('Internal Server Error: $e.');
      } finally {
        await req.response.close();
      }
    } else if (req.method == 'GET' && req.uri.path == '/restart') {
      await mutex.lock();
      await matcherp.stopServers();
      print('Servers stopped: ${DateTime.now()}');
      await readSettingsAndConfigs(options);
      await matcherp.startServers();
      mutex.unlock();
      print('Servers started: ${DateTime.now()}');
      response
        ..statusCode = HttpStatus.ok
        ..write('Server restarted. ${DateTime.now()}');
      await response.close();
    } else {
      response
        ..statusCode = HttpStatus.methodNotAllowed
        ..write('Unsupported request: ${req.method} ${req.uri.path}.');
      await response.close();
    }
  }
}

Future<void> readSettingsAndConfigs(ArgResults options) async {
  matcher = FMatcher();
  await matcher.init();

  if (options['cache'] != null) {
    matcher.queryResultCacheSize = int.tryParse(options['cache'] as String) ??
        matcher.queryResultCacheSize;
  }
  if (options['server'] != null) {
    serverCount =
        max(int.tryParse(options['server'] as String) ?? serverCount, 1);
  }
  if (options['queue'] != null) {
    maxCommandQueueLength = max(
        int.tryParse(options['queue'] as String) ?? maxCommandQueueLength,
        serverCount);
    maxBatchQueueLength = maxCommandQueueLength;
  }

  matcherp = FMatcherP.fromFMatcher(matcher, serverCount);
}

Future<void> sendReceiveResponseOne() async {
  while (true) {
    var req = await commandStreamQueue.next;
    try {
      var cache = req.uri.queryParameters['c'];
      var activateCache = cache == null || cache == '1';
      var query = req.uri.queryParameters['q']!;
      await mutex.lockShared();
      var result = await matcherp.fmatch(query, activateCache);
      mutex.unlockShared();
      var responseContent = josonEncoderWithIdent.convert(result);
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType =
            ContentType('application', 'json', charset: 'utf-8')
        ..write(responseContent);
    } catch (e) {
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType =
            ContentType('application', 'json', charset: 'utf-8')
        ..write('Internal Server Error: $e.');
    } finally {
      await req.response.close();
      commandQueueLength--;
    }
  }
}

Future<void> sendReceiveResponseBulk() async {
  while (true) {
    var req = await batchStreamQueue.next;
    try {
      var cache = req.uri.queryParameters['c'];
      var activateCache = cache == null || cache == '1';
      var jsonString =
          await req.cast<List<int>>().transform(utf8.decoder).join();
      var queries = (jsonDecode(jsonString) as List<dynamic>).cast<String>();
      await mutex.lockShared();
      var result = await matcherp.fmatchb(queries, activateCache);
      mutex.unlockShared();
      req.response
        ..headers.contentType =
            ContentType('application', 'json', charset: 'utf-8')
        ..write(json.encode(result));
      await req.response.close();
    } catch (e, s) {
      req.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType =
            ContentType('application', 'json', charset: 'utf-8')
        ..write('Internal Server Error: $e.');
      print(s);
      await req.response.close();
    } finally {
      batchQueueLength--;
    }
  }
}
