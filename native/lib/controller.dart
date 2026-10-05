import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/models.dart';
import 'domain/engine.dart';
import 'domain/curriculum.dart';

abstract class ProgressStore {Future<String?> read();Future<void> write(String value);}
class NativeProgressStore implements ProgressStore {
  final _prefs=SharedPreferencesAsync();
  final String key;
  NativeProgressStore({this.key='kotoba.progress.v1'});
  @override Future<String?> read()=>_prefs.getString(key);
  @override Future<void> write(String value)=>_prefs.setString(key,value);
}
class MemoryProgressStore implements ProgressStore {
  String? value;
  @override Future<String?> read()async=>value;
  @override Future<void> write(String source)async{value=source;}
}
class LearningController extends ChangeNotifier {
  List<LearningModule> modules;
  Curriculum? curriculum;
  final ProgressStore contentStore;
  final ProgressStore store;
  Progress progress;
  String? storageError;
  String? courseNotice;
  String? _providedModules;
  bool usingProvidedCourses = true;
  Future<void> _pending=Future.value();
  LearningController(this.modules,this.store,{Progress? progress,this.curriculum,ProgressStore? contentStore}):contentStore=contentStore??MemoryProgressStore(),progress=progress??Progress();
  static Future<LearningController> load({ProgressStore? store,ProgressStore? contentStore})async {
    final bundled=Curriculum.parse(await rootBundle.loadString('assets/curriculum.json'));
    final content=contentStore??(store is MemoryProgressStore?MemoryProgressStore():NativeProgressStore(key:'kotoba.curriculum.v1'));
    final c=LearningController(bundled.modules,store??NativeProgressStore(),curriculum:bundled,contentStore:content);
    c._providedModules=canonical(bundled.document['modules']);
    bool storedProgram=false,hasProgress=false,programReadSucceeded=false;
    String? rawProgram;
    try {
      rawProgram=await content.read();programReadSucceeded=true;
      if(rawProgram!=null&&rawProgram.isNotEmpty) {
        c.curriculum=Curriculum.parse(rawProgram);c.modules=c.curriculum!.modules;
        storedProgram=true;
        c.usingProvidedCourses=canonical(c.curriculum!.document['modules'])==c._providedModules;
      }
    } catch(_) {c.storageError='Le programme enregistré n’a pas pu être chargé. Les nouveaux cours fournis sont affichés.';}
    try {
      final raw=await c.store.read();
      if(raw!=null) {c.progress=Progress.fromJson(object(jsonDecode(raw)));hasProgress=true;}
    } catch(_) {c.storageError='Le carnet n’a pas pu être chargé. Tu peux importer une sauvegarde.';}
    final noStoredProgram=programReadSucceeded&&(rawProgram==null||rawProgram.isEmpty);
    if((storedProgram&&!c.usingProvidedCourses)||(noStoredProgram&&hasProgress)) {
      // Compare complete module data: a personal edit is never classified as an old supplied course.
      final history=objects(jsonDecode(await rootBundle.loadString('assets/builtin_history.json')));
      final active=canonical(c.curriculum!.document['modules']);
      final legacy=history.where((entry)=>canonical(entry['document']['modules'])==active);
      if((storedProgram&&legacy.isNotEmpty)||(noStoredProgram&&hasProgress)) {
        if(!storedProgram) {
          c.curriculum=Curriculum.parse(jsonEncode({'format':'kotoba.curriculum','version':1,
            'modules':history.first['document']['modules']}));
          c.modules=c.curriculum!.modules;
        }
        try {
          await c.installCurriculum(bundled);
        } catch(_) {
          // Even if storage is unavailable, the new built-in courses must be usable this session.
          c._applyCurriculum(bundled);await c.save();
          c.storageError='Les nouveaux cours sont actifs, mais leur enregistrement a échoué. Exporte ton carnet pour le conserver.';
        }
        c.courseNotice='Les cours fournis ont été mis à jour : 29 MCO avec 167 kanji. Les fiches enrichies et leurs DS sont à revalider.';
      }
    } else if(noStoredProgram&&!hasProgress) {
      // Persist the initial programme so a future update can distinguish it from a personal import.
      try {await content.write(bundled.encode());}
      catch(_) {c.storageError='Les nouveaux cours fournis sont affichés, mais leur enregistrement est indisponible.';}
    }
    return c;
  }
  void dismissCourseNotice(){courseNotice=null;notifyListeners();}
  Future<void> save(){final encoded=progress.encode();_pending=_pending.catchError((_){ }).then((_)async{try{await store.write(encoded);storageError=null;}catch(_){storageError='Sauvegarde indisponible. Exporte ton carnet pour le conserver.';}notifyListeners();});notifyListeners();return _pending;}
  Future<void> importJson(String source)async{if(source.length>2000000)throw const FormatException('Carnet trop volumineux.');final next=Progress.fromJson(object(jsonDecode(source)));progress=next;await save();}
  Future<void> installCurriculum(Curriculum next)async {
    if(curriculum==null)throw StateError('Programme indisponible.');
    // Commit content storage first: failed imports leave the active course intact.
    await contentStore.write(next.encode());
    _applyCurriculum(next);
    await save();
  }
  void _applyCurriculum(Curriculum next) {
    final oldModules=objects(curriculum!.document['modules']);
    final newModules=objects(next.document['modules']);
    final oldUnits=<String,Json>{for(final m in oldModules)for(final u in [...objects(m['lessons']),...objects(m['mcos'])])u['id']:u};
    final newUnits=<String,Json>{for(final m in newModules)for(final u in [...objects(m['lessons']),...objects(m['mcos'])])u['id']:u};
    final unchanged=newUnits.keys.where((id)=>oldUnits.containsKey(id)&&canonical(oldUnits[id])==canonical(newUnits[id])).toSet();
    progress.data['completed']=progress.completed.where(unchanged.contains).toList();
    for(final key in progress.data.keys.where((key)=>key.startsWith('nativeKanaMastery:')).toList()){
      if(!unchanged.contains(key.substring('nativeKanaMastery:'.length)))progress.data.remove(key);
    }
    var boundary=0;
    while(boundary<oldModules.length&&boundary<newModules.length&&canonical(oldModules[boundary])==canonical(newModules[boundary])){boundary++;}
    final retainedExamIds=newModules.take(boundary).map((m)=>m['id']).toSet();
    progress.data['exams']={for(final e in progress.exams.entries)if(retainedExamIds.contains(e.key))e.key:e.value};
    final oldWords={for(final u in oldUnits.values)for(final w in objects(u['words']))w['id']:w};
    final sameWords={for(final u in newUnits.values)for(final w in objects(u['words']))if(oldWords.containsKey(w['id'])&&canonical(oldWords[w['id']])==canonical(w))w['id']};
    progress.data['cards']={for(final e in progress.cards.entries)if(sameWords.contains(e.key))e.key:e.value};
    progress.data['exerciseStats']=<String,dynamic>{};progress.data['recentQuestions']=<String>[];
    curriculum=next;modules=next.modules;
    usingProvidedCourses=_providedModules!=null&&canonical(next.document['modules'])==_providedModules;
  }
  Future<void> restoreCurriculum()async=>installCurriculum(Curriculum.parse(await rootBundle.loadString('assets/curriculum.json')));
  List<Word> get learnedWords=>modules.asMap().entries.where((e)=>progress.unlocked(e.key,modules)).expand((e)=>e.value.mcos.where((u)=>progress.done(u.id)).expand((u)=>u.words)).toList();
  List<Word> dueWords([int? now])=>learnedWords.where((w){final card=progress.cards[w.id];return card==null||(card['due'] as num)<= (now??DateTime.now().millisecondsSinceEpoch);}).toList();
  List<String> kanji(LearningModule current) {
    final index=modules.indexOf(current);
    final texts=modules.take(index+1).expand((m)=>m.units
      .where((u)=>m.id==current.id||progress.done(u.id))
      .expand((u)=>[
        ...u.words.map((w)=>w.writing),
        ...u.table.map((row)=>row.first),
        ...u.sections.expand((s)=>objects(s['examples']).map((e)=>e['jp'] as String)),
      ]));
    return texts.expand((text)=>text.split(''))
      .where((c)=>RegExp(r'[\u4e00-\u9fff]').hasMatch(c)).toSet().toList();
  }
  Future<void> rate(Word word,int grade)async{final cards=progress.cards;cards[word.id]=schedule(cards[word.id]==null?null:object(cards[word.id]),grade,DateTime.now().millisecondsSinceEpoch);progress.data['cards']=cards;
    final days=progress.activity,key=dateKey(DateTime.now());days[key]=(days[key] as num? ?? 0).toInt()+1;progress.data['activity']=days;await save();}
}
