import 'package:flutter/material.dart';
import '../domain/models.dart';

class VocabularyCard extends StatelessWidget {
  final Word word;
  final VoidCallback onSpeak;
  const VocabularyCard({super.key,required this.word,required this.onSpeak});
  @override Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16),child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,children: [
        Row(children: [Expanded(child: Text(word.writing,style: const TextStyle(fontSize: 28,fontWeight: FontWeight.bold))),
          IconButton(tooltip:'Écouter en japonais',onPressed:onSpeak,icon:const Icon(Icons.volume_up_outlined))]),
        Text('Lecture en kana : ${word.reading}',style:const TextStyle(fontSize:18)),
        Text(word.meaning),
        if(word.readingAlternatives.isNotEmpty) Text('Autres lectures du mot : ${word.readingAlternatives.join('・')}'),
        for(final paragraph in word.usage) Padding(padding:const EdgeInsets.only(top:8),child:Text(paragraph)),
        for(final k in word.kanji) ...[
          const Divider(height:24),
          Text('Kanji : ${k['character']}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20)),
          Text('Kun’yomi : ${strings(k['kunyomi']).isEmpty ? 'aucune lecture usuelle présentée' : strings(k['kunyomi']).join('・')}'),
          Text('On’yomi : ${strings(k['onyomi']).isEmpty ? 'aucune lecture usuelle présentée' : strings(k['onyomi']).join('・')}'),
          for(final e in objects(k['examples'])) Padding(padding:const EdgeInsets.only(top:8),child: Column(
            crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('${e['kind']=='kun' ? 'Exemple kun' : 'Exemple on'} : ${e['writing']}',style:const TextStyle(fontWeight:FontWeight.w600)),
              Text('${e['reading']} · ${e['meaning']}'),
            ])),
          if(k['note']!=null) Padding(padding:const EdgeInsets.only(top:8),child:Text(k['note'])),
        ],
      ])));
}
