import 'dart:io';
import 'package:fmatch/util.dart';

Future<void> main(List<String> args) async {
  var filePath = args[0];
  var trank = filePath.substring(0, filePath.lastIndexOf('.csv'));
  var forCompare = '${trank}_4c.csv';
  var forQueryStats = '${trank}_4q.csv';
  var sb = StringBuffer();
  var f1 =
      File(forCompare).openSync(mode: FileMode.writeOnly);
  var f2 =
      File(forQueryStats).openSync(mode: FileMode.writeOnly);
  var lastIx = -1;
  await for (var l in readCsvLines('batch/results.csv')) {
    sb.clear();
    sb.write('${l[2]},${l[3]},${l[4]},${l[5]},${quoteCsvCell(l[6]!)},${quoteCsvCell(l[7]!)},${l[8]!}');
    l.sublist(9).map((e)=>',${quoteCsvCell(e!)}').forEach((e) => sb.write(e));
    sb.write('\r\n');
    f1.writeStringSync(sb.toString());
    var ix = int.parse(l[2]!);
    if(ix == lastIx) {
      continue;
    }
    lastIx = ix;
    sb.clear();
    f2.writeStringSync('${l[0]},${l[1]},${l[2]},${l[3]},${l[4]},${l[5]},${quoteCsvCell(l[6]!)}\r\n');
  }
  f2.closeSync();
}
