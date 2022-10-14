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
