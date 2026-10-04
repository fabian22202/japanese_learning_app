import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/domain/curriculum.dart';
import 'package:kotoba/domain/engine.dart';
import 'package:kotoba/controller.dart';

String bundled() => File('assets/curriculum.json').readAsStringSync();
Map<String,dynamic> lessonPatch() => {
  'format':'kotoba.lesson','version':1,'moduleId':'m1',
  'lesson':{'id':'my-lesson','title':'Ma leçon','sections':[{'title':'Exemple','examples':[{'jp':'わたしはがくせいです','reading':'watashi wa gakusei desu','fr':'Je suis étudiant.'}]}],
    'exercises':[
      {'id':'write','type':'input','prompt':'Écris en kana : a','answer':'あ','explanation':'あ se lit a.'},
      {'id':'pick','type':'choice','prompt':'Lecture de あ ?','answer':'a','choices':['a','i'],'explanation':'あ se lit a.'},
      {'id':'order','type':'order','prompt':'Écris : je suis étudiant','tokens':['わたし','は','がくせい','です'],'answer':'わたしはがくせいです','explanation':'は marque le thème.'}
    ]}
};
class FailingStore extends MemoryProgressStore {
  @override Future<void> write(String source)async{throw StateError('Disk unavailable');}
}
void main(){
  test('Existing programme passes authoring validation and exports losslessly',(){final c=Curriculum.parse(bundled());expect(c.modules.length,8);expect(canonical(Curriculum.parse(c.encode()).document),canonical(c.document));});
  test('Single lesson adds and replaces content; JSON exercises drive the engine',(){final c=Curriculum.parse(bundled()).withLesson(jsonEncode(lessonPatch()));final u=c.modules.first.lessons.last;expect(u.sections.single['title'],'Exemple');final qs=lessonPool(u,c.modules.first);expect(qs.map((q)=>q.type),['input','choice','order']);expect(qs[1].choices,['a','i']);expect(qs[2].tokens.length,4);final patch=lessonPatch();patch['lesson']['title']='Titre révisé';final next=c.withLesson(jsonEncode(patch));expect(next.modules.first.lessons.length,c.modules.first.lessons.length);expect(next.modules.first.lessons.last.title,'Titre révisé');});
  test('Malformed content rejected before replacing programme',(){final c=Curriculum.parse(bundled());final p=lessonPatch();p['lesson']['exercises'][1]['choices']=['i','u'];expect(()=>c.withLesson(jsonEncode(p)),throwsFormatException);expect(()=>c.withLesson(jsonEncode({...lessonPatch(),'moduleId':'missing'})),throwsFormatException);var doc=jsonDecode(c.encode());doc['modules'][0]['mcos'].removeLast();expect(()=>Curriculum.parse(jsonEncode(doc)),throwsFormatException);doc=jsonDecode(c.encode());doc['modules'][0]['lessons'][0]['generator']['kind']='missing';expect(()=>Curriculum.parse(jsonEncode(doc)),throwsFormatException);});
  test('Template domain and volume constraints rejected with actionable errors',(){final d=jsonDecode(Curriculum.parse(bundled()).encode());final u=d['modules'][2]['lessons'][0];u['generator']['frames'][0]['french']='Je suis {missing}';expect(()=>Curriculum.parse(jsonEncode(d)),throwsFormatException);});
  test('Import persists separately and invalidates modified learning only',()async{final original=Curriculum.parse(bundled()),store=MemoryProgressStore(),content=MemoryProgressStore();final c=LearningController(original.modules,store,curriculum:original,contentStore:content);for(final u in original.modules.first.units){c.progress.complete(u.id);}c.progress.recordExam(original.modules.first,100);c.progress.complete(original.modules[1].lessons.first.id);final d=jsonDecode(original.encode());d['modules'][0]['lessons'][0]['paragraphs'][0]='Explication révisée.';await c.installCurriculum(Curriculum.parse(jsonEncode(d)));expect(c.progress.done('hiragana'),isFalse);expect(c.progress.done('katakana'),isTrue);expect(c.progress.done('numbers'),isTrue);expect(c.progress.unlocked(1,c.modules),isFalse);expect(Curriculum.parse(content.value!).modules.length,8);expect(jsonDecode(store.value!)['exams'],isEmpty);});
  test('Storage failure leaves content and progress untouched',()async{final original=Curriculum.parse(bundled());final c=LearningController(original.modules,MemoryProgressStore(),curriculum:original,contentStore:FailingStore());c.progress.complete('hiragana');await expectLater(c.installCurriculum(original.withLesson(jsonEncode(lessonPatch()))),throwsStateError);expect(c.curriculum,same(original));expect(c.progress.done('hiragana'),isTrue);});
}
