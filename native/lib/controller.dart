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
  Future<void> _pending=Future.value();
  LearningController(this.modules,this.store,{Progress? progress,this.curriculum,ProgressStore? contentStore}):contentStore=contentStore??MemoryProgressStore(),progress=progress??Progress();
  static Future<LearningController> load({ProgressStore? store,ProgressStore? contentStore})async {
    final bundled=Curriculum.parse(await rootBundle.loadString('assets/curriculum.json'));
    final content=contentStore??(store is MemoryProgressStore?MemoryProgressStore():NativeProgressStore(key:'kotoba.curriculum.v1'));
    final c=LearningController(bundled.modules,store??NativeProgressStore(),curriculum:bundled,contentStore:content);
    try{final raw=await content.read();if(raw!=null&&raw.isNotEmpty){c.curriculum=Curriculum.parse(raw);c.modules=c.curriculum!.modules;}}catch(_){c.storageError='Le programme enregistré n’a pas pu être chargé. Le programme fourni est utilisé.';}
    try{final raw=await c.store.read();if(raw!=null)c.progress=Progress.fromJson(object(jsonDecode(raw)));}catch(_){c.storageError='Le carnet n’a pas pu être chargé. Tu peux importer une sauvegarde.';}
    return c;
  }
  Future<void> save(){final encoded=progress.encode();_pending=_pending.catchError((_){ }).then((_)async{try{await store.write(encoded);storageError=null;}catch(_){storageError='Sauvegarde indisponible. Exporte ton carnet pour le conserver.';}notifyListeners();});notifyListeners();return _pending;}
  Future<void> importJson(String source)async{if(source.length>2000000)throw const FormatException('Carnet trop volumineux.');final next=Progress.fromJson(object(jsonDecode(source)));progress=next;await save();}
  Future<void> installCurriculum(Curriculum next)async {
    if(curriculum==null)throw StateError('Programme indisponible.');
    // Commit content storage first: failed imports leave the active course intact.
    await contentStore.write(next.encode());
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
    await save();
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
