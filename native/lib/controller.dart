import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'domain/models.dart';
import 'domain/engine.dart';

abstract class ProgressStore {Future<String?> read();Future<void> write(String value);}
class NativeProgressStore implements ProgressStore {
  final _prefs=SharedPreferencesAsync();
  @override Future<String?> read()=>_prefs.getString('kotoba.progress.v1');
  @override Future<void> write(String value)=>_prefs.setString('kotoba.progress.v1',value);
}
class MemoryProgressStore implements ProgressStore {
  String? value;
  @override Future<String?> read()async=>value;
  @override Future<void> write(String source)async{value=source;}
}
class LearningController extends ChangeNotifier {
  final List<LearningModule> modules;
  final ProgressStore store;
  Progress progress;
  String? storageError;
  Future<void> _pending=Future.value();
  LearningController(this.modules,this.store,{Progress? progress}):progress=progress??Progress();
  static Future<LearningController> load({ProgressStore? store})async {
    final modules=parseCurriculum(await rootBundle.loadString('assets/curriculum.json'));
    final c=LearningController(modules,store??NativeProgressStore());
    try{final raw=await c.store.read();if(raw!=null)c.progress=Progress.fromJson(object(jsonDecode(raw)));}catch(_){c.storageError='Le carnet n’a pas pu être chargé. Tu peux importer une sauvegarde.';}
    return c;
  }
  Future<void> save(){final encoded=progress.encode();_pending=_pending.catchError((_){ }).then((_)async{try{await store.write(encoded);storageError=null;}catch(_){storageError='Sauvegarde indisponible. Exporte ton carnet pour le conserver.';}notifyListeners();});notifyListeners();return _pending;}
  Future<void> importJson(String source)async{if(source.length>2000000)throw const FormatException('Carnet trop volumineux.');final next=Progress.fromJson(object(jsonDecode(source)));progress=next;await save();}
  List<Word> get learnedWords=>modules.asMap().entries.where((e)=>progress.unlocked(e.key,modules)).expand((e)=>e.value.mcos.where((u)=>progress.done(u.id)).expand((u)=>u.words)).toList();
  List<Word> dueWords([int? now])=>learnedWords.where((w){final card=progress.cards[w.id];return card==null||(card['due'] as num)<= (now??DateTime.now().millisecondsSinceEpoch);}).toList();
  List<String> kanji(LearningModule current){final index=modules.indexOf(current);return modules.take(index+1).expand((m)=>m.mcos.where((u)=>m.id==current.id||progress.done(u.id)).expand((u)=>u.words.expand((w)=>w.writing.split('').where((c)=>RegExp(r'[\u4e00-\u9fff]').hasMatch(c))))).toSet().toList();}
  Future<void> rate(Word word,int grade)async{final cards=progress.cards;cards[word.id]=schedule(cards[word.id]==null?null:object(cards[word.id]),grade,DateTime.now().millisecondsSinceEpoch);progress.data['cards']=cards;
    final days=progress.activity,key=dateKey(DateTime.now());days[key]=(days[key] as num? ?? 0).toInt()+1;progress.data['activity']=days;await save();}
}
