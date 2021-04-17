import 'dart:convert';
import 'dart:math';

import 'package:dmp/dmp.dart';
import 'package:archive/archive_io.dart';

void main(List<String> arguments) {
  final s1 = '''Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:


    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

''';

  final s2 = '''Copyright (c) <year> <owner>. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

''';

  final stpWatch = Stopwatch();

  print('Normalizing texts...');
  stpWatch.start();
  final norm1 = normalize(s1);
  print('Normalized --> Elapsed: ${stpWatch.elapsedMilliseconds} ms\n');
  final norm2 = normalize(s2);
  stpWatch.reset();

  print('Tokenizing...');
  final tokens1 = tokenize(norm1);
  print('Created tokens --> Elapsed: ${stpWatch.elapsedMilliseconds} ms\n');
  final tokens2 = tokenize(norm2);
  stpWatch.reset();

  print('Creating q-grams...');
  final qGram1 = createQGrams(tokens1);
  print('Created q-grams --> Elapsed: ${stpWatch.elapsedMilliseconds} ms\n');
  final qGram2 = createQGrams(tokens2);

  print('Calculating possibility...');
  final diceCoeff = diceCoefficent(qGram1, qGram2);
  if (diceCoeff < threshold) {
    print('Not a possible match since dice coefficient ($diceCoeff) < $threshold');
    return;
  }
  print('It is a possible match: ($diceCoeff) --> Elapsed: ${stpWatch.elapsedMilliseconds} ms\n');
  stpWatch.reset();

  print('Calculating final confidence...');
  final confidence = finalConfidence(norm1, norm2);
  print('Calculated confidence --> Elapsed: ${stpWatch.elapsedMilliseconds} ms\n');
  stpWatch.stop();
  print('Confidence: $confidence%\n\n');
}

String normalize(String s) {
  final header = RegExp(r'[\s\S]*?(?=Copyright)');
  final copyrightText = RegExp(r'(^Copyright).*', multiLine: true);
  final bullets = RegExp(r'[*\d\u2022\u2023\u25E6\u2043\u2219](\s|\.|\d\.|\))');
  final whiteSpace = RegExp(r'\s+');

  s = s.replaceAll(header, '');
  s = s.replaceAll(copyrightText, '');
  s = s.replaceAll(bullets, '');
  s = s.replaceAll(whiteSpace, ' ');
  s = s.toLowerCase();
  return s;
}

List<String> tokenize(String s) {
  final str = s.split(' ');
  return str;
}

List createQGrams(List<String> tokens) {
  final q = max(1, (threshold / (1 - threshold))).floor();
  var qGrams = [];

  for (var i = 0; i < (tokens.length - q); ++i) {
    var q_gram_list = <String>[];
    for (var j = 0; j < q; ++j) {
      q_gram_list.add('${tokens[i + j]}');
    }
    final q_gram = q_gram_list.join(' ');
    final encoded = utf8.encode(q_gram);
    final chksum = Crc32().convert(encoded);
    qGrams.add(chksum);
  }

  return qGrams;
}

double diceCoefficent(List unknown, List known) {
  final set1 = unknown.toSet();
  final set2 = known.toSet();

  final intersection = set1.intersection(set2);

  final diceCoeff = (2 * intersection.length) / (set1.length + set2.length);
  return diceCoeff;
}

double finalConfidence(String s1, String s2) {
  final dmp = DiffMatchPatch();
  final diffs = dmp.diff_main(s1, s2);
  final lev = dmp.diff_levenshtein(diffs);
  final confidence = (1 - (lev / s2.length)) * 100;
  return confidence;
}

/// Need to see why to use it. LicenseClassifier used this strategy. Need to do
/// more research.
int diffRangeEnd(String known, List<Diff> diffs) {
  var seen = '';
  final len = diffs.length;
  var end;

  for (end = 0; end < len; ++end) {
    if (seen == known) {
      break;
    }

    switch (diffs[end].operation) {
      case Operation.equal:
      case Operation.insert:
        seen += diffs[end].text!;
        break;
      default:
        break;
    }
  }
  return end;
}

/// Threshold Value
const double threshold = 0.85;
