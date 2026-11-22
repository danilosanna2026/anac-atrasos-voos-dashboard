# Atrasos e cancelamentos de voos no Brasil em 2025 (ANAC) — SQL + Looker Studio

Análise de **977.584 voos programados em 2025** (dados abertos da ANAC) com Python, SQL (SQLite) e um painel interativo no Looker Studio.

**Painel interativo:** [abrir no Looker Studio](https://datastudio.google.com/reporting/108c9307-de33-46c1-af7c-1016138d5300) (cartões com a taxa de atraso, a taxa de cancelamento e o total de voos; série diária; comparação entre companhias; filtro doméstico/internacional).

## O que os dados mostram

| Indicador (2025) | Resultado |
|---|---|
| Voos programados / cancelados | 977.584 / 27.705 (**2,8%**) |
| Chegadas com mais de 15 min de atraso | **16,0%** (8,6% com mais de 30 min) |
| Doméstico x internacional (atraso >15 min) | 14,4% x **24,2%**; cancelamentos 2,0% x 6,6% |
| Três maiores companhias (atraso >15 min) | GOL 11,6% · Azul 14,3% · LATAM Brasil 16,7% |
| Melhor e pior mês | Março 13,3% · **Dezembro 26,5%** |
| Dia da semana | Sexta 18,0% · Sábado 13,3% · Domingo 13,4% |
| Aeroporto com mais atraso na partida (voos domésticos, mín. 5 mil saídas) | Guarulhos (SBGR) **24,4%**; Congonhas (SBSP) 16,8% |
| Rotas com mais de 3 mil voos | Piores: saindo de Guarulhos (até 24,5%). Melhor: ponte aérea Santos Dumont–Brasília (~6%) |

**Dias críticos.** O pior dia do ano foi 10/12/2025: 60,8% dos voos atrasaram e 17,8% foram cancelados. A base não informa causas (ver limitações); a notícia da época registra um ciclone extratropical com ventania em São Paulo (Congonhas e Guarulhos) com efeito em aeroportos de vários estados. Em 30/09/2025, o Santos Dumont (SBRJ) cancelou 79 dos 89 voos programados, o que coincide com a suspensão das operações por vazamento de óleo na pista noticiada no dia. Em 22/09/2025 (50,1% de atrasos) não identifiquei a causa.

## Como o projeto foi feito

1. **Coleta**: 12 arquivos mensais do VRA (Voo Regular Ativo) e o cadastro de aeródromos públicos, no portal de dados abertos da ANAC. `scripts/00_coleta.py`.
2. **Carga e limpeza**: leitura dos CSVs (`;`, cabeçalho na 2ª linha, ausentes escritos como `null`), remoção de 4 linhas duplicadas e gravação em SQLite. `scripts/01_carga_sqlite.py`.
3. **Tratamento em SQL**: cálculo dos atrasos em minutos, escopo doméstico/internacional, flags de qualidade. `sql/01_voos_tratados.sql`.
4. **Análise em SQL**: perguntas por companhia, mês, dia da semana, aeroporto e rota. `sql/02_indicadores.sql`.
5. **Tabelas do painel**: agregados em `sql/03_tabelas_painel.sql`, exportados para `data/painel/`.
6. **Painel no Looker Studio** sobre essas tabelas. Passo a passo detalhado em [`docs/passo_a_passo.md`](docs/passo_a_passo.md).

## Definições adotadas

- **Atraso** = horário real − horário previsto. Voo **atrasado** = mais de 15 minutos (também mostro mais de 30). É uma convenção de análise minha, não um índice oficial da ANAC.
- **Cancelamento** = `Situação Voo = CANCELADO` sobre voos programados.
- **Voo analisável** (base das taxas de atraso): realizado, com os 4 horários, partida prevista em 2025 e atrasos entre −120 e +1440 min. Fora da base: 27.705 cancelados, 28.197 realizados sem horário previsto e 971 registros inconsistentes (0,1%).
- **Doméstico** = origem e destino com prefixo ICAO brasileiro (SB, SD, SI, SJ, SN, SS, SW).

## Limitações

- **Sem causa de atraso**: a coluna `Código Justificativa` vem `N/A` em 100% das linhas de 2025.
- **Fuso horário não informado** nos arquivos; por isso não fiz análise por hora do dia. Atrasos (diferença entre dois horários) não são afetados.
- Segundo relatório da própria ANAC, voo não relatado pela companhia entra no VRA como pontual (horário real = previsto). Medi isso nos dados: só 0,3% dos voos têm partida e chegada exatamente iguais ao previsto, então o efeito parece pequeno, mas não dá para descartá-lo.
- Na tabela por aeroporto (`data/painel/fato_aeroporto_mes.csv`), o atraso de chegada aparece junto ao **aeroporto de origem** do voo (os voos que saíram dali). Atraso na partida é o indicador mais direto por aeroporto.
- No painel, só Azul, LATAM Brasil e GOL aparecem separadas; as demais companhias (inclusive estrangeiras) ficam agrupadas em "Demais companhias".
- Comparar companhias é descritivo: rotas, aeroportos e horários diferem entre elas e não foram controlados.

## Estrutura

```
scripts/   coleta, carga em SQLite, execução de SQL
sql/       tratamento, indicadores e tabelas do painel
data/painel/   tabelas agregadas usadas no Looker Studio (CSV)
docs/      dicionário de dados e passo a passo
```

Reprodução: `python scripts/00_coleta.py --ano 2025`, depois `01_carga_sqlite.py` e `02_executa_sql.py` com os três arquivos SQL (opções em `--help`). Requer Python 3 e pandas.

## Fontes

- ANAC, dados abertos: Voo Regular Ativo (VRA) e Aeródromos Públicos, https://sistemas.anac.gov.br/dadosabertos/ (arquivos do VRA atualizados em 28/10/2026; cadastro em 15/11/2026).
- Contexto dos dias críticos (fora da base de dados): Panrotas e Agência Brasil, dezembro de 2025; Panrotas, 30/09/2025.
