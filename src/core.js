export const PASS = 80;
export const DAY = 86400000;
export function normalize(value) {
  return String(value).normalize('NFKC').trim().toLocaleLowerCase('fr').replace(/\s+/g, ' ');
}
export function correct(question, value) {
  return [question.answer, ...(question.alternatives || [])].some(a => normalize(a) === normalize(value));
}
export function freshState() { return {version:1, completed:[], exams:{}, cards:{}, activity:{}, goal:10}; }
export function validState(s) {
  return s && s.version === 1 && Array.isArray(s.completed) && s.completed.every(x=>typeof x==='string') &&
    s.exams && typeof s.exams==='object' && !Array.isArray(s.exams) && Object.values(s.exams).every(x=>x && Number.isFinite(x.score) && x.score>=0 && x.score<=100 && Number.isFinite(x.at)) &&
    s.cards && typeof s.cards==='object' && !Array.isArray(s.cards) && Object.values(s.cards).every(x=>x && Number.isFinite(x.due) && Number.isFinite(x.interval) && x.interval>=0 && Number.isFinite(x.ease) && x.ease>=1.3 && Number.isInteger(x.repetitions) && x.repetitions>=0) &&
    s.activity && typeof s.activity==='object' && !Array.isArray(s.activity) && Object.values(s.activity).every(x=>Number.isInteger(x)&&x>=0) && Number.isInteger(s.goal) && s.goal>=5 && s.goal<=50;
}
export function required(module) { return [...module.lessons, ...module.mcos].map(x=>x.id); }
export function ready(module, state) { return required(module).every(id=>state.completed.includes(id)); }
export function unlocked(index, modules, state) { return index===0 || (state.exams[modules[index-1].id]?.score ?? 0) >= PASS; }
export function schedule(previous, grade, now=Date.now()) {
  if(![0,1,2,3].includes(grade)) throw new Error('Invalid grade');
  const p=previous || {due:now,interval:0,ease:2.5,repetitions:0};
  if (grade===0) return {...p, repetitions:0,interval:0,due:now+600000,ease:Math.max(1.3,p.ease-0.2)};
  const ease=Math.max(1.3,p.ease+(grade===1?-0.15:grade===3?0.15:0));
  const interval=p.repetitions===0?(grade===1?1:grade===3?4:1):p.repetitions===1?(grade===1?3:grade===3?8:6):Math.max(1,Math.round(p.interval*(grade===1?1.2:ease)));
  return {due:now+interval*DAY,interval,ease,repetitions:p.repetitions+1};
}
export function shuffle(items, random=Math.random) {
  const copy=[...items]; for(let i=copy.length-1;i>0;i--){const j=Math.floor(random()*(i+1));[copy[i],copy[j]]=[copy[j],copy[i]];} return copy;
}
export function wordQuestions(mco) {
  return mco.words.flatMap(w=>[{prompt:`Écris en kana : « ${w.meaning} »`,answer:w.reading,explanation:`${w.writing} se lit ${w.reading} : ${w.meaning}.`}, ...(/\p{Script=Han}/u.test(w.writing)?[{prompt:`Lis ce mot en kanji : ${w.writing}`,answer:w.reading,explanation:`${w.writing} se lit ${w.reading} : ${w.meaning}.`}]:[])]);
}
export function examQuestions(module, random=Math.random) {
  // Every lesson and every mandatory vocabulary group is represented.
  return shuffle([...module.lessons.flatMap(l=>shuffle(l.questions,random).slice(0,4)),...module.mcos.flatMap(m=>shuffle(wordQuestions(m),random).slice(0,4))],random);
}
export function score(questions, answers) {return Math.round(questions.filter((q,i)=>correct(q,answers[i]??'')).length/questions.length*100);}
export function recordExam(state, module, result, now=Date.now()) {
  if(!ready(module,state)) throw new Error('Mandatory units incomplete');
  const old=state.exams[module.id];
  state.exams[module.id]={score:Math.max(old?.score??0,result),lastScore:result,at:now};
}
export function localDate(now=new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`;
}
export function streak(activity, now=new Date()) {
  const day=new Date(now.getFullYear(),now.getMonth(),now.getDate());
  if(!activity[localDate(day)]) day.setDate(day.getDate()-1);
  let count=0; while(activity[localDate(day)]) { count++;day.setDate(day.getDate()-1); } return count;
}
