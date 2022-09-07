import 'dart:io';
import 'package:fmatch/util.dart';

Future<void> main() async {
  var sb = StringBuffer();
  var f1 =
      File('batch/results_4c.csv').openSync(mode: FileMode.writeOnly);
  var f2 =
      File('batch/results_4q.csv').openSync(mode: FileMode.writeOnly);
  var lastIx = -1;
  await for (var l in readCsvLines('batch/results.csv')) {
    sb.clear();
    sb.write('${l[2]},${l[3]},${l[4]},${quoteCsvCell(l[5]!)},${quoteCsvCell(l[6]!)},${l[7]!}');
    l.sublist(8).map((e)=>',${quoteCsvCell(e!)}').forEach((e) => sb.write(e));
    sb.write('\r\n');
    f1.writeStringSync(sb.toString());
    var ix = int.parse(l[2]!);
    if(ix == lastIx) {
      continue;
    }
    lastIx = ix;
    sb.clear();
    f2.writeStringSync('${l[0]},${l[1]},${l[2]},${l[3]},${l[4]},${quoteCsvCell(l[5]!)}\r\n');
  }
  f2.closeSync();
}
