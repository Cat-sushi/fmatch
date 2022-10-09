// Copyright (c) 2020, 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:fmatch/util.dart';
import 'package:html/parser.dart';

final pls = 'database';

final consolidatedUri = Uri(
    scheme: 'https',
    host: 'data.trade.gov',
    path: '/downloadable_consolidated_screening_list/v1/consolidated.json');
final consolidatedJson = '$pls/consolidated.json';
final consolidatedJsonIndent = '$pls/consolidated_indent.json';
final consolidatedList = '$pls/consolidated_list.csv';

final fulUri = Uri(
    scheme: 'https', host: 'www.meti.go.jp', path: '/policy/anpo/law05.html');
final fulHtml = '$pls/ful.html';
final fulXlsx = '$pls/ful.xlsx';
final fulCsv = '$pls/ful.csv';
final fulList = '$pls/ful_list.csv';

final concatList = '$pls/list.csv';

final rBulletSplitter = RegExp(r'[\r\n]+ *[・･]', multiLine: true, unicode: true);
final rSemicolonSplitter = RegExp(' *; *(and;?)? *');
final rCrConnector = RegExp(r'[\r\n]', multiLine: true, unicode: true);
final rTrailCamma = RegExp(r'^(.*) *,$', unicode: true);
final rBullet = RegExp(r'^[・･] *', unicode: true);
final rDoubleQuate = RegExp(r'^["”] *(.*) *["”]$', unicode: true);

Future<void> main(List<String> args) async {
  await fetchConsolidated();
  await extConsolidated();

  await fetchFul();
  await extFul();

  await concatCsvs([consolidatedList, fulList]);
}

Future<void> fetchConsolidated() async {
  var client = HttpClient();
  try {
    HttpClientRequest request = await client.getUrl(consolidatedUri);
    HttpClientResponse response = await request.close();
    var outSink = File(consolidatedJson).openWrite();
    await for (var chank in response) {
      outSink.add(chank);
    }
    await outSink.close();
  } finally {
    client.close();
  }

  final jsonString = File(consolidatedJson).readAsStringSync();
  final jsonObject = jsonDecode(jsonString) as Map<String, dynamic>;
  final jsonEncoderIndent = JsonUtf8Encoder('  ');
  final jsonStringIndent = jsonEncoderIndent.convert(jsonObject);
  final outSink = File(consolidatedJsonIndent).openWrite();
  outSink.add(jsonStringIndent);
  await outSink.close();
}

Future<void> extConsolidated() async {
  final jsonString = File(consolidatedJsonIndent).readAsStringSync();
  final jsonObject = jsonDecode(jsonString) as Map<String, dynamic>;
  final results = jsonObject['results']! as List<dynamic>;
  final outSink = File(consolidatedList).openWrite();
  for (var r in results) {
    var result = r as Map<String, dynamic>;
    var name = result['name']! as String;
    outSink.write(quoteCsvCell(name));
    outSink.write('\r\n');
    var altNames = result['alt_names'] as List<dynamic>?;
    if (altNames == null) {
      continue;
    }
    for (var a in altNames) {
      var altName = a as String;
      if (altName == '') {
        continue;
      }
      var altNames2 = altName.split(rSemicolonSplitter);
      for (var a in altNames2) {
        a = a.trim();
        a = a.replaceFirstMapped(rTrailCamma, (match) => match.group(1)!);
        a = a.replaceFirstMapped(rDoubleQuate, (match) => match.group(1)!);
        if (a == '') {
          continue;
        }
        outSink.write(quoteCsvCell(a));
        outSink.write('\r\n');
      }
    }
  }
  await outSink.close();
}

Future<void> fetchFul() async {
  var client = HttpClient();
  String stringData;
  try {
    HttpClientRequest request = await client.getUrl(fulUri);
    HttpClientResponse response = await request.close();
    stringData = await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
  var htmlSink = File(fulHtml).openWrite();
  htmlSink.write(stringData);
  await htmlSink.close();
  var fulHtmlSring = File(fulHtml).readAsStringSync();
  var dom = parse(fulHtmlSring);
  var elementFul = dom
      .getElementsByTagName('a')
      .where((e) => e.attributes['name'] == 'user-list')
      .first;
  var elementTbody = elementFul.parent!.parent!.parent;
  var elementFulRow = elementTbody!.children[4];
  var elementFulCol = elementFulRow.children[2];
  var ancorFulCsv = elementFulCol.getElementsByTagName('a')[2];
  var fulCsvPath = ancorFulCsv.attributes['href']!;
  final fulCsvUri =
      Uri(scheme: 'https', host: 'www.meti.go.jp', path: fulCsvPath);
  client = HttpClient();
  try {
    HttpClientRequest request = await client.getUrl(fulCsvUri);
    HttpClientResponse response = await request.close();
    var outSink = File(fulXlsx).openWrite();
    await for (var chank in response) {
      outSink.add(chank);
    }
    await outSink.close();
  } finally {
    client.close();
  }
  Process.runSync('libreoffice', [
    '--headless',
    '--convert-to',
    'csv:Text - txt - csv (StarCalc):44,34,76,,,,,,true',
    fulXlsx,
    '--outdir',
    pls
  ]);
}

Future<void> extFul() async {
  final fl = File(fulList).openWrite();
  await for (var l in readCsvLines(fulCsv).skip(1)) {
    var n = l[2]!;
    n = n.replaceAll(rCrConnector, ' ');
    n = n.trim();
    n = n.replaceFirstMapped(rTrailCamma, (match) => match.group(1)!);
    fl.write(quoteCsvCell(n));
    fl.write('\r\n');
    var a = l[3];
    if (a == null) {
      continue;
    }
    var aliases = a.split(rBulletSplitter);
    for (var a in aliases) {
      a = a.replaceAll(rCrConnector, ' ');
      a = a.trim();
      a = a.replaceFirstMapped(rTrailCamma, (match) => match.group(1)!);
      a = a.replaceFirst(rBullet, '');
      a = a.replaceFirstMapped(rDoubleQuate, (match) => match.group(1)!);
      if (a == '') {
        continue;
      }
      fl.write(quoteCsvCell(a));
      fl.write('\r\n');
    }
  }
  await fl.close();
}

Future<void> concatCsvs(List<String> lists) async {
  var oSink = File(concatList).openWrite();
  oSink.add([0xEF, 0xBB, 0xBF]);
  for (var list in lists) {
    var inStream = File(list).openRead();
    await for (var chank in inStream) {
      oSink.add(chank);
    }
  }
  await oSink.close();
}
