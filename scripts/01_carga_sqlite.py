"""
Carga do VRA (Voo Regular Ativo, ANAC) em um banco SQLite.

Le todos os CSVs mensais VRA_*.csv de uma pasta, aplica a limpeza basica
e grava as tabelas `voos_brutos` (dado como veio) e `aerodromos` (cadastro ANAC).

Uso:
    python scripts/01_carga_sqlite.py --csv-dir <pasta com VRA_*.csv> \
        --aerodromos <AerodromosPublicos.csv> --db data/vra_2025.db
"""
import argparse
import glob
import os
import sqlite3

import pandas as pd

COLUNAS = {
    "ICAO Empresa Aérea": "empresa",
    "Número Voo": "numero_voo",
    "Código Autorização (DI)": "codigo_autorizacao",
    "Código Tipo Linha": "codigo_tipo_linha",
    "ICAO Aeródromo Origem": "origem",
    "ICAO Aeródromo Destino": "destino",
    "Partida Prevista": "partida_prevista",
    "Partida Real": "partida_real",
    "Chegada Prevista": "chegada_prevista",
    "Chegada Real": "chegada_real",
    "Situação Voo": "situacao",
    "Código Justificativa": "codigo_justificativa",
}
DATAS = ["partida_prevista", "partida_real", "chegada_prevista", "chegada_real"]


def ler_vra(caminho):
    # A primeira linha do arquivo e "Atualizado em: ..."; o cabecalho vem na segunda.
    # keep_default_na=False evita que o texto "N/A" vire vazio.
    df = pd.read_csv(caminho, sep=";", skiprows=1, dtype=str, keep_default_na=False)
    df = df.rename(columns=COLUNAS)
    df["arquivo_origem"] = os.path.basename(caminho)
    for c in DATAS:
        # ausentes vem como a palavra "null"; cancelados trazem fracao ".1" nos segundos
        df[c] = df[c].replace("null", pd.NA).str[:19]
    return df


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv-dir", required=True)
    ap.add_argument("--aerodromos", required=True)
    ap.add_argument("--db", required=True)
    a = ap.parse_args()

    arquivos = sorted(glob.glob(os.path.join(a.csv_dir, "VRA_*.csv")))
    if not arquivos:
        raise SystemExit("Nenhum arquivo VRA_*.csv encontrado em " + a.csv_dir)
    voos = pd.concat([ler_vra(f) for f in arquivos], ignore_index=True)
    antes = len(voos)
    voos = voos.drop_duplicates(subset=[c for c in voos.columns if c != "arquivo_origem"])
    print(f"{len(arquivos)} arquivos, {antes} linhas, {antes - len(voos)} duplicadas removidas")

    aero = pd.read_csv(a.aerodromos, sep=";", skiprows=1, dtype=str,
                       keep_default_na=False, encoding="latin-1")
    aero = aero.rename(columns={
        "Código OACI": "icao", "Nome": "nome", "Município": "municipio", "UF": "uf",
        "LATGEOPOINT": "latitude", "LONGEOPOINT": "longitude",
    })[["icao", "nome", "municipio", "uf", "latitude", "longitude"]]
    aero["latitude"] = pd.to_numeric(aero["latitude"], errors="coerce")
    aero["longitude"] = pd.to_numeric(aero["longitude"], errors="coerce")

    if os.path.exists(a.db):
        os.remove(a.db)
    con = sqlite3.connect(a.db)
    voos.to_sql("voos_brutos", con, index=False)
    aero.to_sql("aerodromos", con, index=False)
    con.commit()
    con.close()
    print("Banco gerado:", a.db)


if __name__ == "__main__":
    main()
