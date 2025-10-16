# ------------------------------------------------------------
# Jeu de données synthétique (1 000 000 d'individus) en data.table
# Auteur : toi :)
# Objectif : colonnes prenom, age, date_naissance, sexe, taille, niveau_etudes
# ------------------------------------------------------------

log_msg(sprintf("Démarrage du script de génération de données %s...", format_number(N)))
start_time_createdata <- Sys.time()
set.seed(42)  # reproductibilité
aujourd_hui <- Sys.Date()


# 2) Dictionnaires simples de prénoms FR (extraits courants, non exhaustifs)

# --- dictionnaires de prénoms ---
log_msg("Chargement des prénoms...")
prenoms_f <- c(
  "Emma","Louise","Jade","Alice","Chloé","Lina","Mila","Léa","Rose","Anna",
  "Camille","Sarah","Inès","Zoé","Jeanne","Manon","Eva","Lucie","Julia","Romy",
  "Lola","Ambre","Agathe","Charlie","Elena","Nina","Margaux","Madeleine","Ava","Maëlys",
  "Clémence","Marine","Apolline","Alix","Noémie","Elise","Pauline","Capucine","Adèle","Iris",
  "Victoire","Giulia","Louna","Salomé","Anouk","Héloïse","Éléonore","Yasmine","Billie","Maya"
)

prenoms_h <- c(
  "Gabriel","Léo","Raphaël","Arthur","Louis","Jules","Hugo","Maël","Noah","Adam",
  "Lucas","Paul","Gabin","Sacha","Nathan","Mohamed","Tom","Ethan","Aaron","Théo",
  "Timéo","Victor","Axel","Antoine","Rayan","Martin","Enzo","Maxime","Baptiste","Clément",
  "Oscar","Nolan","Émile","Samuel","Mathis","Noé","Eliott","Ibrahim","Yanis","Amaury",
  "Marius","Robin","Quentin","Charles","Diego","Valentin","Tiago","Simon","Ayden","Matteo"
)

prenoms_nb <- c( # prénoms unisexes courants
  "Alex","Charlie","Sasha","Camille","Maxime","Noa","Eden","Lou","Sam","Robin",
  "Andrea","Dominique","Morgan","Claude","Yaël"
)

# 3) Distribution de l'âge (0–100) ~ proche d'une pyramide réelle (approximation)
ages <- 0:100
poids_age <- numeric(length(ages))
poids_age[ages <= 4]   <- 1.2
poids_age[ages %between% c(5,14)]  <- 1.5
poids_age[ages %between% c(15,24)] <- 1.3
poids_age[ages %between% c(25,39)] <- 1.8
poids_age[ages %between% c(40,59)] <- 1.7
poids_age[ages %between% c(60,79)] <- 1.3
poids_age[ages >= 80]  <- 0.7
poids_age <- poids_age / sum(poids_age)
log_msg("Distribution d'âge générée.")

# 4) Sexe (proportions réalistes, en incluant une petite part non-binaire)
modalites_sexe <- c("Femme","Homme")
prob_sexe <- c(0.505, 0.495)
log_msg("Modalités de sexe définies.")


# 5) Génération vectorisée
log_msg("Génération de la table principale...")
DT <- data.table(id = 1:N,
                 sexe = sample(modalites_sexe, size = N, replace = TRUE, prob = prob_sexe),
                 age  = sample(ages, size = N, replace = TRUE, prob = poids_age))
log_msg("Table de base créée (%d lignes).", nrow(DT))

# 6) Prénoms conditionnels au sexe (vectorisé)
DT[, prenom := fifelse(sexe == "Femme", sample(prenoms_f, .N, TRUE),
               fifelse(sexe == "Homme", sample(prenoms_h, .N, TRUE), ""), "")]
log_msg("Prénoms assignés.")

# 7) Dates de naissance cohérentes avec l'âge
#    On pioche un jour de l'année au hasard puis on recalcule l'âge "observé" aujourd'hui
#    pour garantir la cohérence (floor((today - dob)/365.25))
jour_annee <- sample(0:364, N, replace = TRUE)
DT[, date_naissance_estimee := aujourd_hui - (age*365.25) - jour_annee]
# Recalcule l'âge exact à partir de la date de naissance pour cohérence stricte
DT[, date_naissance := as.Date(date_naissance_estimee)]
DT[, age := as.integer(floor(as.numeric(aujourd_hui - date_naissance) / 365.25))]
DT[, date_naissance_estimee := NULL]
log_msg("Dates de naissance et âges recalculés.")

# 8) Taille (cm) selon le sexe, avec troncature plausible
#    ~ N(178, 7^2) H ; N(164, 6.5^2) F ; mix pour NB
rnorm_clamp <- function(n, mean, sd, minv = 140, maxv = 205) {
  x <- rnorm(n, mean, sd)
  pmin(pmax(x, minv), maxv)
}

DT[sexe == "Homme",       taille := rnorm_clamp(.N, mean = 178, sd = 7)]
DT[sexe == "Femme",       taille := rnorm_clamp(.N, mean = 164, sd = 6.5)]
DT[, taille := round(taille, 1)]  # une décimale
log_msg("Tailles générées.")


# 9) Niveau d'études avec profil par âge
niv_etudes_levels <- c(
  "Aucun/Primaire", "Collège", "Lycée", "CAP/BEP",
  "Bac", "Bac+2", "Licence", "Master", "Doctorat"
)

# Fonction qui renvoie un échantillon de niveaux en fonction de l'âge
sample_niv <- function(age_vec) {
  n <- length(age_vec)
  out <- character(n)
  # tranches
  idx_0_14   <- which(age_vec <= 14)
  idx_15_17  <- which(age_vec %between% c(15,17))
  idx_18_24  <- which(age_vec %between% c(18,24))
  idx_25_39  <- which(age_vec %between% c(25,39))
  idx_40_59  <- which(age_vec %between% c(40,59))
  idx_60p    <- which(age_vec >= 60)
  
  # Probas (chaque vecteur doit sommer à 1)
  p_0_14  <- c(0.85, 0.10, 0.05, 0, 0, 0, 0, 0, 0)
  p_15_17 <- c(0.10, 0.45, 0.35, 0.05, 0.05, 0, 0, 0, 0)
  p_18_24 <- c(0.02, 0.10, 0.20, 0.10, 0.18, 0.18, 0.16, 0.05, 0.01)
  p_25_39 <- c(0.03, 0.07, 0.12, 0.12, 0.18, 0.20, 0.17, 0.09, 0.02)
  p_40_59 <- c(0.05, 0.10, 0.18, 0.15, 0.18, 0.17, 0.12, 0.04, 0.01)
  p_60p   <- c(0.10, 0.18, 0.22, 0.15, 0.16, 0.10, 0.07, 0.01, 0.01)
  
  # tirages
  if (length(idx_0_14))  out[idx_0_14]  <- sample(niv_etudes_levels, length(idx_0_14),  TRUE, p_0_14)
  if (length(idx_15_17)) out[idx_15_17] <- sample(niv_etudes_levels, length(idx_15_17), TRUE, p_15_17)
  if (length(idx_18_24)) out[idx_18_24] <- sample(niv_etudes_levels, length(idx_18_24), TRUE, p_18_24)
  if (length(idx_25_39)) out[idx_25_39] <- sample(niv_etudes_levels, length(idx_25_39), TRUE, p_25_39)
  if (length(idx_40_59)) out[idx_40_59] <- sample(niv_etudes_levels, length(idx_40_59), TRUE, p_40_59)
  if (length(idx_60p))   out[idx_60p]   <- sample(niv_etudes_levels, length(idx_60p),   TRUE, p_60p)
  
  out
}

DT[, niveau_etudes := sample_niv(age)]
DT[, niveau_etudes := factor(niveau_etudes, levels = niv_etudes_levels, ordered = TRUE)]
log_msg("Niveau d'études assigné.")

setcolorder(DT, c("prenom","age","date_naissance","sexe","taille","niveau_etudes"))
DT[, id := NULL]  # id non demandé

log_msg("Résumé : %d individus", nrow(DT))
log_msg("Âge moyen : %.1f ans", mean(DT$age))
log_msg("Taille moyenne : %.1f cm", mean(DT$taille))
log_msg("Répartition par sexe : %s", paste(DT[, .N, by=sexe][, paste0(sexe, "=", round(100*N/sum(N),1), "%")], collapse=", "))




# 11) (Optionnel) Contrôles rapides

#log_msg("Contrôles rapides")
#head(DT)
#DT[, .N]  # 1e6 ?
#DT[, .(moy_age = mean(age), p95_age = quantile(age, .95), moy_taille = mean(taille)), by = sexe]
#DT[, .N, by = niveau_etudes][order(niveau_etudes)]
#summary(DT$age)

 
# 12) Export
fwrite(DT, csv_path)
log_msg("Export CSV terminé.")
DT <- as_tibble(DT)
log_msg("Conversion en tibble terminé.")
arrow::write_parquet(DT, pq_path)
log_msg("Export Parquet terminé.")
#DT |>
#  group_by(age) |>
#  write_dataset(path = pq_path2,  format = "parquet")
#log_msg("Export Parquet par âge terminé.")


# --- fin ---
end_time <- Sys.time()
log_msg("Durée totale : %.1f secondes", as.numeric(difftime(end_time, start_time_createdata, units="secs")))
log_msg("Script terminé avec succès ✅")
