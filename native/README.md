# Kotoba 0.3 — Android et Windows

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

`assets/curriculum.json` contient le programme pédagogique. Le moteur Dart produit et sélectionne des variantes. Les kana ne sont validés qu’après réussite de chaque caractère ; les autres étapes demandent 80 %, et le DS débloque le module suivant à 80 %. Les cartes de vocabulaire entrent dans les révisions après validation du MCO.
