import '../domain/models.dart';
bool needsKeyboard(Question q)=>q.type=='input'&&!RegExp('rōmaji|romaji',caseSensitive:false).hasMatch(q.prompt)&&RegExp('kana|hiragana|katakana|kanji',caseSensitive:false).hasMatch(q.prompt);
String katakana(String s)=>String.fromCharCodes(s.runes.map((n)=>n>=0x3041&&n<=0x3096?n+0x60:n));
String hiragana(String s)=>String.fromCharCodes(s.runes.map((n)=>n>=0x30a1&&n<=0x30f6?n-0x60:n));
class Edit {final String text;final int cursor;const Edit(this.text,this.cursor);}
Edit edit(String text,int start,int end,String action,[String insertion='']){
  if(action=='clear')return const Edit('',0);
  if(action=='backspace'){if(start!=end)return Edit(text.substring(0,start)+text.substring(end),start);if(start==0)return Edit(text,0);final last=text.substring(0,start).runes.last;final size=last>0xffff?2:1;return Edit(text.substring(0,start-size)+text.substring(end),start-size);}
  if(action=='dakuten'||action=='handakuten'){
    final target=start!=end?text.substring(start,end):start>0?text.substring(start-1,start):'';if(target.runes.length!=1)return Edit(text,end);
    final hira=hiragana(target);var next=hira;
    const base=['かきくけこ','さしすせそ','たちつてと','はひふへほ','う'],voiced=['がぎぐげご','ざじずぜぞ','だぢづでど','ばびぶべぼ','ゔ'],semi='ぱぴぷぺぽ';
    if(action=='dakuten'){for(var i=0;i<base.length;i++){final bi=base[i].indexOf(hira),vi=voiced[i].indexOf(hira);if(bi>=0)next=voiced[i][bi];else if(vi>=0)next=base[i][vi];}if(semi.contains(hira))next=voiced[3][semi.indexOf(hira)];}
    if(action=='handakuten'){final i=base[3].contains(hira)?base[3].indexOf(hira):voiced[3].contains(hira)?voiced[3].indexOf(hira):semi.indexOf(hira);if(i>=0)next=semi.contains(hira)?base[3][i]:semi[i];}
    if(hira!=target)next=katakana(next);if(next==target)return Edit(text,end);final from=start==end?start-target.length:start;return Edit(text.substring(0,from)+next+text.substring(end),from+next.length);
  }
  return Edit(text.substring(0,start)+insertion+text.substring(end),start+insertion.length);
}
