-- Consultas exploratorias usadas para responder as perguntas do projeto.
-- Convencao: "atrasado" = chegada com mais de 15 min de atraso (atraso_chegada_min > 15).

-- Q1. Visao geral
SELECT
    COUNT(*)                                                      AS voos_programados,
    SUM(situacao = 'CANCELADO')                                   AS cancelados,
    ROUND(100.0 * SUM(situacao = 'CANCELADO') / COUNT(*), 2)      AS pct_cancelados,
    SUM(analisavel)                                               AS voos_analisaveis,
    ROUND(100.0 * SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) / SUM(analisavel), 2) AS pct_atraso_chegada_15,
    ROUND(100.0 * SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 30 THEN 1 ELSE 0 END) / SUM(analisavel), 2) AS pct_atraso_chegada_30
FROM voos
WHERE no_periodo = 1;

-- Q2. Por companhia (minimo de 10 mil voos programados)
SELECT
    empresa,
    COUNT(*)                                                      AS voos_programados,
    ROUND(100.0 * SUM(situacao = 'CANCELADO') / COUNT(*), 2)      AS pct_cancelados,
    ROUND(100.0 * SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) / NULLIF(SUM(analisavel), 0), 2) AS pct_atraso_chegada_15
FROM voos
WHERE no_periodo = 1
GROUP BY empresa
HAVING COUNT(*) >= 10000
ORDER BY pct_atraso_chegada_15 DESC;

-- Q3. Por mes
SELECT
    ano_mes,
    COUNT(*)                                                      AS voos_programados,
    ROUND(100.0 * SUM(situacao = 'CANCELADO') / COUNT(*), 2)      AS pct_cancelados,
    ROUND(100.0 * SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) / SUM(analisavel), 2) AS pct_atraso_chegada_15
FROM voos
WHERE no_periodo = 1
GROUP BY ano_mes ORDER BY ano_mes;

-- Q4. Por dia da semana (0 = domingo)
SELECT
    dia_semana,
    COUNT(*)                                                      AS voos_programados,
    ROUND(100.0 * SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) / SUM(analisavel), 2) AS pct_atraso_chegada_15
FROM voos
WHERE no_periodo = 1
GROUP BY dia_semana ORDER BY dia_semana;

-- Q5. Aeroportos de origem com mais atraso na partida (minimo de 5 mil saidas analisaveis)
SELECT
    v.origem,
    a.nome, a.municipio, a.uf,
    SUM(v.analisavel)                                             AS saidas_analisaveis,
    ROUND(100.0 * SUM(CASE WHEN v.analisavel = 1 AND v.atraso_partida_min > 15 THEN 1 ELSE 0 END) / SUM(v.analisavel), 2) AS pct_atraso_partida_15
FROM voos v LEFT JOIN aerodromos a ON a.icao = v.origem
WHERE v.no_periodo = 1 AND v.escopo = 'Doméstico'
GROUP BY v.origem
HAVING SUM(v.analisavel) >= 5000
ORDER BY pct_atraso_partida_15 DESC
LIMIT 15;

-- Q6. Doméstico x Internacional
SELECT
    escopo,
    COUNT(*)                                                      AS voos_programados,
    ROUND(100.0 * SUM(situacao = 'CANCELADO') / COUNT(*), 2)      AS pct_cancelados,
    ROUND(100.0 * SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) / SUM(analisavel), 2) AS pct_atraso_chegada_15
FROM voos
WHERE no_periodo = 1
GROUP BY escopo;
