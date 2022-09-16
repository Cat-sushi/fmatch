// Copyright (c) 2020, Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:fmatch/fmatch.dart';
import 'package:fmatch/preprocess.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('distance 1', () {
    expect(FMatcher.distance(Term('abc'), Term('abcd')), 1);
  });
  test('distance 2', () {
    expect(FMatcher.distance(Term('abcd'), Term('abdc')), 2);
  });
  test('distance 3', () {
    expect(FMatcher.distance(Term('abcd'), Term('abdd')), 1);
  });
  test('distance 4', () {
    expect(FMatcher.distance(Term('𠀋𡈽𡌛𡑮'), Term('𠀋𡈽𡌛')), 1);
  });
  test('distance 5', () {
    expect(FMatcher.distance(Term('𠀋𡈽𡌛𡑮'), Term('𠀋𡈽𡑮𡌛')), 2);
  });
  test('distance 6', () {
    expect(FMatcher.distance(Term('𠀋𡈽𡌛𡑮'), Term('𠀋𠮟𡌛𡑮')), 1);
  });
}
