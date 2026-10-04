import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/controller.dart';
import 'package:kotoba/main.dart';
import 'package:kotoba/domain/models.dart';
import 'package:kotoba/ui/screens.dart';
void main(){
 testWidgets('Native navigation and persisted goal', (tester)async{
   final c=(await tester.runAsync(() => LearningController.load(store:MemoryProgressStore())))!;
   await tester.pumpWidget(KotobaApp(controller:c));
   expect(find.text('Un petit pas, chaque jour.'),findsOneWidget);
   await tester.tap(find.text('Parcours'));await tester.pumpAndSettle();
   expect(find.text('Ton parcours'),findsOneWidget);
   await tester.tap(find.text('Carnet'));await tester.pumpAndSettle();
   expect(find.text('Exporter le carnet'),findsOneWidget);
   expect(tester.takeException(),isNull);
 });
 testWidgets('Kana key edits the answer and validates exercise', (tester)async{
   final c=(await tester.runAsync(() => LearningController.load(store:MemoryProgressStore())))!;
   final q=Question(id:'sample',conceptId:'sample',type:'input',prompt:'Écris en kana : a',answer:'あ',explanation:'あ se lit a.');
   await tester.pumpWidget(MaterialApp(home:SessionPage(c:c,module:c.modules.first,unit:c.modules.first.lessons.first,questions:[q])));
   await tester.tap(find.byKey(const ValueKey('key:insert:あ')));await tester.pump();
   expect(find.widgetWithText(TextField,'あ'),findsOneWidget);
   await tester.scrollUntilVisible(find.text('Vérifier'),200,scrollable:find.byType(Scrollable).first);await tester.tap(find.text('Vérifier'));await tester.pump();
   expect(find.text('Bien joué !'),findsOneWidget);
   await tester.scrollUntilVisible(find.text('Continuer'),200,scrollable:find.byType(Scrollable).first);await tester.tap(find.text('Continuer'));await tester.pumpAndSettle();
   expect(find.text('100 %'),findsOneWidget);
   expect(c.progress.done(c.modules.first.lessons.first.id),isFalse);
   expect(tester.takeException(),isNull);
 });
}
