import 'dart:math' as math;
import 'dart:ui';

/// A transparent geometric training aid, not handwriting recognition.
class WritingResult {
  final int shape, order, direction, score;
  final List<int> matches;
  final List<double> errors;
  final int expected, drawn;
  const WritingResult(
    this.shape,
    this.order,
    this.direction,
    this.score,
    this.matches,
    this.errors,
    this.expected,
    this.drawn,
  );
}

double strokeLength(List<Offset> points) {
  double length = 0;
  for (int i = 1; i < points.length; i++) {
    length += (points[i] - points[i - 1]).distance;
  }
  return length;
}

List<Offset> resampleStroke(List<Offset> points, [int count = 32]) {
  if (points.isEmpty) return List.filled(count, Offset.zero);
  final length = strokeLength(points);
  if (length < 1e-8) return List.filled(count, points.first);
  final result = <Offset>[points.first];
  int segment = 1;
  double traversed = 0;
  for (int i = 1; i < count - 1; i++) {
    final target = length * i / (count - 1);
    while (segment < points.length - 1 &&
        traversed + (points[segment] - points[segment - 1]).distance < target) {
      traversed += (points[segment] - points[segment - 1]).distance;
      segment++;
    }
    final distance = (points[segment] - points[segment - 1]).distance;
    result.add(
      Offset.lerp(
        points[segment - 1],
        points[segment],
        distance < 1e-8 ? 0 : ((target - traversed) / distance).clamp(0.0, 1.0),
      )!,
    );
  }
  return result..add(points.last);
}

double _distance(List<Offset> a, List<Offset> b, bool reverse) {
  double sum = 0;
  for (int i = 0; i < a.length; i++) {
    sum += (a[i] - b[reverse ? b.length - 1 - i : i]).distance;
  }
  return sum / a.length;
}

WritingResult evaluateWriting(
  List<List<Offset>> drawing,
  List<List<Offset>> model,
) {
  if (model.isEmpty) throw ArgumentError('A stroke model is required');
  final a = drawing.map(resampleStroke).toList();
  final b = model.map(resampleStroke).toList();
  final matches = List.filled(a.length, -1);
  final errors = List.filled(a.length, 1.0);
  final forward = List.generate(
    a.length,
    (i) => List.generate(b.length, (j) => _distance(a[i], b[j], false)),
  );
  final backward = List.generate(
    a.length,
    (i) => List.generate(b.length, (j) => _distance(a[i], b[j], true)),
  );
  // Match by shape first so order and direction can be explained separately.
  final availableA = List.generate(a.length, (i) => i).toSet();
  final availableB = List.generate(b.length, (i) => i).toSet();
  while (availableA.isNotEmpty && availableB.isNotEmpty) {
    int ai = -1, bj = -1;
    double best = double.infinity;
    for (final i in availableA) {
      for (final j in availableB) {
        final d = math.min(forward[i][j], backward[i][j]);
        if (d < best) {
          best = d;
          ai = i;
          bj = j;
        }
      }
    }
    matches[ai] = bj;
    errors[ai] = best;
    availableA.remove(ai);
    availableB.remove(bj);
  }
  final denominator = math.max(drawing.length, model.length);
  double shape = 0, order = 0, direction = 0;
  for (int i = 0; i < a.length; i++) {
    final j = matches[i];
    if (j < 0 || strokeLength(drawing[i]) < .015) continue;
    final fidelity = (1 - errors[i] / .16).clamp(0.0, 1.0);
    final ratio = strokeLength(drawing[i]) / strokeLength(model[j]);
    // Prevent loops and retraced scribbles from earning a good shape score.
    final lengthFit = math.min(ratio, 1 / ratio).clamp(0.0, 1.0);
    final fit = fidelity * lengthFit;
    shape += fit;
    if (i == j) order += fit;
    if (forward[i][j] <= backward[i][j]) direction += fit;
  }
  final s = (100 * shape / denominator).round();
  final o = (100 * order / denominator).round();
  final d = (100 * direction / denominator).round();
  return WritingResult(
    s,
    o,
    d,
    (.7 * s + .2 * o + .1 * d).round(),
    matches,
    errors,
    model.length,
    drawing.length,
  );
}
