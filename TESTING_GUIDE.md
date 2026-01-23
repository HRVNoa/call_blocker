# Guide de test du blocage d'appels

## Problème résolu

Le problème était double :
1. **Bug de normalisation** : Les préfixes avec espaces (comme "06 61") n'étaient pas nettoyés avant la comparaison, donc ils ne correspondaient jamais aux numéros nettoyés.
2. **Pas de service de blocage réel** : L'application n'avait aucun mécanisme pour intercepter les appels entrants.

## Solutions implémentées

### 1. Correction du bug de normalisation
- Le préfixe stocké est maintenant nettoyé des espaces et caractères non-numériques avant la comparaison
- Fichier modifié : `lib/services/storage_service.dart`

### 2. Implémentation du CallScreeningService Android
- Création d'un service natif Android qui intercepte les appels en temps réel
- Fichiers créés/modifiés :
  - `android/app/src/main/kotlin/com/callblocker/call_blocker/CallScreeningServiceImpl.kt` (nouveau)
  - `android/app/src/main/kotlin/com/callblocker/call_blocker/MainActivity.kt` (modifié)
  - `android/app/src/main/AndroidManifest.xml` (modifié)
  - `lib/services/call_service.dart` (modifié)
  - `lib/screens/home_screen.dart` (modifié)

## Comment tester

### Étape 1 : Reconstruire l'application
```bash
cd d:\nhervieu\antigravity\call_blocker
flutter clean
flutter pub get
flutter run
```

### Étape 2 : Activer le service
1. Ouvrez l'application
2. Activez le switch "Service de blocage"
3. Acceptez les permissions demandées
4. Un dialogue s'affichera vous demandant d'ouvrir les paramètres
5. Cliquez sur "Ouvrir les paramètres"

### Étape 3 : Configurer Android
Dans les paramètres Android qui s'ouvrent :
1. Cherchez "Applications par défaut" ou "Default apps"
2. Trouvez "Caller ID & spam" ou "Identification de l'appelant"
3. Sélectionnez "call_blocker" comme application par défaut

**Note importante** : Cette fonctionnalité nécessite Android 10 (API 29) ou supérieur.

### Étape 4 : Ajouter des préfixes à bloquer
1. Dans l'app, allez dans "Gérer" les préfixes
2. Ajoutez "0661" (ou "06 61" avec espace, ça fonctionne maintenant !)
3. Assurez-vous que le préfixe est activé (switch vert)

### Étape 5 : Tester le blocage
1. Assurez-vous que le service est activé (switch vert)
2. Assurez-vous d'être en mode "Blocage direct"
3. Demandez à quelqu'un d'appeler depuis un numéro commençant par 0661
4. L'appel devrait être bloqué automatiquement

## Vérification des logs

Pour voir si le service fonctionne, vous pouvez vérifier les logs Android :
```bash
adb logcat | grep CallScreeningService
```

Vous devriez voir des messages comme :
- "onScreenCall triggered"
- "Incoming call from: +33661..."
- "Should block: true"
- "Call blocked from: +33661..."

## Dépannage

### Le service ne bloque pas les appels
1. Vérifiez que l'app est définie comme app de blocage par défaut dans les paramètres Android
2. Vérifiez que le service est activé dans l'app (switch vert)
3. Vérifiez que le préfixe est bien activé
4. Vérifiez les logs avec `adb logcat`

### L'option "call_blocker" n'apparaît pas dans les paramètres
- Assurez-vous d'avoir Android 10 ou supérieur
- Reconstruisez l'app avec `flutter clean` puis `flutter run`

### Les préfixes avec espaces ne fonctionnent toujours pas
- Désactivez puis réactivez le service
- Cela forcera le service à relire les préfixes depuis le stockage

## Limitations

- **Android uniquement** : Cette fonctionnalité ne fonctionne que sur Android 10+
- **iOS** : iOS nécessite une approche différente avec CallKit (non implémenté)
- **Permissions** : L'utilisateur doit manuellement définir l'app comme app de blocage par défaut
