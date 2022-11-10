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
