// Fuzzy text matcher for entity/ persn screening.
// Copyright (c) 2022, Yako.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:convert';
import 'dart:io';

import 'package:fmatch/src/configs.dart';
import 'package:fmatch/src/fmatch_impl.dart';
import 'package:fmatch/src/util.dart';
import 'package:html/parser.dart';

final pls = 'assets/database';

// https://www.trade.gov/consolidated-screening-list JSON
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

final rBulletSplitter =
    RegExp(r'[\r\n]+ *[・･]', multiLine: true, unicode: true);
final rSemicolonSplitter = RegExp(' *; *(and;?)? *');
final rCrConnector = RegExp(r'[\r\n]', multiLine: true, unicode: true);
final rTrailCamma = RegExp(r'^(.*) *,$', unicode: true);
final rBullet = RegExp(r'^[・･] *', unicode: true);
final rDoubleQuate = RegExp(r'^["”] *(.*) *["”]$', unicode: true);
final rNewLine = RegExp(r'[\r\n]+', unicode: true);

Future<void> main(List<String> args) async {
  var consolidatedJsonFile = File(consolidatedJson);
  var fetching = !consolidatedJsonFile.existsSync() ||
      DateTime.now()
              .difference(consolidatedJsonFile.lastModifiedSync())
              .inHours >
          24 - 1;

  if (fetching) {
    print("Fetching consolidated list.");
    await fetchConsolidated();
    print("Fetching foreign user list.");
    await fetchFul();
  }

  print("Extracting entries from consolidated list.");
  await extConsolidated();
  print("Extracting entries from foreign user list.");
  await extFul();

  print("Concatanating lists.");
  await catFilesWithUtf8Bom([consolidatedList, fulList], concatList);

  print("Building db and idb.");
  final matcher = FMatcherImpl();
  await matcher.preper.readConfigs(Pathes.configDir);
  await matcher.buildDb(Pathes.configDir, Pathes.dbDir);
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
}

Future<void> extConsolidated() async {
  final jsonString = File(consolidatedJson).readAsStringSync();
  final jsonObject = jsonDecode(jsonString) as Map<String, dynamic>;
  final jsonEncoderIndent = JsonEncoder.withIndent('  ');
  final jsonStringIndent = jsonEncoderIndent.convert(jsonObject);
  final outSinkIndent = File(consolidatedJsonIndent).openWrite();
  outSinkIndent.write(jsonStringIndent);
  await outSinkIndent.close();
  final results = jsonObject['results'] as List<dynamic>;
  final outSinkCsv = File(consolidatedList).openWrite()..add(utf8Bom);
  for (var r in results) {
    var result = r as Map<String, dynamic>;
    var name = result['name'] as String;
    name = name.replaceAll(rNewLine, ' ');
    outSinkCsv.write(quoteCsvCell(name));
    outSinkCsv.write('\r\n');
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
        outSinkCsv.write(quoteCsvCell(a));
        outSinkCsv.write('\r\n');
      }
    }
  }
  await outSinkCsv.close();
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
}

Future<void> extFul() async {
  Process.runSync('libreoffice', [
    '--headless',
    '--convert-to',
    'csv:Text - txt - csv (StarCalc):44,34,76,,,,,,true',
    fulXlsx,
    '--outdir',
    pls
  ]);
  final fl = File(fulList).openWrite()..add(utf8Bom);
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
