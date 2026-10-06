import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotoba/domain/models.dart';
import 'package:kotoba/domain/engine.dart';
import 'package:kotoba/domain/keyboard.dart';
void main(){
  final modules=parseCurriculum(File('test/fixtures/legacy-curriculum.json').readAsStringSync());
  test('All lessons produce valid varied questions and module structure',(){
    expect(modules.length,8);
    final ids=<String>{};
    for(final m in modules){expect(m.mcos.length,inInclusiveRange(2,4));for(final u in m.units){if(u.isVocabulary)expect(u.words.length,lessThanOrEqualTo(10));final pool=u.isVocabulary?vocabularyPool(u):lessonPool(u,m);expect(pool,isNotEmpty,reason:u.id);for(final q in pool){expect(q.answer,isNotEmpty);expect(ids.add(q.id),isTrue,reason:q.id);expect(correct(q,q.answer),isTrue);if(q.type=='order')expect(correct(q,q.tokens.join()),isTrue);if(q.type=='choice')expect(q.choices,contains(q.answer));}}}
    expect(ids.length,greaterThan(1000));
  });
  test('Kana progress, gating and exam best score survive roundtrip',(){final p=Progress();expect(p.unlocked(1,modules),isFalse);expect(()=>p.recordExam(modules.first,100),throwsStateError);for(final u in modules.first.units){p.complete(u.id);}p.recordExam(modules.first,90);p.recordExam(modules.first,40);final copy=Progress.fromJson(object(jsonDecode(p.encode())));expect(copy.unlocked(1,modules),isTrue);expect(copy.exams['m1']['score'],90);});
  test('Review intervals and failures',(){final first=schedule(null,2,1000);expect(first['interval'],1);expect(schedule(first,2,1000)['interval'],6);expect(schedule(first,0,1000)['due'],601000);});
  test('Sessions avoid recent variants and respect unique coverage',(){final pool=lessonPool(modules.first.lessons.first,modules.first),p=Progress();final first=selectSession(pool,p,count:10,random:Random(1));for(final q in first){p.answer(q,true);}final second=selectSession(pool,p,count:10,random:Random(1));expect(second.map((q)=>q.id).toSet().intersection(first.map((q)=>q.id).toSet()),isEmpty);expect(selectSession(pool,p,count:10,cover:true).map((q)=>q.conceptId).toSet().length,10);});
  test('Keyboard selection, accents and surrogate deletion',(){expect(edit('かな',1,2,'insert','き').text,'かき');expect(edit('は',1,1,'handakuten').text,'ぱ');expect(edit('カ',1,1,'dakuten').text,'ガ');expect(edit('あ😀',3,3,'backspace').text,'あ');expect(katakana('きゃ'),'キャ');expect(normalize(' ｶﾞ '),'ガ');});
  test('Invalid backup rejected without partial state',(){expect(()=>Progress.fromJson({'version':1}),throwsFormatException);});
}
