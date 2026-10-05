// Course content validation only; no application behavior is changed.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/domain/curriculum.dart';
import 'package:kotoba/domain/engine.dart';
import 'package:kotoba/controller.dart';

void main() {
  final path = File('../content/kotoba-cours-debutant.json');
  final pack = Curriculum.parse(path.readAsStringSync());
  test('Expanded course pack parses through the real importer and engine', () {
    expect(pack.modules.length, 12);
    expect(pack.modules.expand((m) => m.lessons).length, 51);
    expect(pack.modules.expand((m) => m.mcos).length, 29);
    expect(pack.modules.expand((m) => m.mcos).expand((u) => u.words).length, 230);
    var total = 0;
    final ids = <String>{};
    for (final m in pack.modules) {
      for (final u in m.units) {
        final pool = u.isVocabulary ? vocabularyPool(u) : lessonPool(u, m);
        expect(pool, isNotEmpty, reason: u.id);
        total += pool.length;
        for (final q in pool) {
          expect(ids.add(q.id), isTrue, reason: q.id);
          expect(correct(q, q.answer), isTrue, reason: q.id);
          if (q.type == 'choice') expect(q.choices, contains(q.answer));
          if (q.type == 'order') expect(correct(q, q.tokens.join()), isTrue, reason: q.id);
        }
      }
    }
    expect(total, 2867);
  });
  test('Vocabulary courses teach character readings and accept valid whole-word variants', () {
    final mcos=pack.modules.expand((m)=>m.mcos).toList();
    expect(mcos.every((u)=>u.sections.isNotEmpty), isTrue);
    final days=mcos.firstWhere((u)=>u.id=='m5-days');
    final tomorrow=days.words.firstWhere((w)=>w.writing=='明日');
    final reading=vocabularyPool(days).firstWhere((q)=>q.id=='${tomorrow.id}:read');
    expect(correct(reading,'あす'), isTrue);
    final world=mcos.firstWhere((u)=>u.id=='m2-world');
    final book=world.words.firstWhere((w)=>w.writing=='本');
    final bookReading=vocabularyPool(world).firstWhere((q)=>q.id=='${book.id}:read');
    expect(correct(bookReading,'もと'), isFalse);
    final nature=mcos.firstWhere((u)=>u.id=='m2-nature');
    expect(vocabularyPool(nature).any((q)=>q.id=='m2-nature:custom:kunyomi-reference'), isTrue);
    expect(nature.sections.expand((s)=>s['paragraphs'] as List? ?? []).any((s)=>s.toString().contains('スイ')), isTrue);
  });
  test('Course pack installs with current progress and exports for a restart', () async {
    final old = Curriculum.parse(File('test/fixtures/legacy-curriculum.json').readAsStringSync());
    final content = MemoryProgressStore();
    final c = LearningController(old.modules, MemoryProgressStore(), curriculum: old, contentStore: content);
    for (final u in old.modules.first.units) { c.progress.complete(u.id); }
    c.progress.recordExam(old.modules.first, 100);
    await c.installCurriculum(pack);
    expect(c.progress.done('hiragana'), isFalse);
    expect(c.progress.done('m1-life'), isFalse);
    expect(c.progress.unlocked(1, c.modules), isFalse);
    final reloaded = Curriculum.parse(content.value!);
    expect(reloaded.modules.last.lessons.last.id, 'abilities-hobbies');
    expect(canonical(reloaded.document), canonical(pack.document));
  });
}
