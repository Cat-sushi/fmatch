// Copyright (c) 2022 Yako.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

int _min(int a, int b) => a < b ? a : b;

int distance(String s1, String s2) {
  if (s1 == s2) {
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
  
  var a1 = Int32List(l1);
  var a2 = Int32List(l2);
  for (var i = 0; i < l1; i++){
    a1[i] = s1.codeUnitAt(i);
  }
  for (var i = 0; i < l2; i++){
    a2[i] = s2.codeUnitAt(i);
  }

  var size2 = l2 + 1;
  var v0 = Int32List(size2);
  var v1 = Int32List(size2);
  Int32List vtemp;
  for (var i = 0; i < size2; i++) {
    v0[i] = i;
  }

  for (var i = 0; i < l1; i++) {
    v1[0] = i + 1;

    for (var j = 0; j < l2; j++) {
      int cost = 1;
      if (a1[i] == a2[j]) {
        cost = 0;
      }
      v1[j + 1] = _min(v1[j] + 1, _min(v0[j + 1] + 1, v0[j] + cost));
    }

    vtemp = v0;
    v0 = v1;
    v1 = vtemp;
  }

  return v0[l2];
}
