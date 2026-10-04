import 'dart:convert';

typedef Json = Map<String, dynamic>;
Json object(dynamic value) => Map<String, dynamic>.from(value as Map);
List<Json> objects(dynamic value) => (value as List? ?? []).map(object).toList();
List<String> strings(dynamic value) => (value as List? ?? []).map((x) => x.toString()).toList();

class Word {
  final String id, writing, reading, meaning;
  Word.fromJson(Json j) : id=j['id'], writing=j['writing'], reading=j['reading'], meaning=j['meaning'];
}
class Unit {
  final String id, title;
  final List<String> paragraphs;
  final List<Word> words;
  final List<Json> facts, resources, exercises, sections;
  final List<List<String>> table;
  final Json generator;
  Unit.fromJson(Json j) : id=j['id'],title=j['title'],paragraphs=strings(j['paragraphs']),
    words=objects(j['words']).map(Word.fromJson).toList(),facts=objects(j['questions']),resources=objects(j['resources']),exercises=objects(j['exercises']),sections=objects(j['sections']),
    table=(j['table'] as List? ?? []).map((r)=>strings(r)).toList(),generator=j['generator']==null?{}:object(j['generator']);
  bool get isVocabulary => words.isNotEmpty;
  bool get isKana => generator['kind']=='kana';
}
class LearningModule {
  final String id,title,subtitle,symbol,color;
  final List<Unit> lessons,mcos;
  LearningModule.fromJson(Json j):id=j['id'],title=j['title'],subtitle=j['subtitle'],symbol=j['symbol'],color=j['color'],
    lessons=objects(j['lessons']).map(Unit.fromJson).toList(),mcos=objects(j['mcos']).map(Unit.fromJson).toList();
  List<Unit> get units=>[...lessons,...mcos];
}
List<LearningModule> parseCurriculum(String source)=>(jsonDecode(source) as List).map((j)=>LearningModule.fromJson(object(j))).toList();

class Question {
  final String id,conceptId,type,prompt,answer,explanation;
  final List<String> choices,tokens,alternatives;
  final String? masteryId;
  Question({required this.id,required this.conceptId,required this.type,required this.prompt,required this.answer,
    required this.explanation,this.choices=const [],this.tokens=const [],this.alternatives=const [],this.masteryId});
  Question shuffled(List<String> options)=>Question(id:id,conceptId:conceptId,type:type,prompt:prompt,answer:answer,
    explanation:explanation,choices:options,tokens:tokens,alternatives:alternatives,masteryId:masteryId);
}
class Progress {
  Json data;
  Progress():data={'version':1,'completed':<String>[],'exams':<String,dynamic>{},'cards':<String,dynamic>{},'activity':<String,dynamic>{},'goal':10,'recentQuestions':<String>[],'exerciseStats':<String,dynamic>{}};
  Progress.fromJson(Json source):data=source {
    if(!valid(source))throw const FormatException('Carnet Kotoba invalide.');
    data['recentQuestions']??=<String>[];data['exerciseStats']??=<String,dynamic>{};
  }
  static bool valid(Json s){
    bool number(dynamic n)=>n is num&&n.isFinite;
    bool map(dynamic m)=>m is Map;
    bool integer(dynamic n)=>n is num&&n.isFinite&&n==n.round()&&n>=0;
    if(s['version']!=1||s['completed'] is! List||(s['completed'] as List).any((x)=>x is! String)||!map(s['exams'])||!map(s['cards'])||!map(s['activity']))return false;
    if(!integer(s['goal'])||s['goal']<5||s['goal']>50)return false;
    for(final e in (s['exams'] as Map).values){if(!map(e)||!number(e['score'])||e['score']<0||e['score']>100||!number(e['at']))return false;}
    for(final c in (s['cards'] as Map).values){if(!map(c)||!number(c['due'])||!number(c['interval'])||c['interval']<0||!number(c['ease'])||c['ease']<1.3||!integer(c['repetitions']))return false;}
    if((s['activity'] as Map).values.any((n)=>!integer(n)))return false;
    if(s.containsKey('recentQuestions')&&(s['recentQuestions'] is! List||(s['recentQuestions'] as List).length>80||(s['recentQuestions'] as List).any((x)=>x is! String)))return false;
    if(s.containsKey('exerciseStats')){if(!map(s['exerciseStats']))return false;for(final x in (s['exerciseStats'] as Map).values){if(!map(x)||!integer(x['right'])||!integer(x['wrong']))return false;}}
    return true;
  }
  List<String> get completed=>strings(data['completed']);
  Json get exams=>object(data['exams']);
  Json get cards=>object(data['cards']);
  Json get stats=>object(data['exerciseStats']);
  Json get activity=>object(data['activity']);
  List<String> get recent=>strings(data['recentQuestions']);
  int get goal=>(data['goal'] as num).toInt();
  bool done(String id)=>completed.contains(id);
  void complete(String id){if(!done(id))data['completed']=[...completed,id];}
  bool ready(LearningModule m)=>m.units.every((u)=>done(u.id));
  bool unlocked(int i,List<LearningModule> modules)=>i==0||((exams[modules[i-1].id]?['score'] as num?)??0)>=80;
  void recordExam(LearningModule m,int score){if(!ready(m))throw StateError('Termine les étapes obligatoires.');
    final all=exams;final previous=(all[m.id]?['score'] as num?)?.toInt()??0;
    all[m.id]={'score':score>previous?score:previous,'lastScore':score,'at':DateTime.now().millisecondsSinceEpoch};data['exams']=all;}
  void answer(Question q,bool ok){final all=stats;final old=all[q.conceptId] as Map? ?? {'right':0,'wrong':0};
    final wrong=(old['wrong'] as num).toInt();all[q.conceptId]={'right':(old['right'] as num).toInt()+(ok?1:0),'wrong':ok?(wrong>0?wrong-1:0):wrong+1};data['exerciseStats']=all;
    final ids=[...recent.where((id)=>id!=q.id),q.id];data['recentQuestions']=ids.length>80?ids.sublist(ids.length-80):ids;
    final days=activity,key=dateKey(DateTime.now());days[key]=(days[key] as num? ?? 0).toInt()+1;data['activity']=days;
  }
  String encode()=>jsonEncode(data);
}
String dateKey(DateTime d)=>'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
int streak(Progress p,DateTime now){var day=DateTime(now.year,now.month,now.day);if((p.activity[dateKey(day)] as num? ?? 0)==0)day=DateTime(day.year,day.month,day.day-1);
  var n=0;while((p.activity[dateKey(day)] as num? ?? 0)>0){n++;day=DateTime(day.year,day.month,day.day-1);}return n;}
