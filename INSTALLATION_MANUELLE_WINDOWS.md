# 📥 Installation manuelle sur Windows (si téléchargement automatique échoue)

Si vous obtenez l'erreur **"Le nom distant n'a pas pu être résolu: 'raw.githubusercontent.com'"**, suivez ces étapes pour télécharger et installer manuellement.

## Étape 1: Télécharger les scripts

### Option A: Via GitHub (navigateur web)

1. Ouvrez votre navigateur web
2. Allez sur: https://github.com/we-dream-team/Halimou
3. Téléchargez les fichiers suivants:
   - `install-prerequisites.ps1` - Script d'installation des prérequis
   - `install-and-start.ps1` - Script d'installation et démarrage de l'application

**Pour télécharger un fichier:**
- Cliquez sur le nom du fichier
- Cliquez sur le bouton "Raw" (en haut à droite)
- Clic droit > "Enregistrer sous..."
- Enregistrez avec l'extension `.ps1` (ex: `install-prerequisites.ps1`)

### Option B: Cloner le repository (si Git est installé)

```powershell
git clone https://github.com/we-dream-team/Halimou.git
cd Halimou
```

## Étape 2: Exécuter le script d'installation

1. **Ouvrez PowerShell en tant qu'administrateur:**
   - Appuyez sur `Windows + X`
   - Sélectionnez "Windows PowerShell (Admin)" ou "Terminal (Admin)"
   - Ou: Clic droit sur PowerShell > "Exécuter en tant qu'administrateur"

2. **Naviguez vers le dossier où vous avez enregistré le script:**
   ```powershell
   cd "C:\Users\VotreNom\Downloads"
   # ou
   cd "C:\chemin\vers\Halimou"  # si vous avez cloné le repo
   ```

3. **Exécutez le script:**
   ```powershell
   .\install-prerequisites.ps1
   ```

4. **Si vous obtenez une erreur d'exécution:**
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\install-prerequisites.ps1
   ```

## Étape 3: Suivre les instructions du script

Le script va:
- ✅ Installer Git, Node.js, jq, MongoDB, pnpm
- ⚠️ Vous guider pour installer Python manuellement
- 🔄 Proposer de cloner le projet et démarrer l'application

## Problèmes de connexion réseau?

### Vérifier votre connexion

```powershell
# Tester la connexion à GitHub
Test-NetConnection github.com -Port 443

# Tester la résolution DNS
Resolve-DnsName github.com
```

### Solutions possibles:

1. **Vérifiez votre connexion internet**
2. **Désactivez temporairement votre VPN** (si vous en utilisez un)
3. **Vérifiez votre pare-feu** - Autorisez PowerShell à accéder à internet
4. **Changez votre serveur DNS** (ex: utilisez 8.8.8.8 et 8.8.4.4)
5. **Utilisez un autre réseau** (ex: hotspot mobile)

## Alternative: Installation complètement hors ligne

Si vous ne pouvez pas télécharger depuis GitHub:

1. **Sur un autre ordinateur avec internet:**
   - Téléchargez tous les fichiers du repository
   - Copiez-les sur une clé USB

2. **Sur votre ordinateur:**
   - Copiez les fichiers depuis la clé USB
   - Exécutez les scripts localement

## Besoin d'aide?

Consultez le guide de dépannage complet:
- [TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)

