# Cours Kotoba — parcours débutant approfondi

Ce dossier contient les cours, indépendamment des sources de l’application.

- **kotoba-cours-debutant.json** : programme complet fourni dans Kotoba 0.3.4, également importable.
- **Kotoba-cours-debutant.md** : cours lisible, exercices et corrigés expliqués.
- **verify_courses.py** : vérification du format, des contraintes MCO et de la cohérence technique des exercices.
- **export_coursebook.py** : régénération du livre depuis le JSON de référence.

Le parcours contient 12 modules et 51 leçons : les 25 premières fiches sont approfondies, 26 nouvelles leçons sont ajoutées. Il comprend 29 MCO, 230 entrées de vocabulaire, 282 exemples lus et traduits, 497 exercices rédigés et corrigés. Le moteur existant produit au total 2 867 variantes en comptant les exercices et le vocabulaire.

## Utiliser

Kotoba 0.3.4 embarque directement ce programme. Les anciennes versions fournies intactes sont mises à jour automatiquement ; les cours personnalisés sont conservés. Pour importer un programme modifié : **Carnet → Mes cours → Importer des cours JSON**. Le contenu actif est remplacé après confirmation ; Kotoba 0.3.3 est nécessaire pour les exercices rédigés des MCO et les variantes de lecture. Les étapes modifiées et les DS concernés sont à revalider. Exporte le carnet et le programme actuel pour conserver l’état précédent.

## Modifier

Modifie le JSON, puis depuis la racine du dépôt :

```sh
python content/verify_courses.py
python content/export_coursebook.py
```

Le JSON est la source pédagogique. Le livre est un export. Les contrôles techniques ne vérifient pas à eux seuls la justesse grammaticale : relis les explications, les exemples, les alternatives admises et les distracteurs.

Le test `native/test/content_pack_test.dart` vérifie également ce pack avec le véritable importeur et le moteur Dart existants. Il ne modifie pas le fonctionnement de l’application.

Le livre donne les références complémentaires, notamment la chaîne de Julien Fontanier et les programmes Irodori de la Japan Foundation. Les textes et exercices sont originaux ; ce contenu ne prétend pas reproduire les vidéos ni certifier un niveau JLPT complet.

## MCO et kanji

Les 29 MCO sont des cours de vocabulaire avec sens, écriture usuelle, kana, repères kun’yomi/on’yomi, exemples et exercices. 184 entrées contiennent des kanji, pour 167 caractères distincts ; chaque MCO reste limité à dix entrées. Les mots courants en kana ne sont pas artificiellement convertis en kanji.

`kanji-reference.json` rassemble les références des caractères, avec provenance. Les données Kanji alive sont adaptées sous CC BY 4.0 ; les quatre caractères absents de cette référence ont été vérifiés dans KanjiPedia. Voir les attributions du livre et du JSON.

Une fiche de mot possède `kana`, `kanji` (caractère, `kunyomi`, `onyomi`, source) et `readingAlternatives`. Les champs `usage` et `kanji`, avec leurs exemples, sont affichés directement dans la fiche du mot ; les sections présentent le contexte et les explications communes au MCO. La lecture du mot ne se déduit pas automatiquement des lectures de chaque caractère.

Les fiches de mots des MCO 1 à 8, comme celles de la suite, affichent leurs références directement avec des exemples de vocabulaire pour kun et on. `kanji-reference.json` comporte 312 illustrations de lecture. Elles n’ajoutent pas de cartes obligatoires aux dix entrées maximales du MCO. Pour modifier l’affichage d’une fiche, édite `usage` et les données `kanji` du mot ; l’application les affiche directement.
