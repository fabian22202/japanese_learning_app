const ROWS=['あいうえお','かきくけこ','さしすせそ','たちつてと','なにぬねの','はひふへほ','まみむめも','や ゆ よ','らりるれろ','わ を ん'];
const SMALL='ぁぃぅぇぉゃゅょっゎ';
const VOICED=['かきくけこ','さしすせそ','たちつてと','はひふへほ','う'];
const DAKUTEN=['がぎぐげご','ざじずぜぞ','だぢづでど','ばびぶべぼ','ゔ'];
const HANDAKUTEN='ぱぴぷぺぽ';
let preferredScript='hiragana';
const escape=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export const toKatakana=s=>[...s].map(c=>{const n=c.codePointAt(0);return n>=0x3041&&n<=0x3096?String.fromCodePoint(n+0x60):c;}).join('');
const toHiragana=s=>[...s].map(c=>{const n=c.codePointAt(0);return n>=0x30a1&&n<=0x30f6?String.fromCodePoint(n-0x60):c;}).join('');
export function needsKeyboard(q){return q.type==='input'&&(q.inputScript==='japanese'||(!/rōmaji|romaji/i.test(q.prompt)&&/kana|hiragana|katakana|kanji/i.test(q.prompt)));}
export function editText(value,start,end,action,text=''){
 const chars=[...value.slice(0,start)];
 if(action==='clear')return {value:'',cursor:0};
 if(action==='backspace'){
  if(start!==end)return {value:value.slice(0,start)+value.slice(end),cursor:start};
  const last=chars.pop()||'';return {value:chars.join('')+value.slice(end),cursor:start-last.length};
 }
 if(action==='dakuten'||action==='handakuten'){
  const target=start!==end?value.slice(start,end):chars.at(-1)||'';
  if([...target].length!==1)return {value,cursor:end};
  const hira=toHiragana(target);let next=hira;
  if(action==='dakuten')for(let i=0;i<VOICED.length;i++){
   const base=VOICED[i].indexOf(hira),voiced=DAKUTEN[i].indexOf(hira);
   if(base>=0)next=DAKUTEN[i][base];else if(voiced>=0)next=VOICED[i][voiced];
  }
  if(action==='dakuten'&&HANDAKUTEN.includes(hira))next=DAKUTEN[3][HANDAKUTEN.indexOf(hira)];
  if(action==='handakuten'){
   const index=VOICED[3].includes(hira)?VOICED[3].indexOf(hira):DAKUTEN[3].includes(hira)?DAKUTEN[3].indexOf(hira):HANDAKUTEN.indexOf(hira);
   if(index>=0)next=HANDAKUTEN.includes(hira)?VOICED[3][index]:HANDAKUTEN[index];
  }
  if(target!==hira)next=toKatakana(next);
  if(next===target)return {value,cursor:end};
  const from=start===end?start-target.length:start;
  return {value:value.slice(0,from)+next+value.slice(end),cursor:from+next.length};
 }
 return {value:value.slice(0,start)+text+value.slice(end),cursor:start+text.length};
}
export function mountKeyboard(container,input,{kanji=[]}={}){
 let script=preferredScript==='kanji'&&!kanji.length?'hiragana':preferredScript,small=false,open=true,start=input.selectionStart||0,end=input.selectionEnd||0;
 const remember=()=>{start=input.selectionStart??input.value.length;end=input.selectionEnd??start;};
 input.addEventListener('select',remember);input.addEventListener('keyup',remember);input.addEventListener('click',remember);input.addEventListener('input',remember);
 function render(){
  input.inputMode=open?'none':'text';
  const tabs=[['hiragana','ひらがな'],['katakana','カタカナ'],...(kanji.length?[['kanji','漢字']]:[])];
  const alphabet=small?[SMALL.slice(0,5),SMALL.slice(5)]:ROWS;
  container.innerHTML=`<div class="keyboard-heading"><strong>Clavier japonais</strong><button type="button" data-jkey="toggle" aria-expanded="${open}">${open?'Masquer':'Afficher'}</button></div>${open?`<div class="keyboard-tabs" role="group" aria-label="Écriture japonaise">${tabs.map(([id,label])=>`<button type="button" data-jkey="script" data-value="${id}" aria-pressed="${id===script}" lang="ja">${label}</button>`).join('')}</div>${script==='kanji'?`<p class="keyboard-hint">Caractères du vocabulaire déjà accessible dans ton parcours.</p><div class="kanji-keys">${[...new Set(kanji)].map(c=>key(c)).join('')}</div>`:`<div class="kana-keys">${alphabet.map(row=>[...row].map(c=>c===' '?'<span></span>':key(script==='katakana'?toKatakana(c):c)).join('')).join('')}</div>`}<div class="keyboard-tools">${script==='kanji'?'':`<button type="button" data-jkey="small" aria-pressed="${small}">Petits kana</button><button type="button" data-jkey="dakuten" aria-label="Ajouter ou enlever les dakuten">゛</button><button type="button" data-jkey="handakuten" aria-label="Ajouter ou enlever le handakuten">゜</button>${key('ー')}` }<button type="button" data-jkey="backspace" aria-label="Effacer le caractère précédent">⌫</button><button type="button" data-jkey="clear">Tout effacer</button></div><p class="keyboard-hint">゛ et ゜ modifient le kana précédent ou sélectionné. Masque ce clavier pour utiliser celui de ton appareil.</p>`:''}`;
  container.querySelectorAll('button').forEach(b=>b.disabled=input.disabled);
 }
 function key(c){return `<button type="button" data-jkey="insert" data-value="${escape(c)}" lang="ja">${escape(c)}</button>`;}
 container.addEventListener('pointerdown',e=>{if(e.target.closest('button')){remember();e.preventDefault();}});
 container.addEventListener('click',e=>{
  const b=e.target.closest('[data-jkey]');if(!b||input.disabled||input.readOnly)return;
  const action=b.dataset.jkey;
  if(action==='toggle'){open=!open;render();return;}
  if(action==='script'){script=b.dataset.value;preferredScript=script;small=false;render();return;}
  if(action==='small'){small=!small;render();return;}
  // If the input has just been replaced programmatically, never edit outside its bounds.
  start=Math.min(start,input.value.length);end=Math.min(end,input.value.length);
  const result=editText(input.value,start,end,action,b.dataset.value||'');
  input.value=result.value;start=end=result.cursor;input.setSelectionRange(start,end);input.dispatchEvent(new Event('input',{bubbles:true}));
 });
 render();
 return {disable(){container.querySelectorAll('button').forEach(b=>b.disabled=true);}};
}
