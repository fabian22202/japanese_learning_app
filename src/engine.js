// Exercise generation uses constrained language data: only compatible combinations are emitted.
const unique=xs=>[...new Set(xs)];
function shuffled(xs,random=Math.random){const a=[...xs];for(let i=a.length-1;i>0;i--){const j=Math.floor(random()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}
function choices(answer,others){return unique([answer,...others.filter(x=>x!==answer)]);}
function item(id,conceptId,type,prompt,answer,explanation,extra={}){return {id,conceptId,type,prompt,answer,explanation,...extra};}
export function vocabularyPool(mco){return mco.words.flatMap(w=>{
 const conceptId=`word:${w.id}`,explanation=`${w.writing} se lit ${w.reading} : ${w.meaning}.`;
 return [item(`${w.id}:produce`,conceptId,'input',`Écris en kana : « ${w.meaning} »`,w.reading,explanation),
 item(`${w.id}:meaning`,conceptId,'choice',`Quel est le sens de ${w.writing} ?`,w.meaning,explanation,{choices:choices(w.meaning,mco.words.map(x=>x.meaning))}),
 item(`${w.id}:recognize`,conceptId,'choice',`Choisis le mot : « ${w.meaning} »`,w.writing,explanation,{choices:choices(w.writing,mco.words.map(x=>x.writing))}),
 ...(/\p{Script=Han}/u.test(w.writing)?[item(`${w.id}:read`,conceptId,'input',`Lis ce mot en kanji : ${w.writing}`,w.reading,explanation)]:
 [item(`${w.id}:spell`,conceptId,'order',`Reconstruis en kana : « ${w.meaning} »`,w.reading,explanation,{tokens:[...w.reading]})])];
 });}
const romanAliases={shi:['si'],chi:['ti'],tsu:['tu'],fu:['hu'],wo:['o'],koohii:['kōhī','kouhii'],keeki:['kēki'],gakkou:['gakkō']};
const equivalent=(a,b)=>[a,...(romanAliases[a]||[])].some(x=>[b,...(romanAliases[b]||[])].includes(x));
const digits=['れい','いち','に','さん','よん','ご','ろく','なな','はち','きゅう'];
export function numberReading(n){if(!Number.isInteger(n)||n<0||n>99)throw Error('Number out of lesson range');if(n<10)return digits[n];return (n>=20?digits[Math.floor(n/10)]:'')+'じゅう'+(n%10?digits[n%10]:'');}
function cartesian(domains){let rows=[{}];for(const [key,values] of Object.entries(domains))rows=rows.flatMap(row=>values.map(value=>({...row,[key]:value})));return rows;}
function interpolate(template,row,field){return template.replace(/\{([^}]+)\}/g,(_,key)=>row[key][field]);}
export function frameContexts(unit){return (unit.generator?.frames||[]).flatMap((f,fi)=>cartesian(f.domains).map((row,ri)=>{
 const tokens=f.tokens.map(t=>interpolate(t,row,'jp'));
 return {id:`${unit.id}:f${fi}:r${ri}`,conceptId:`${unit.id}:frame:${fi}`,tokens,japanese:tokens.join(''),french:interpolate(f.french,row,'fr'),focus:f.focus,explanation:f.explanation};
 }));}
export function lessonPool(unit,module){const kind=unit.generator?.kind;
 if(kind==='kana')return unit.table.flatMap(([kana,romaji],i)=>{
 const conceptId=`${unit.id}:q:${i}`,explanation=`${kana} se lit « ${romaji} ».`,extra={masteryId:conceptId};
 return [item(`${conceptId}:read`,conceptId,'input',`Lis en rōmaji : ${kana}`,romaji,explanation,{...extra,alternatives:romanAliases[romaji]||[]}),
 item(`${conceptId}:recognize`,conceptId,'choice',`Quelle écriture se lit « ${romaji} » ?`,kana,explanation,{...extra,choices:choices(kana,unit.table.filter(x=>!equivalent(x[1],romaji)).map(x=>x[0]))}),
 item(`${conceptId}:sound`,conceptId,'choice',`Choisis la lecture de ${kana}.`,romaji,explanation,{...extra,choices:choices(romaji,unit.table.filter(x=>!equivalent(x[1],romaji)).map(x=>x[1]))})];
 });
 if(kind==='numbers')return Array.from({length:unit.generator.max-unit.generator.min+1},(_,i)=>i+unit.generator.min).flatMap(n=>{
 const reading=numberReading(n),conceptId=`${unit.id}:number:${n}`,explanation=`${n} se lit ${reading}. Les dizaines se construisent avec じゅう.`,variants=n===0?['ぜろ']:n===4?['し']:n===7?['しち']:n===9?['く']:[];
 return [item(`${conceptId}:read`,conceptId,'input',`Écris en hiragana le nombre ${n}.`,reading,explanation,{alternatives:variants}),
 item(`${conceptId}:value`,conceptId,'choice',`Quel nombre correspond à ${reading} ?`,String(n),explanation,{choices:choices(String(n),[n+1,n+2,n-1].filter(x=>x>=unit.generator.min&&x<=unit.generator.max).map(String))}),
 item(`${conceptId}:order`,conceptId,'order',`Construis la lecture du nombre ${n}.`,reading,explanation,{tokens:[...(n>=20?[digits[Math.floor(n/10)]]:[]),...(n>=10?['じゅう']:[]),...(n%10||n===0?[digits[n%10]]:[])]})];
 });
 if(kind==='kanji')return module.mcos.flatMap(vocabularyPool).map(q=>({...q,id:`${unit.id}:${q.id}`,conceptId:`${unit.id}:${q.conceptId}`}));
 if(kind==='frames'){
 const contexts=frameContexts(unit);
 return contexts.flatMap(c=>{
 const answer=c.tokens[c.focus],distractors=contexts.map(x=>x.tokens[x.focus]);
 const blank=c.tokens.map((t,i)=>i===c.focus?'＿':t).join('');
 const alternatives=(c.tokens.length===5&&(['で','と'].includes(c.tokens[1])&&c.tokens[3]==='に'||c.tokens[1]==='に'&&c.tokens[3]==='が'))?[c.tokens.slice(2,4).concat(c.tokens.slice(0,2),c.tokens[4]).join('')]:[];
 const feedback=`${c.japanese} — ${c.french} ${c.explanation}`;
 const possible=choices(answer,distractors.concat(['は','が','の','に','で','を','です','ます','ません']));
 return [item(`${c.id}:cloze`,c.conceptId,'choice',`Complète : ${blank}\nSens : ${c.french}`,answer,feedback,{choices:possible}),
 item(`${c.id}:order`,c.conceptId,'order',`Reconstruis : ${c.french}`,c.japanese,feedback,{tokens:c.tokens.length===1?[...c.tokens[0]]:c.tokens,japanese:true,alternatives}),
 item(`${c.id}:meaning`,c.conceptId,'choice',`Comprends cette phrase : ${c.japanese}`,c.french,feedback,{choices:choices(c.french,contexts.map(x=>x.french))})].filter(q=>q.type!=='choice'||q.choices.length>=2);
 });
 }
 return unit.questions.flatMap((q,i)=>{const conceptId=`${unit.id}:fact:${i}`;return [item(`${conceptId}:input`,conceptId,'input',q.prompt,q.answer,q.explanation,{alternatives:q.alternatives}),item(`${conceptId}:choice`,conceptId,'choice',q.prompt,q.answer,q.explanation,{choices:choices(q.answer,unit.questions.map(x=>x.answer))})].filter(x=>x.type!=='choice'||x.choices.length>1);});
}
export function selectSession(pool,{count=10,recent=[],stats={},random=Math.random,coverConcepts=false,unmastered=null}={}){
 let candidates=pool.filter(q=>!unmastered||unmastered.includes(q.masteryId));if(!candidates.length)candidates=pool;
 const seen=new Set(recent),scored=shuffled(candidates,random).map(q=>({q,priority:(seen.has(q.id)?-100:0)+Math.min(3,stats[q.conceptId]?.wrong||0)*3-(stats[q.conceptId]?.right||0)*.05})).sort((a,b)=>b.priority-a.priority);
 const result=[],concepts=new Set(),ids=new Set();
 // Cycle modalities while preferring new contexts and concepts that need work.
 for(let i=0;i<Math.min(count,candidates.length);i++){
  const type=['input','choice','order'][i%3];
  const allowed=x=>!ids.has(x.q.id)&&(!coverConcepts||!concepts.has(x.q.conceptId));
  const available=scored.filter(allowed);if(!available.length)break;
  const best=available[0].priority;
  const pick=available.find(x=>x.q.type===type&&x.priority>=best-3)||available[0];
  result.push(pick.q);ids.add(pick.q.id);concepts.add(pick.q.conceptId);
 }
 return result.map(q=>({...q,...(q.choices?{choices:shuffled([q.answer,...shuffled(q.choices.filter(x=>x!==q.answer),random).slice(0,3)],random)}:{}),...(q.tokens?{displayTokens:shuffled(q.tokens.map((text,i)=>({text,index:i})),random)}:{})}));
}
export function trackAnswer(state,q,ok){state.exerciseStats??={};state.recentQuestions??=[];const old=state.exerciseStats[q.conceptId]||{right:0,wrong:0};state.exerciseStats[q.conceptId]={right:old.right+(ok?1:0),wrong:ok?Math.max(0,old.wrong-1):old.wrong+1};state.recentQuestions=[...state.recentQuestions.filter(id=>id!==q.id),q.id].slice(-80);}
