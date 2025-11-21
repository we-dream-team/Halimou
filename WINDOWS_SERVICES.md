# 🪟 Services Windows - Halimou

Guide pour installer et gérer Halimou comme services Windows.

## 📋 Prérequis

- Windows 10/11 ou Windows Server
- Python 3.10+ installé
- Node.js 18+ installé
- MongoDB installé et démarré
- Application installée (via `install-and-start.ps1`)

## 🚀 Installation des services

### Étape 1: Préparer l'application

Assurez-vous que l'application est installée et fonctionne :

```powershell
# Installer les dépendances
.\install-and-start.ps1
```

### Étape 2: Installer les services Windows

**IMPORTANT:** Exécutez PowerShell en tant qu'administrateur.

```powershell
.\install-windows-services.ps1
```

Ce script va :
- ✅ Télécharger et installer NSSM (Non-Sucking Service Manager)
- ✅ Créer le service `HalimouBackend` (port 8001)
- ✅ Créer le service `HalimouFrontend` (port 3000)
- ✅ Configurer les services pour démarrer automatiquement
- ✅ Configurer la rotation des logs

## 🎮 Gestion des services

### Utiliser le script de gestion

```powershell
# Voir le statut
.\manage-services.ps1 status

# Démarrer tous les services
.\manage-services.ps1 start

# Démarrer uniquement le backend
.\manage-services.ps1 start -Service backend

# Démarrer uniquement le frontend
.\manage-services.ps1 start -Service frontend

# Arrêter tous les services
.\manage-services.ps1 stop

# Redémarrer tous les services
.\manage-services.ps1 restart

# Redémarrer uniquement le backend
.\manage-services.ps1 restart -Service backend
```

### Utiliser PowerShell directement

```powershell
# Voir le statut
Get-Service Halimou*

# Démarrer les services
Start-Service HalimouBackend
Start-Service HalimouFrontend

# Arrêter les services
Stop-Service HalimouBackend
Stop-Service HalimouFrontend

# Redémarrer les services
Restart-Service HalimouBackend
Restart-Service HalimouFrontend
```

### Utiliser l'interface graphique Windows

1. Ouvrez `services.msc`
2. Recherchez `HalimouBackend` et `HalimouFrontend`
3. Clic droit > Démarrer/Arrêter/Redémarrer

## 📁 Structure des services

### Backend Service
- **Nom:** `HalimouBackend`
- **Port:** 8001
- **Commande:** `python -m uvicorn server:app --host 0.0.0.0 --port 8001`
- **Répertoire:** `backend/`
- **Logs:** `logs/backend.log` et `logs/backend-error.log`

### Frontend Service
- **Nom:** `HalimouFrontend`
- **Port:** 3000
- **Commande:** `next start -p 3000`
- **Répertoire:** `frontend/`
- **Logs:** `logs/frontend.log` et `logs/frontend-error.log`

## 📊 Logs

Les logs sont stockés dans le dossier `logs/` à la racine du projet :

```
logs/
├── backend.log          # Logs stdout du backend
├── backend-error.log    # Logs stderr du backend
├── frontend.log         # Logs stdout du frontend
└── frontend-error.log   # Logs stderr du frontend
```

Les logs sont automatiquement :
- ✅ Rotatés quotidiennement
- ✅ Rotatés si > 10 MB
- ✅ Conservés en ligne pendant la rotation

### Consulter les logs

```powershell
# Voir les derniers logs du backend
Get-Content logs\backend.log -Tail 50

# Suivre les logs en temps réel
Get-Content logs\backend.log -Wait -Tail 20

# Voir les erreurs
Get-Content logs\backend-error.log -Tail 50
```

## 🔧 Configuration

### Modifier les ports

Si vous voulez changer les ports, vous devez :

1. **Modifier les services NSSM :**
   ```powershell
   .\nssm\nssm.exe set HalimouBackend AppParameters "-m uvicorn server:app --host 0.0.0.0 --port 8002"
   .\nssm\nssm.exe set HalimouFrontend AppParameters "`"$PWD\frontend\node_modules\.bin\next.cmd`" start -p 3001"
   ```

2. **Redémarrer les services :**
   ```powershell
   .\manage-services.ps1 restart
   ```

### Modifier les variables d'environnement

Les variables d'environnement sont chargées depuis `backend/.env`. Modifiez ce fichier et redémarrez le service :

```powershell
# Modifier backend/.env
# Puis redémarrer
.\manage-services.ps1 restart -Service backend
```

## 🗑️ Désinstallation

Pour désinstaller les services :

```powershell
# Exécuter en tant qu'administrateur
.\install-windows-services.ps1 -Uninstall
```

Ou manuellement :

```powershell
Stop-Service HalimouBackend
Stop-Service HalimouFrontend
.\nssm\nssm.exe remove HalimouBackend confirm
.\nssm\nssm.exe remove HalimouFrontend confirm
```

## ⚠️ Dépannage

### Le service ne démarre pas

1. **Vérifier les logs d'erreur :**
   ```powershell
   Get-Content logs\backend-error.log -Tail 50
   ```

2. **Vérifier que MongoDB est démarré :**
   ```powershell
   Get-Service MongoDB*
   # Si arrêté :
   Start-Service MongoDB
   ```

3. **Vérifier que les ports sont libres :**
   ```powershell
   netstat -ano | findstr ":8001"
   netstat -ano | findstr ":3000"
   ```

4. **Tester manuellement :**
   ```powershell
   cd backend
   .venv\Scripts\Activate.ps1
   python -m uvicorn server:app --host 0.0.0.0 --port 8001
   ```

### Le service démarre puis s'arrête

1. **Vérifier les logs d'erreur**
2. **Vérifier que l'environnement virtuel existe :**
   ```powershell
   Test-Path backend\.venv\Scripts\python.exe
   ```

3. **Vérifier que le frontend est construit :**
   ```powershell
   Test-Path frontend\.next
   # Si absent :
   cd frontend
   npm run build
   ```

### Modifier la configuration d'un service

Utiliser NSSM GUI :

```powershell
.\nssm\nssm.exe edit HalimouBackend
```

Ou en ligne de commande :

```powershell
# Voir la configuration actuelle
.\nssm\nssm.exe get HalimouBackend AppParameters

# Modifier
.\nssm\nssm.exe set HalimouBackend AppParameters "nouveaux parametres"
```

## 🔐 Sécurité

- Les services s'exécutent avec les privilèges du compte système local
- Pour plus de sécurité, vous pouvez créer un compte utilisateur dédié et configurer NSSM pour l'utiliser
- Les logs peuvent contenir des informations sensibles, protégez le dossier `logs/`

## 📝 Notes

- Les services démarrent automatiquement au démarrage de Windows
- Les services redémarrent automatiquement en cas de crash (configuré par NSSM)
- Pour le développement, il est recommandé d'utiliser `install-and-start.ps1` au lieu des services
- Les services utilisent la version de production (frontend construit avec `npm run build`)

