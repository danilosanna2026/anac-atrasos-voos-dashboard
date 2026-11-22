-- Tabela tratada: um voo por linha, com atrasos em minutos e flags de qualidade.
-- Atraso = horario real - horario previsto (positivo = atrasou, negativo = adiantou).
DROP TABLE IF EXISTS voos;
CREATE TABLE voos AS
SELECT
    empresa,
    numero_voo,
    origem,
    destino,
    situacao,
    partida_prevista,
    partida_real,
    chegada_prevista,
    chegada_real,
    date(partida_prevista)                       AS data_prevista,
    substr(partida_prevista, 1, 7)               AS ano_mes,
    CAST(strftime('%w', partida_prevista) AS INT) AS dia_semana,   -- 0 = domingo
    -- Escopo definido a partir dos prefixos ICAO brasileiros (SB, SD, SI, SJ, SN, SS, SW)
    CASE WHEN substr(origem, 1, 2)  IN ('SB','SD','SI','SJ','SN','SS','SW')
          AND substr(destino, 1, 2) IN ('SB','SD','SI','SJ','SN','SS','SW')
         THEN 'Doméstico' ELSE 'Internacional' END AS escopo,
    ROUND((julianday(partida_real) - julianday(partida_prevista)) * 1440) AS atraso_partida_min,
    ROUND((julianday(chegada_real) - julianday(chegada_prevista)) * 1440) AS atraso_chegada_min
FROM voos_brutos;

-- Flags de qualidade
ALTER TABLE voos ADD COLUMN tem_horarios INTEGER;
ALTER TABLE voos ADD COLUMN atraso_inconsistente INTEGER;
ALTER TABLE voos ADD COLUMN analisavel INTEGER;
ALTER TABLE voos ADD COLUMN no_periodo INTEGER;

-- voo realizado com os 4 horarios preenchidos
UPDATE voos SET tem_horarios =
    CASE WHEN situacao = 'REALIZADO'
          AND partida_prevista IS NOT NULL AND partida_real IS NOT NULL
          AND chegada_prevista IS NOT NULL AND chegada_real IS NOT NULL
         THEN 1 ELSE 0 END;

-- atrasos fora de [-120 min, +1440 min] sao tratados como registro inconsistente
-- (adiantamento de mais de 2 h ou atraso de mais de 24 h)
UPDATE voos SET atraso_inconsistente =
    CASE WHEN tem_horarios = 1
          AND (atraso_partida_min  NOT BETWEEN -120 AND 1440
            OR atraso_chegada_min  NOT BETWEEN -120 AND 1440)
         THEN 1 ELSE 0 END;

-- periodo de analise: voos com partida prevista em 2025 (os arquivos mensais trazem alguns voos de jan/2026)
UPDATE voos SET no_periodo = CASE WHEN data_prevista BETWEEN '2025-01-01' AND '2025-12-31' THEN 1 ELSE 0 END;

UPDATE voos SET analisavel = CASE WHEN tem_horarios = 1 AND atraso_inconsistente = 0 AND no_periodo = 1 THEN 1 ELSE 0 END;

CREATE INDEX idx_voos_data ON voos(data_prevista);
CREATE INDEX idx_voos_empresa ON voos(empresa);
