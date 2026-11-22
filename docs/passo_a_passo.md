# Passo a passo do projeto

## 1. Pergunta
Como se comportaram atrasos e cancelamentos de voos regulares no Brasil em 2025, por companhia, aeroporto, rota e período?

## 2. Dados
VRA da ANAC (12 meses de 2025, ~1 milhão de linhas) e cadastro de aeródromos públicos (nome, município, UF, coordenadas). Os arquivos têm ~12 MB por mês e não estão no repositório (use `scripts/00_coleta.py`).

## 3. O que descobri ao inspecionar os dados (antes de analisar)
- A 1ª linha de cada CSV é `Atualizado em: ...`; o cabeçalho vem na 2ª.
- O texto `N/A` da coluna de justificativa vira vazio se o leitor aplicar valores nulos padrão; foi preciso desligar isso para ver que **100%** dos valores são `N/A`.
- Horários ausentes vêm escritos `null`; nos cancelados, os horários previstos trazem uma fração `.1` nos segundos.
- 4 linhas duplicadas; 28.197 voos realizados sem horário previsto; 971 com atraso fora de −120 a +1440 min (até 44.635 min).
- 99% dos aeroportos brasileiros dos voos estão no cadastro da ANAC; os 11 sem cadastro (ex.: SNCL, SBUY) ficam como "Não cadastrado".

## 4. Decisões
| Decisão | Motivo |
|---|---|
| Atrasado = mais de 15 min (e também mostro >30) | Convenção comum de pontualidade; deixo as duas visíveis |
| Excluir atrasos fora de −120/+1440 min | Registros que parecem erro; 0,1% dos voos |
| Escopo doméstico/internacional pelos prefixos ICAO dos aeroportos | O código de tipo de linha não tem significado documentado nos arquivos |
| Sem análise por hora do dia | Fuso horário não informado |
| Agregar em tabelas (dia × companhia × aeroporto) | O painel recalcula taxas corretamente em qualquer filtro e o arquivo fica pequeno |

## 5. Validação cruzada
Os resultados batem com fatos públicos independentes dos dados: 10/12/2025 aparece como o pior dia (ciclone em São Paulo) e o Santos Dumont tem 79 de 89 voos cancelados em 30/09/2025 (fechamento por vazamento de óleo).

## 6. Painel
Fontes: `fato_dia_companhia`, `fato_aeroporto_mes`, `fato_rotas_mes`, `dim_aeroporto` (CSV em `data/painel/`). Campos calculados: ver `docs/dicionario_de_dados.md`.

Como foi montado:
1. Os CSV de `data/painel/` foram publicados neste repositório.
2. Uma planilha do Google Planilhas lê cada CSV com `IMPORTDATA`, apontando para o arquivo bruto do repositório. O envio direto de CSV e o conector de Excel do Looker Studio não funcionaram no meu caso, por isso essa ponte.
3. O Looker Studio se conecta à planilha. As taxas são campos calculados (soma dos voos atrasados dividida pela soma dos voos analisáveis), o que mantém o resultado correto em qualquer filtro.

Página atual do painel: cartões com a taxa de atraso (16,02%), a taxa de cancelamento (2,83%) e o total de voos programados (977.584), série diária da taxa de atraso, comparação entre companhias e filtro doméstico/internacional. Esses números conferem com a tabela de resultados do README. As visões por aeroporto e por rota ainda não estão no painel: as tabelas estão em `data/painel/` e as consultas em `sql/02_indicadores.sql`.
