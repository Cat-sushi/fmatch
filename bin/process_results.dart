import 'dart:io';
import 'package:fmatch/util.dart';

Future<void> main(List<String> args) async {
  var queryPath = args[0];
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultsPath = '${trank}_results.csv';
  var forCompare = '${trank}_results_4c.csv';
  var forCompare2 = '${trank}_results_4c2.csv';
  var forQueryStats = '${trank}_results_4q.csv';
  var sb = StringBuffer();
  var fc = File(forCompare).openWrite()..add(utf8Bom);
  var fc2 = File(forCompare2).openWrite()..add(utf8Bom);
  var fq = File(forQueryStats).openWrite()..add(utf8Bom);
  var lastIx = -1;
  await for (var l in readCsvLines(resultsPath)) {
    sb.clear();
    sb.write(
        '${l[3]},${l[4]},${l[5]},${quoteCsvCell(l[6]!)},${quoteCsvCell(l[7]!)},${l[8]!}');
    l.sublist(9).map((e) => ',${quoteCsvCell(e!)}').forEach((e) => sb.write(e));
    sb.write('\r\n');
    fc.write(sb);
    sb.clear();
    if (l[7] != '') {
      sb.write('${quoteCsvCell(l[6]!)},${quoteCsvCell(l[7]!)},${l[8]!}');
      l
          .sublist(9)
          .map((e) => ',${quoteCsvCell(e!)}')
          .forEach((e) => sb.write(e));
      sb.write('\r\n');
      fc2.write(sb);
      sb.clear();
    }
    var ix = int.parse(l[2]!);
    if (ix == lastIx) {
      continue;
    }
    lastIx = ix;
    fq.write(
        '${l[0]},${l[1]},${l[2]},${l[3]},${l[4]},${l[5]},${quoteCsvCell(l[6]!)}\r\n');
  }
  await fc.close();
  await fc2.close();
  await fq.close();
}
