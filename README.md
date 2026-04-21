# PFE-DevSecopsProject

> **Projet de Fin d'Études — Sopra Steria / ESPRIT**
> Mise en place d'une plateforme **DevSecOps complète multi-cloud** pour une application web React/TypeScript.

## Vue d'ensemble

Ce dépôt contient :
- L'**application web** (React 18 + TypeScript + Vite)
- Le **pipeline CI/CD** (GitHub Actions — 13 jobs)
- L'**infrastructure as Code** GCP et Azure (Terraform)
- La configuration **Grafana** (monitoring Cloud Run)

Le déploiement est entièrement automatisé sur **deux clouds** :
- **Google Cloud Platform** : Cloud Run (production + staging + Grafana)
- **Microsoft Azure** : AKS via GitOps ArgoCD (voir [PFE-GitOps](https://github.com/saharhamraoui/PFE-GitOps))

---

## Architecture

```
git push
   │
   ▼
GitHub Actions (13 jobs)
   │
   ├── Lint + Test + SonarQube + OWASP DC + npm audit
   │
   ├── Build → Trivy scan → Push GCP Artifact Registry
   │     └── Deploy staging → ZAP DAST scan → Deploy production (Cloud Run)
   │
   └── Build → Push Azure ACR
         └── Update image tag → PFE-GitOps → ArgoCD auto-sync → AKS
```

---

## Stack Technique

| Couche | Technologie |
|--------|-------------|
| Frontend | React 18, TypeScript, Vite, Tailwind CSS |
| Serveur | Nginx (port 8080) |
| Tests | Vitest |
| Lint | ESLint |
| Conteneur | Docker (multi-stage build) |
| CI/CD | GitHub Actions |
| IaC | Terraform |
| GitOps | ArgoCD |
| Monitoring | Grafana + Google Cloud Monitoring |

---

## Pipeline CI/CD — 13 Jobs

| Job | Rôle | Bloque si... |
|-----|------|--------------|
| `lint` | ESLint | erreur de syntaxe |
| `test` | Vitest unit tests | test échoue |
| `sonarqube` | SAST — analyse qualité code | — |
| `security` | `npm audit` | vulnérabilité CRITICAL |
| `owasp` | OWASP Dependency Check (SCA) | CVSS ≥ 7 |
| `build-and-push` | Build Docker + Trivy scan + push GCP | CRITICAL/HIGH CVE |
| `deploy-staging` | Déploiement Cloud Run staging | — |
| `zap-scan` | OWASP ZAP Full Scan DAST sur staging | alerte ZAP |
| `deploy` | Déploiement Cloud Run **production** | zap-scan échoue |
| `build-push-grafana` | Build image Grafana | — |
| `deploy-grafana` | Déploiement Grafana sur Cloud Run | — |
| `build-push-acr` | Build Docker + push Azure ACR | — |
| `update-gitops` | Met à jour le tag image dans PFE-GitOps | — |

---

## Sécurité (Security Shift Left)

- **SAST** : SonarQube (runner self-hosted)
- **SCA** : OWASP Dependency Check + npm audit
- **Container scan** : Trivy (bloque si CRITICAL/HIGH)
- **DAST** : OWASP ZAP Full Scan sur environnement staging
- **Secrets** : Google Secret Manager (Grafana) + Azure Key Vault (AKS)
- **Auth GCP sans clé** : Workload Identity Federation (OIDC)

---

## Infrastructure GCP (Terraform)

Répertoire : [`terraform/`](./terraform/)

- Artifact Registry `my-repo`
- Cloud Run `my-app` (production, min 1 instance)
- Cloud Run `my-app-staging`
- Cloud Run `grafana`
- Workload Identity Federation (GitHub Actions → GCP, sans clé)
- Google Secret Manager (`grafana-admin-password`)
- Service Accounts dédiés

```bash
cd terraform/
terraform init
terraform apply
```

---

## Infrastructure Azure (Terraform)

Répertoire : [`azure/`](./azure/)

- Resource Group `sahar-rg` (East US)
- Azure Container Registry `saharacr.azurecr.io`
- AKS `sahar-aks` (Kubernetes 1.33, 1 nœud Standard_B2s)
- Azure Key Vault `sahar-kv-pfe` + CSI Secrets Store Driver
- Role Assignment AKS → ACR (`AcrPull`)

```bash
cd azure/
terraform init
terraform apply -var="acr_admin_password=<PASSWORD>"
```

---

## Lancer l'application localement

```bash
# Installer les dépendances
npm install

# Démarrer en mode développement
npm run dev

# Lancer les tests
npm test

# Build de production
npm run build
```

---

## Endpoints

| Service | URL |
|---------|-----|
| App production (GCP) | https://my-app-lpqw42tata-uc.a.run.app |
| App staging (GCP) | https://my-app-staging-lpqw42tata-uc.a.run.app |
| App (Azure AKS) | http://\<IP LoadBalancer\> |
| Grafana | https://grafana-lpqw42tata-uc.a.run.app |
| ArgoCD UI | https://\<IP LoadBalancer\> |
| SonarQube | http://localhost:9000 (self-hosted) |

---

## Secrets GitHub Actions requis

| Secret | Description |
|--------|-------------|
| `WIF_PROVIDER` | Workload Identity Federation provider (GCP) |
| `GCP_SA_EMAIL` | Service account email GCP deployer |
| `SONAR_TOKEN` | Token SonarQube |
| `ACR_USERNAME` | Username Azure Container Registry |
| `ACR_PASSWORD` | Password Azure Container Registry |
| `GITOPS_TOKEN` | PAT GitHub avec accès Contents R/W sur PFE-GitOps |

---

## Dépôts liés

| Dépôt | Rôle |
|-------|------|
| [PFE-DevSecopsProject](https://github.com/saharhamraoui/PFE-DevSecopsProject) | Ce dépôt — app + pipeline + Terraform |
| [PFE-GitOps](https://github.com/saharhamraoui/PFE-GitOps) | Manifests Kubernetes — géré par ArgoCD |

---

## Auteur

**Sahar Hamraoui** — Étudiante ingénieure ESPRIT, stagiaire Sopra Steria

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/REPLACE_WITH_PROJECT_ID) and click on Share -> Publish.

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/features/custom-domain#custom-domain)
