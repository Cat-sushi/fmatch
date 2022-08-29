// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:fmatch/fmatch.dart';
import 'package:fmatch/pbatch.dart';
import 'package:fmatch/util.dart';

void main(List<String> arguments) async {
  var matcher = FMatcher();
  print('Start Parallel Batch');
  await time(() => matcher.readSettings(null), 'settings.read');
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  await time(() => pbatch(matcher), 'pbatch');
  exit(0);
}
