CREATE OR REPLACE VIEW population_100M AS 
SELECT * FROM read_parquet('C:\Users\laurentp\source\repos\10power8\output\population_100M.parquet');

SELECT
prenom,
COUNT(*) AS N,
AVG(age) AS moy_age,
PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY age) AS p95_age,
AVG(taille) AS moy_taille,
STDDEV(taille) AS sd_taille
FROM  population_100M
GROUP BY prenom
ORDER BY prenom;

SELECT sexe,taille, count(*) 
FROM population_100M 
GROUP BY sexe, taille 
ORDER BY sexe, taille;

SELECT niveau_etudes, count(*) 
FROM population_100M 
GROUP BY niveau_etudes 
ORDER BY niveau_etudes;

SELECT prenom, age, count(*) 
FROM population_100M 
GROUP BY age 
ORDER BY age;