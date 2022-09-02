// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/batch.dart';
import 'package:fmatch/fmatch.dart';
import 'package:fmatch/util.dart';

Future<void> main() async {
  print('Start Batch');
  var matcher = FMatcher();
  await time(() => matcher.readSettings(null), 'settings.read');
  await time(() => matcher.preper.readConfigs(), 'Configs.read');
  await time(() => matcher.buildDb(), 'buildDb');
  await time(() => batch(matcher), 'batch');
}
