# Exercice d’écriture

Dans une leçon, « Exercice d’écriture » ouvre les kana et kanji présents dans
les tableaux, le vocabulaire et les exemples. Chaque caractère propose :

- modèle guidé avec numéros de traits ;
- démonstration animée, avec un point mobile indiquant le sens ;
- écriture de mémoire en masquant le modèle ;
- comparaison avec score et superposition du modèle ;
- nouvel essai et passage au caractère suivant.

La démonstration efface l’essai (le bouton l’indique). Un geste représente un
trait. Les gestes annulés par le système sont retirés. Le dessin fonctionne
au doigt, au stylet ou à la souris ; un deuxième pointeur est ignoré. Toute
modification du dessin invalide le résultat précédent.

## Évaluation

Les coordonnées restent relatives au carré d’écriture. Chaque trait est
rééchantillonné à intervalles réguliers ; les traits dessinés sont associés
aux traits du modèle selon leur proximité géométrique. La comparaison teste
les deux sens du parcours pour distinguer la forme et le sens du geste.

- Forme (70 %) : distance au modèle et rapport des longueurs.
- Ordre (20 %) : position du trait dans la séquence, pondérée par sa forme.
- Sens (10 %) : parcours dans le sens attendu, pondéré par sa forme.

Les traits manquants ou supplémentaires réduisent tous les scores. Un tap
ou un trait de longueur inférieure à 1,5 % du côté du carré n’apporte pas de
points. Les traits éloignés de plus de 6 % du carré apparaissent en orange.

Il s’agit d’une aide géométrique indicative, pas d’un modèle de reconnaissance
ni d’une évaluation validée de la calligraphie. Les tolérances doivent encore
être confrontées aux essais de vrais apprenants. Un même caractère peut avoir
des variantes manuscrites acceptables que ce modèle pénalisera. Les résultats
ne valident aucun DS et ne sont pas enregistrés dans la progression Anki.
Un caractère ajouté dans un JSON sans modèle reste dessinable, avec comparaison
typographique et sans score automatique.

## Sources

Les cours ne sont pas modifiés. Les coordonnées techniques proviennent de
[KanjiVG](https://kanjivg.tagaini.net/), copyright Ulrich Apel,
[CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).
Commit source : `70a0b7ae0c18ceb5cb358274b029cce0234a43bc`.
Le fichier `assets/stroke_models_LICENSE.txt` contient l’attribution et la licence.
Les courbes SVG, dans leur ordre original, sont transformées en polylignes
normalisées ; ces données dérivées restent sous CC BY-SA 3.0.

613 caractères sont couverts, y compris les caractères du programme enrichi
fourni séparément. La génération inclut tous les kana disponibles.

Pour régénérer les données (hors compilation) :

```sh
python -m pip install svgpathtools==1.8.0
python tool/stroke_models.py chemin/kanjivg.zip chemin/cours-supplementaires.json
```

Le ZIP source se télécharge depuis le dépôt officiel KanjiVG au commit ci-dessus.
L’argument du programme supplémentaire est facultatif.

## Vérification et intégration

Appliquer le correctif depuis la racine du dépôt avec `git apply atelier-ecriture.patch`.
Puis, depuis `native/`, exécuter `flutter pub get`, `flutter analyze` et
`flutter test --timeout 60s`. Aucun changement du numéro de version n’est requis.

Le workflow GitHub actuel produit des applications Android et Windows à chaque
push. Les changements sont fournis pour examen local ; ne les pousser ou ne
produire une nouvelle distribution qu’après accord explicite de Fabian.

## Contrôles effectués pour ce correctif

- Parseur/formatage Dart : cinq fichiers vérifiés.
- Données : 613 modèles avec coordonnées finies et traits utilisables.
- Calcul seul : 623 contrôles passés, dont les modèles parfaits, les points,
  les traits inversés/réordonnés, manquants, supplémentaires ou retracés.
  Ils exécutent le même évaluateur Dart avec un adaptateur local pour Offset,
  sans exécuter Flutter ; ils ne remplacent pas les tests de l’interface.
- Les tests Flutter sont fournis mais non exécutés. La vérification automatique
  a bloqué l’outil Flutter, qui tente une requête vers un service de métadonnées
  link-local susceptible de donner accès à des identifiants. Il reste donc
  nécessaire de lancer l’analyse Flutter et les tests sur un poste autorisé.
- Pas de compilation Android/Windows et numéro de version inchangé.
- Pour intégrer les sources sans produire de distribution, le commit utilise
  `[skip ci]`, conformément à la directive de ne pas créer de version sans accord.
