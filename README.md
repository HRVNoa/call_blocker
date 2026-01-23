# Call Blocker - Bloqueur d'appels Android

Application Flutter pour bloquer automatiquement les appels indésirables sur Android.

## ✨ Fonctionnalités

- ✅ **Blocage automatique** des appels par préfixes
- ✅ **Statistiques** des appels bloqués
- ✅ **Gestion des préfixes** personnalisés
- ✅ **Support Android 16** (API 35)
- ✅ **Indicateur de statut** pour vérifier la configuration

## 📱 Prérequis

- **Android 10+** (API 29 minimum)
- **OnePlus Nord 4** ou tout appareil Android compatible
- Permissions téléphone requises

## 🚀 Installation

### 1. Construire l'APK

```bash
cd d:\nhervieu\antigravity\call_blocker
flutter clean
flutter pub get
flutter build apk --release
```

### 2. Installer sur le téléphone

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Ou transférer manuellement l'APK et l'installer depuis le gestionnaire de fichiers.

## ⚙️ Configuration

### Première utilisation

1. **Ouvrir l'application**
2. **Activer le service** (switch en haut)
3. **Accepter les permissions** téléphone
4. **Cliquer sur "Configurer"** dans le dialogue
5. **Dans les paramètres Android** :
   - Aller dans "Applications par défaut"
   - Sélectionner "Identification de l'appelant et spam"
   - Choisir "call_blocker"
6. **Retourner dans l'app** et vérifier le statut ✓

### Ajouter des préfixes

1. Cliquer sur **"Gérer"** dans la section "Préfixes bloqués"
2. Ajouter vos préfixes (ex: "0661", "06 61", "0162")
3. S'assurer que les préfixes sont activés (switch vert)

## 📊 Utilisation

Une fois configuré, l'application :
- Bloque automatiquement les appels des préfixes configurés
- Affiche le nombre d'appels bloqués
- Indique si l'app est correctement configurée comme app par défaut

## 🔍 Débogage

### Vérifier les logs

```bash
adb logcat | grep CallScreeningService
```

### Logs attendus pour un appel bloqué

```
D/CallScreeningService: onScreenCall triggered
D/CallScreeningService: Incoming call from: +33661123456
D/CallScreeningService: Clean number: 33661123456
D/CallScreeningService: Converted to national format: 0661123456
I/CallScreeningService: ✓ Number matches blocked prefix: 0661
I/CallScreeningService: ✓ Call blocked from: +33661123456
D/CallScreeningService: Blocked calls count: 1
```

## 🛠️ Développement

### Tests

```bash
flutter test
```

### Build debug

```bash
flutter run
```

## 📝 Notes importantes

- L'application bloque les appels **avant qu'ils sonnent**
- Les numéros masqués et courts (urgences) sont autorisés
- Les numéros internationaux (+33) sont convertis automatiquement en format national (0)
- Les préfixes avec espaces ("06 61") fonctionnent correctement

## ⚠️ Limitations

- **Android uniquement** (iOS non supporté)
- **Android 10+ requis** (API 29+)
- L'utilisateur doit configurer manuellement l'app comme app par défaut
- Les numéros masqués ne peuvent pas être bloqués (limitation Android)

## 🔧 Technologies

- **Flutter** 3.10.7+
- **Kotlin** pour le code natif Android
- **CallScreeningService** Android API
- **SharedPreferences** pour le stockage

## 📄 Licence

Projet privé - Tous droits réservés

## 👤 Auteur

Développé pour OnePlus Nord 4 (Android 16)
