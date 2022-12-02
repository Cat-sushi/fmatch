import 'dart:convert';

import 'package:fmatch/fmatch.dart';

Future<void> main(List<String> args) async {
  print('Start Batch');
  var matcher = FMatcher();
  await matcher.init();

  var result = await matcher.fmatch('abc');

  final resultJsonObject = result.toJson();
  final jsonEncorder = JsonEncoder.withIndent('  ');
  final resultJsonString = jsonEncorder.convert(resultJsonObject);
  print(resultJsonString);
}
