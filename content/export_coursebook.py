"""Render the canonical JSON into a readable course book, with separated corrections."""
import json
from pathlib import Path
R=Path(__file__).resolve().parent
p=json.loads((R/'kotoba-cours-debutant.json').read_text())
L=['# Kotoba — Parcours débutant approfondi','',
'Un cours en français pour aller des premiers kana à des phrases du quotidien. Le programme comprend 51 leçons : les 25 fiches initiales sont approfondies et 26 nouvelles leçons prolongent la progression. Les 29 MCO contiennent 230 entrées de vocabulaire ; certaines notions reviennent à des étapes différentes. Les 497 exercices ci-dessous possèdent un corrigé expliqué. Les générateurs des premières leçons fournissent aussi des variantes dans l’application.','',
'Les textes, exemples et exercices sont rédigés pour Kotoba. Les vidéos de Julien Fontanier sont des compléments ; ce document n’est ni une transcription de ses cours ni un programme officiel du JLPT. Les références Irodori de la Japan Foundation servent de repères complémentaires pour les notions et situations abordées.','',
'Chaque MCO est un cours de vocabulaire : écriture usuelle, lecture en kana, sens, explications, exemples et exercices. Les 230 entrées comprennent 184 mots ou formes écrits avec des kanji et présentent 167 caractères distincts. Les emprunts et les formules couramment écrits en kana gardent leur écriture naturelle. Les références kun’yomi et on’yomi portent sur les caractères ; la lecture du mot est apprise séparément.','',
'## Comment travailler','',
'1. Lis l’objectif et les exemples. Cache ensuite la traduction et retrouve le sens.','2. Consulte les MCO dès qu’un mot manque, sans attendre de deviner un sens à partir du français.','3. Fais les exercices avant de lire le corrigé. Explique la particule ou la transformation qui justifie ta réponse.','4. Reviens aux erreurs et à quelques exemples anciens lors de la séance suivante.','5. Dans l’application, termine les leçons et MCO puis passe le DS du module. Les DS utilisent le contenu des étapes du programme importé.','',
'La lecture des exemples est fournie en kana, parfois avec un repère en rōmaji au tout début. Les espaces dans la lecture facilitent la segmentation ; pour は, を et へ utilisés comme particules, le guide peut écrire la prononciation わ, お ou え. Ce guide de lecture ne remplace pas l’orthographe de la phrase. La ponctuation et les espaces pédagogiques ne constituent pas des mots supplémentaires.','',
'Les exercices demandent un modèle précis. En dehors de cette consigne, d’autres formulations peuvent être naturelles. La reconnaissance au clavier ne vérifie ni la prononciation ni le tracé manuscrit.','',
'## Plan du parcours','', '| Module | Leçons | MCO | Objectif |','|---|---:|---:|---|']
for i,m in enumerate(p['modules'],1):L.append(f"| {i} · {m['title']} | {len(m['lessons'])} | {len(m['mcos'])} | {m['subtitle']} |")

def esc(v):return str(v).replace('|','\\|').replace('\n','<br>')
for i,m in enumerate(p['modules'],1):
 L.extend(['',f"## Module {i} — {m['title']}",'',m['subtitle'],''])
 for j,u in enumerate(m['lessons'],1):
  L.extend([f"### {i}.{j} — {u['title']}",''])
  for s in u['sections']:
   L.extend([f"**{s['title']}**",''])
   for paragraph in s.get('paragraphs',[]):L.extend([paragraph,''])
   if s.get('examples'):
    L.extend(['| Japonais | Lecture | Sens |','|---|---|---|'])
    for e in s['examples']:L.append(f"| {esc(e['jp'])} | {esc(e['reading'])} | {esc(e['fr'])} |")
    L.append('')
   if s.get('note'):L.extend(['**À retenir :** '+s['note'],''])
  if u.get('table'):
   L.extend(['**Tableau de repérage**','','| Écriture / catégorie | Lecture / correspondance |','|---|---|'])
   for row in u['table']:L.append(f"| {esc(row[0])} | {esc(' · '.join(row[1:]))} |")
   L.append('')
  L.extend(['**Exercices — cherche avant de lire le corrigé**',''])
  for qi,q in enumerate(u['exercises'],1):
   L.append(f"{qi}. {q['prompt']}")
   if q['type']=='choice':
    options=q['choices'];offset=qi%len(options);options=options[offset:]+options[:offset]
    L.append('   Choix : '+' / '.join(options))
   elif q['type']=='order':
    tokens=q['tokens'];display=tokens[1:]+tokens[:1]
    L.append('   Éléments : '+' / '.join(display))
  L.extend(['','**Corrigé expliqué**',''])
  for qi,q in enumerate(u['exercises'],1):
   L.append(f"{qi}. **{q['answer']}** — {q['explanation']}")
   if q.get('alternatives'):L.append('   Alternatives admises pour cette consigne : '+', '.join(q['alternatives'])+'.')
  L.append('')
  if u.get('resources'):
   L.extend(['**Pour compléter**',''])
   for r in u['resources']:L.append(f"- [{r['title']}]({r['url']})")
   L.append('')
 L.extend(['### MCO du module','', 'Chaque liste est obligatoire dans le parcours. Lis les trois colonnes ensemble : écriture, lecture, sens.',''])
 for u in m['mcos']:
  L.extend([f"**{u['title']}**",'','| Écriture usuelle | Kana / lecture du mot | Sens |','|---|---|---|'])
  for w in u['words']:L.append(f"| {esc(w['writing'])} | {esc(w['reading'])} | {esc(w['meaning'])} |")
  L.append('')
  for s in u.get('sections',[]):
   L.extend([f"**{s['title']}**",''])
   for paragraph in s.get('paragraphs',[]):L.extend([paragraph,''])
   if s.get('examples'):
    L.extend(['| Exemple | Lecture | Sens |','|---|---|---|'])
    for e in s['examples']:L.append(f"| {esc(e['jp'])} | {esc(e['reading'])} | {esc(e['fr'])} |")
    L.append('')
  L.extend(['**Exercices du MCO**',''])
  for qi,q in enumerate(u.get('exercises',[]),1):
   L.append(f"{qi}. {q['prompt']}")
   if q['type']=='choice':
    options=q['choices'];offset=qi%len(options);options=options[offset:]+options[:offset]
    L.append('   Choix : '+' / '.join(options))
  L.extend(['','**Corrigé du MCO**',''])
  for qi,q in enumerate(u.get('exercises',[]),1):L.append(f"{qi}. **{q['answer']}** — {q['explanation']}")
  L.append('')
 L.extend(['**Avant le DS**','', 'Pour chaque leçon du module, formule son objectif avec tes mots, lis un exemple sans la traduction et explique une erreur corrigée. Dans les MCO, vérifie la lecture et le sens indépendamment de la place du mot dans la liste.',''])
L.extend(['## Référence des kanji des MCO','','Les lectures sont une sélection de référence, pas un dictionnaire exhaustif. Le point sépare les okurigana ; on ne le copie pas dans une phrase. Une case vide signifie qu’aucune lecture de cette famille n’est proposée ici.','', '| Kanji | Kun’yomi (hiragana) | On’yomi (katakana) |','|---|---|---|'])
reference=json.loads((R/'kanji-reference.json').read_text())
for k in reference['characters']:L.append(f"| {k['character']} | {esc('・'.join(k['kunyomi']) or '—')} | {esc('・'.join(k['onyomi']) or '—')} |")
L.extend(['','Données de lectures adaptées de [Kanji alive](https://github.com/kanjialive/kanji-data-media), révision `e1e24d39fc43e839948a8c7e99743b0994dedad5`, sous [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Adaptations : sélection des caractères du parcours, suppression des doublons de radical de lecture et mise en forme des okurigana. Pour 傘・撮・椅・鍵, les lectures ont été vérifiées dans [KanjiPedia](https://www.kanjipedia.jp/) ; aucune définition ou illustration n’est reproduite. Les explications, traductions, exemples et exercices français sont originaux.',''])
L.extend(['## Continuer après ce parcours','',
'Cette base n’épuise pas le niveau débutant. Une suite pourra traiter les expériences en たことがある, les obligations et l’absence d’obligation, les formes potentielles, les propositions relatives, les dons et réceptions, les conditionnels et des textes plus longs. Le JLPT demanderait en plus un travail d’écoute, de lecture et de kanji ciblé ; ce fichier ne prétend pas certifier un niveau.','',
'## Installer ou modifier les cours','',
'Dans Kotoba 0.3.3 : **Carnet → Mes cours → Importer des cours JSON** puis sélectionne `kotoba-cours-debutant.json`. Il remplace le programme actif après validation et confirmation. Les fiches modifiées et les DS concernés sont à revalider ; exporte le carnet et le programme actif si tu souhaites conserver un état antérieur. Kotoba 0.3.3 ajoute la prise en compte des exercices rédigés des MCO et des variantes de lecture ; les versions précédentes peuvent afficher les cours mais ne proposent pas ces exercices supplémentaires dans les MCO.','',
'Pour éditer : les données pédagogiques de référence sont dans le JSON. Après modification, `python content/verify_courses.py` vérifie les identifiants, les contraintes MCO et la cohérence technique des réponses ; `python content/export_coursebook.py` régénère ce livre. Ces contrôles ne remplacent pas une relecture linguistique.','',
'## Références complémentaires','',
'- [Cours de japonais ! — chaîne de Julien Fontanier](https://www.youtube.com/@coursdejaponais/videos)','- [Julien Fontanier — Le négatif des verbes japonais](https://www.youtube.com/watch?v=PGDXY-25PzY)','- [Julien Fontanier — Les classificateurs numéraux](https://www.youtube.com/watch?v=qqTNLCU4Xxk)','- [Japan Foundation — Irodori, programme Starter](https://www.irodori.jpf.go.jp/assets/data/starter/pdf/X_contents_en.pdf)','- [Japan Foundation — Irodori, programme Elementary 1](https://www.irodori.jpf.go.jp/assets/data/elementary01/pdf/Y_contents_en.pdf)','- [Japan Foundation — Irodori, programme Elementary 2](https://www.irodori.jpf.go.jp/assets/data/elementary02/pdf/Z_contents_en.pdf)',''])
(R/'Kotoba-cours-debutant.md').write_text('\n'.join(L))

# Focused vocabulary book is exported from the same canonical data as the full book.
book='\n'.join(L)
parts=['# Kotoba — MCO : cours de vocabulaire et lectures des kanji','',
'29 cours de vocabulaire, 230 entrées, dont 184 écrites avec des kanji ; 167 caractères distincts. Chaque MCO contient au maximum dix entrées. Étudie la lecture du mot et son sens, puis les références kun’yomi et on’yomi de ses caractères. Les emprunts et les expressions couramment écrits en kana gardent leur écriture naturelle.','',
'Les textes, exemples et exercices sont originaux. Les références de lectures proviennent des sources attribuées en fin de document. Dans Kotoba 0.3.3, importe le programme JSON depuis Carnet → Mes cours. Les dessins de l’atelier ne sont pas corrigés automatiquement.','']
for i,m in enumerate(p['modules'],1):
 start=book.index('### MCO du module',book.index(f"## Module {i} —"))
 end=book.index('**Avant le DS**',start)
 parts.extend([f"## Module {i} — {m['title']}",'',book[start:end]])
start=book.index('## Référence des kanji des MCO');end=book.index('## Continuer après ce parcours',start)
parts.append(book[start:end])
(R/'Kotoba-MCO-vocabulaire.md').write_text('\n'.join(parts))
