import 'dart:io';
import 'package:fmatch/util.dart';

Future<void> main() async {
  var map = <String, int>{};
  var lastQuery = '';
  await for (var line in readCsvLines('lib/batch/results_quad.csv')) {
    var n = int.parse(line[1]!);
    var qterm0 = line[6]!;
    var entry = line[4]!;
    if (qterm0 == lastQuery) {
      continue;
    }
    lastQuery = qterm0;
    if (entry == '') {
      n = 0;
    }
    map[qterm0] = n;
  }
  var f =
      File('lib/batch/quad_histgram.csv').openSync(mode: FileMode.writeOnly);
  var entries = map.entries.toList();
  entries.sort((a, b) => -a.value.compareTo(b.value));
  for (var e in entries) {
    f.writeStringSync('${quoteCsvCell(e.key)},${e.value}\r\n');
  }
  f.closeSync();
}
