import 'dart:io';
import 'package:fmatch/util.dart';

Future<void> main(List<String> args) async {
  var queryPath = args[0];
  var trank = queryPath.substring(0, queryPath.lastIndexOf('.csv'));
  var resultsPath = '${trank}_results.csv';
  var forCompare = '${trank}_results_4c.csv';
  var forQueryStats = '${trank}_results_4q.csv';
  var sb = StringBuffer();
  var f1 =
      File(forCompare).openWrite()..add(utf8Bom);
  var f2 =
      File(forQueryStats).openWrite()..add(utf8Bom);
  var lastIx = -1;
  await for (var l in readCsvLines(resultsPath)) {
    sb.clear();
    sb.write('${l[3]},${l[4]},${l[5]},${quoteCsvCell(l[6]!)},${quoteCsvCell(l[7]!)},${l[8]!}');
    l.sublist(9).map((e)=>',${quoteCsvCell(e!)}').forEach((e) => sb.write(e));
    sb.write('\r\n');
    f1.write(sb);
    sb.clear();
    var ix = int.parse(l[2]!);
    if(ix == lastIx) {
      continue;
    }
    lastIx = ix;
    f2.write('${l[0]},${l[1]},${l[2]},${l[3]},${l[4]},${l[5]},${quoteCsvCell(l[6]!)}\r\n');
  }
  await f1.close();
  await f2.close();
}
