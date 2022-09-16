// Copyright (c) 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'preprocess.dart';

int _min(int a, int b) => a < b ? a : b;

int distance(Term s1, Term s2) {
  if (s1.string == s2.string) {
    return 0;
  }

  var l1 = s1.length;
  var l2 = s2.length;

  if (l1 == 0) {
    return l2;
  }

  if (l2 == 0) {
    return l1;
  }

  Int32List r1;
  Int32List r2;

  if (l2 > l1) {
    r1 = s2.runes;
    r2 = s1.runes;
    var lt = l1;
    l1 = l2;
    l2 = lt;
  } else {
    r1 = s1.runes;
    r2 = s2.runes;
  }

  var size2 = l2 + 1;
  var v0 = Int32List(size2);
  var v1 = Int32List(size2);
  Int32List vtemp;
  for (var i = 0; i < size2; i++) {
    v0[i] = i;
  }

  int cost;
  for (var i = 0; i < l1; i++) {
    v1[0] = i + 1;

    for (var j = 0; j < l2; j++) {
      cost = (r1[i] == r2[j]) ? 0 : 1;
      v1[j + 1] = _min(v1[j] + 1, _min(v0[j + 1] + 1, v0[j] + cost));
    }

    vtemp = v0;
    v0 = v1;
    v1 = vtemp;
  }

  return v0[l2];
}
