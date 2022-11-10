// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';
import 'package:fmatch/util.dart';

Future<void> main(List<String> args) async {
  var columnId = int.parse(args[0]);
  var inPath = args[1];
  var outPath = args[2];
  var outSink = File(outPath).openWrite()..add(utf8Bom);
  await for (var l in readCsvLines(inPath)) {
  outSink.write('${quoteCsvCell(l[columnId - 1]!)}\r\n');
  }
  await outSink.close();
}
