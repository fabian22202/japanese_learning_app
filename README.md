# Kotoba — japanese_learning_app · 0.3.1

La version principale est désormais une **application Flutter en Dart pour Android et Windows**, sans WebView. Elle reprend le parcours, les exercices variés, le clavier japonais et la charte visuelle.

[Instructions de compilation et installation](native/README.md) · [Télécharger les builds dans GitHub Actions](https://github.com/fabian22202/japanese_learning_app/actions/workflows/native.yml)

[Rédiger et importer des cours JSON](native/COURS.md), sans recompilation.

Les sources de l’application sont dans `native/`. La première version web est conservée ci-dessous comme prototype ; son carnet JSON peut être importé dans l’application native.

---

# Prototype web · 0.2

Application de japonais en français, conçue d’abord pour le téléphone et utilisable sur PC. PWA installable, parcours guidé et révision espacée. Les fiches, exercices et cartes fonctionnent hors ligne après une première ouverture ; les cours vidéo nécessitent Internet.

## Démarrer

Python 3 pour le serveur local ; Node.js 20+ pour les tests. Aucun paquet requis pour exécuter l’application.

```sh
python3 -m http.server 8080
```

Ouvrir http://localhost:8080. Sous Windows : `py -m http.server 8080`. Ne pas ouvrir `index.html` en `file://`, car les modules JavaScript nécessitent un serveur HTTP.

Sur Android et PC, utiliser « Installer l’application » dans Chrome/Edge. Sur iPhone : Safari → Partager → Sur l’écran d’accueil. L’installation sur téléphone nécessite un hébergement HTTPS. Ce dépôt ne fournit pas encore d’APK ni de paquet iOS/Windows.

## Ce qui change en 0.2

Les trois modules de départ étaient des exemples de structure, pas un programme complet. Le parcours s’étend à **8 modules, 25 leçons et 16 MCO**, avec 124 entrées de vocabulaire réparties en groupes de dix mots maximum. Certains mots reviennent dans un autre contexte. Les dix mots en kanji du module 2 restent une introduction limitée ; les autres notions s’appuient largement sur les kana.

| Module | Objectif et notions |
| --- | --- |
| 1 · Hiragana & katakana | Syllabaires, accents, combinaisons, pauses, allongements et lecture de mots |
| 2 · Nombres & kanji | Arabiasūji, composition des nombres jusqu’à 99, premiers mots en kanji |
| 3 · Première phrase | Thème, possession, « aussi », questions, négation nominale, objets et lieux d’action |
| 4 · Montrer & situer | これ/それ/あれ, この/その/あの, lieux, あります et います |
| 5 · Actions & moments | ます/ません, repères temporels, heures, transport et accompagnement |
| 6 · Descriptions & goûts | Adjectifs en い et な, négation, すき, intensité |
| 7 · Raconter & proposer | Passé poli, invitations, propositions, première approche des demandes en てください |
| 8 · Situations | Commander, demander un prix ou un lieu, comprendre des échanges simples |

Les radicaux verbaux et les formes en て sont fournis avant une étude complète des groupes de verbes. Le parcours ne prétend pas couvrir tout le niveau N5. Chaque fiche propose des explications, des exemples et, pour la grammaire combinable, un lexique consultable.

## Un moteur de défis, plutôt qu’une petite liste fixe

`src/engine.js` produit les exercices à partir des données linguistiques des leçons :

- Kana : lecture écrite, reconnaissance du caractère, choix du son. Les graphies qui ont la même lecture ne sont pas présentées comme deux réponses concurrentes correctes.
- MCO : rappel du mot depuis le français, choix du sens, reconnaissance de l’écriture et reconstruction du mot / lecture des kanji.
- Nombres : les lectures de 0 à 99 sont composées par règle, puis travaillées dans plusieurs directions.
- Grammaire : des domaines de mots compatibles sont combinés dans des structures contrôlées ; chaque contexte donne une phrase à compléter, une phrase à reconstruire et une question de compréhension.

Le corpus produit plus de **1 800 variantes** de défis, incluant plusieurs tâches sur une même notion. Ce nombre mesure des variantes de questions, pas autant de notions distinctes. Les phrases restent issues de règles et de données contrôlées ; aucune génération libre par IA n’est utilisée.

Les séances mélangent les modalités. Les 80 derniers identifiants sont mémorisés pour éviter la répétition immédiate quand d’autres variantes restent disponibles. Les erreurs augmentent la priorité des notions ; les réussites réduisent progressivement cette priorité. Les distracteurs et les tuiles sont mélangés. La répétition reste nécessaire pour mémoriser, mais elle ne se limite plus au même petit quiz dans un ordre différent.

## Clavier japonais intégré

Les défis de saisie en kana/kanji disposent d’un clavier hiragana/katakana, avec petits kana, dakuten, handakuten, allongement, effacement et remplacement de la sélection. Un onglet kanji propose les caractères du vocabulaire déjà accessible dans le parcours. Il fonctionne aussi dans les DS et hors ligne, sans sélectionner les touches à partir de la réponse attendue. Masquer le clavier permet d’utiliser celui de l’appareil. Les exercices de rōmaji, les QCM et les tuiles conservent leur mode de saisie propre.

## Progression & révision

- Séances de dix défis maximum pour les leçons. Les sons doivent être réussis au moins une fois pour valider leur fiche ; les autres leçons demandent 80 %.
- Un MCO teste chacun de ses mots une fois par séance, avec une forme de défi variable. Objectif : 80 %.
- DS disponible après les leçons et les MCO. Chaque unité est représentée ; aucun indice/correction intermédiaire. Corrections détaillées à la fin.
- 80 % au DS ouvre le module suivant. Les meilleurs scores et acquis de 0.1 sont conservés ; les nouvelles fiches restent à faire. Une mauvaise nouvelle tentative ne referme pas un module acquis.
- Les mots des MCO terminés alimentent une révision espacée. « À revoir » : dix minutes ; les autres notes espacent les rappels. Maximum vingt cartes par séance.
- Sauvegarde locale, objectif quotidien, série de jours d’activité, export/import JSON. L’historique des exercices fait partie du carnet.

## Ressource pédagogique de base

Référence choisie par le projet : **[Cours de japonais !, Julien Fontanier](https://www.youtube.com/@coursdejaponais/videos)**. La page de vidéos est disponible depuis les fiches ; des liens précis sont associés lorsque la correspondance est identifiée :

- [Présentation des hiragana](https://www.youtube.com/watch?v=_PCJnq_-oT8)
- [Les nombres japonais](https://www.youtube.com/watch?v=-a8A0Bf3sxo)
- [La particule は](https://www.youtube.com/watch?v=z9dU8wwFEEs)
- [La particule の](https://www.youtube.com/watch?v=LDevjw4zit0)
- [Les préfixes démonstratifs こ・そ・あ・ど](https://www.youtube.com/watch?v=-ML1OqJxCz8)

Les fiches et exercices sont originaux et ne reproduisent pas les supports officiels. Le découpage est propre à Kotoba : il ne prétend pas reproduire l’ordre intégral de la chaîne. Projet indépendant, sans affiliation. Le site Irodori de la Fondation du Japon a également été consulté pour vérifier la cohérence des thèmes du quotidien : https://www.irodori.jpf.go.jp/en/starter/pdf.html. Aucune de ses illustrations n’est utilisée.

La charte papier, corail et sauge de 0.1 est conservée. Une police japonaise locale assure l’affichage des caractères du parcours hors ligne, sous SIL Open Font License (`fonts/OFL.txt`). Les logos et illustrations de la chaîne ne sont pas repris.

## Architecture

- `scripts/content.py` + `scripts/curriculum.py` : sources des contenus, génération avec `python3 scripts/content.py`.
- `src/content.js` : contenus et domaines linguistiques, séparés de l’interface.
- `src/engine.js` : génération, sélection des modalités, historique et adaptation aux erreurs.
- `src/core.js` : correction, prérequis, DS, calendrier de révision et sauvegardes.
- `src/app.js` / `src/style.css` : fiches, séances, choix, tuiles et interface responsive.
- `sw.js` : cache hors ligne, version 3. Une mise à jour s’active après fermeture des anciennes fenêtres de l’application.

Lorsqu’on ajoute des caractères japonais, compléter le sous-ensemble de police embarqué. Les données du carnet restent dans `localStorage` : effacer les données du navigateur efface la progression. Exporter pour la conserver ou la transférer. Pas encore de comptes, synchronisation automatique, reconnaissance de tracé ou notation de prononciation. L’écoute utilise la synthèse vocale de l’appareil et nécessite une voix japonaise installée.

## Vérifier

```sh
npm test
npm run check
```

Les 19 tests couvrent les contraintes du contenu, la progression, les DS, la cohérence des exercices générés, les variantes phonétiques, la composition des nombres, l’adaptation aux erreurs, l’historique anti-répétition et l’édition via le clavier japonais.

Contrôle navigateur facultatif, avec Playwright et Chromium :

```sh
npm install --no-save playwright@1.63.0
npx playwright install chromium
# Avec le serveur lancé sur 8080 :
node scripts/browser-check.mjs
```

Le contrôle vérifie les formats mobile/PC, les exercices de MCO, un DS complet, la révision, la progression, les tuiles et choix de grammaire, la persistance et le mode hors ligne. Les captures sont écrites dans le dossier temporaire du système. GitHub Actions exécute les contrôles métier et navigateur.

## Suite pédagogique

Étendre les groupes de verbes et la formation des formes en て ; ajouter les compteurs, les dates et les comparaisons ; enrichir les dialogues contextualisés et l’écoute. Faire relire le contenu avant une diffusion pédagogique plus large.
