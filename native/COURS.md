# Écrire et installer tes cours

Dans l’application : **Carnet → Mes cours → Exporter les cours JSON**. Modifie le fichier avec un éditeur de texte puis choisis **Importer des cours JSON**. Aucune recompilation n’est nécessaire. Le programme personnalisé est enregistré sur l’appareil et rechargé au démarrage. Pour le transférer sur un autre appareil, exporte puis importe le même fichier.

Pour ajouter ou remplacer **une seule leçon**, copie [cet exemple prêt à importer](examples/lecon-personnalisee.json). Change `moduleId` pour choisir un module existant. Si `lesson.id` existe déjà dans ce module, sa leçon est remplacée ; sinon elle est ajoutée à la fin des leçons. Un fichier de leçon remplace toute la fiche correspondante : conserve les champs que tu souhaites garder.

## Une leçon

| Champ | Contenu |
|---|---|
| `id` | Identifiant stable et unique, lettres/chiffres/tirets/soulignés ; maximum 80 caractères |
| `title` | Titre affiché |
| `paragraphs` | Liste facultative de paragraphes simples |
| `sections` | Sections facultatives avec `title`, `paragraphs`, `examples`, `note` |
| `sections[].examples` | Exemples avec `jp` (japonais), `reading` (lecture), `fr` (traduction) |
| `table` | Tableau facultatif sous forme de listes, au moins deux textes par ligne |
| `resources` | Liens facultatifs : `title` et `url` HTTPS |
| `exercises` | Exercices et corrections écrits directement en JSON |
| `generator` | Facultatif : générateurs déjà disponibles, expliqués ci-dessous |

Une leçon doit avoir au moins un exercice, une question historique ou un générateur. Les titres et les réponses ne doivent pas être vides. Les sections sont affichées avant les paragraphes simples.

## Exercices sans code

Tous demandent `id`, `type`, `prompt`, `answer`, `explanation`. `alternatives` est une liste facultative de réponses également acceptées. Les identifiants d’exercices doivent être uniques dans leur leçon.

| `type` | Champs supplémentaires | Comportement |
|---|---|---|
| `input` | Aucun | Saisie libre ; le clavier japonais apparaît si le texte de la consigne contient kana, hiragana, katakana ou kanji et ne demande pas du rōmaji |
| `choice` | `choices` | Au moins deux choix distincts, incluant exactement `answer` ; la session mélange les choix et en affiche au maximum quatre |
| `order` | `tokens` | Au moins deux éléments à remettre en ordre ; leur concaténation dans le JSON doit correspondre à `answer` ou une alternative |

`explanation` est la correction affichée après validation. Des exercices personnalisés peuvent aussi compléter un générateur. Les accents et la normalisation Unicode sont gérés par le moteur ; les alternatives doivent être précisées lorsqu’une autre réponse est valable. Le JSON ne vérifie pas la justesse pédagogique ou linguistique.

## Programme complet et MCO

L’export contient `format: "kotoba.curriculum"`, `version: 1`, et `modules`. L’ancien tableau JSON des modules est aussi accepté. Modifie la liste pour ajouter, supprimer ou réordonner les modules.

Chaque module contient `id`, `title`, `subtitle`, `symbol`, `color`, `lessons` et `mcos`. Un module doit avoir au moins une leçon et **2 à 4 MCO**. Chaque MCO contient `id`, `title` et `words` de **1 à 10 mots**. Chaque mot demande `id`, `writing`, `reading`, `meaning`. Les identifiants des mots sont uniques dans tout le programme. Le moteur génère automatiquement les exercices et cartes des MCO.

## Générateurs existants

- `{"kind":"kana"}` utilise `table` : chaque ligne contient l’écriture puis sa lecture en rōmaji. La validation exige la réussite de tous les caractères.
- `{"kind":"numbers","min":0,"max":99}` entraîne les nombres dans cette plage (minimum et maximum inclus).
- `{"kind":"kanji"}` utilise les mots des MCO du module.
- `{"kind":"frames","frames":[...]}` combine des modèles de phrases. Chaque modèle contient `tokens`, `french`, `domains`, `focus`, `explanation`. `focus` est l’index, à partir de zéro, du token à compléter. Les domaines proposent des objets `jp` et `fr`, insérés via `{nom-du-domaine}`. Maximum 500 combinaisons par modèle. Les modèles du programme exporté servent d’exemples complets.

Ces générateurs produisent des variantes à partir des données. Une nouvelle mécanique d’exercice, au-delà des types disponibles, nécessitera du code Dart.

## Après modification

L’import affiche un aperçu et demande confirmation après validation. Un fichier invalide indique le champ à corriger et ne remplace pas les cours en cours. Maximum 4 Mo, 50 modules et 30 000 variantes.

Les étapes dont le contenu est inchangé restent validées. Une étape modifiée doit être repassée. Les DS du premier module modifié et des modules suivants doivent être repassés pour respecter les prérequis. Les cartes des mots inchangés sont conservées ; l’activité quotidienne et l’objectif restent conservés. Exporte aussi ton carnet avant une révision importante.

**Restaurer les cours fournis** réinstalle le programme embarqué. Exporte d’abord tes cours personnalisés pour les conserver. L’application n’a pas encore d’éditeur de cours intégré : l’édition se fait dans le fichier JSON.
