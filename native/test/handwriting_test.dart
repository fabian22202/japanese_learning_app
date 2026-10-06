
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/domain/handwriting.dart';

void main() {
  final model = [
    [const Offset(.2, .3), const Offset(.8, .3)],
    [const Offset(.1, .7), const Offset(.9, .7)],
  ];
  test('Identical strokes score 100, regardless of sampling density', () {
    final drawing = model.map((s) => resampleStroke(s, 80)).toList();
    expect(evaluateWriting(drawing, model).score, 100);
  });
  test('Empty drawing and taps cannot earn points', () {
    expect(evaluateWriting([], model).score, 0);
    expect(
      evaluateWriting([
        [const Offset(.2, .3)],
        [const Offset(.1, .7)],
      ], model).score,
      0,
    );
  });
  test('Wrong order is distinguished from correct shape', () {
    final r = evaluateWriting(model.reversed.toList(), model);
    expect(r.shape, 100);
    expect(r.order, 0);
    expect(r.direction, 100);
  });
  test('Backward strokes retain shape but lose direction points', () {
    final r = evaluateWriting(
      model.map((s) => s.reversed.toList()).toList(),
      model,
    );
    expect(r.shape, 100);
    expect(r.direction, 0);
  });
  test('Missing, extra and displaced strokes reduce the score', () {
    expect(evaluateWriting([model.first], model).score, lessThanOrEqualTo(50));
    expect(evaluateWriting([...model, model.first], model).score, lessThan(80));
    final wrong = model
        .map((s) => s.map((p) => p + const Offset(0, .3)).toList())
        .toList();
    expect(evaluateWriting(wrong, model).score, lessThan(40));
  });
  test('Retracing a stroke cannot score as a perfect straight line', () {
    final scribble = [
      model.first.first,
      model.first.last,
      model.first.first,
      model.first.last,
    ];
    expect(evaluateWriting([scribble, model.last], model).score, lessThan(80));
  });
  test('Unsupported targets must not be graded', () {
    expect(() => evaluateWriting(model, []), throwsArgumentError);
  });
}
