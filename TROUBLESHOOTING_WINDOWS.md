# 🔧 Dépannage - Windows 11

Guide pour résoudre les problèmes courants lors de l'installation sur Windows 11.

## ⚠️ Problèmes courants

### 1. "Le script ne peut pas être exécuté car il est désactivé sur ce système"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Ou exécutez directement avec:
```powershell
PowerShell -ExecutionPolicy Bypass -File .\install-prerequisites.ps1
```

### 2. "Access Denied" ou erreurs de permissions

**Solution:**
- Clic droit sur PowerShell
- Sélectionnez "Exécuter en tant qu'administrateur"
- Réessayez le script

### 3. "Command not found" après installation

**Causes possibles:**
- Le PATH n'a pas été mis à jour
- Le terminal n'a pas été redémarré

**Solutions:**
1. **Fermez complètement PowerShell** et rouvrez-le
2. Si ça ne fonctionne toujours pas, **redémarrez votre ordinateur**
3. Vérifiez manuellement que les outils sont installés:
   ```powershell
   # Vérifier Git
   git --version
   
   # Vérifier Node.js
   node --version
   
   # Vérifier Python
   python --version
   # ou
   py --version
   ```

### 4. winget n'est pas reconnu

**Solution:**
- winget est inclus dans Windows 11, mais peut nécessiter une mise à jour
- Installez le "App Installer" depuis le Microsoft Store
- Ou utilisez Chocolatey (le script l'installera automatiquement)

### 5. Erreur lors de l'installation de Chocolatey

**Solution manuelle:**
1. Ouvrez PowerShell en administrateur
2. Exécutez:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```
3. Fermez et rouvrez PowerShell

### 6. Python installé mais "python" non reconnu

**Solution:**
1. Réinstallez Python depuis https://www.python.org/downloads/
2. **IMPORTANT:** Cochez "Add Python to PATH" lors de l'installation
3. Redémarrez PowerShell

### 7. MongoDB ne démarre pas

**Vérifications:**
```powershell
# Vérifier si le service existe
Get-Service -Name MongoDB*

# Démarrer le service
net start MongoDB

# Ou via Services
services.msc
```

**Si le service n'existe pas:**
- Réinstallez MongoDB
- Ou utilisez MongoDB Atlas (cloud gratuit): https://www.mongodb.com/cloud/atlas

### 8. Erreur "Cannot activate virtual environment"

**Solution:**
```powershell
# Supprimer l'environnement virtuel existant
Remove-Item -Recurse -Force backend\.venv

# Recréer l'environnement
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
```

### 9. Erreurs lors de l'installation des dépendances Python

**Solutions:**
```powershell
# Mettre à jour pip
python -m pip install --upgrade pip

# Installer les dépendances une par une si nécessaire
pip install fastapi
pip install uvicorn
# etc.
```

### 10. Erreurs lors de l'installation des dépendances Node.js

**Solutions:**
```powershell
# Nettoyer le cache npm
npm cache clean --force

# Supprimer node_modules et réinstaller
cd frontend
Remove-Item -Recurse -Force node_modules
npm install
```

## 📋 Vérification étape par étape

### Étape 1: Vérifier les prérequis installés

```powershell
# Git
git --version

# Node.js
node --version
npm --version

# Python
python --version
# ou
py --version

# pnpm (optionnel)
pnpm --version
```

### Étape 2: Vérifier MongoDB

```powershell
# Vérifier si MongoDB est installé
mongod --version

# Vérifier si le service est démarré
Get-Service -Name MongoDB*
```

### Étape 3: Tester l'installation

```powershell
# Backend
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python init_db.py

# Frontend
cd ..\frontend
npm install
npm run dev
```

## 🆘 Besoin d'aide supplémentaire?

1. Vérifiez les logs d'erreur dans PowerShell
2. Assurez-vous d'avoir les dernières mises à jour Windows 11
3. Vérifiez que votre antivirus ne bloque pas les installations
4. Consultez la documentation officielle:
   - [Git](https://git-scm.com/download/win)
   - [Node.js](https://nodejs.org/)
   - [Python](https://www.python.org/downloads/)
   - [MongoDB](https://www.mongodb.com/try/download/community)

## 💡 Astuces

- **Toujours exécuter PowerShell en administrateur** pour les installations
- **Fermer et rouvrir PowerShell** après chaque installation
- **Redémarrer l'ordinateur** si les commandes ne sont toujours pas reconnues
- **Utiliser MongoDB Atlas** si l'installation locale pose problème (gratuit jusqu'à 512MB)

