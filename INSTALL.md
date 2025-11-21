# 🚀 Installation Rapide - Halimou

Guide d'installation en **une seule ligne de commande** pour les personnes non initiées.

## 📋 Prérequis automatiques

### macOS / Linux

Copiez-collez cette ligne dans votre terminal:

```bash
bash <(curl -sSL https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.sh)
```

**Ou si vous avez déjà cloné le projet:**

```bash
bash install-prerequisites.sh
```

### Windows

Ouvrez PowerShell (en tant qu'administrateur) et copiez-collez:

```powershell
PowerShell -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/we-dream-team/Halimou/main/install-prerequisites.ps1'))"
```

**⚠️ IMPORTANT sur Windows:**
- Exécutez PowerShell **en tant qu'administrateur** (clic droit > Exécuter en tant qu'administrateur)
- Si vous avez des erreurs, consultez [TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)

**Ou si vous avez déjà cloné le projet:**

```powershell
.\install-prerequisites.ps1
```

## 📦 Ce qui sera installé automatiquement

- ✅ **Git** - Pour cloner le projet
- ✅ **Node.js 18+** - Pour le frontend
- ✅ **Python 3.10+** - Pour le backend
- ✅ **MongoDB** - Base de données
- ✅ **pnpm** - Gestionnaire de paquets Node.js

## 🎯 Après l'installation des prérequis

### 1. Cloner le projet

```bash
git clone https://github.com/we-dream-team/Halimou.git
cd Halimou
```

### 2. Installer et démarrer l'application

**macOS / Linux:**
```bash
bash install-and-start.sh
```

**Windows:**
```powershell
.\install-and-start.ps1
```

C'est tout ! L'application sera accessible sur:
- 🌐 **Frontend Web**: http://localhost:3000
- 🔌 **API Backend**: http://localhost:8001

## ⚠️ Notes importantes

### MongoDB

Après l'installation, vous devez démarrer MongoDB:

**macOS:**
```bash
brew services start mongodb-community
```

**Linux:**
```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

**Windows:**
```powershell
net start MongoDB
```

**Alternative:** Utilisez [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (gratuit) pour une base de données dans le cloud.

### Problèmes courants

1. **"Command not found" après installation**
   - Fermez et rouvrez votre terminal
   - Sur macOS, vérifiez que Homebrew est dans votre PATH

2. **Erreurs de permissions (Linux)**
   - Utilisez `sudo` pour les commandes d'installation
   - Exemple: `sudo bash install-prerequisites.sh`

3. **MongoDB ne démarre pas**
   - Vérifiez que le service est installé
   - Consultez les logs: `brew services list` (macOS) ou `sudo systemctl status mongod` (Linux)

4. **Problèmes spécifiques à Windows 11**
   - Consultez le guide détaillé: [TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)
   - Assurez-vous d'exécuter PowerShell en tant qu'administrateur
   - Fermez et rouvrez PowerShell après chaque installation

## 📞 Besoin d'aide?

Si vous rencontrez des problèmes:
1. Vérifiez que tous les prérequis sont installés: `git --version`, `node --version`, `python3 --version`
2. Consultez le [README.md](README.md) pour plus de détails
3. **Windows 11:** Consultez [TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md) pour les problèmes spécifiques
4. Vérifiez que MongoDB est démarré et accessible

