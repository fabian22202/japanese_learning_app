# Cours Kotoba — parcours débutant approfondi

Ce dossier contient les cours, indépendamment des sources de l’application.

- **kotoba-cours-debutant.json** : programme complet importable dans Kotoba 0.3.1.
- **Kotoba-cours-debutant.md** : cours lisible, exercices et corrigés expliqués.
- **verify_courses.py** : vérification du format, des contraintes MCO et de la cohérence technique des exercices.
- **export_coursebook.py** : régénération du livre depuis le JSON de référence.

Le parcours contient 12 modules et 50 leçons : les 25 premières fiches sont approfondies, 25 nouvelles leçons sont ajoutées. Il comprend 28 MCO, 220 entrées de vocabulaire, 203 exemples lus et traduits, 234 exercices rédigés et corrigés. Le moteur existant produit au total 2 498 variantes en comptant les exercices et le vocabulaire.

## Utiliser

Dans l’application : **Carnet → Mes cours → Importer des cours JSON**, puis choisir le programme. Le contenu actif est remplacé après confirmation ; aucune mise à jour de l’application n’est nécessaire. Les étapes modifiées et les DS concernés sont à revalider. Exporte le carnet et le programme actuel pour conserver l’état précédent.

## Modifier

Modifie le JSON, puis depuis la racine du dépôt :

```sh
python content/verify_courses.py
python content/export_coursebook.py
```

Le JSON est la source pédagogique. Le livre est un export. Les contrôles techniques ne vérifient pas à eux seuls la justesse grammaticale : relis les explications, les exemples, les alternatives admises et les distracteurs.

Le test `native/test/content_pack_test.dart` vérifie également ce pack avec le véritable importeur et le moteur Dart existants. Il ne modifie pas le fonctionnement de l’application.

Le livre donne les références complémentaires, notamment la chaîne de Julien Fontanier et les programmes Irodori de la Japan Foundation. Les textes et exercices sont originaux ; ce contenu ne prétend pas reproduire les vidéos ni certifier un niveau JLPT complet.
