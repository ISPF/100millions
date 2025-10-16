#| **Taille des données** | **Génération (s)** | **Analyse Parquet (s)** | **Analyse CSV (s)** |
#| ---------------------- | ------------------ | ----------------------- | ------------------- |
#| **1 M**                | 00.4 s             | 0.1 s                   | 0.3 s               |
#| **10 M**               | 09.5 s             | 0.5 s                   | 2.3 s               |
#| **100 M**              | 93.8 s             | 4.3 s                   | 22.5 s              |
  

N <- 1e7  
source("src/functions.R")
source("src/createData.R")
source("src/analyse.R")

head(Results_DT)
head(Results_Parquet)
