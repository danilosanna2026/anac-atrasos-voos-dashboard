# Dicionário de dados

## Fonte original: VRA (Voo Regular Ativo), ANAC

Um arquivo CSV por mês, separador `;`, primeira linha com `Atualizado em: ...` e cabeçalho na segunda.

| Coluna original | Descrição | Observações verificadas nos dados de 2025 |
|---|---|---|
| ICAO Empresa Aérea | Código ICAO da companhia | 111 códigos distintos |
| Número Voo | Número do voo | texto, com zeros à esquerda |
| Código Autorização (DI) | Código de autorização | — |
| Código Tipo Linha | Código do tipo de linha (N, I, G, C ou NA) | Significado não documentado nos arquivos; **não usado** (o escopo doméstico/internacional foi derivado dos códigos ICAO dos aeroportos) |
| ICAO Aeródromo Origem / Destino | Código ICAO dos aeroportos | 419 códigos distintos, 91% dos voos com origem brasileira |
| Partida Prevista / Real, Chegada Prevista / Real | Data e hora | Sem fuso horário informado; ausentes aparecem como o texto `null` |
| Situação Voo | `REALIZADO` ou `CANCELADO` | 2,8% cancelados |
| Código Justificativa | Justificativa do atraso/cancelamento | **`N/A` em 100% das linhas de 2025**: a base não permite analisar causas |

## Tabelas geradas neste projeto

**`voos`** (SQLite, um voo por linha, `sql/01_voos_tratados.sql`)

| Coluna | Descrição |
|---|---|
| atraso_partida_min / atraso_chegada_min | Horário real − horário previsto, em minutos (positivo = atraso) |
| escopo | `Doméstico` se origem e destino têm prefixo ICAO brasileiro (SB, SD, SI, SJ, SN, SS, SW); senão `Internacional` |
| no_periodo | 1 se a partida prevista é em 2025 |
| tem_horarios | 1 se o voo foi realizado e tem os 4 horários |
| atraso_inconsistente | 1 se algum atraso está fora de −120 a +1440 minutos |
| analisavel | 1 se `no_periodo` e `tem_horarios` e não inconsistente. Só estes entram nas taxas de atraso |

**`fato_dia_companhia`** (dia × companhia × escopo) e **`fato_aeroporto_mes`** (mês × companhia × aeroporto de origem × escopo)

`companhia` separa Azul, LATAM Brasil e GOL (códigos ICAO AZU, TAM, GLO); as outras 108 companhias da base ficam em "Demais companhias".

| Coluna | Descrição |
|---|---|
| voos_programados | Voos com partida prevista no período (realizados + cancelados) |
| voos_cancelados | Cancelados |
| voos_analisaveis | Base das taxas de atraso |
| partidas_atrasadas_15 | Partida com mais de 15 min de atraso |
| chegadas_atrasadas_15 / _30 | Chegada com mais de 15 / 30 min de atraso (`_30` e minutos só em `fato_dia_companhia`; nos voos que partiram do aeroporto, em `fato_aeroporto_mes`) |
| minutos_atraso_chegada_dos_atrasados | Soma dos minutos de atraso de chegada dos voos com mais de 15 min |

**`fato_rotas_mes`**: contagens por mês × origem × destino. **`dim_aeroporto`**: cadastro de aeródromos públicos da ANAC (nome, município, UF, coordenadas); aeroportos sem cadastro ficam só com o código ICAO.

## Medidas calculadas no painel

- % de atraso na chegada = soma(chegadas_atrasadas_15) / soma(voos_analisaveis)
- % de cancelamento = soma(voos_cancelados) / soma(voos_programados)
- Atraso médio dos voos atrasados (min) = soma(minutos_atraso_chegada_dos_atrasados) / soma(chegadas_atrasadas_15)
