import 'dart:io';

const a = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

void main() {
  var f = File('lib/batch/queries_triple.csv').openSync(mode: FileMode.writeOnly);
  for (var i = 0; i < 26; i++) {
    f.writeStringSync('",${a[i]},"\n');
  }
  for (var i = 0; i < 26; i++) {
    for (var j = 0; j < 26; j++) {
      f.writeStringSync('",${a[i]}${a[j]},"\n');
    }
  }
  for (var i = 0; i < 26; i++) {
    for (var j = 0; j < 26; j++) {
      for (var k = 0; k < 26; k++) {
        f.writeStringSync('",${a[i]}${a[j]}${a[k]},"\n');
      }
    }
  }
  for (var i = 0; i < 26; i++) {
    for (var j = 0; j < 26; j++) {
      for (var k = 0; k < 26; k++) {
        for (var l = 0; l < 26; l++) {
          f.writeStringSync('",${a[i]}${a[j]}${a[k]}${a[l]},"\n');
        }
      }
    }
  }
  f.closeSync();
}
