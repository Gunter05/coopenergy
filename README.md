# CoopEnergie ☀️🔗

**CoopEnergie** est une application Flutter innovante permettant la gestion et la participation à des **coopératives solaires transparentes sur blockchain**. L'objectif du projet est de démocratiser l'investissement dans l'énergie solaire en offrant une plateforme sécurisée, transparente et décentralisée.

## ✨ Fonctionnalités Principales

- 🔐 **Authentification Sécurisée** : Gestion des utilisateurs via Supabase.
- ⚡ **Investissement et Contribution** : Participez au financement de projets solaires.
- 📊 **Suivi de Progression** : Visualisation en temps réel de la production et de l'avancement des projets (graphiques via `fl_chart`).
- 🗳️ **Gouvernance Décentralisée (Vote)** : Système de vote pour les membres de la coopérative, garantissant une prise de décision démocratique.
- 🔗 **Transparence Blockchain** : Intégration Web3 (`web3dart`) pour assurer la traçabilité et l'immuabilité des transactions et des votes.
- 📄 **Rapports et Export PDF** : Génération de rapports détaillés sur les performances et les investissements au format PDF.

## 🛠️ Stack Technique

Le projet repose sur des technologies modernes pour assurer performance, sécurité et maintenabilité :

- **Framework :** [Flutter](https://flutter.dev/) (Dart)
- **Gestion d'état :** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Navigation :** [GoRouter](https://pub.dev/packages/go_router)
- **Backend / BaaS :** [Supabase](https://supabase.com/) (`supabase_flutter`)
- **Blockchain :** [Web3Dart](https://pub.dev/packages/web3dart)
- **Interface Utilisateur :** Material Design, `google_fonts`, `fl_chart`, `shimmer`
- **Génération de PDF :** `pdf`, `printing`

## 📂 Architecture du Projet

Le code source est organisé dans le dossier `lib/` selon l'architecture suivante :

```text
lib/
├── core/       # Configurations globales (Routeur, Thème, Client Supabase...)
├── models/     # Modèles de données
├── providers/  # Gestionnaires d'état Riverpod
├── screens/    # Écrans de l'application
│   ├── auth/         # Connexion, Inscription
│   ├── contribute/   # Parcours d'investissement
│   ├── cooperative/  # Détails de la coopérative solaire
│   ├── home/         # Tableau de bord principal
│   ├── onboarding/   # Écrans de présentation
│   ├── report/       # Génération de rapports PDF
│   ├── splash/       # Écran de chargement
│   └── vote/         # Interface de vote et gouvernance
├── services/   # Services externes et logique métier
└── widgets/    # Composants UI réutilisables
```

## 🚀 Démarrage Rapide

### Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `>=3.0.0 <4.0.0`)
- Un environnement de développement (VS Code, Android Studio, etc.)
- Un projet [Supabase](https://supabase.com/) configuré.

### Installation

1. **Cloner le dépôt :**
   ```bash
   git clone <URL_DU_DEPOT>
   cd coopenergy
   ```

2. **Installer les dépendances :**
   ```bash
   flutter pub get
   ```

3. **Configuration de l'environnement :**
   Créez un fichier `.env` à la racine du projet et ajoutez vos clés Supabase :
   ```env
   SUPABASE_URL=votre_url_supabase
   SUPABASE_ANON_KEY=votre_cle_anonyme_supabase
   ```

4. **Lancer l'application :**
   ```bash
   flutter run
   ```

## 🧪 Tests

Pour exécuter les tests du projet :
```bash
flutter test
```

## 📝 Licence

Ce projet est sous licence [MIT](LICENSE) - voir le fichier LICENSE pour plus de détails.
