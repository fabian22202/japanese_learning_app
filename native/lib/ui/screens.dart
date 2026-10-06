import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller.dart';
import '../domain/models.dart';
import '../domain/engine.dart';
import '../domain/keyboard.dart';
import '../domain/curriculum.dart';
import 'japanese_keyboard.dart';
import 'writing_practice.dart';
import 'vocabulary_card.dart';

void message(BuildContext context, String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
Widget sheet(List<Widget> children) => Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children))));
Widget heading(String title, [String? subtitle]) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), if(subtitle != null) Text(subtitle)]));
void open(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

class Shell extends StatefulWidget {
  final LearningController controller;
  const Shell({super.key, required this.controller});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int tab = 0;
  static const destinations = [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'), NavigationDestination(icon: Icon(Icons.route), label: 'Parcours'), NavigationDestination(icon: Icon(Icons.style_outlined), label: 'Révisions'), NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Carnet')];
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.controller, builder: (context, _) {
    final c = widget.controller;
    final pages = [HomePage(c: c, onPath: () => setState(() => tab = 1)), PathPage(c: c), ReviewPage(c: c), SettingsPage(c: c)];
    final wide = MediaQuery.sizeOf(context).width >= 860;
    return Scaffold(appBar: AppBar(title: const Text('ことば  Kotoba'), actions: [Padding(padding: const EdgeInsets.all(12), child: Text('${streak(c.progress, DateTime.now())} jours'))]),
      body: Column(children: [if(c.courseNotice != null) MaterialBanner(content: Text(c.courseNotice!), actions: [TextButton(onPressed: c.dismissCourseNotice, child: const Text('Compris'))]), if(c.storageError != null) MaterialBanner(content: Text(c.storageError!), actions: [TextButton(onPressed: () => setState(() => tab = 3), child: const Text('Mon carnet'))]), Expanded(child: Row(children: [if(wide) NavigationRail(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), labelType: NavigationRailLabelType.all, destinations: destinations.map((d) => NavigationRailDestination(icon: d.icon, label: Text(d.label))).toList()), Expanded(child: pages[tab])]))]),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: destinations));
  });
}
class HomePage extends StatelessWidget {
  final LearningController c;
  final VoidCallback onPath;
  const HomePage({super.key, required this.c, required this.onPath});
  @override Widget build(BuildContext context) {
    final today = (c.progress.activity[dateKey(DateTime.now())] as num? ?? 0).toInt();
    return sheet([heading('Un petit pas, chaque jour.', 'Apprends le japonais, à ton rythme.'), Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('今日の目標  •  Objectif du jour'), const SizedBox(height: 15), LinearProgressIndicator(value: min(1.0, today/c.progress.goal)), Text('$today / ${c.progress.goal} réponses'), const SizedBox(height: 18), FilledButton(onPressed: onPath, child: const Text('Continuer mon parcours'))]))), heading('Ton carnet'), Text('${c.progress.completed.length} étapes terminées · ${c.learnedWords.length} mots appris · ${c.dueWords().length} cartes à revoir'), heading('Apprendre, pratiquer, retenir'), const Text('Chaque module associe des leçons, 2 à 4 MCO de vocabulaire et un DS. Termine les étapes puis obtiens 80 % au DS pour débloquer la suite. Les révisions espacées entretiennent les mots appris.'), const SizedBox(height: 15), const Text('Les ressources vidéo de Julien Fontanier accompagnent les leçons. Les explications et exercices de Kotoba sont rédigés pour cette application.')]);
  }
}
class PathPage extends StatelessWidget {
  final LearningController c;
  const PathPage({super.key, required this.c});
  @override Widget build(BuildContext context) => sheet([heading('Ton parcours', 'Du premier kana aux phrases du quotidien.'), ...c.modules.asMap().entries.map((e) {
    final m=e.value, unlocked=c.progress.unlocked(e.key,c.modules), count=m.units.where((u)=>c.progress.done(u.id)).length;
    return Card(child: ListTile(leading: Text(m.symbol,style: const TextStyle(fontSize:26)),title: Text('${e.key+1}. ${m.title}'),subtitle: Text('${m.subtitle}\n$count / ${m.units.length} étapes'),isThreeLine:true,trailing:Icon(unlocked?Icons.chevron_right:Icons.lock_outline),onTap:unlocked?()=>open(context,ModulePage(c:c,module:m)):null));
  })]);
}
class ModulePage extends StatelessWidget {
  final LearningController c;
  final LearningModule module;
  const ModulePage({super.key,required this.c,required this.module});
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:c,builder:(context,_)=>Scaffold(appBar:AppBar(title:Text(module.title)),body:sheet([heading(module.title,module.subtitle),...module.units.map((u)=>Card(child:ListTile(title:Text(u.title),subtitle:Text(u.isVocabulary?'MCO obligatoire · ${u.words.length} mots':'Leçon et entraînement'),trailing:Icon(c.progress.done(u.id)?Icons.check_circle:Icons.chevron_right),onTap:()=>open(context,LessonPage(c:c,module:module,unit:u))))),const SizedBox(height:18),FilledButton.icon(onPressed:c.progress.ready(module)?()=>open(context,SessionPage(c:c,module:module,questions:examQuestions(module,c.progress),exam:true)):null,icon:const Icon(Icons.assignment_outlined),label:const Text('Passer le DS')),Text(c.progress.ready(module)?'Objectif : 80 % · résultat conservé dans ton carnet.':'Termine toutes les leçons et tous les MCO pour accéder au DS.'),if(c.progress.exams[module.id]!=null)Text('Meilleur résultat : ${c.progress.exams[module.id]['score']} %')] )));
}
class LessonPage extends StatelessWidget {
  final LearningController c;
  final LearningModule module;
  final Unit unit;
  const LessonPage({super.key,required this.c,required this.module,required this.unit});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(unit.title)),body:sheet([heading(unit.title),...unit.sections.map((section)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[heading(section['title']),...strings(section['paragraphs']).map((p)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Text(p,style:const TextStyle(height:1.6)))),...objects(section['examples']).map((e)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e['jp'],style:const TextStyle(fontSize:23)),Text(e['reading']),Text(e['fr'])])))),if(section['note']!=null)Card(color:const Color(0xffe3ecdc),child:Padding(padding:const EdgeInsets.all(16),child:Text(section['note'])))])),...unit.paragraphs.map((p)=>Padding(padding:const EdgeInsets.only(bottom:15),child:Text(p,style:const TextStyle(fontSize:16,height:1.65)))),if(unit.table.isNotEmpty)Wrap(spacing:8,runSpacing:8,children:unit.table.map((r)=>Chip(label:Text(r.join('  ·  ')))).toList()),...unit.words.map((w)=>VocabularyCard(key:ValueKey('vocabulary:${w.id}'),word:w,onSpeak:()=>speak(context,w.reading))),...unit.resources.map((r)=>TextButton.icon(onPressed:()async{try{if(!await launchUrl(Uri.parse(r['url']),mode:LaunchMode.externalApplication)&&context.mounted)message(context,'Impossible d’ouvrir la vidéo.');}catch(_){if(context.mounted)message(context,'Impossible d’ouvrir la vidéo.');}},icon:const Icon(Icons.play_circle_outline),label:Text(r['title']??'Ressource vidéo'))),const SizedBox(height:20),OutlinedButton.icon(onPressed:()=>open(context,WritingPracticePage(characters:writingCharacters([...unit.table.map((r)=>r.first),...unit.words.map((w)=>w.writing),...unit.sections.expand((s)=>objects(s['examples']).map((e)=>e['jp'] as String))]))),icon:const Icon(Icons.draw_outlined),label:const Text('Pratiquer l’écriture à la main')),FilledButton(onPressed:()=>open(context,SessionPage(c:c,module:module,unit:unit,questions:selectSession(unit.isVocabulary?vocabularyPool(unit):lessonPool(unit,module),c.progress,count:10))),child:const Text('M’entraîner'))]));
}
Future<void> speak(BuildContext context,String text)async{
  final tts=FlutterTts();
  try{final voices=await tts.getVoices;final jp=(voices as List).where((v)=>(v['locale'] as String? ?? '').toLowerCase().startsWith('ja')).toList();if(jp.isEmpty){if(context.mounted)message(context,'Installe une voix japonaise dans les paramètres de ton appareil pour écouter les mots.');return;}await tts.setVoice({'name':jp.first['name'].toString(),'locale':jp.first['locale'].toString()});await tts.setSpeechRate(0.4);await tts.awaitSpeakCompletion(true);await tts.speak(text);}catch(_){if(context.mounted)message(context,'La voix japonaise n’est pas disponible sur cet appareil.');}
}
class SessionPage extends StatefulWidget {
  final LearningController c;
  final LearningModule module;
  final Unit? unit;
  final List<Question> questions;
  final bool exam;
  const SessionPage({super.key,required this.c,required this.module,required this.questions,this.unit,this.exam=false});
  @override State<SessionPage> createState()=>_SessionState();
}
class _SessionState extends State<SessionPage>{
  final input=TextEditingController();
  int index=0,right=0;
  bool checked=false,ok=false,keyboardVisible=true;
  String? choice;
  List<int> ordered=[],tileOrder=[];
  final Set<String> mastered={};
  @override void initState(){super.initState();shuffleTiles();}
  void shuffleTiles(){if(index<widget.questions.length)tileOrder=List.generate(widget.questions[index].tokens.length,(i)=>i)..shuffle();}
  @override void dispose(){input.dispose();super.dispose();}
  void check(){final q=widget.questions[index];final answer=q.type=='choice'?choice??'':q.type=='order'?ordered.map((i)=>q.tokens[i]).join():input.text;
    setState((){checked=true;ok=correct(q,answer);if(ok){right++;mastered.add(q.masteryId??q.conceptId);}});widget.c.progress.answer(q,ok);widget.c.save();}
  void next(){setState((){index++;checked=false;choice=null;ordered=[];input.clear();keyboardVisible=true;shuffleTiles();});if(index==widget.questions.length){final score=(100*right/widget.questions.length).round();if(widget.exam)widget.c.progress.recordExam(widget.module,score);else if(score>=80&&widget.unit!=null){final u=widget.unit!;if(u.isKana){final ids=List.generate(u.table.length,(i)=>'${u.id}:q:$i');final key='nativeKanaMastery:${u.id}';final all={...strings(widget.c.progress.data[key]),...mastered};widget.c.progress.data[key]=all.toList();if(ids.every(all.contains))widget.c.progress.complete(u.id);}else widget.c.progress.complete(u.id);}widget.c.save();}}
  @override Widget build(BuildContext context){final complete=index>=widget.questions.length;
    if(complete){final score=widget.questions.isEmpty?0:(100*right/widget.questions.length).round();final passed=score>=80;
      return Scaffold(appBar:AppBar(title:const Text('Bilan')),body:sheet([heading('$score %', '$right bonnes réponses sur ${widget.questions.length}'),Text(widget.exam?(passed?'DS réussi ! Le module suivant est débloqué.':'Reprends les points difficiles puis retente le DS.'):widget.c.progress.done(widget.unit?.id??'')?'Étape validée !':'Continue l’entraînement pour maîtriser cette étape. Pour les kana, chaque caractère doit être réussi.'),const SizedBox(height:20),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Retour au module')),TextButton(onPressed:(){final u=widget.unit;if(u!=null){final pool=u.isVocabulary?vocabularyPool(u):lessonPool(u,widget.module);final learned=strings(widget.c.progress.data['nativeKanaMastery:${u.id}']);final remaining=u.isKana?List.generate(u.table.length,(i)=>'${u.id}:q:$i').where((id)=>!learned.contains(id)).toList():null;Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>SessionPage(c:widget.c,module:widget.module,unit:u,questions:selectSession(pool,widget.c.progress,count:10,cover:u.isKana,unmastered:remaining))));}else Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>SessionPage(c:widget.c,module:widget.module,exam:true,questions:examQuestions(widget.module,widget.c.progress))));},child:const Text('Nouvel entraînement'))]));}
    final q=widget.questions[index], keyboard=needsKeyboard(q);
    return Scaffold(appBar:AppBar(title:Text(widget.exam?'DS · ${widget.module.title}':widget.unit?.title??'Entraînement')),body:sheet([LinearProgressIndicator(value:index/widget.questions.length),Text('${index+1} / ${widget.questions.length}'),heading(q.prompt),if(q.type=='choice')...q.choices.map((v)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:OutlinedButton(onPressed:checked?null:()=>setState(()=>choice=v),style:OutlinedButton.styleFrom(backgroundColor:choice==v?Theme.of(context).colorScheme.primaryContainer:null),child:Padding(padding:const EdgeInsets.all(10),child:Text(v))))),if(q.type=='input')TextField(controller:input,readOnly:checked,keyboardType:keyboard&&keyboardVisible?TextInputType.none:TextInputType.text,autocorrect:false,decoration:const InputDecoration(labelText:'Ta réponse'),onSubmitted:(_){if(!checked&&input.text.trim().isNotEmpty)check();}),if(keyboard&&!checked)JapaneseKeyboard(controller:input,kanji:widget.c.kanji(widget.module),enabled:!checked,onVisibility:(v)=>setState(()=>keyboardVisible=v)),if(q.type=='order')...[
      Card(child:Padding(padding:const EdgeInsets.all(16),child:Text(ordered.isEmpty?'Touche les éléments dans le bon ordre':ordered.map((i)=>q.tokens[i]).join(),style:const TextStyle(fontSize:22)))),Wrap(spacing:8,runSpacing:8,children:tileOrder.map((i)=>OutlinedButton(onPressed:checked||ordered.contains(i)?null:()=>setState(()=>ordered.add(i)),child:Text(q.tokens[i]))).toList()),TextButton(onPressed:checked?null:()=>setState(()=>ordered.clear()),child:const Text('Recommencer la phrase'))],const SizedBox(height:20),if(checked)Card(color:ok?const Color(0xffe3ecdc):const Color(0xffffe2d9),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(ok?'Bien joué !':'À retenir',style:const TextStyle(fontWeight:FontWeight.bold)),Text('Réponse : ${q.answer}'),Text(q.explanation)]))),FilledButton(onPressed:checked?next:check,child:Text(checked?'Continuer':'Vérifier'))]));
  }
}
class ReviewPage extends StatefulWidget{
  final LearningController c;
  const ReviewPage({super.key,required this.c});
  @override State<ReviewPage> createState()=>_ReviewState();
}
class _ReviewState extends State<ReviewPage>{
  bool reveal=false;
  @override Widget build(BuildContext context){final words=widget.c.dueWords();return sheet([heading('Révisions espacées','Les mots de tes MCO reviennent au bon moment.'),if(words.isEmpty)Text(widget.c.learnedWords.isEmpty?'Termine un MCO pour ajouter ses mots à ton carnet.':'Tout est à jour. Reviens demain !')else ...[Text('${words.length} cartes à revoir'),Card(child:Padding(padding:const EdgeInsets.all(25),child:Column(children:[Text(words.first.meaning,style:const TextStyle(fontSize:25)),if(reveal)...[Text(words.first.writing,style:const TextStyle(fontSize:36)),Text(words.first.reading),IconButton(onPressed:()=>speak(context,words.first.reading),icon:const Icon(Icons.volume_up_outlined))]]))),if(!reveal)FilledButton(onPressed:()=>setState(()=>reveal=true),child:const Text('Voir la réponse'))else Wrap(spacing:8,runSpacing:8,children:['À revoir','Difficile','Bien','Facile'].asMap().entries.map((e)=>OutlinedButton(onPressed:()async{await widget.c.rate(words.first,e.key);if(mounted)setState(()=>reveal=false);},child:Text(e.value))).toList())]]);}
}
class SettingsPage extends StatelessWidget{
  final LearningController c;
  const SettingsPage({super.key,required this.c});
  Future<void> export(BuildContext context)async{try{await FilePicker.saveFile(fileName:'kotoba-carnet.json',bytes:Uint8List.fromList(utf8.encode(c.progress.encode())),mimeType:'application/json');}catch(_){if(context.mounted)message(context,'Le carnet n’a pas pu être exporté.');}}
  Future<void> restore(BuildContext context)async{try{final file=await FilePicker.pickFile(type:FileType.custom,allowedExtensions:['json']);if(file==null)return;final bytes=await file.readAsBytes();if(bytes.length>2000000)throw const FormatException();final source=utf8.decode(bytes);final p=Progress.fromJson(object(jsonDecode(source)));if(!context.mounted)return;final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Importer ce carnet ?'),content:Text('${p.completed.length} étapes et ${p.cards.length} cartes. Le carnet actuel sera remplacé.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Importer'))]));if(yes==true){await c.importJson(source);if(context.mounted)message(context,'Carnet importé.');}}catch(_){if(context.mounted)message(context,'Ce fichier n’est pas un carnet Kotoba valide.');}}
  Future<void> exportCourse(BuildContext context)async{
    try{await FilePicker.saveFile(fileName:'kotoba-programme.json',bytes:Uint8List.fromList(utf8.encode(c.curriculum!.encode())),mimeType:'application/json');}catch(_){if(context.mounted)message(context,'Le programme n’a pas pu être exporté.');}
  }
  Future<void> importCourse(BuildContext context)async{
    try{
      final file=await FilePicker.pickFile(type:FileType.custom,allowedExtensions:['json']);if(file==null)return;
      final size=await file.length();if(size!=null&&size>4000000)throw const FormatException('Maximum 4 Mo.');
      final bytes=await file.readAsBytes();if(bytes.length>4000000)throw const FormatException('Maximum 4 Mo.');
      final source=utf8.decode(bytes),raw=jsonDecode(utf8.decode(bytes));
      final next=raw is Map&&raw['format']=='kotoba.lesson'?c.curriculum!.withLesson(source):Curriculum.parse(source);
      if(!context.mounted)return;
      final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Installer ces cours ?'),content:Text('${next.modules.length} modules, ${next.modules.expand((m)=>m.lessons).length} leçons.\nLes étapes modifiées et les DS correspondants devront être revalidés. Les cartes des mots inchangés sont conservées.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Installer'))]));
      if(yes==true){await c.installCurriculum(next);if(context.mounted)message(context,'Cours installés. Ils seront disponibles au prochain démarrage.');}
    }on FormatException catch(e){if(context.mounted)message(context,e.message);}catch(_){if(context.mounted)message(context,'Les cours n’ont pas pu être installés. Le programme actuel est conservé.');}
  }
  Future<void> resetCourse(BuildContext context)async{
    final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Restaurer les cours fournis ?'),content:const Text('Exporte tes cours personnalisés pour les conserver. Les étapes modifiées et leurs DS devront être revalidés.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Annuler')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Restaurer'))]));
    if(yes==true){try{await c.restoreCurriculum();if(context.mounted)message(context,'Programme fourni restauré.');}catch(_){if(context.mounted)message(context,'La restauration a échoué.');}}
  }
  @override Widget build(BuildContext context)=>sheet([heading('Ton carnet','Ta progression est enregistrée sur cet appareil.'),const Text('Objectif quotidien'),DropdownButton<int>(value:c.progress.goal,items:{5,10,15,20,30,40,50,c.progress.goal}.toList().map((n)=>DropdownMenuItem(value:n,child:Text('$n réponses'))).toList(),onChanged:(v){if(v!=null){c.progress.data['goal']=v;c.save();}}),heading('Sauvegarde'),const Text('Exporte ton carnet pour le conserver ou le transférer entre téléphone et PC. Tu peux aussi importer une sauvegarde de la première version web.'),const SizedBox(height:15),FilledButton.icon(onPressed:()=>export(context),icon:const Icon(Icons.download),label:const Text('Exporter le carnet')),TextButton.icon(onPressed:()=>restore(context),icon:const Icon(Icons.upload),label:const Text('Importer un carnet')),heading('Mes cours'),Text('Programme actif : ${c.usingProvidedCourses ? 'cours fournis' : 'cours personnalisés'} · ${c.modules.length} modules · ${c.modules.expand((m)=>m.mcos).length} MCO'),if(!c.usingProvidedCourses)const Text('Les nouveaux cours fournis contiennent 29 MCO avec 167 kanji. Utilise « Restaurer les cours fournis » pour les afficher à la place de ton programme personnalisé.'),const Text('Exporte le programme, modifie le JSON puis réimporte-le. Un fichier de leçon peut aussi ajouter ou remplacer une seule leçon dans un module. Les nouveaux cours restent enregistrés sur cet appareil.'),FilledButton.icon(onPressed:()=>importCourse(context),icon:const Icon(Icons.library_add_outlined),label:const Text('Importer des cours JSON')),TextButton(onPressed:()=>exportCourse(context),child:const Text('Exporter les cours JSON')),TextButton(onPressed:()=>resetCourse(context),child:const Text('Restaurer les cours fournis')),heading('Kotoba · 0.3.4'),const Text('Application Flutter en Dart. Leçons et exercices disponibles hors ligne ; les vidéos s’ouvrent dans ton application habituelle. La lecture audio utilise une voix japonaise installée sur ton appareil.')]);
}
