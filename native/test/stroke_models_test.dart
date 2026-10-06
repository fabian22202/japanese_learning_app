import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/domain/handwriting.dart';
import 'package:kotoba/ui/writing_practice.dart';

void main() {
  test('Bundled lesson writing targets have usable, ordered stroke models', () {
    final data = jsonDecode(
      File('assets/stroke_models.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final models = data['characters'] as Map<String, dynamic>;
    final curriculum = File('assets/curriculum.json').readAsStringSync();
    for (final c in writingCharacters([curriculum])) {
      expect(models.containsKey(c), isTrue, reason: 'Missing $c');
    }
    for (final entry in models.entries) {
      final strokes = (entry.value as List)
          .map(
            (s) => (s as List)
                .map(
                  (p) => Offset(
                    (p[0] as num).toDouble(),
                    (p[1] as num).toDouble(),
                  ),
                )
                .toList(),
          )
          .toList();
      expect(strokes, isNotEmpty, reason: entry.key);
      for (final stroke in strokes) {
        expect(strokeLength(stroke), greaterThan(.015), reason: entry.key);
        expect(stroke.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
      }
      expect(evaluateWriting(strokes, strokes).score, 100, reason: entry.key);
    }
  });
}
