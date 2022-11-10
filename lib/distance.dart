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

import 'dart:typed_data';

import 'preprocess.dart';

int distance(Term s1, Term s2) {
  int min(int a, int b) => a < b ? a : b;
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
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }
    vtemp = v0;
    v0 = v1;
    v1 = vtemp;
  }
  return v0[l2];
}
