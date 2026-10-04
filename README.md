# Kotoba — japanese_learning_app

Application de japonais en français, conçue d’abord pour le téléphone et utilisable sur PC. Cette première version est une **PWA installable**, avec un parcours guidé et des cartes à répétition espacée. Les cours et exercices fonctionnent hors ligne après une première ouverture ; les ressources YouTube nécessitent Internet.

## Démarrer

Prérequis : Python 3 pour le serveur de développement. Node.js 20+ pour les tests. Aucun paquet n’est nécessaire pour exécuter l’application.

```sh
python3 -m http.server 8080
```

Ouvrir http://localhost:8080. Sur Windows, `py -m http.server 8080` convient aussi. Pour essayer sur un téléphone, un hébergement HTTPS est nécessaire à l’installation et au mode hors ligne. Ne pas ouvrir `index.html` directement avec `file://` : les modules JavaScript nécessitent un serveur HTTP.

Installation : Chrome/Edge → Installer l’application ; iPhone → Safari → Partager → Sur l’écran d’accueil. Le même code fonctionne sur Android, iOS et ordinateur via un navigateur compatible. Ce dépôt ne fournit pas encore d’APK, de paquet iOS ou d’installeur Windows.

## Parcours disponible

| Module | Leçons | MCO obligatoires | Vocabulaire |
| --- | --- | --- | --- |
| 1 · Hiragana & katakana | 46 hiragana, 46 katakana, accents, combinaisons, pauses | Quotidien ; mots en katakana | 16 mots, sans kanji |
| 2 · Arabiasūji & premiers kanji | Chiffres 0–10 ; sens et lectures des kanji | Nature ; autour de soi | Exactement 10 mots en kanji |
| 3 · Particules de base | は / の / も ; を / に / で | Personnes et lieux ; actions | 14 mots en kana |

Chaque module possède deux MCO (le format permet de deux à quatre), de huit mots au plus dans cette version, et un DS. Le schéma impose un maximum de dix mots par MCO.

- Séances de dix questions maximum pour les grands syllabaires. Un kana doit avoir été reconnu correctement au moins une fois pour que sa leçon soit terminée.
- Leçons courtes et MCO : au moins 80 % de bonnes réponses. Les MCO demandent de retrouver le mot à partir du français ; les mots en kanji sont également testés en lecture.
- DS disponible après toutes les leçons et tous les MCO. Le tirage aléatoire couvre chaque leçon et chaque MCO. Aucune correction intermédiaire ; bilan détaillé à la fin.
- Score de 80 % au DS pour ouvrir le module suivant. Le meilleur score est conservé ; une nouvelle tentative moins bonne ne referme pas un module.
- Révision active des mots des MCO terminés. « À revoir » programme un rappel après dix minutes ; les autres notes espacent progressivement les rappels. La séance reste bornée à vingt cartes.
- Objectif quotidien, série de jours d’activité, progression locale, export/import JSON pour passer manuellement d’un appareil à l’autre.
- Lecture audio si une voix de synthèse japonaise est installée sur l’appareil. Aucun fichier audio n’est fourni, et une voix japonaise est requise pour cette fonction.

## Ressources et direction artistique

Référence indiquée : [Cours de japonais !, Julien Fontanier](https://www.youtube.com/@coursdejaponais). Liens vérifiés vers [la présentation des hiragana](https://www.youtube.com/watch?v=_PCJnq_-oT8), [les nombres japonais](https://www.youtube.com/watch?v=-a8A0Bf3sxo) et [la particule は](https://www.youtube.com/watch?v=z9dU8wwFEEs). Les autres fiches pointent vers les vidéos de la chaîne sans inventer de correspondance précise.

Les fiches et exercices sont originaux : ils ne sont pas des transcriptions des vidéos ni les exercices officiels de la chaîne. Le regroupement en modules suit le cahier des charges de ce projet, et ne prétend pas reproduire l’ordre intégral des cours de Julien Fontanier. Projet indépendant, sans affiliation.

La direction graphique de cette version utilise un carnet clair, des couleurs papier, corail et sauge, ainsi que des repères japonais. Les illustrations et logos de la chaîne ne sont pas repris. Les caractères japonais utilisés par le parcours disposent d’une police Noto Sans JP embarquée et réduite aux caractères de l’application, sous licence SIL Open Font License (`fonts/OFL.txt`). Une adaptation visuelle plus précise pourra s’appuyer sur des références choisies avec le propriétaire du projet.

## Architecture

- `src/content.js` : données du parcours, séparées de l’interface.
- `scripts/content.py` : source éditable qui régénère le parcours avec `python3 scripts/content.py` (pas de bibliothèque externe).
- `src/core.js` : correction, progression, tirage des DS, calendrier de révision et validation des sauvegardes.
- `src/app.js` : interface, navigation, séances, stockage et import/export.
- `src/style.css` : interface responsive, navigation inférieure sur mobile, focus clavier et réduction des animations.
- `sw.js` : cache hors ligne des fichiers de l’application. Lors d’une modification, augmenter la version du cache ; fermer les anciennes fenêtres permet ensuite l’activation de la nouvelle version.

Lors de l’ajout de nouveaux caractères, compléter le sous-ensemble de police embarqué pour les appareils sans police japonaise.

Les données restent dans `localStorage`, sans compte ni serveur de données. La suppression des données du navigateur efface le carnet : utiliser l’export pour le conserver. Il n’y a pas encore de synchronisation automatique, de reconnaissance de tracé ou de notation de prononciation.

## Vérifier

```sh
npm test
npm run check
```

Les tests couvrent les contraintes du contenu, la correction des réponses, les prérequis, les DS, les rappels et les sauvegardes. Une action GitHub exécute ces contrôles à chaque push et PR.

Contrôle navigateur facultatif (Playwright et Chromium requis) :

```sh
npm install --no-save playwright@1.63.0
npx playwright install chromium
# Avec le serveur lancé sur 8080 :
node scripts/browser-check.mjs
```

Ce contrôle vérifie le format mobile, un MCO complet, la révision, un DS complet, le déblocage, la persistance, le mode hors ligne et le format PC. Les captures sont écrites dans le dossier temporaire du système.

## Suite du projet

1. Faire relire les trois modules et enrichir les exercices (écoute, choix de particules en contexte, ordre des mots).
2. Étendre les nombres et les particules, puis ajouter les modules suivants avec deux à quatre MCO chacun.
3. Ajouter des comptes et une synchronisation optionnelle après choix du backend.
4. Préparer les paquets mobiles natifs si une distribution en boutiques est souhaitée.
