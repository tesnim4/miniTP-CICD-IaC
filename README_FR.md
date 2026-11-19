# Mini-TP réel : CI/CD + Infrastructure as Code

## Ce que vous allez montrer

1. Une page HTML simple est empaquetée dans une image Docker.
2. Terraform décrit l'image et le conteneur à créer.
3. Terraform affiche le plan, puis crée le conteneur Nginx sur le port 8080.
4. Vous vérifiez la page dans le navigateur, puis vous détruisez et recréez l'infrastructure.
5. En poussant le projet sur GitHub, GitHub Actions vérifie Terraform, construit l'image Docker et teste la page automatiquement.

**Important :** la partie Terraform/Docker se fait localement. GitHub Actions réalise ici une intégration continue (validation + build + test), pas un déploiement en production. L'extension Ansible est séparée : elle nécessite une machine Linux accessible en SSH.

## Prérequis

- Docker Desktop installé et démarré (icône Docker active).
- Terraform installé et disponible dans le terminal (`terraform -version`).
- Git installé (`git --version`).
- Un compte GitHub pour observer le pipeline (facultatif pour la partie locale).

Dans PowerShell, vérifier :

```powershell
docker version
docker info
terraform -version
git --version
```

Si `docker info` échoue, démarrer Docker Desktop avant de continuer. Sur Windows, si Terraform n'arrive pas à joindre le moteur Docker, essayer dans PowerShell :

```powershell
$env:DOCKER_HOST = "npipe:////./pipe/docker_engine"
docker info
```

Si le moteur est accessible par Docker mais pas par Terraform, faire le mini-TP dans Ubuntu sous WSL2 avec l'intégration Docker Desktop activée.

## Partie A — Démonstration locale avec Terraform et Docker

Ouvrir PowerShell dans le dossier du projet :

```powershell
cd chemin\vers\miniTP_CICD_IaC
```

### 1. Présenter les fichiers

- `index.html` : la page web à afficher.
- `Dockerfile` : explique comment fabriquer l'image Nginx avec notre page.
- `main.tf` : décrit l'image Docker et le conteneur voulu.
- `.github/workflows/ci.yml` : décrit les vérifications automatiques sur GitHub.

### 2. Construire et vérifier l'image Docker (facultatif avant Terraform)

```powershell
docker build -t mini-tp-cicd:1.0 .
docker image ls
```

### 3. Initialiser Terraform

```powershell
terraform init
```

Expliquer : Terraform télécharge le provider Docker, c'est le connecteur qui permet à Terraform de parler au moteur Docker.

### 4. Formater et valider

```powershell
terraform fmt
terraform validate
```

Expliquer : `fmt` met le fichier au format standard ; `validate` vérifie la cohérence de la configuration.

### 5. Afficher le plan avant de modifier quoi que ce soit

```powershell
terraform plan
```

Faire observer les deux ressources annoncées : `docker_image.web` et `docker_container.web`. Dire : « Le plan est un aperçu ; à ce stade, Terraform n'a pas encore créé le conteneur. »

### 6. Créer l'infrastructure

```powershell
terraform apply
```

Lire le plan affiché puis taper `yes` à la demande de confirmation. Pour une démonstration contrôlée, préférer cette commande à `-auto-approve`.

### 7. Vérifier le résultat réel

```powershell
docker ps
```

Ouvrir dans le navigateur : `http://localhost:8080`.

Ou tester depuis PowerShell :

```powershell
(Invoke-WebRequest http://localhost:8080).StatusCode
```

Le résultat attendu est `200`, et la page doit afficher « Bravo ! Le mini-TP fonctionne. »

### 8. Montrer l'idempotence

```powershell
terraform plan
```

Le résultat attendu est qu'aucun changement n'est nécessaire (`No changes`). Expliquer : « Terraform compare l'état déclaré avec l'état réel. Si rien n'a changé, il ne recrée pas inutilement le conteneur. »

### 9. Détruire puis recréer

```powershell
terraform destroy
```

Confirmer avec `yes`, puis actualiser `http://localhost:8080` : le service n'est plus disponible.

Recréer :

```powershell
terraform apply
```

Confirmer avec `yes`, puis recharger la page. Elle revient. C'est la reproductibilité.

À la fin, nettoyer :

```powershell
terraform destroy
```

## Partie B — Montrer le pipeline GitHub Actions

Cette partie nécessite un dépôt GitHub. Créer un dépôt vide nommé `miniTP-CICD-IaC`, puis dans PowerShell, à la racine du dossier :

```powershell
git init
git add .
git commit -m "Initialisation du mini TP CI-CD IaC"
git branch -M main
git remote add origin https://github.com/VOTRE-COMPTE/miniTP-CICD-IaC.git
git push -u origin main
```

Remplacer `VOTRE-COMPTE` par votre identifiant GitHub. Si Git demande une authentification, suivre la fenêtre de connexion proposée.

Sur GitHub : ouvrir le dépôt puis l'onglet **Actions**. Le workflow « CI - Mini TP CI-CD IaC » démarre automatiquement.

Faire observer les étapes :

1. Checkout : GitHub récupère les fichiers.
2. Terraform fmt/init/validate : le code d'infrastructure est contrôlé.
3. `needs: validate-infrastructure` : le job Docker attend la réussite du premier job.
4. Docker build : l'image est construite.
5. Docker run + curl : le conteneur démarre et la page est testée.
6. Nettoyage : le conteneur temporaire du runner est supprimé.

Pour montrer un déclenchement, modifier une phrase dans `index.html`, puis :

```powershell
git add .
git commit -m "Modification de la page"
git push
```

Retourner dans **Actions** et observer le nouveau pipeline. On peut aussi créer volontairement une erreur de format dans `main.tf`, pousser, et constater que le job suivant est bloqué ; corriger ensuite le fichier et repousser.

## Extension facultative — Ansible

Ansible configure une machine Linux distante ; il ne remplace pas Terraform. Terraform provisionne les ressources, Ansible configure le système et les services.

Le playbook fourni suppose un hôte Debian/Ubuntu nommé `web`, accessible en SSH avec un utilisateur autorisé à utiliser `sudo`. Créer un fichier `ansible/inventory.ini` adapté à votre machine Linux :

```ini
[web]
192.168.1.50 ansible_user=ubuntu
```

Remplacer l'adresse et l'utilisateur par ceux de votre VM Linux. Depuis Ubuntu/WSL avec Ansible installé, lancer :

```bash
ansible -i ansible/inventory.ini web -m ping
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

Ne pas lancer ce playbook sur une machine dont vous ne possédez pas l'accès. Sans VM Linux/SSH, expliquer le rôle d'Ansible à partir du fichier et ne pas prétendre l'avoir exécuté.

## Déroulé oral conseillé (5 à 7 minutes)

- 30 s : annoncer l'objectif et le résultat attendu.
- 1 min : présenter `Dockerfile`, `index.html` et `main.tf`.
- 1 min : lancer `terraform init`, `terraform validate` et `terraform plan`.
- 1 min : lancer `terraform apply` et ouvrir `localhost:8080`.
- 30 s : refaire `terraform plan` pour montrer « No changes ».
- 1 min : `terraform destroy`, puis `terraform apply` pour prouver la reproductibilité.
- 1 à 2 min : ouvrir GitHub Actions et expliquer les jobs, le contrôle et la dépendance `needs`.

**Phrase de conclusion :** « Nous avons décrit l'infrastructure dans un fichier versionnable, demandé à Terraform de la créer, vérifié le service, puis recréé le même résultat. En parallèle, GitHub Actions automatise les contrôles à chaque push. »
