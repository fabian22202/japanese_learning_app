"""Validate this authoring pack against the existing native course contract.
No application changes. Run: python content/verify_courses.py
"""
import itertools,json,re,unicodedata
from pathlib import Path
R=Path(__file__).resolve().parent
p=json.loads((R/'kotoba-cours-debutant.json').read_text())
assert p['format']=='kotoba.curriculum' and p['version']==1
assert (R/'kotoba-cours-debutant.json').stat().st_size<4000000

def text(s):assert isinstance(s,str) and s.strip() and len(s)<=12000
def texts(xs):
 assert xs is None or isinstance(xs,list)
 for s in xs or []:text(s)
def normal(s):
 s=re.sub(r'\s+',' ',unicodedata.normalize('NFKC',s).strip().lower())
 return re.sub(r'([\u3000-\u9fff])\s+(?=[\u3000-\u9fff])',r'\1',s)
def exact(q,answer):return any(normal(answer)==normal(s) for s in [q['answer'],*q.get('alternatives',[])])
ids=set();word_ids=set();exercise_ids=set();total_pool=0
for m in p['modules']:
 for field in ['id','title','subtitle','symbol','color']:text(m[field])
 assert m['id'] not in ids;ids.add(m['id'])
 assert 1<=len(m['lessons'])<=50 and 2<=len(m['mcos'])<=4
 for kind in ['lessons','mcos']:
  for u in m[kind]:
   assert re.fullmatch('[A-Za-z0-9_-]{1,80}',u['id']) and u['id'] not in ids;ids.add(u['id']);text(u['title'])
   texts(u.get('paragraphs'))
   for section in u.get('sections',[]):
    text(section['title']);texts(section.get('paragraphs'))
    if section.get('note'):text(section['note'])
    for e in section.get('examples',[]):
     for f in ['jp','reading','fr']:text(e[f])
   for row in u.get('table') or []:assert len(row)>=2;texts(row)
   for r in u.get('resources',[]):text(r['title']);assert r['url'].startswith('https://')
   if kind=='mcos':
    assert 1<=len(u['words'])<=10
    for w in u['words']:
     for f in ['id','writing','reading','meaning']:text(w[f])
     assert w['id'] not in word_ids;word_ids.add(w['id'])
    total_pool+=4*len(u['words']);continue
   assert u['sections'],u['id']
   for q in u.get('questions',[]):
    for f in ['prompt','answer','explanation']:text(q[f])
    texts(q.get('alternatives'))
   for q in u['exercises']:
    assert q['id'] not in [x[1] for x in exercise_ids if x[0]==u['id']];exercise_ids.add((u['id'],q['id']))
    for f in ['id','prompt','answer','explanation']:text(q[f])
    assert q['type'] in ['input','choice','order'];texts(q.get('alternatives'))
    assert exact(q,q['answer'])
    if q['type']=='choice':
     assert len(q['choices'])>=2 and len(set(q['choices']))==len(q['choices'])
     assert q['answer'] in q['choices'];texts(q['choices'])
     # No distractor is also an accepted answer.
     assert all(not exact(q,x) for x in q['choices'] if x!=q['answer'])
    if q['type']=='order':assert len(q['tokens'])>=2 and exact(q,''.join(q['tokens']));texts(q['tokens'])
   g=u.get('generator') or {};count=len(u['exercises'])
   if g.get('kind')=='kana':assert u['table'];count+=3*len(u['table'])
   elif g.get('kind')=='numbers':assert 0<=g['min']<=g['max']<=99;count+=3*(g['max']-g['min']+1)
   elif g.get('kind')=='kanji':count+=4*sum(len(w['words']) for w in m['mcos'])
   elif g.get('kind')=='frames':
    for f in g['frames']:
     assert 0<=f['focus']<len(f['tokens']);text(f['explanation']);text(f['french'])
     keys=list(f['domains']);domains=[f['domains'][k] for k in keys]
     combinations=1
     for d in domains:
      assert d;combinations*=len(d)
      for x in d:text(x['jp']);text(x['fr'])
     assert combinations<=500
     contexts=[]
     for row in itertools.product(*domains):
      mapping=dict(zip(keys,row))
      def fill(t,field):return re.sub(r'\{([^}]+)\}',lambda match:mapping[match[1]][field],t)
      tokens=[fill(t,'jp') for t in f['tokens']];french=fill(f['french'],'fr');text(french)
      assert all(tokens) and '＿' not in ''.join(tokens)
      contexts.append(french)
     # The native engine adds cloze and order, plus meaning if multiple meanings exist in the unit.
     count+=combinations*3
   else:count+=len(u.get('questions',[]))*2
   assert count>0;total_pool+=count
assert total_pool<=30000
assert 1<=len(p['modules'])<=50
if len(p['modules'])>1 and p['modules'][1]['id']=='m2':
 assert sum(bool(re.search('[\u4e00-\u9fff]',w['writing'])) for u in p['modules'][1]['mcos'] for w in u['words'])<=10
print(json.dumps({'modules':len(p['modules']),'lessons':sum(len(m['lessons']) for m in p['modules']),'mcos':sum(len(m['mcos']) for m in p['modules']),'vocabulary_entries':len(word_ids),'original_corrected_exercises':len(exercise_ids),'pool_upper_bound':total_pool,'examples_with_reading_and_translation':sum(len(s.get('examples',[])) for m in p['modules'] for u in m['lessons'] for s in u['sections'])},ensure_ascii=False))
