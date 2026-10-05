# Kotoba 0.3.4 — Android et Windows

Application Flutter en Dart, avec des composants natifs Flutter, sans WebView ni serveur HTML. Parcours, contenus et police japonaise intégrés ; sauvegarde locale, clavier japonais, DS et cartes espacées. Import/export JSON compatible avec le carnet de la version web.

## Compiler

Installer le SDK Flutter stable, Android Studio pour Android, ou Visual Studio avec « Développement Desktop en C++ » pour Windows. Puis, depuis ce dossier :

```sh
flutter create --platforms=android,windows --project-name kotoba --org fr.kotoba .
python tool/configure.py
flutter pub get
flutter analyze
flutter test
flutter run
```

Sous Windows, `python` peut être remplacé par `py`. La création des dossiers plateforme conserve les fichiers Dart existants. Ne pas utiliser `--overwrite`.

```sh
flutter build apk --release
flutter build windows --release
```

L’APK se trouve dans `build/app/outputs/flutter-apk/app-release.apk`. La version Windows se trouve dans `build/windows/x64/runner/Release/` : conserver tout le dossier avec l’exécutable et ses dépendances.

## Télécharger

Le workflow **Native Android and Windows** fournit **Kotoba-Android** et **Kotoba-Windows** dans ses artefacts après une compilation réussie. Décompresser Windows puis ouvrir `kotoba.exe`. Android : extraire et installer l’APK sur le téléphone.

Les vidéos nécessitent Internet. L’audio utilise une voix japonaise du système, à installer sur l’appareil si elle manque. Les paquets de test utilisent la signature de développement Flutter ; une publication sur Play Store nécessitera une signature de distribution.

## Contenus

Les cours sont désormais importables et exportables depuis **Carnet → Mes cours**, sans recompiler. [Guide de rédaction](COURS.md) · [Exemple de leçon prêt à importer](examples/lecon-personnalisee.json).

`assets/curriculum.json` contient le programme pédagogique. Le moteur Dart produit et sélectionne des variantes. Les kana ne sont validés qu’après réussite de chaque caractère ; les autres étapes demandent 80 %, et le DS débloque le module suivant à 80 %. Les cartes de vocabulaire entrent dans les révisions après validation du MCO.

## Atelier d’écriture

Depuis une leçon ou un MCO : « Pratiquer l’écriture à la main ». Dessine au doigt, au stylet ou à la souris dans le quadrillage ; affiche ou masque le modèle, annule un trait, efface ou compare. Le modèle est typographique : aucun ordre des traits ni reconnaissance automatique n’est fourni. Les dessins restent temporaires et ne valident pas les DS.

Les 51 leçons et les 29 MCO enrichis sont directement fournis dans l’application. Aucune importation n’est nécessaire pour voir les kanji.

La version 0.3.3 entraîne aussi les exercices rédigés dans les MCO et accepte les variantes de lecture définies par le cours. Le pack contient désormais 29 cours de vocabulaire enrichis, avec 167 kanji distincts et leurs références kun/on.

## Cours fournis dans la version 0.3.4

Le programme embarqué est identique à `content/kotoba-cours-debutant.json` : 12 modules, 51 leçons, 29 MCO, 167 kanji distincts. Les anciennes versions fournies, si elles sont intactes, sont mises à jour automatiquement au démarrage. Les cours personnalisés sont conservés ; Carnet affiche le programme actif et permet de restaurer les nouveaux cours fournis. Les étapes modifiées et leurs DS sont à revalider, tandis que l’objectif quotidien et l’historique d’activité restent conservés.
