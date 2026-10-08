import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/ui/writing_practice.dart';

void main() {
  testWidgets('Vertical and diagonal touch strokes never scroll the page', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: WritingPracticePage(
      characters: ['一', '二'], strokeBundle: _StrokeBundle(),
    )));
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('writing-canvas'));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    final origin = tester.getTopLeft(canvas);
    final pixels = scroll.pixels;
    final steps = [
      const Offset(0, 12), const Offset(0, -12),
      const Offset(8, 12), const Offset(-8, -12),
    ];
    for (int i = 0; i < steps.length; i++) {
      final gesture = await tester.startGesture(tester.getCenter(canvas));
      for (int step = 0; step < 8; step++) {
        await gesture.moveBy(steps[i]);
        await tester.pump(const Duration(milliseconds: 16));
        expect(scroll.pixels, pixels);
        expect(tester.getTopLeft(canvas), origin);
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('${i + 1} trait${i == 0 ? '' : 's'} dessiné${i == 0 ? '' : 's'}'), findsOneWidget);
      expect(scroll.pixels, pixels);
    }
    // Padding outside the square still belongs to the page's scroll view.
    await tester.dragFrom(const Offset(8, 650), const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(scroll.pixels, greaterThan(pixels));
    final afterScroll = scroll.pixels;
    await tester.dragFrom(const Offset(8, 500), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(scroll.pixels, lessThan(afterScroll));
    expect(tester.takeException(), isNull);
  });

  testWidgets('A second finger cannot scroll or add a second stroke', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: WritingPracticePage(
      characters: ['一'], strokeBundle: _StrokeBundle(),
    )));
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('writing-canvas'));
    final origin = tester.getTopLeft(canvas);
    final first = await tester.startGesture(tester.getCenter(canvas), pointer: 1);
    final second = await tester.startGesture(tester.getCenter(canvas) + const Offset(30, 0), pointer: 2);
    await second.moveBy(const Offset(0, -90));
    await first.moveBy(const Offset(0, 90));
    await tester.pump();
    await second.up();
    await first.up();
    await tester.pumpAndSettle();
    expect(find.text('1 trait dessiné'), findsOneWidget);
    expect(tester.getTopLeft(canvas), origin);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancelled drawing releases the canvas for the next stroke', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: WritingPracticePage(
      characters: ['一'], strokeBundle: _StrokeBundle(),
    )));
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('writing-canvas'));
    final origin = tester.getTopLeft(canvas);
    final gesture = await tester.startGesture(tester.getCenter(canvas));
    await gesture.moveBy(const Offset(0, 90));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(find.text('0 traits dessinés'), findsOneWidget);
    await tester.dragFrom(tester.getCenter(canvas), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(find.text('1 trait dessiné'), findsOneWidget);
    expect(tester.getTopLeft(canvas), origin);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stroke animation and memory mode work on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: WritingPracticePage(characters: ['あ'], strokeBundle: _StrokeBundle())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voir le tracé animé (efface l’essai)'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Trait 1 / 3'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(find.text('Écriture de mémoire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Writing targets exclude Latin letters and duplicate characters', () {
    expect(writingCharacters(['一二一', 'あア abc 123']), ['一', '二', 'あ', 'ア']);
  });
  testWidgets('Draw, undo, clear, compare and switch characters on mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: WritingPracticePage(characters: ['一', '二'], strokeBundle: _StrokeBundle())),
    );
    await tester.pumpAndSettle();
    final canvas = find.byKey(const ValueKey('writing-canvas'));
    final before = tester.getTopLeft(canvas);
    await tester.dragFrom(
      tester.getCenter(canvas) - const Offset(50, 0),
      const Offset(100, 0),
    );
    await tester.pump();
    expect(find.text('1 trait dessiné'), findsOneWidget);
    expect(tester.getTopLeft(canvas), before);
    await tester.ensureVisible(find.text('Annuler le dernier trait'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler le dernier trait'));
    await tester.pump();
    expect(find.text('0 traits dessinés'), findsOneWidget);
    expect(find.textContaining('Fidélité du tracé :'), findsNothing);
    await tester.ensureVisible(canvas);
    await tester.pumpAndSettle();
    await tester.tap(canvas);
    await tester.pump();
    expect(find.text('1 trait dessiné'), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await tester.ensureVisible(find.text('Comparer au modèle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparer au modèle'));
    await tester.pump();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(find.textContaining('Fidélité du tracé :'), findsOneWidget);
    expect(find.text('Fidélité du tracé : 0/100'), findsOneWidget);
    await tester.ensureVisible(find.text('Tout effacer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tout effacer'));
    await tester.pump();
    expect(find.text('0 traits dessinés'), findsOneWidget);
    expect(find.textContaining('Fidélité du tracé :'), findsNothing);
    await tester.ensureVisible(canvas);
    await tester.pumpAndSettle();
    await tester.tap(canvas);
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '二'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '二'));
    await tester.pump();
    expect(find.text('0 traits dessinés'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

// Supply the real bundled data without isolate/file I/O in the fake clock.
class _StrokeBundle extends Fake implements AssetBundle {
  final String data = File('assets/stroke_models.json').readAsStringSync();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => data;
}
