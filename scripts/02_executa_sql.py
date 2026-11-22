"""
Executa um ou mais arquivos .sql no banco SQLite e, opcionalmente,
exporta o resultado de uma consulta para CSV.

Uso:
    python scripts/02_executa_sql.py --db data/vra_2025.db --sql sql/01_voos_tratados.sql
    python scripts/02_executa_sql.py --db data/vra_2025.db --consulta "SELECT ..." --saida resultado.csv
"""
import argparse
import sqlite3

import pandas as pd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--db", required=True)
    ap.add_argument("--sql", nargs="*", default=[])
    ap.add_argument("--consulta")
    ap.add_argument("--saida")
    a = ap.parse_args()
    con = sqlite3.connect(a.db)
    for arq in a.sql:
        with open(arq, encoding="utf-8") as f:
            con.executescript(f.read())
        print("executado:", arq)
    con.commit()
    if a.consulta:
        df = pd.read_sql_query(a.consulta, con)
        if a.saida:
            df.to_csv(a.saida, index=False, encoding="utf-8")
            print(f"{len(df)} linhas -> {a.saida}")
        else:
            print(df.to_string(index=False))
    con.close()


if __name__ == "__main__":
    main()
