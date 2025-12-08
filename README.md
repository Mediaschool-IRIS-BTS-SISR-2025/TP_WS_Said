# TP Windows Server – Infrastructure d’Établissement
## Déploiement AD DS • DNS • DHCP • GPO • FSRM • WSUS • MDT/WDS  
### Auteur : **Saïd AHMED MOUSSA – BTS SIO 2 SISR**

---

## 1. 🎯 Contexte du TP

Ce TP a pour objectif de mettre en place l’infrastructure informatique d’un établissement scolaire (lycée).  
L’environnement repose sur **Windows Server 2022** et doit permettre :

- La centralisation des identités (Active Directory)
- La gestion des postes élèves / professeurs / administratifs
- La gestion du réseau (DHCP + DNS)
- La sécurisation par politiques (GPO)
- La gestion des quotas (FSRM)
- La gestion interne des mises à jour (WSUS)
- Le déploiement automatique de Windows (MDT + WDS)

L’objectif final est de reproduire un **SI complet**, similaire à ce qui existe dans un vrai établissement scolaire.

---

## 2. 🎓 Objectifs pédagogiques

Le TP permet de :

✔ Comprendre et administrer Active Directory  
✔ Structurer une organisation (OU, groupes, comptes)  
✔ Déployer des services réseau : DHCP, DNS  
✔ Implémenter des politiques de sécurité (GPO)  
✔ Gérer l’espace disque (FSRM)  
✔ Administrer et configurer un service WSUS  
✔ Déployer des postes à distance via MDT et WDS  
✔ Automatiser la configuration grâce à PowerShell  

---

## 3. 🖧 Architecture Réseau du Lycée

```
           RÉSEAU 192.168.100.0 / 24

                +-----------------------+
                |      SRV-DC1          |
                | AD DS / DNS / DHCP    |
                | 192.168.100.10        |
                +-----------+-----------+
                            |
                            |
                +-----------+-----------+
                |        SRV-FS1        |
                |  Fichiers / FSRM      |
                |  WSUS / WDS / MDT     |
                | 192.168.100.20        |
                +-----------+-----------+
                            |
                            |
                +-----------+-----------+
                |     Client Windows     |
                | DHCP / Domaine AD      |
                +------------------------+
```

---

## 4. 📌 Plan d’Adressage IP

| Élément | Adresse | Rôle |
|--------|---------|------|
| SRV-DC1 | 192.168.100.10 | AD, DNS, DHCP |
| SRV-FS1 | 192.168.100.20 | Partages, Quotas, WSUS, WDS/MDT |
| Client Windows 11 | DHCP | Poste géré par le domaine |

Scope DHCP défini : **192.168.100.50 → 192.168.100.200**

---

## 5. 📂 Structure Active Directory

L’arborescence AD mise en place :

```
ECOLE
 ├── Comptes-Utilisateurs
 │    ├── Administration
 │    ├── Profs
 │    └── Eleves
 └── Comptes-Ordinateurs
      ├── Pilotes
      └── Production
```

Groupes de sécurité :

- **MS-Administration**
- **MS-Profs**
- **MS-Eleves**

---

## 6. 🔧 Scripts PowerShell – Explications détaillées

### 6.1 **etape1.ps1 — Installation AD/DNS/DHCP + Promotion du DC**

- Installe les rôles AD DS, DNS, DHCP  
- Définit un mot de passe Administrateur conforme  
- Promote SRV-DC1 en contrôleur de domaine  
- Domaine créé : `mediaschool.local`

---

### 6.2 **etape2.ps1 — Structure Active Directory**

- Création de la zone DNS inverse  
- Création des OU  
- Création des groupes globaux  

---

### 6.3 **dhcp.ps1 — Configuration DHCP**

- Ajout du serveur DHCP à AD  
- Scope : 192.168.100.50 ➝ 200  
- Options : routeur (003), DNS (006), domaine (015)  
- Mises à jour DNS sécurisées  

---

### 6.4 **horaires.ps1 / horloge.ps1 — Gestion des horaires**

- Élèves : 08h–18h  
- Profs : 07h–20h  
- Administration : 07h–19h  

---

### 6.5 **partage&quota.ps1 — Dossiers personnels & Quotas**

- Création du partage Homes  
- Templates FSRM :
  - Élèves : 1 Go  
  - Profs : 5 Go  
  - Admin : 10 Go  
- AutoQuota appliqué à `D:\Donnees\Homes`  

---

### 6.6 **config wsus.ps1 — WSUS**

- Initialisation WSUS  
- Produits Windows 10 / 11 / Server 2022  
- Classifications Security / Critical / Definition  
- Groupes WSUS  
- Mise à jour et synchronisation  

---

### 6.7 **wsu&wds.ps1 — GPO WSUS + DHCP PXE**

- Création GPO WSUS Pilote & Production  
- Paramétrage registre client WSUS  
- Options DHCP PXE (66 & 67)  

---

### 6.8 **wds & mdt.ps1 — Déploiement Windows Automatisé**

- Initialisation WDS  
- Importation Windows 11  
- Task Sequence MDT  
- Boot LiteTouchPE ajouté à WDS  

---

## 7. 🧪 Tests & Vérifications

✔ Résolution DNS  
✔ Attribution IP DHCP  
✔ Intégration domaine OK  
✔ GPO appliquées  
✔ Quotas FSRM fonctionnels  
✔ WSUS opérationnel  
✔ PXE fonctionnel via WDS  
✔ Déploiement Windows 11 automatisé  

---

## 8. 🧠 Conclusion

Ce TP valide les compétences essentielles du BTS SIO SISR :

- Administration AD/DNS/DHCP  
- GPO avancées  
- Gestion du stockage avec FSRM  
- WSUS + WDS/MDT  
- Automatisation PowerShell  
- Déploiement complet d'une infrastructure Windows Server  


