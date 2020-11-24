// Copyright (c) 2016, Kwang Yul Seo. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// The Levenshtein distance, or edit distance, between two words is the
/// minimum number of single-character edits (insertions, deletions or
/// substitutions) required to change one word into the other.
class Levenshtein {
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

    var v0 = List<int>.generate(l2 + 1, (i) => i);
    var v1 = List<int>.filled(l2 + 1, 0);
    List<int> vtemp;

    for (var i = 0; i < l1; i++) {
      v1[0] = i + 1;

      for (var j = 0; j < l2; j++) {
        var cost = s1.codeUnitAt(i) == s2.codeUnitAt(j) ? 0 : 1;
        var a = v0[j + 1] + 1;
        var b = v0[j] + cost;
        var mab = a < b ? a : b;
        var c = v1[j] + 1;
        v1[j + 1] = mab < c ? mab : c;
        // v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      vtemp = v0;
      v0 = v1;
      v1 = vtemp;
    }

    return v0[l2];
  }

  // int min(int a, int b) => a < b ? a : b;
}
