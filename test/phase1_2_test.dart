// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/levenshtein.dart';
import 'package:fmatch/preprocess.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('distance 1', () {
    expect(distance(RString('abc'), RString('abcd')), 1);
  });
  test('distance 2', () {
    expect(distance(RString('abcd'), RString('abdc')), 2);
  });
  test('distance 3', () {
    expect(distance(RString('abcd'), RString('abdd')), 1);
  });
  test('distance 4', () {
    expect(distance(RString('𠀋𡈽𡌛𡑮'), RString('𠀋𡈽𡌛')), 1);
  });
  test('distance 5', () {
    expect(distance(RString('𠀋𡈽𡌛𡑮'), RString('𠀋𡈽𡑮𡌛')), 2);
  });
  test('distance 6', () {
    expect(distance(RString('𠀋𡈽𡌛𡑮'), RString('𠀋𠮟𡌛𡑮')), 1);
  });
}
