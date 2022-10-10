// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/util.dart';

Future<void> main(List<String> args) async {
  var inFiles = List<String>.of(args);
  var outFile = inFiles.removeLast();
  catFilesWithUtf8Bom(inFiles, outFile);
}
