// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/util.dart';
import 'package:fmatch/configs.dart';
import 'package:fmatch/database.dart';
import 'package:fmatch/batch.dart';

Future<void> main() async {
  print('Start Batch');
  await time(() => Settings.read(), 'Settings.read');
  await time(() => Configs.read(), 'Configs.read');
  await time(() => buildDb(), 'buildDb');
  await time(() => batch(), 'batch');
}
