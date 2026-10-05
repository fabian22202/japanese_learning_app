import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/controller.dart';
import 'package:kotoba/domain/curriculum.dart';
import 'package:kotoba/domain/models.dart';
import 'package:kotoba/ui/screens.dart';

class ReadOnlyCourseStore extends MemoryProgressStore {
  @override Future<void> write(String source) async => throw StateError('Read only');
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final history=objects(jsonDecode(File('assets/builtin_history.json').readAsStringSync()));
  Curriculum oldProgramme(Map<String,dynamic> entry)=>Curriculum.parse(jsonEncode({
    'format':'kotoba.curriculum','version':1,'modules':entry['document']['modules']}));

  test('Shipped curriculum contains exactly the latest authored courses', () {
    final provided=Curriculum.parse(File('assets/curriculum.json').readAsStringSync());
    final authored=Curriculum.parse(File('../content/kotoba-cours-debutant.json').readAsStringSync());
    expect(canonical(provided.document),canonical(authored.document));
    expect(provided.modules.length,12);
    expect(provided.modules.first.mcos.first.words.first.writing,'猫');
  });
  testWidgets('Fresh install displays kanji and kun/on explanations without importing JSON', (tester) async {
    final content=MemoryProgressStore();
    final c=(await tester.runAsync(()=>LearningController.load(store:MemoryProgressStore(),contentStore:content)))!;
    expect(c.usingProvidedCourses,isTrue);
    expect(Curriculum.parse(content.value!).modules.length,12);
    await tester.binding.setSurfaceSize(const Size(390,844));
    addTearDown(()=>tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home:LessonPage(c:c,module:c.modules.first,unit:c.modules.first.mcos.first)));
    expect(find.text('猫 · ねこ'),findsOneWidget);
    expect(find.textContaining('on’yomi : ビョウ'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
  test('Each unmodified older supplied programme upgrades once and keeps daily settings', () async {
    for(final entry in history) {
      final old=oldProgramme(entry),store=MemoryProgressStore(),content=MemoryProgressStore();
      content.value=old.encode();
      final progress=Progress()..complete('m1-life');
      progress.data['goal']=20;progress.data['activity']={'2026-10-04':5};store.value=progress.encode();
      final c=await LearningController.load(store:store,contentStore:content);
      expect(c.modules.first.mcos.first.words.first.writing,'猫',reason:entry['revision']);
      expect(c.progress.done('m1-life'),isFalse);
      expect(c.progress.goal,20);expect(c.progress.activity['2026-10-04'],5);
      expect(c.courseNotice,isNotNull);expect(c.usingProvidedCourses,isTrue);
      c.progress.complete('m1-life');await c.save();
      final restarted=await LearningController.load(store:store,contentStore:content);
      expect(restarted.progress.done('m1-life'),isTrue);
      expect(restarted.courseNotice,isNull);
    }
  });
  test('Progress from the old default without a saved programme upgrades to current courses', () async {
    final store=MemoryProgressStore(),content=MemoryProgressStore();
    store.value=(Progress()..complete('m1-life')).encode();
    final c=await LearningController.load(store:store,contentStore:content);
    expect(c.modules.length,12);expect(c.progress.done('m1-life'),isFalse);
    expect(c.courseNotice,isNotNull);expect(content.value,isNotNull);
  });
  test('Personal changes are preserved and restoring supplied courses loads enriched vocabulary', () async {
    final old=oldProgramme(history.first),store=MemoryProgressStore(),content=MemoryProgressStore();
    final doc=jsonDecode(old.encode());doc['modules'][0]['mcos'][0]['words'][0]['meaning']='Mon chat personnel';
    content.value=jsonEncode(doc);
    final c=await LearningController.load(store:store,contentStore:content);
    expect(c.modules.length,8);expect(c.modules.first.mcos.first.words.first.meaning,'Mon chat personnel');
    expect(c.usingProvidedCourses,isFalse);expect(c.courseNotice,isNull);
    await c.restoreCurriculum();
    expect(c.modules.first.mcos.first.words.first.writing,'猫');expect(c.usingProvidedCourses,isTrue);
  });
  test('Unavailable course storage still displays the enriched built-in courses', () async {
    final content=ReadOnlyCourseStore()..value=oldProgramme(history.first).encode();
    final c=await LearningController.load(store:MemoryProgressStore(),contentStore:content);
    expect(c.modules.first.mcos.first.words.first.writing,'猫');
    expect(c.usingProvidedCourses,isTrue);expect(c.storageError,isNotNull);
    expect(Curriculum.parse(content.value!).modules.length,8);
  });
}
