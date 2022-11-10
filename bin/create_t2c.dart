// Copyright (c) 2022, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:fmatch/util.dart';
import 'package:html/parser.dart';

final pls = 'config';

final uri = Uri(
    scheme: 'https',
    host: 'www.sayjack.com',
    path: '/chinese/simplified-to-traditional-chinese-conversion-table/');
final html = '$pls/t2s.html';
final filePath = '$pls/t2s.csv';

Future<void> main(List<String> args) async {
  await fetchHtml();
  await extCsv();
}

Future<void> fetchHtml() async {
  var client = HttpClient();
  String htmlString;
  try {
    HttpClientRequest request = await client.getUrl(uri);
    HttpClientResponse response = await request.close();
    htmlString = await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
  var htmlSink = File(html).openWrite();
  htmlSink.write(htmlString);
  await htmlSink.close();
}

Future<void> extCsv() async {
  var htmlString = File(html).readAsStringSync();
  var dom = parse(htmlString);
  var table = dom.getElementsByClassName('zhts').first;
  String pinyin;
  var file = File(filePath).openWrite()..add(utf8Bom);
  for (var row in table.children) {
    if (row.localName == 'h3') {
      pinyin = row.id;
      file.write(',$pinyin\r\n');
      continue;
    }
    var chars = row.children.where((e) => e.localName == 'div').toList();
    var simple = chars[0].text.trim();
    var set = {simple};
    var buf = StringBuffer()..write(simple);
    for (var i = 1; i < chars.length; i++) {
      var trad = chars[i].getElementsByTagName('div').first.text.trim();
      if (set.contains(trad)) {
        continue;
      }
      set.add(trad);
      buf.write(',$trad');
    }
    file.write('$buf\r\n');
  }
  file.close();
}
