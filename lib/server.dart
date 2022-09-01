// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:fmatch/fmatch.dart';

late File resultFile;
late IOSink resultSink;
late IOSink logSink;
late int lc;
late DateTime startTime;
late DateTime currentLap;
late DateTime lastLap;

class Server {
  final FMatcher matcher;
  final ReceivePort crp;
  late final StreamIterator<dynamic> cri;
  late final SendPort csp;
  late final Isolate isolate;
  Server(this.matcher) : crp = ReceivePort() {
    cri = StreamIterator<dynamic>(crp);
  }
  Future<void> spawn(int id) async {
    isolate = await Isolate.spawn<List<dynamic>>(
        main, <dynamic>[crp.sendPort, matcher]);
    await cri.moveNext();
    csp = cri.current as SendPort;
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
