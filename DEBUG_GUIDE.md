# Guide de débogage - Blocage d'appels

## ✅ Configuration vérifiée

Vous avez bien configuré l'app dans "Appli numéro de l'appelant et spam" → call_blocker ✓

## 🔧 Problème résolu : Format international

**Le problème** : Les numéros arrivent au format **+33 6 61 XX XX XX** (international) mais vous bloquez **0661** (format national).

**La solution** : J'ai ajouté la conversion automatique :
- `+33661123456` → converti en → `0661123456`
- Maintenant ça correspondra à votre préfixe `0661` !

---

## 🚀 Étapes pour tester maintenant

### 1. Reconstruire l'app avec les nouvelles modifications
```bash
cd d:\nhervieu\antigravity\call_blocker
flutter clean
flutter run
```

### 2. Vérifier la configuration
- ✅ Service activé (switch vert)
- ✅ Mode "Blocage direct"
- ✅ Préfixe "0661" activé (ou "06 61", les deux fonctionnent)
- ✅ App définie dans les paramètres Android

### 3. Tester un appel
Demandez à quelqu'un d'appeler depuis un 06 61 XX XX XX

### 4. Vérifier les logs en temps réel
Ouvrez un terminal et lancez :
```bash
adb logcat -c  # Nettoyer les logs
adb logcat | grep CallScreeningService
```

**Vous devriez voir** :
```
D/CallScreeningService: onScreenCall triggered
D/CallScreeningService: Incoming call from: +33661123456
D/CallScreeningService: Clean number: 33661123456
D/CallScreeningService: Converted to national format: 0661123456  ← NOUVEAU !
D/CallScreeningService: Found enabled prefix: 0661
D/CallScreeningService: Number matches blocked prefix: 0661
D/CallScreeningService: Should block: true
D/CallScreeningService: Call blocked from: +33661123456
```

---

## 🔍 Checklist de dépannage

Si ça ne marche toujours pas, vérifiez :

### ☑️ 1. Version Android
```bash
adb shell getprop ro.build.version.sdk
```
**Doit être ≥ 29** (Android 10+)

### ☑️ 2. Service activé dans l'app
- Ouvrir l'app
- Le switch "Service de blocage" doit être **VERT**
- Si gris, réactivez-le

### ☑️ 3. Préfixe bien configuré
- Aller dans "Gérer" les préfixes
- Vérifier que "0661" (ou "06 61") est dans la liste
- Vérifier que le switch à côté est **VERT**

### ☑️ 4. App définie comme app par défaut
```bash
# Vérifier quelle app est définie
adb shell dumpsys telecom | grep -i "screening"
```

### ☑️ 5. Permissions accordées
```bash
adb shell dumpsys package com.callblocker.call_blocker | grep -i permission
```
Cherchez : `android.permission.READ_PHONE_STATE: granted=true`

### ☑️ 6. Le service Android est bien enregistré
```bash
adb shell dumpsys package com.callblocker.call_blocker | grep -i "CallScreening"
```
Vous devriez voir : `CallScreeningServiceImpl`

---

## 🐛 Problèmes courants

### Problème : "Aucun log n'apparaît"
**Cause** : Le service n'est pas appelé par Android

**Solutions** :
1. Vérifier que l'app est bien définie comme app par défaut
2. Redémarrer le téléphone
3. Désactiver puis réactiver le service dans l'app

### Problème : "Service is disabled, allowing call"
**Cause** : Le switch dans l'app est désactivé

**Solution** : Activer le switch "Service de blocage"

### Problème : "No prefixes found, allowing call"
**Cause** : Les préfixes ne sont pas sauvegardés

**Solution** :
1. Aller dans "Gérer" les préfixes
2. Ajouter "0661"
3. Vérifier qu'il est activé
4. Désactiver/réactiver le service

### Problème : "Number matches blocked prefix: 0661" mais l'appel passe quand même
**Cause** : Problème avec les permissions de blocage

**Solution** :
1. Aller dans Paramètres Android → Applications → call_blocker
2. Vérifier toutes les permissions
3. Redémarrer l'app

---

## 📊 Test manuel de la logique

Pour tester si la conversion fonctionne sans faire d'appel :

```bash
# Lancer les tests unitaires
flutter test test/prefix_normalization_test.dart
```

Tous les tests doivent passer, y compris :
- ✅ "Should block +33661123456 (converted to 0661)"
- ✅ "Should block +33 6 61 12 34 56 (converted to 0661)"

---

## 🆘 Si rien ne fonctionne

Envoyez-moi les logs complets :
```bash
# Nettoyer les logs
adb logcat -c

# Faire un appel test

# Récupérer les logs
adb logcat -d > logs.txt
```

Puis cherchez dans `logs.txt` :
- "CallScreeningService"
- "call_blocker"
- "telecom"

---

## 📝 Modifications apportées

### Fichiers modifiés pour le format international :
1. `lib/services/storage_service.dart` - Conversion +33 → 0
2. `android/.../CallScreeningServiceImpl.kt` - Conversion +33 → 0
3. `test/prefix_normalization_test.dart` - Tests mis à jour

### Logique de conversion :
```
+33 6 61 12 34 56
    ↓ (nettoyage)
33661123456
    ↓ (conversion)
0661123456
    ↓ (comparaison)
Correspond à "0661" ✓
```
