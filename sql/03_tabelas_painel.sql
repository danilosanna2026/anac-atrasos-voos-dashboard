-- Tabelas agregadas que alimentam o painel (Looker Studio).
-- Medidas guardadas como contagens/somas para o Looker recalcular taxas corretamente em qualquer filtro.

-- Companhias: as tres maiores aparecem separadas; as demais (110 codigos ICAO) ficam em 'Demais companhias'.
-- Fato diario: um registro por dia x companhia x escopo (serie temporal e dias criticos)
DROP TABLE IF EXISTS fato_dia_companhia;
CREATE TABLE fato_dia_companhia AS
SELECT
    data_prevista                                                    AS data,
    CASE empresa WHEN 'AZU' THEN 'Azul' WHEN 'TAM' THEN 'LATAM Brasil' WHEN 'GLO' THEN 'GOL'
         ELSE 'Demais companhias' END                                 AS companhia,
    escopo,
    COUNT(*)                                                         AS voos_programados,
    SUM(situacao = 'CANCELADO')                                      AS voos_cancelados,
    SUM(analisavel)                                                  AS voos_analisaveis,
    SUM(CASE WHEN analisavel = 1 AND atraso_partida_min > 15 THEN 1 ELSE 0 END) AS partidas_atrasadas_15,
    SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) AS chegadas_atrasadas_15,
    SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 30 THEN 1 ELSE 0 END) AS chegadas_atrasadas_30,
    SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN atraso_chegada_min ELSE 0 END) AS minutos_atraso_chegada_dos_atrasados
FROM voos
WHERE no_periodo = 1
GROUP BY data_prevista, companhia, escopo;

-- Fato por aeroporto: um registro por mes x companhia x aeroporto de origem x escopo
DROP TABLE IF EXISTS fato_aeroporto_mes;
CREATE TABLE fato_aeroporto_mes AS
SELECT
    ano_mes,
    CASE empresa WHEN 'AZU' THEN 'Azul' WHEN 'TAM' THEN 'LATAM Brasil' WHEN 'GLO' THEN 'GOL'
         ELSE 'Demais companhias' END                                 AS companhia,
    origem                                                           AS aeroporto_origem,
    escopo,
    COUNT(*)                                                         AS voos_programados,
    SUM(situacao = 'CANCELADO')                                      AS voos_cancelados,
    SUM(analisavel)                                                  AS voos_analisaveis,
    SUM(CASE WHEN analisavel = 1 AND atraso_partida_min > 15 THEN 1 ELSE 0 END) AS partidas_atrasadas_15,
    SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) AS chegadas_atrasadas_15
FROM voos
WHERE no_periodo = 1
GROUP BY ano_mes, companhia, origem, escopo;

-- Rotas por mes: um registro por origem x destino x mes
DROP TABLE IF EXISTS fato_rotas_mes;
CREATE TABLE fato_rotas_mes AS
SELECT
    ano_mes,
    origem                                                           AS aeroporto_origem,
    destino                                                          AS aeroporto_destino,
    origem || ' > ' || destino                                       AS rota,
    COUNT(*)                                                         AS voos_programados,
    SUM(situacao = 'CANCELADO')                                      AS voos_cancelados,
    SUM(analisavel)                                                  AS voos_analisaveis,
    SUM(CASE WHEN analisavel = 1 AND atraso_chegada_min > 15 THEN 1 ELSE 0 END) AS chegadas_atrasadas_15
FROM voos
WHERE no_periodo = 1
GROUP BY ano_mes, origem, destino;

-- Dimensao de aeroportos (cadastro ANAC; aeroportos sem cadastro ficam identificados so pelo codigo ICAO)
DROP TABLE IF EXISTS dim_aeroporto;
CREATE TABLE dim_aeroporto AS
SELECT
    c.icao                                                           AS icao,
    COALESCE(a.nome, c.icao)                                         AS nome,
    COALESCE(a.municipio, 'Não cadastrado')                          AS municipio,
    COALESCE(a.uf, CASE WHEN substr(c.icao,1,2) IN ('SB','SD','SI','SJ','SN','SS','SW') THEN 'Não cadastrado' ELSE 'Exterior' END) AS uf,
    a.latitude                                                       AS latitude,
    a.longitude                                                      AS longitude,
    CASE WHEN a.latitude IS NOT NULL THEN a.latitude || ',' || a.longitude END AS latlong
FROM (SELECT DISTINCT origem AS icao FROM voos UNION SELECT DISTINCT destino FROM voos) c
LEFT JOIN aerodromos a ON a.icao = c.icao;
