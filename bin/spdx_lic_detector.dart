import 'dart:convert';
import 'dart:math';

import 'package:dmp/dmp.dart';
import 'package:archive/archive_io.dart';

import 'texts.dart';

void main() {
  final s1 = unknown_with_changed_seq;
  final s2 = known;

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
    print('Not a possible match since dice coefficient: $diceCoeff < $threshold');
    return;
  }
  print(
      'It is a possible match: ${diceCoeff * 100}% --> Elapsed: ${stpWatch.elapsedMilliseconds} ms\n');
  stpWatch.reset();

  print('Calculating final confidence...');
  final confidence = finalConfidence(norm1, norm2);
  print('Calculated confidence --> Elapsed: ${stpWatch.elapsedMilliseconds} ms\n');
  stpWatch.stop();
  print('Confidence: ${confidence * 100}%\n');

  if (confidence > threshold) {
    print('Its a match!!\n');
  } else {
    print('Not a match :(\n');
  }
}

/// Normalize the text
/// Currently handles header, copyright notice, list indicators/bullets, spaces
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

/// Tokenize the text
List<String> tokenize(String s) {
  final str = s.split(' ');
  return str;
}

/// Create hashed q-grams of the text
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

/// Calculate the Sorenson dice coefficient
/// Its a measure to determine whether it can be a possible match or not
double diceCoefficent(List unknown, List known) {
  final set1 = unknown.toSet();
  final set2 = known.toSet();

  final intersection = set1.intersection(set2);

  final diceCoeff = (2 * intersection.length) / (set1.length + set2.length);
  return diceCoeff;
}

/// Calculate the final confidence using the Levenshtein distance
double finalConfidence(String s1, String s2) {
  final dmp = DiffMatchPatch();
  final diffs = dmp.diff_main(s1, s2);
  final lev = dmp.diff_levenshtein(diffs);
  final confidence = 1 - (lev / s2.length);
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
