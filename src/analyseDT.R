log_msg(sprintf("Démarrage du script d'analyse des données %s...", format_number(N)))

log_msg("Ouverture du fichier CSV")
start_time_analyse <- Sys.time()
DT <- fread(csv_path)
log_msg("Lancement de DT[, ...]")  
Results_DT <- DT[ , .(
  N          = .N,
  moy_age    = mean(age, na.rm = TRUE),
  p95_age    = quantile(age, 0.95, na.rm = TRUE),
  moy_taille = mean(taille, na.rm = TRUE),
  sd_taille  = sd(taille, na.rm = TRUE)
), by = prenom][order(prenom)]
log_msg("Fin de DT[, ...]")  
end_time <- Sys.time()
log_msg("Durée totale : %.1f secondes", as.numeric(difftime(end_time, start_time_analyse, units="secs")))
