# 🧮 Explorer une population de 100 millions de personnes… pour zéro budget

 La statistique n’est pas réservée aux supercalculateurs ni aux logiciels coûteux.

 Avec **R** et quelques packages libres, il est possible de manipuler et d’analyser **des centaines de millions d’individus** sur un simple ordinateur.

## Objectif du projet

Générer une **population fictive réaliste** composée de millions d’individus, dotés de caractéristiques cohérentes


| Colonne          | Description                                    |
| ---------------- | ---------------------------------------------- |
| `prenom`         | Prénom simulé selon le sexe                    |
| `age`            | Âge recalculé à partir de la date de naissance |
| `date_naissance` | Date de naissance cohérente avec l’âge         |
| `sexe`           | Sexe biologique simulé (“Homme” / “Femme”)     |
| `taille`         | Taille en cm, distribuée selon le sexe         |
| `niveau_etudes`  | Niveau d’études selon l’âge                    |


L’ensemble repose sur une génération **vectorisée** via [`data.table`](https://rdatatable.gitlab.io/data.table/), assurant **vitesse et efficacité mémoire** même sur des jeux de données géants.
Les données sont ensuite analysés via les packages [`data.table`](https://cran.r-project.org/package=data.table) et  [`arrow`](https://cran.r-project.org/package=arrow) (parquet/dplyr)

- ✅ Génération rapide de plusieurs millions (jusqu’à 100 M) d’individus
- ✅ Données statistiquement plausibles et cohérentes
- ✅ Vectorisation complète (aucune boucle lente)
- ✅ Exports automatiques en **CSV** et **Parquet**
- ✅ Système de **log** détaillé (temps, étapes, succès)


## Création du jeu de données

- Initialisation
- Définition du nombre d’individus, de la date du jour et de la graine aléatoire (set.seed(42) - pour la reproductibilité).
- Lancement du chronomètre et du système de log.
- Dictionnaires et distributions
- Listes de prénoms masculins, féminins et unisexes.
- Répartition d’âge inspirée d’une pyramide réelle.
- Proportions de sexes réalistes (≈ 50/50).
- Création du tableau principal
- Génération vectorisée des variables sexe et age.
- Attribution conditionnelle d’un prénom selon le sexe.
- Dates et cohérence des âges
- Calcul d’une date de naissance aléatoire cohérente avec l’âge.
- Recalcul exact de l’âge à partir de la date.
- Taille et niveau d’études
- Simulation de la taille selon une distribution normale (différente pour hommes et femmes).
- Attribution d’un niveau d’études dépendant de l’âge (enfant, actif, senior).
- Export et logs
- Sauvegarde automatique en CSV et Parquet.
- Enregistrement des durées et statistiques globales dans un fichier de log.


### 💾 Export des données Parquet et CSV

Les fichiers produits sont enregistrés dans le répertoire courant :

* `population_1M.csv`
* `population_1M.parquet`

Ces formats sont directement exploitables dans **R**, **Python (pandas)**, ou tout environnement **Big Data** (Spark, Arrow…).


#### Nature des formats

| Format      | Type                               | Description                                                                 |
| ----------- | ---------------------------------- | --------------------------------------------------------------------------- |
| **CSV**     | Texte brut                         | Chaque ligne correspond à un enregistrement, colonnes séparées par virgule. |
| **Parquet** | Binaire, compressé, **colonnaire** | Stocke les données par colonne, avec typage et compression intégrés.        |


#### Principales différences

| Critère                | CSV              | Parquet                                 |
| ---------------------- | ---------------- | --------------------------------------- |
| Taille du fichier      | Large            | 5–10× plus petit                        |
| Lecture                | Lente            | Très rapide                             |
| Écriture               | Rapide           | Moyenne (compression)                   |
| Conservation des types | Non              | Oui                                     |
| Compatibilité          | Universelle      | Outils modernes (Arrow, Spark, Pandas…) |
| Idéal pour             | Échanges simples | Stockage massif et analyse rapide       |


En résumé

-  **CSV** : simple et universel, mais lent et volumineux.
- **Parquet** : compact, rapide, typé et prêt pour le Big Data —


## Arrow vs data.table — deux façons d’analyser les mêmes données

On cherche à fournir une **vue agrégée de la population** :

* combien d’individus ont chaque âge,
* quelle est la taille moyenne et sa dispersion selon l’âge,
* et si les distributions générées sont cohérentes.


| Colonne          | Description                                                                                                       |
| ---------------- | ----------------------------------------------------------------------------------------------------------------- |
| **`age`**        | Âge des individus (variable de regroupement). Chaque ligne du résultat correspond à un âge donné.                 |
| **`N`**          | Nombre d’individus de cet âge. Permet d’observer la répartition de la population.                                 |
| **`moy_age`**    | Moyenne de l’âge dans le groupe. Ici, elle est en pratique égale à la valeur d’`age` (vérification de cohérence). |
| **`p95_age`**    | 95ᵉ percentile de l’âge — indicateur de distribution utilisé à titre de contrôle.                                 |
| **`moy_taille`** | Taille moyenne (en cm) des individus ayant cet âge. Permet de visualiser la croissance selon l’âge.               |
| **`sd_taille`**  | Écart-type de la taille, c’est-à-dire la variabilité observée au sein du groupe d’âge.                            |




Une fois les fichiers exportés, le script compare deux méthodes d’analyse :

### 🟦 1. Avec **Arrow** (`query |> collect()`)

```r
query <- DTPQ %>%
  group_by(age) %>%
  summarise(
    N          = n(),
    moy_age    = mean(age, na.rm = TRUE),
    p95_age    = quantile(age, 0.95, na.rm = TRUE),
    moy_taille = mean(taille, na.rm = TRUE),
    sd_taille  = sd(taille, na.rm = TRUE)
  )
Results_Parquet <- query |> collect()
```

- Le fichier **Parquet** est lu *à la demande* (lazy loading).
- Le calcul est **déporté dans le moteur Arrow**, sans charger toutes les données en RAM.
- Seules les colonnes nécessaires (`age`, `taille`) sont lues.
- Idéal pour les très grands jeux de données (plusieurs dizaines ou centaines de millions de lignes).
- **Avantage :** ultra-rapide et économe en mémoire.
- **Format :** Parquet (colonnaire, compressé).



### 🟨 2. Avec **data.table** sur le **CSV**

```r
Results_DT <- DT[ , .(
  N          = .N,
  moy_age    = mean(age, na.rm = TRUE),
  p95_age    = quantile(age, 0.95, na.rm = TRUE),
  moy_taille = mean(taille, na.rm = TRUE),
  sd_taille  = sd(taille, na.rm = TRUE)
), by = age][order(age)]
```

-Le fichier **CSV** est lu en entier dans la mémoire (`fread`).
- Le calcul est ensuite effectué **entièrement en RAM**, via `data.table`.
- Les agrégations sont extrêmement rapides, mais nécessitent que tout tienne en mémoire.
- **Avantage :** très performant pour des fichiers déjà chargés.
- **Limite :** lecture lente et forte consommation mémoire sur de très grands fichiers.

### En résumé

| Aspect                         | `arrow` (Parquet)               | `data.table` (CSV)            |
| ------------------------------ | ------------------------------- | ----------------------------- |
| Lecture des données            | Paresseuse (lazy)               | Complète en RAM               |
| Format                         | Parquet (colonnaire, compressé) | CSV (texte brut)              |
| Colonnes lues                  | Sélectives                      | Toutes                        |
| Calcul                         | Déporté (moteur Arrow)          | Local (en mémoire)            |
| Performance sur grands volumes | ⚡ Très bonne                    | 🐢 Limitée par la mémoire     |
| Idéal pour                     | Données massives (Big Data)     | Données locales déjà chargées |


### Temps de traitement - Performances quasi linéaires

| Taille du jeu de données | Génération | Analyse (Arrow) | Analyse (data.table) |
| ------------------------ | ---------- | --------------- | -------------------- |
| **1 M**                  | 1.0 s      | 0.1 s           | 0.2 s                |
| **10 M**                 | 8.4 s      | 0.4 s           | 2.0 s                |
| **100 M**                | 87.2 s     | 4.3 s           | 17.8 s               |


* Le temps de génération croît **quasiment linéairement** avec la taille (×10 lignes → ×8 à ×10 temps).
* Lecture et agrégation restent **très rapides** : moins de 25 secondes pour 100 millions de lignes.
* `data.table` et `arrow` offrent une **scalabilité remarquable** et une **utilisation mémoire optimale**.

### 🧭 En résumé

> 🔹 **Arrow + Parquet** : pour lire et agréger rapidement d’énormes volumes sans les charger intégralement.
> 🔹 **data.table + CSV** : pour des analyses RAM rapides sur des jeux déjà importés.

Cette comparaison met en évidence l’intérêt de **coupler Arrow et Parquet** pour la lecture,
et **data.table** pour le calcul intensif : un duo puissant pour manipuler des données massives en R.


## Logs

```
2025-10-15 14:51:59 HST - Démarrage du script de génération de données 1M... 
2025-10-15 14:51:59 HST - Chargement des prénoms... 
2025-10-15 14:51:59 HST - Distribution d'âge générée. 
2025-10-15 14:51:59 HST - Modalités de sexe définies. 
2025-10-15 14:51:59 HST - Génération de la table principale... 
2025-10-15 14:51:59 HST - Table de base créée (1000000 lignes). 
2025-10-15 14:51:59 HST - Prénoms assignés. 
2025-10-15 14:51:59 HST - Dates de naissance et âges recalculés. 
2025-10-15 14:52:00 HST - Tailles générées. 
2025-10-15 14:52:00 HST - Niveau d'études assigné. 
2025-10-15 14:52:00 HST - Résumé : 1000000 individus 
2025-10-15 14:52:00 HST - Âge moyen : 44.9 ans 
2025-10-15 14:52:00 HST - Taille moyenne : 170.9 cm 
2025-10-15 14:52:00 HST - Répartition par sexe : Homme=49.5%, Femme=50.5% 
2025-10-15 14:52:00 HST - Export CSV terminé. 
2025-10-15 14:52:00 HST - Conversion en tibble terminé. 
2025-10-15 14:52:00 HST - Export Parquet terminé. 
2025-10-15 14:52:01 HST - Durée totale : 1.4 secondes 
2025-10-15 14:52:01 HST - Script terminé avec succès ✅ 
2025-10-15 14:52:01 HST - Démarrage du script d'analyse des données 1M... 
2025-10-15 14:52:01 HST - Ouverture du fichier parquet 
2025-10-15 14:52:01 HST - Lancement de arrow |> collect() 
2025-10-15 14:52:01 HST - Fin de arrow |> collect() 
2025-10-15 14:52:01 HST - Durée totale : 0.1 secondes 
2025-10-15 14:52:01 HST - Ouverture du fichier parquet 
2025-10-15 14:52:01 HST - Lancement de DT[, ...] 
2025-10-15 14:52:01 HST - Fin de DT[, ...] 
2025-10-15 14:52:01 HST - Durée totale : 0.3 secondes 


2025-10-15 14:52:01 HST - Démarrage du script de génération de données 10M... 
2025-10-15 14:52:02 HST - Chargement des prénoms... 
2025-10-15 14:52:02 HST - Distribution d'âge générée. 
2025-10-15 14:52:02 HST - Modalités de sexe définies. 
2025-10-15 14:52:02 HST - Génération de la table principale... 
2025-10-15 14:52:02 HST - Table de base créée (10000000 lignes). 
2025-10-15 14:52:04 HST - Prénoms assignés. 
2025-10-15 14:52:04 HST - Dates de naissance et âges recalculés. 
2025-10-15 14:52:06 HST - Tailles générées. 
2025-10-15 14:52:06 HST - Niveau d'études assigné. 
2025-10-15 14:52:06 HST - Résumé : 10000000 individus 
2025-10-15 14:52:06 HST - Âge moyen : 44.8 ans 
2025-10-15 14:52:06 HST - Taille moyenne : 170.9 cm 
2025-10-15 14:52:06 HST - Répartition par sexe : Homme=49.5%, Femme=50.5% 
2025-10-15 14:52:07 HST - Export CSV terminé. 
2025-10-15 14:52:07 HST - Conversion en tibble terminé. 
2025-10-15 14:52:10 HST - Export Parquet terminé. 
2025-10-15 14:52:11 HST - Durée totale : 9.5 secondes 
2025-10-15 14:52:11 HST - Script terminé avec succès ✅ 
2025-10-15 14:52:11 HST - Démarrage du script d'analyse des données 10M... 
2025-10-15 14:52:11 HST - Ouverture du fichier parquet 
2025-10-15 14:52:11 HST - Lancement de arrow |> collect() 
2025-10-15 14:52:11 HST - Fin de arrow |> collect() 
2025-10-15 14:52:11 HST - Durée totale : 0.5 secondes 
2025-10-15 14:52:11 HST - Ouverture du fichier parquet 
2025-10-15 14:52:13 HST - Lancement de DT[, ...] 
2025-10-15 14:52:13 HST - Fin de DT[, ...] 
2025-10-15 14:52:13 HST - Durée totale : 2.3 secondes 


2025-10-15 14:52:13 HST - Démarrage du script de génération de données 100M... 
2025-10-15 14:52:13 HST - Chargement des prénoms... 
2025-10-15 14:52:13 HST - Distribution d'âge générée. 
2025-10-15 14:52:13 HST - Modalités de sexe définies. 
2025-10-15 14:52:13 HST - Génération de la table principale... 
2025-10-15 14:52:20 HST - Table de base créée (100000000 lignes). 
2025-10-15 14:52:33 HST - Prénoms assignés. 
2025-10-15 14:52:43 HST - Dates de naissance et âges recalculés. 
2025-10-15 14:52:54 HST - Tailles générées. 
2025-10-15 14:53:02 HST - Niveau d'études assigné. 
2025-10-15 14:53:02 HST - Résumé : 100000000 individus 
2025-10-15 14:53:02 HST - Âge moyen : 44.8 ans 
2025-10-15 14:53:02 HST - Taille moyenne : 170.9 cm 
2025-10-15 14:53:02 HST - Répartition par sexe : Homme=49.5%, Femme=50.5% 
2025-10-15 14:53:10 HST - Export CSV terminé. 
2025-10-15 14:53:12 HST - Conversion en tibble terminé. 
2025-10-15 14:53:47 HST - Export Parquet terminé. 
2025-10-15 14:53:47 HST - Durée totale : 93.8 secondes 
2025-10-15 14:53:47 HST - Script terminé avec succès ✅ 
2025-10-15 14:53:47 HST - Démarrage du script d'analyse des données 100M... 
2025-10-15 14:53:47 HST - Ouverture du fichier parquet 
2025-10-15 14:53:48 HST - Lancement de arrow |> collect() 
2025-10-15 14:53:51 HST - Fin de arrow |> collect() 
2025-10-15 14:53:51 HST - Durée totale : 4.3 secondes 
2025-10-15 14:53:51 HST - Ouverture du fichier parquet 
2025-10-15 14:54:10 HST - Lancement de DT[, ...] 
2025-10-15 14:54:14 HST - Fin de DT[, ...] 
2025-10-15 14:54:14 HST - Durée totale : 22.5 secondes 
```

## 📜 Licence

🪪 **MIT License** — libre d’utilisation, de modification et de diffusion, sous réserve de mention de l’auteur.

