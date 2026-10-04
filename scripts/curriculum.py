"""Progression complémentaire et données combinables, sans listes de questions écrites à la main."""
def enrich(modules, lesson, words):
 def d(*pairs): return [dict(jp=a,fr=b) for a,b in pairs]
 def frame(tokens,french,domains,focus,explanation): return dict(tokens=tokens.split('|'),french=french,domains=domains,focus=focus,explanation=explanation)
 def generated(id,title,paragraphs,frames):
  l=lesson(id,title,paragraphs,[]);l['generator']=dict(kind='frames',frames=frames);return l
 def mod(id,title,subtitle,symbol,color,lessons,mcos):return dict(id=id,title=title,subtitle=subtitle,symbol=symbol,color=color,lessons=lessons,mcos=mcos)
 roles=d(('がくせい','étudiant'),('せんせい','professeur'))
 nouns=d(('ほん','livre'),('かさ','parapluie'),('くつ','chaussures'),('カメラ','appareil photo'))
 places=d(('がっこう','école'),('いえ','maison'),('ホテル','hôtel'))
 for l in modules[0]['lessons'][:2]:l['generator']=dict(kind='kana')
 modules[0]['lessons'].append(generated('writing-context','Lire des mots, pas seulement des signes',[
 'Un son connu doit aussi être reconnu dans un mot. Les exercices mélangent maintenant lecture, reconnaissance et reconstruction.','Le petit や est différent du petit ゃ : きや contient deux syllabes, きゃ un son combiné. Même vigilance pour っ et つ.'],[
 frame('{word}','{word}',{'word':d(('ねこ','chat'),('いぬ','chien'),('かさ','parapluie'),('くつ','chaussures'),('カメラ','appareil photo'),('バス','bus'))},0,'Retrouve le mot dans son ensemble ; chaque kana contribue à sa lecture.')]))
 modules[1]['lessons'][0]['generator']=dict(kind='numbers',min=0,max=10)
 modules[1]['lessons'].insert(1,lesson('tens','Construire les nombres jusqu’à 99',[
 '11 se lit じゅういち : dix puis un. 20 se lit にじゅう : deux dizaines. 23 se lit にじゅうさん : deux dizaines puis trois.','Pour ces nombres sans compteur, nous utilisons よん, なな et きゅう. Les lectures des heures et des compteurs obéissent à d’autres règles, introduites plus tard.'],[]))
 modules[1]['lessons'][1]['generator']=dict(kind='numbers',min=11,max=99)
 modules[1]['lessons'][2]['generator']=dict(kind='kanji')
 modules[2]['title']='Construire sa première phrase'
 modules[2]['subtitle']='Se présenter, relier des noms et comprendre les rôles'
 modules[2]['lessons'][0]['generator']=dict(kind='frames',frames=[
 frame('わたし|は|{role}|です','Je suis {role}.',{'role':roles},1,'は marque le thème. La phrase nominale se termine ici par です.'),
 frame('わたし|も|{role}|です','Moi aussi, je suis {role}.',{'role':roles},1,'も ajoute le sens « aussi » ; elle remplace ici は.'),
 frame('わたし|の|{noun}','Mon objet : {noun}.',{'noun':nouns},1,'の relie le possesseur au nom.')])
 modules[2]['lessons'].insert(1,generated('questions-negative','Poser une question et dire non',[
 'か en fin de phrase transforme une phrase polie en question : がくせいですか = êtes-vous étudiant(e) ? Le sujet peut être omis quand il est évident.','Pour nier une phrase nominale, on emploie notamment ではありません. じゃありません est une variante plus courante à l’oral.','いいえ、がくせいではありません signifie « Non, je ne suis pas étudiant(e) ». Ce modèle concerne les noms, pas tous les verbes ni les adjectifs.'],[
 frame('{role}|です|か','Êtes-vous {role} ?',{'role':roles},2,'か termine une question polie.'),
 frame('わたし|は|{role}|ではありません','Je ne suis pas {role}.',{'role':roles},3,'La négation polie d’une phrase nominale est ici ではありません.')]))
 modules[2]['lessons'][-1]['generator']=dict(kind='frames',frames=[
 frame('{drink}|を|のみます','Je bois : {drink}.',{'drink':d(('みず','de l’eau'),('コーヒー','du café'))},1,'を marque l’objet bu.'),
 frame('{place}|に|いきます','Je vais à cet endroit : {place}.',{'place':places},1,'に marque ici la destination, tandis que le verbe reste à la fin.'),
 frame('{place}|で|べんきょうします','J’étudie à cet endroit : {place}.',{'place':d(('がっこう','école'),('いえ','maison'))},1,'で indique le lieu où l’action d’étudier se déroule.')])
 objects=d(('ほん','livre'),('かさ','parapluie'),('カメラ','appareil photo'),('くつ','chaussures'),('かばん','sac'))
 whereabouts=d(('ここ','ici'),('そこ','là, près de vous'),('あそこ','là-bas'))
 modules.append(mod('m4','Montrer & situer','Parler des objets, des lieux et de ce qui s’y trouve','こ','sage',[
 generated('demonstratives','これ・それ・あれ et この・その・あの',[
 'これ désigne une chose près de la personne qui parle ; それ près de l’interlocuteur ; あれ éloignée des deux. Ils remplacent un nom.','この, その et あの accompagnent obligatoirement un nom : このほん = ce livre-ci. Pour demander « lequel ? », utilise どれ ; devant un nom, どの.'],[
 frame('{demo}|は|{object}|です','{demo} est un objet : {object}.',{'demo':d(('これ','Cette chose près de moi'),('それ','Cette chose près de vous'),('あれ','Cette chose là-bas')),'object':objects},0,'これ・それ・あれ remplacent un nom et distinguent la distance.'),
 frame('{demo}|{object}','{object} : {demo}.',{'demo':d(('この','près de moi'),('その','près de vous'),('あの','là-bas')),'object':objects},0,'この・その・あの sont suivis du nom désigné.')]),
 generated('where','Où ? ここ・そこ・あそこ',[
 'ここ signifie ici, そこ là près de l’autre personne, あそこ là-bas. どこ demande où.','トイレはどこですか signifie « Où sont les toilettes ? ». Une réponse courte peut être そこです. Ces mots désignent un lieu, pas un objet.'],[
 frame('{place}|は|どこ|です|か','Où se trouve cet endroit : {place} ?',{'place':d(('トイレ','toilettes'),('ホテル','hôtel'),('えき','gare'),('がっこう','école'))},2,'どこ interroge sur un lieu ; か termine la question.'),
 frame('{place}|は|{where}|です','Cet endroit ({place}) est {where}.',{'place':d(('トイレ','toilettes'),('えき','gare')),'where':whereabouts},2,'ここ・そこ・あそこ situent un lieu par rapport aux personnes qui parlent.')]),
 generated('existence','Il y a : あります et います',[
 'あります sert ici à indiquer la présence d’une chose inanimée ; います celle d’une personne ou d’un animal.','いえにねこがいます = il y a un chat dans la maison. に marque le lieu d’existence et が introduit ce qui est présent. On n’utilise pas で pour ce lieu d’existence.'],[
 frame('{place}|に|{object}|が|あります','Il y a un objet ({object}) à cet endroit : {place}.',{'place':d(('いえ','maison'),('へや','chambre')),'object':objects},4,'Un objet inanimé est présent : あります. に marque le lieu et が ce qui existe.'),
 frame('{place}|に|{being}|が|います','Il y a {being} à cet endroit : {place}.',{'place':d(('いえ','maison'),('こうえん','parc')),'being':d(('ねこ','un chat'),('いぬ','un chien'),('ともだち','un ami'))},4,'Pour un animal ou une personne présents, on utilise います.')])],[
 words('m4-objects','Objets & repères',[('かばん','かばん','sac'),('つくえ','つくえ','bureau / table'),('いす','いす','chaise'),('へや','へや','chambre'),('まど','まど','fenêtre'),('でんわ','でんわ','téléphone'),('ドア','ドア','porte'),('とけい','とけい','horloge / montre')]),
 words('m4-places','Se repérer',[('えき','えき','gare'),('トイレ','トイレ','toilettes'),('こうえん','こうえん','parc'),('みせ','みせ','magasin'),('びょういん','びょういん','hôpital'),('としょかん','としょかん','bibliothèque'),('ここ','ここ','ici'),('そこ','そこ','là près de vous'),('あそこ','あそこ','là-bas'),('どこ','どこ','où')])]))
 actions=d(('ほんをよみ','lis un livre'),('みずをのみ','bois de l’eau'),('パンをたべ','mange du pain'),('べんきょうし','étudie'))
 # French person and tense are expressed by complete compatible fragments, not arbitrary word substitutions.
 modules.append(mod('m5','Actions & moments','Décrire sa journée avec les formes polies','時','blue',[
 generated('polite-verbs','ます et ません : agir ou ne pas agir',[
 'Une forme polie comme よみます décrit selon le contexte une habitude, le présent ou le futur. Pour la nier, remplace ます par ません : よみません.','Pour l’instant, les radicaux sont donnés. On ne fabrique pas le radical de tous les verbes en supprimant simplement leur dernier kana : les groupes de verbes demandent une leçon dédiée.'],[
 frame('{action}|ます','Je {action}.',{'action':actions},1,'ます est la terminaison polie affirmative non passée.'),
 frame('{action}|ません','Je ne fais pas cette action : {action}.',{'action':actions},1,'ません est la terminaison polie négative non passée.')]),
 generated('time','Quand ? 今日・明日, puis les heures',[
 'きょう signifie aujourd’hui, あした demain et きのう hier. Les mots relatifs comme きょう ne prennent généralement pas に dans ces phrases.','Une heure précise peut prendre に : しちじにおきます = je me lève à sept heures. Retiens les lectures particulières よじ (4 h), しちじ (7 h), くじ (9 h).','Une activité régulière : まいにちべんきょうします = j’étudie chaque jour. Ces exemples n’utilisent pas encore les minutes ni les dates.'],[
 frame('{day}|べんきょうします','J’étudie : {day}.',{'day':d(('きょう','aujourd’hui'),('あした','demain'),('まいにち','chaque jour'))},0,'Un repère relatif comme きょう se place ici sans に.'),
 frame('{hour}|に|おきます','Je me lève à {hour}.',{'hour':d(('ろくじ','six heures'),('しちじ','sept heures'),('はちじ','huit heures'),('くじ','neuf heures'))},1,'Une heure précise est suivie ici de に.')]),
 generated('transport','Aller quelque part, avec quelqu’un',[
 'に ou へ peut indiquer une destination avec いきます. La particule へ se prononce e.','で peut indiquer un moyen de transport : バスでいきます = j’y vais en bus. と accompagne une personne : ともだちといきます = j’y vais avec un ami.','Les exercices séparent les emplois de で (lieu d’action ou moyen), pour apprendre à les lire dans leur contexte.'],[
 frame('{vehicle}|で|{place}|に|いきます','Je vais à cet endroit ({place}) en {vehicle}.',{'vehicle':d(('バス','bus'),('タクシー','taxi'),('でんしゃ','train')),'place':d(('えき','gare'),('がっこう','école'),('みせ','magasin'))},1,'で marque le moyen de transport ; に marque la destination.'),
 frame('{person}|と|{place}|に|いきます','Je vais à cet endroit ({place}) avec {person}.',{'person':d(('ともだち','un ami'),('かぞく','ma famille')),'place':d(('こうえん','parc'),('みせ','magasin'))},1,'と marque ici la personne qui accompagne.')])],[
 words('m5-days','Le temps',[('きょう','きょう','aujourd’hui'),('あした','あした','demain'),('きのう','きのう','hier'),('まいにち','まいにち','chaque jour'),('あさ','あさ','matin'),('ひる','ひる','midi / journée'),('よる','よる','soir / nuit'),('いま','いま','maintenant')]),
 words('m5-day-actions','La journée',[('おきます','おきます','se lever (forme polie)'),('ねます','ねます','dormir (forme polie)'),('はたらきます','はたらきます','travailler (forme polie)'),('かえります','かえります','rentrer (forme polie)'),('でんしゃ','でんしゃ','train'),('かぞく','かぞく','famille'),('ろくじ','ろくじ','six heures'),('しちじ','しちじ','sept heures'),('はちじ','はちじ','huit heures'),('くじ','くじ','neuf heures')])]))
 i_adj=d(('おおきい','grand'),('ちいさい','petit'),('あたらしい','neuf'),('ふるい','ancien'))
 na_adj=d(('しずか','calme'),('きれい','propre / joli'),('べんり','pratique'))
 modules.append(mod('m6','Décrire & exprimer ses goûts','Adjectifs en い et な, préférences et intensité','好','coral',[
 generated('adjectives','Qualifier un nom : い ou な ?',[
 'Un adjectif en い précède directement un nom : おおきいかばん = un grand sac. Un adjectif en な utilise な devant un nom : しずかなへや = une chambre calme.','Attention : la seule apparence du mot ne suffit pas. きれい se termine graphiquement par い mais appartient au groupe en な.','En fin de phrase polie : このへやはしずかです. On n’ajoute pas な juste avant です.'],[
 frame('{adj}|{noun}','Objet {noun} ; qualité : {adj}.',{'adj':i_adj,'noun':d(('かばん','sac'),('いえ','maison'),('くつ','chaussures'))},0,'Un adjectif en い accompagne directement le nom.'),
 frame('{adj}|な|{noun}','{noun} ; qualité : {adj}.',{'adj':na_adj,'noun':d(('へや','chambre'),('みせ','magasin'))},1,'Un adjectif en な nécessite な devant le nom, même pour きれい.')]),
 generated('likes','すき・きらい : dire ce que l’on aime',[
 'すき signifie aimé / apprécié et se comporte comme un adjectif en な. わたしはコーヒーがすきです = j’aime le café. L’objet de la préférence est marqué ici par が.','きらい exprime une aversion. Il est souvent plus doux de dire あまりすきではありません : je n’aime pas beaucoup.','とても renforce une qualité positive : とてもすきです = j’aime beaucoup. Nous n’utilisons pas とても avec toutes les formes de négation.'],[
 frame('わたし|は|{thing}|が|すき|です','J’aime {thing}.',{'thing':d(('コーヒー','le café'),('ねこ','les chats'),('おんがく','la musique'),('えいが','les films'),('にほんご','le japonais'))},3,'Avec すき, が marque ici ce qui est aimé.'),
 frame('わたし|は|{thing}|が|とても|すき|です','J’aime beaucoup {thing}.',{'thing':d(('おんがく','la musique'),('えいが','les films'),('にほんご','le japonais'))},4,'とても augmente l’intensité de la préférence.')]),
 generated('negative-adjectives','Nier une description',[
 'Pour nier un adjectif en い, on remplace le dernier い par くない : おおきい → おおきくない. Dans ces phrases polies, on ajoute です.','Pour un adjectif en な : しずかではありません. N’applique pas la transformation en くない aux adjectifs en な.','いい (bon) est irrégulier : sa négation est よくない. Cette exception est travaillée explicitement.'],[
 frame('{noun}|は|{negative}|です','{noun} : {negative}.',{'noun':d(('かばん','Le sac'),('いえ','La maison')),'negative':d(('おおきくない','pas grand(e)'),('ちいさくない','pas petit(e)'),('あたらしくない','pas neuf / neuve'))},2,'Adjectif en い : remplacer い par くない, puis ajouter です pour cette forme polie.'),
 frame('{noun}|は|{adj}|ではありません','{noun} n’est pas {adj}.',{'noun':d(('へや','La chambre'),('みせ','Le magasin')),'adj':na_adj},3,'Adjectif en な : utiliser ici ではありません.')])],[
 words('m6-description','Décrire',[('おおきい','おおきい','grand'),('ちいさい','ちいさい','petit'),('あたらしい','あたらしい','neuf'),('ふるい','ふるい','ancien'),('しずか','しずか','calme'),('きれい','きれい','propre / joli'),('べんり','べんり','pratique'),('いい','いい','bon')]),
 words('m6-tastes','Goûts & loisirs',[('すき','すき','aimé / apprécié'),('きらい','きらい','détesté'),('とても','とても','très'),('あまり','あまり','pas très (avec négation)'),('おんがく','おんがく','musique'),('えいが','えいが','film'),('にほんご','にほんご','langue japonaise'),('ゲーム','ゲーム','jeu vidéo')])]))
 modules.append(mod('m7','Raconter & proposer','Passé poli, invitations et demandes simples','話','sage',[
 generated('past','ます → ました : raconter hier',[
 'Le passé poli affirmatif remplace ます par ました. よみます → よみました. La négation passée utilise ませんでした.','きのうほんをよみました = hier, j’ai lu un livre. Le mot きのう situe la phrase dans le passé.','Pour une phrase nominale, です devient でした. Ne remplace pas directement です par ました.'],[
 frame('きのう|{action}|ました','Hier, action réalisée : {action}.',{'action':actions},2,'Le radical est conservé ; ました marque le passé poli affirmatif.'),
 frame('きのう|{action}|ませんでした','Hier, action non réalisée : {action}.',{'action':actions},2,'ませんでした est la forme polie négative passée.')]),
 generated('invitations','ませんか et ましょう',[
 'ませんか sert à proposer une activité : いっしょにたべませんか = voulez-vous manger ensemble ? Malgré sa forme négative, cette tournure fonctionne comme une invitation.','ましょう propose de faire quelque chose ensemble : いきましょう = allons-y.','Les radicaux sont donnés pour concentrer l’exercice sur le choix de la terminaison.'],[
 frame('いっしょに|{action}|ません|か','Invitation à faire ensemble cette action : {action}.',{'action':actions},2,'ませんか est une invitation formulée comme une question.'),
 frame('いっしょに|{action}|ましょう','Proposition : faisons ensemble cette action ({action}).',{'action':actions},2,'ましょう exprime ici une proposition d’action commune.')]),
 generated('requests','Une première demande : てください',[
 'La forme en て suivie de ください permet de formuler une demande : みてください = regardez, s’il vous plaît.','Les formes en て ont différentes règles selon les verbes. Elles sont données dans cette leçon : みて, たべて, のんで, よんで. Une future leçon expliquera leurs groupes et leur formation.','Ne fabrique pas une forme en て à partir de ます par une simple substitution : のみます donne のんで, pas のみて.'],[
 frame('{verb}|ください','Demande polie : {verb}.',{'verb':d(('みて','regardez'),('たべて','mangez'),('のんで','buvez'),('よんで','lisez'))},1,'La forme en て fournie est suivie de ください pour exprimer une demande.')])],[
 words('m7-social','Ensemble',[('いっしょに','いっしょに','ensemble'),('しゅうまつ','しゅうまつ','week-end'),('やすみ','やすみ','repos / congé'),('りょこう','りょこう','voyage'),('しゃしん','しゃしん','photo'),('さんぽ','さんぽ','promenade'),('あそびます','あそびます','jouer (forme polie)'),('あいます','あいます','rencontrer (forme polie)')]),
 words('m7-requests','Demandes & réponses',[('ください','ください','s’il vous plaît / donnez-moi'),('みて','みて','regarder (forme en te)'),('たべて','たべて','manger (forme en te)'),('のんで','のんで','boire (forme en te)'),('よんで','よんで','lire (forme en te)'),('はい','はい','oui'),('いいえ','いいえ','non'),('すみません','すみません','excusez-moi')])]))
 modules.append(mod('m8','Le japonais en situation','Commander, demander son chemin et comprendre une réponse','旅','blue',[
 generated('ordering','Commander quelque chose',[
 'Au restaurant, un nom suivi de をください permet de demander un objet ou une consommation : みずをください = de l’eau, s’il vous plaît.','これはいくらですか demande le prix de cette chose. Les compteurs et quantités détaillées seront étudiés ensuite.','Les situations de ce module réutilisent les structures déjà vues. Cherche le sens avant de lire la correction.'],[
 frame('{food}|を|ください','Commande : {food}, s’il vous plaît.',{'food':d(('みず','de l’eau'),('コーヒー','un café'),('おちゃ','du thé'),('パン','du pain'),('ごはん','du riz'))},1,'を marque ici l’objet demandé ; ください exprime la demande polie.'),
 frame('{demo}|は|いくら|です|か','Quel est le prix de {demo} ?',{'demo':d(('これ','cette chose près de moi'),('それ','cette chose près de vous'),('あれ','cette chose là-bas'))},2,'いくら demande le prix ; か termine la question.')]),
 generated('directions','Demander son chemin',[
 'Réutilise どこですか pour demander un lieu. Ajoute すみません avant la demande pour attirer poliment l’attention.','Un nom de lieu suivi de にいきます indique une destination. Un moyen de transport suivi de で précise comment tu y vas.','Ne cherche pas à traduire chaque mot séparément : identifie le lieu, la particule et le verbe.'],[
 frame('すみません|{place}|は|どこ|です|か','Excusez-moi, où se trouve cet endroit : {place} ?',{'place':d(('えき','gare'),('トイレ','toilettes'),('びょういん','hôpital'),('みせ','magasin'))},3,'どこ interroge sur un lieu, après le thème marqué par は.'),
 frame('{vehicle}|で|{place}|に|いきます','Je vais à cet endroit ({place}) en {vehicle}.',{'vehicle':d(('バス','bus'),('タクシー','taxi'),('でんしゃ','train')),'place':d(('えき','gare'),('ホテル','hôtel'),('びょういん','hôpital'))},3,'に indique la destination ; で indique le moyen de transport.')]),
 generated('dialogues','Comprendre de petits échanges',[
 'Une réponse courte reprend souvent seulement l’information demandée. À une question en どこ, on répond par un lieu ; à une question en いくら, par un prix.','いいえ n’est pas à lui seul une phrase négative : la terminaison qui suit indique ce qu’on nie.','Les exercices mélangent maintenant les formes étudiées pour travailler la compréhension et la construction.'],[
 frame('はい|{thing}|が|すき|です','Oui, j’aime {thing}.',{'thing':d(('コーヒー','le café'),('おちゃ','le thé'),('にほんご','le japonais'))},2,'が introduit ici ce qui est aimé ; すきです exprime la préférence.'),
 frame('いいえ|{role}|ではありません','Non, je ne suis pas {role}.',{'role':roles},2,'La réponse négative utilise ici ではありません pour nier un nom.')])],[
 words('m8-food','Au café',[('おちゃ','おちゃ','thé'),('ごはん','ごはん','riz cuit / repas'),('さかな','さかな','poisson'),('にく','にく','viande'),('やさい','やさい','légumes'),('くだもの','くだもの','fruit'),('メニュー','メニュー','menu'),('おいしい','おいしい','délicieux')]),
 words('m8-travel','En voyage',[('くうこう','くうこう','aéroport'),('きっぷ','きっぷ','billet de transport'),('ちず','ちず','carte géographique'),('いくら','いくら','combien (prix)'),('えん','えん','yen'),('みぎ','みぎ','droite'),('ひだり','ひだり','gauche'),('まっすぐ','まっすぐ','tout droit')])]))
 # Expand phonetic reading data (dakuten, handakuten, yōon) independently of exercise forms.
 sounds=modules[0]['lessons'][2]
 accented=list(zip(list('がぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ'),
 'ga gi gu ge go za ji zu ze zo da ji zu de do ba bi bu be bo pa pi pu pe po'.split()))
 combined=[(base+small,roman+vowel) for base,roman in [('き','ky'),('ぎ','gy'),('し','sh'),('じ','j'),('ち','ch'),('に','ny'),('ひ','hy'),('び','by'),('ぴ','py'),('み','my'),('り','ry')] for small,vowel in [('ゃ','a'),('ゅ','u'),('ょ','o')]]
 sounds['table']=accented+combined+[('きって','kitte'),('コーヒー','koohii'),('おかあさん','okaasan'),('がっこう','gakkou'),('ケーキ','keeki')]
 sounds['generator']=dict(kind='kana')
 # Natural French prompts remain aligned with compatible radicals and tense.
 by_id={l['id']:l for m in modules for l in m['lessons']}
 negative=d(('ほんをよみ','Je ne lis pas de livre.'),('みずをのみ','Je ne bois pas d’eau.'),('パンをたべ','Je ne mange pas de pain.'),('べんきょうし','Je n’étudie pas.'))
 f=by_id['polite-verbs']['generator']['frames'][1];f['french']='{action}';f['domains']['action']=negative
 past=d(('ほんをよみ','Hier, j’ai lu un livre.'),('みずをのみ','Hier, j’ai bu de l’eau.'),('パンをたべ','Hier, j’ai mangé du pain.'),('べんきょうし','Hier, j’ai étudié.'))
 past_neg=d(('ほんをよみ','Hier, je n’ai pas lu de livre.'),('みずをのみ','Hier, je n’ai pas bu d’eau.'),('パンをたべ','Hier, je n’ai pas mangé de pain.'),('べんきょうし','Hier, je n’ai pas étudié.'))
 for f,domain in zip(by_id['past']['generator']['frames'],[past,past_neg]):f['french']='{action}';f['domains']['action']=domain
 invites=d(('ほんをよみ','Voulez-vous lire un livre ensemble ?'),('みずをのみ','Voulez-vous boire de l’eau ensemble ?'),('パンをたべ','Voulez-vous manger du pain ensemble ?'),('べんきょうし','Voulez-vous étudier ensemble ?'))
 proposals=d(('ほんをよみ','Lisons un livre ensemble.'),('みずをのみ','Buvons de l’eau ensemble.'),('パンをたべ','Mangeons du pain ensemble.'),('べんきょうし','Étudions ensemble.'))
 for f,domain in zip(by_id['invitations']['generator']['frames'],[invites,proposals]):f['french']='{action}';f['domains']['action']=domain
 # Keep generated instructions grammatical in French as well as Japanese.
 f=by_id['topic']['generator']['frames'][2];f['french']='{noun}';f['domains']['noun']=d(('ほん','Mon livre'),('かさ','Mon parapluie'),('くつ','Mes chaussures'),('カメラ','Mon appareil photo'))
 frames=by_id['action']['generator']['frames'];frames[0]['french']='Je bois {drink}.'
 frames[1]['french']='Je vais {place}.';frames[1]['domains']['place']=d(('がっこう','à l’école'),('いえ','à la maison'),('ホテル','à l’hôtel'))
 frames[2]['french']='J’étudie {place}.';frames[2]['domains']['place']=d(('がっこう','à l’école'),('いえ','à la maison'))
 f=by_id['demonstratives']['generator']['frames'][0];f['french']='{demo} est {object}.';f['domains']['object']=d(('ほん','un livre'),('かさ','un parapluie'),('カメラ','un appareil photo'),('くつ','des chaussures'),('かばん','un sac'))
 fs=by_id['existence']['generator']['frames'];fs[0]['french']='Il y a {object} {place}.';fs[0]['domains']['object']=d(('ほん','un livre'),('かさ','un parapluie'),('カメラ','un appareil photo'),('くつ','des chaussures'),('かばん','un sac'));fs[0]['domains']['place']=d(('いえ','dans la maison'),('へや','dans la chambre'))
 fs[1]['french']='Il y a {being} {place}.';fs[1]['domains']['place']=d(('いえ','dans la maison'),('こうえん','dans le parc'))
 fs=by_id['transport']['generator']['frames'];fs[0]['french']='Je vais {place} en {vehicle}.';fs[0]['domains']['place']=d(('えき','à la gare'),('がっこう','à l’école'),('みせ','au magasin'));fs[1]['french']='Je vais {place} avec {person}.';fs[1]['domains']['place']=d(('こうえん','au parc'),('みせ','au magasin'))
 fs=by_id['adjectives']['generator']['frames'];fs[0]['french']='Un {noun} {adj}.';fs[0]['domains']['noun']=d(('かばん','sac'),('ほん','livre'),('カメラ','appareil photo'))
 fs[1]['french']='Un {noun} {adj}.';fs[1]['domains']['noun']=d(('こうえん','parc'),('みせ','magasin'));fs[1]['domains']['adj']=d(('しずか','calme'),('きれい','propre'),('べんり','pratique'))
 fs=by_id['negative-adjectives']['generator']['frames'];fs[0]['french']='{noun} n’est {negative}.';fs[0]['domains']['noun']=d(('かばん','Le sac'),('ほん','Le livre'));fs[0]['domains']['negative']=d(('おおきくない','pas grand'),('ちいさくない','pas petit'),('あたらしくない','pas neuf'))
 f=by_id['requests']['generator']['frames'][0];f['french']='{verb}, s’il vous plaît.'
 # Resource mappings are used only when the channel/course identity was found.
 by_id['demonstratives']['resources']=[dict(title='Les préfixes démonstratifs こ・そ・あ・ど',url='https://www.youtube.com/watch?v=-ML1OqJxCz8')]
 by_id['where']['resources']=by_id['demonstratives']['resources']
 by_id['topic']['resources']=[dict(title='La particule は',url='https://www.youtube.com/watch?v=z9dU8wwFEEs'),dict(title='La particule の',url='https://www.youtube.com/watch?v=LDevjw4zit0')]
 for m in modules:
  for l in m['lessons']:
   l.setdefault('resources',[dict(title=l['title'] if l.get('video') else 'Explorer les cours de japonais de Julien Fontanier',url=l.get('video') or 'https://www.youtube.com/@coursdejaponais/videos')])
 return modules
