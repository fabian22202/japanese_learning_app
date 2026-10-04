import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/ui/writing_practice.dart';
void main() {
  test('Writing targets exclude Latin letters and duplicate characters', () {
    expect(writingCharacters(['一二一', 'あア abc 123']), ['一', '二', 'あ', 'ア']);
  });
  testWidgets('Draw, undo, clear, compare and switch characters on mobile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: WritingPracticePage(characters: ['一', '二'])));
    final canvas = find.byKey(const ValueKey('writing-canvas'));
    final before = tester.getTopLeft(canvas);
    await tester.dragFrom(tester.getCenter(canvas) - const Offset(50, 0), const Offset(100, 0));
    await tester.pump();
    expect(find.text('1 trait dessiné'), findsOneWidget);
    expect(tester.getTopLeft(canvas), before);
    await tester.ensureVisible(find.text('Annuler le dernier trait'));
    await tester.tap(find.text('Annuler le dernier trait')); await tester.pump();
    expect(find.text('0 traits dessinés'), findsOneWidget);
    await tester.ensureVisible(canvas);
    await tester.tap(canvas); await tester.pump();
    expect(find.text('1 trait dessiné'), findsOneWidget);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile)); await tester.pump();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    await tester.ensureVisible(find.text('Comparer au modèle'));
    await tester.tap(find.text('Comparer au modèle')); await tester.pump();
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    await tester.ensureVisible(find.text('Tout effacer'));
    await tester.tap(find.text('Tout effacer')); await tester.pump();
    expect(find.text('0 traits dessinés'), findsOneWidget);
    await tester.ensureVisible(canvas); await tester.tap(canvas); await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '二'));
    await tester.tap(find.widgetWithText(ChoiceChip, '二')); await tester.pump();
    expect(find.text('0 traits dessinés'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
