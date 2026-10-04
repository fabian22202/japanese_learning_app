import 'package:flutter/material.dart';
import '../domain/keyboard.dart';
class JapaneseKeyboard extends StatefulWidget {
  final TextEditingController controller;
  final List<String> kanji;
  final bool enabled;
  final ValueChanged<bool> onVisibility;
  const JapaneseKeyboard({super.key,required this.controller,required this.kanji,required this.onVisibility,this.enabled=true});
  @override State<JapaneseKeyboard> createState()=>_JapaneseKeyboardState();
}
class _JapaneseKeyboardState extends State<JapaneseKeyboard>{
  String script='hiragana';bool small=false,open=true;
  void insert(String action,[String value='']){final c=widget.controller,selection=c.selection;final start=selection.isValid?selection.start:c.text.length,end=selection.isValid?selection.end:c.text.length;final result=edit(c.text,start,end,action,value);c.value=TextEditingValue(text:result.text,selection:TextSelection.collapsed(offset:result.cursor));}
  Widget key(String text,String action,{String? value,String? tooltip})=>Tooltip(message:tooltip??text,child:OutlinedButton(key:ValueKey('key:$action:${value??text}'),onPressed:widget.enabled?()=>insert(action,value??text):null,style:OutlinedButton.styleFrom(padding:const EdgeInsets.all(4),minimumSize:const Size(40,42)),child:Text(text,style:const TextStyle(fontSize:21,fontFamily:'KotobaJapanese'))));
  @override Widget build(BuildContext context){const rows=['あいうえお','かきくけこ','さしすせそ','たちつてと','なにぬねの','はひふへほ','まみむめも','や ゆ よ','らりるれろ','わ を ん'];
    final chars=script=='kanji'?widget.kanji:(small?'ぁぃぅぇぉゃゅょっゎ':rows.join()).split('').map((c)=>script=='katakana'?katakana(c):c).toList();
    return Container(decoration:BoxDecoration(color:const Color(0xfffbf7ef),border:Border.all(color:const Color(0xffe4e2d7)),borderRadius:BorderRadius.circular(12)),padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Expanded(child:Text('Clavier japonais',style:TextStyle(fontWeight:FontWeight.w700))),TextButton(onPressed:widget.enabled?(){setState(()=>open=!open);widget.onVisibility(open);}:null,child:Text(open?'Masquer':'Afficher'))]),
      if(open)...[
        Wrap(spacing:8,children:[for(final tab in ['hiragana','katakana',if(widget.kanji.isNotEmpty)'kanji'])ChoiceChip(label:Text({'hiragana':'ひらがな','katakana':'カタカナ','kanji':'漢字'}[tab]!,style:const TextStyle(fontFamily:'KotobaJapanese')),selected:script==tab,onSelected:widget.enabled?(_)=>setState((){script=tab;small=false;}):null)]),
        const SizedBox(height:12),SizedBox(height:chars.length<=10?100:280,child:GridView.builder(primary:false,itemCount:chars.length,gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:5,mainAxisSpacing:6,crossAxisSpacing:6,mainAxisExtent:42),itemBuilder:(_,i)=>chars[i]==' '?const SizedBox():key(chars[i],'insert',value:chars[i]))),
        const SizedBox(height:10),Wrap(spacing:6,runSpacing:6,children:[if(script!='kanji')...[
          FilterChip(label:const Text('Petits kana'),selected:small,onSelected:widget.enabled?(v)=>setState(()=>small=v):null),key('゛','dakuten',tooltip:'Ajouter ou enlever les dakuten'),key('゜','handakuten',tooltip:'Ajouter ou enlever le handakuten'),key('ー','insert',value:'ー')],
          key('⌫','backspace',tooltip:'Effacer le caractère précédent'),TextButton(onPressed:widget.enabled?()=>insert('clear'):null,child:const Text('Tout effacer'))]),
        const SizedBox(height:8),const Text('Les accents modifient le kana précédent ou sélectionné. Masque ce clavier pour utiliser celui de ton appareil.',style:TextStyle(fontSize:11,color:Color(0xff68726b)))
      ]
    ]));
  }
}
