import 'dart:math';
import 'package:unorm_dart/unorm_dart.dart' as unicode;
import 'models.dart';

String normalize(String value)=>unicode.nfkc(value).trim().toLowerCase().replaceAll(RegExp(r'\s+'),' ').replaceAllMapped(RegExp(r'([\u3000-\u9fff])\s+(?=[\u3000-\u9fff])'),(m)=>m[1]!);
bool correct(Question q,String answer)=>[q.answer,...q.alternatives].any((a)=>normalize(a)==normalize(answer));
const digits=['れい','いち','に','さん','よん','ご','ろく','なな','はち','きゅう'];
const aliases={'shi':['si'],'chi':['ti'],'tsu':['tu'],'fu':['hu'],'wo':['o'],'koohii':['kōhī','kouhii'],'keeki':['kēki'],'gakkou':['gakkō']};
bool equivalent(String a,String b)=>[a,...(aliases[a]??<String>[])].any((x)=>[b,...(aliases[b]??<String>[])].contains(x));
String numberReading(int n){if(n<0||n>99)throw RangeError.range(n,0,99);if(n<10)return digits[n];return '${n>=20?digits[n~/10]:''}じゅう${n%10>0?digits[n%10]:''}';}
List<String> options(String answer,Iterable<String> others)=>{answer,...others}.toList();
Question make(String id,String concept,String type,String prompt,String answer,String explanation,{List<String> choices=const [],List<String> tokens=const [],List<String> alternatives=const [],String? mastery})=>Question(id:id,conceptId:concept,type:type,prompt:prompt,answer:answer,explanation:explanation,choices:choices,tokens:tokens,alternatives:alternatives,masteryId:mastery);

List<Question> vocabularyPool(Unit u)=>u.words.expand((w){final concept='word:${w.id}',explanation='${w.writing} se lit ${w.reading} : ${w.meaning}.';
  final kanji=RegExp(r'[\u4e00-\u9fff]').hasMatch(w.writing);
  return [make('${w.id}:produce',concept,'input','Écris en kana : « ${w.meaning} »',w.reading,explanation,alternatives:w.readingAlternatives),
    make('${w.id}:meaning',concept,'choice','Quel est le sens de ${w.writing} ?',w.meaning,explanation,choices:options(w.meaning,u.words.map((x)=>x.meaning))),
    make('${w.id}:recognize',concept,'choice','Choisis le mot : « ${w.meaning} »',w.writing,explanation,choices:options(w.writing,u.words.map((x)=>x.writing))),
    kanji?make('${w.id}:read',concept,'input','Lis ce mot en kanji : ${w.writing}',w.reading,explanation,alternatives:w.readingAlternatives):make('${w.id}:spell',concept,'order','Reconstruis en kana : « ${w.meaning} »',w.reading,explanation,tokens:w.reading.split(''))];
}).toList()..addAll(authoredQuestions(u));
List<Question> authoredQuestions(Unit u)=>u.exercises.map((e)=>make('${u.id}:custom:${e['id']}','${u.id}:custom:${e['id']}',e['type'],e['prompt'],e['answer'],e['explanation'],choices:strings(e['choices']),tokens:strings(e['tokens']),alternatives:strings(e['alternatives']))).toList();
List<Json> cartesian(Json domains){var rows=<Json>[{}];for(final entry in domains.entries){rows=rows.expand((r)=>(entry.value as List).map((v)=><String,dynamic>{...r,entry.key:object(v)})).toList();}return rows;}
String interpolate(String template,Json row,String field)=>template.replaceAllMapped(RegExp(r'\{([^}]+)\}'),(m)=>row[m[1]][field] as String);
List<Json> contexts(Unit u){final result=<Json>[];final frames=objects(u.generator['frames']);for(var fi=0;fi<frames.length;fi++){final f=frames[fi],rows=cartesian(object(f['domains']));for(var ri=0;ri<rows.length;ri++){final tokens=strings(f['tokens']).map((t)=>interpolate(t,rows[ri],'jp')).toList();result.add({'id':'${u.id}:f$fi:r$ri','concept':'${u.id}:frame:$fi','tokens':tokens,'japanese':tokens.join(),'french':interpolate(f['french'],rows[ri],'fr'),'focus':f['focus'],'explanation':f['explanation']});}}return result;}
List<Question> lessonPool(Unit u,LearningModule m){
  final result=<Question>[];switch(u.generator['kind']){
    case 'kana':
      for(var i=0;i<u.table.length;i++){final kana=u.table[i][0],roman=u.table[i][1],concept='${u.id}:q:$i',explanation='$kana se lit « $roman ».';
        result.addAll([make('$concept:read',concept,'input','Lis en rōmaji : $kana',roman,explanation,mastery:concept,alternatives:aliases[roman]??[]),
          make('$concept:recognize',concept,'choice','Quelle écriture se lit « $roman » ?',kana,explanation,mastery:concept,choices:options(kana,u.table.where((r)=>!equivalent(r[1],roman)).map((r)=>r[0]))),
          make('$concept:sound',concept,'choice','Choisis la lecture de $kana.',roman,explanation,mastery:concept,choices:options(roman,u.table.where((r)=>!equivalent(r[1],roman)).map((r)=>r[1])))]);}
      break;
    case 'numbers':
      for(var n=u.generator['min'] as int;n<=u.generator['max'];n++){final reading=numberReading(n),concept='${u.id}:number:$n',explanation='$n se lit $reading. Les dizaines se construisent avec じゅう.';
        result.addAll([make('$concept:read',concept,'input','Écris en hiragana le nombre $n.',reading,explanation,alternatives:({0:['ぜろ'],4:['し'],7:['しち'],9:['く']})[n]??[]),
          make('$concept:value',concept,'choice','Quel nombre correspond à $reading ?',n.toString(),explanation,choices:options(n.toString(),[n+1,n+2,n-1].where((x)=>x>=u.generator['min']&&x<=u.generator['max']).map((x)=>'$x'))),
          make('$concept:order',concept,'order','Construis la lecture du nombre $n.',reading,explanation,tokens:[if(n>=20)digits[n~/10],if(n>=10)'じゅう',if(n%10>0||n==0)digits[n%10]])]);}
      break;
    case 'kanji':
      for(final group in m.mcos){for(final q in vocabularyPool(group)){result.add(make('${u.id}:${q.id}','${u.id}:${q.conceptId}',q.type,q.prompt,q.answer,q.explanation,choices:q.choices,tokens:q.tokens,alternatives:q.alternatives));}}
      break;
    case 'frames':
      final all=contexts(u);
      for(final c in all){final tokens=strings(c['tokens']),focus=c['focus'] as int,answer=tokens[focus],id=c['id'] as String,concept=c['concept'] as String;
        final feedback='${c['japanese']} — ${c['french']} ${c['explanation']}';final alternatives=<String>[];
        if(tokens.length==5&&((['で','と'].contains(tokens[1])&&tokens[3]=='に')||(tokens[1]=='に'&&tokens[3]=='が'))){alternatives.add([...tokens.sublist(2,4),...tokens.sublist(0,2),tokens[4]].join());}
        final blank=List<String>.from(tokens)..[focus]='＿';
        result.add(make('$id:cloze',concept,'choice','Complète : ${blank.join()}\nSens : ${c['french']}',answer,feedback,choices:options(answer,[...all.map((x)=>strings(x['tokens'])[x['focus'] as int]),'は','が','の','に','で','を','です','ます','ません'])));
        result.add(make('$id:order',concept,'order','Reconstruis : ${c['french']}',c['japanese'],feedback,tokens:tokens.length==1?tokens[0].split(''):tokens,alternatives:alternatives));
        final meanings=options(c['french'],all.map((x)=>x['french'] as String));if(meanings.length>1)result.add(make('$id:meaning',concept,'choice','Comprends cette phrase : ${c['japanese']}',c['french'],feedback,choices:meanings));}
      break;
    default:
      for(var i=0;i<u.facts.length;i++){final q=u.facts[i],concept='${u.id}:fact:$i';result.add(make('$concept:input',concept,'input',q['prompt'],q['answer'],q['explanation'],alternatives:strings(q['alternatives'])));
        final choices=options(q['answer'],u.facts.map((x)=>x['answer'] as String));if(choices.length>1)result.add(make('$concept:choice',concept,'choice',q['prompt'],q['answer'],q['explanation'],choices:choices));}
  }
  result.addAll(authoredQuestions(u));
  return result;
}
List<Question> selectSession(List<Question> pool,Progress p,{int count=10,bool cover=false,List<String>? unmastered,Random? random}){
  final rng=random??Random();var candidates=pool.where((q)=>unmastered==null||unmastered.contains(q.masteryId)).toList();if(candidates.isEmpty)candidates=List.from(pool);
  candidates.shuffle(rng);double priority(Question q){final stats=p.stats[q.conceptId] as Map? ?? {};return (p.recent.contains(q.id)?-100:0)+min(3,(stats['wrong'] as num? ?? 0)).toDouble()*3-(stats['right'] as num? ?? 0).toDouble()*0.05;}
  candidates.sort((a,b)=>priority(b).compareTo(priority(a)));final selected=<Question>[],ids=<String>{},concepts=<String>{};
  for(var i=0;i<min(count,pool.length);i++){final available=candidates.where((q)=>!ids.contains(q.id)&&(!cover||!concepts.contains(q.conceptId))).toList();if(available.isEmpty)break;
    final type=['input','choice','order'][i%3],best=priority(available.first);final q=available.firstWhere((q)=>q.type==type&&priority(q)>=best-3,orElse:()=>available.first);
    final others=q.choices.where((x)=>x!=q.answer).toList()..shuffle(rng);final options=[q.answer,...others.take(3)]..shuffle(rng);
    selected.add(q.shuffled(q.choices.isEmpty?[]:options));ids.add(q.id);concepts.add(q.conceptId);}
  return selected;
}
List<Question> examQuestions(LearningModule m,Progress p,{Random? random}){final rng=random??Random();final qs=[...m.lessons.expand((u)=>selectSession(lessonPool(u,m),p,count:4,random:rng)),...m.mcos.expand((u)=>selectSession(vocabularyPool(u),p,count:4,cover:true,random:rng))]..shuffle(rng);return qs;}
Json schedule(Json? old,int grade,int now){if(grade<0||grade>3)throw RangeError.range(grade,0,3);final p=old??{'due':now,'interval':0,'ease':2.5,'repetitions':0};final ease=(p['ease'] as num).toDouble(),reps=(p['repetitions'] as num).toInt();
  if(grade==0)return {...p,'repetitions':0,'interval':0,'due':now+600000,'ease':max(1.3,ease-0.2)};
  final newEase=max(1.3,ease+(grade==1 ? -0.15 : grade==3 ? 0.15 : 0));final interval=reps==0?(grade==3?4:1):reps==1?(grade==1?3:grade==3?8:6):max(1,((p['interval'] as num)*(grade==1?1.2:newEase)).round());
  return {'due':now+interval*86400000,'interval':interval,'ease':newEase,'repetitions':reps+1};
}
