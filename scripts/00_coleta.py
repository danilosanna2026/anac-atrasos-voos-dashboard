"""
Baixa os arquivos mensais do VRA (Voo Regular Ativo) e o cadastro de aerodromos
publicos, a partir do portal de dados abertos da ANAC.

Uso:
    python scripts/00_coleta.py --ano 2025 --destino dados_brutos
    python scripts/00_coleta.py --ano 2025 --listar      # so mostra as URLs

Observacao: neste projeto os arquivos foram baixados pelo navegador, a partir
dos mesmos enderecos que este script monta.
"""
import argparse
import os
import time
from urllib.parse import quote

import requests

BASE = "https://sistemas.anac.gov.br/dadosabertos"
MESES = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
         "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
PASTA_VRA = "Voos e operações aéreas/Voo Regular Ativo (VRA)"
URL_AERODROMOS = (BASE + "/Aerodromos/" + quote("Aeródromos Públicos") + "/"
                  + quote("Lista de aeródromos públicos") + "/AerodromosPublicos.csv")


def urls_vra(ano):
    for n, nome in enumerate(MESES, start=1):
        pasta = f"{n:02d} - {nome}"
        arquivo = f"VRA_{ano}{n}.csv"          # ex.: VRA_20251.csv, VRA_202510.csv
        yield arquivo, f"{BASE}/{quote(PASTA_VRA)}/{ano}/{quote(pasta)}/{arquivo}"


def baixar(url, destino, tentativas=3):
    for i in range(tentativas):
        try:
            r = requests.get(url, timeout=120)
            r.raise_for_status()
            with open(destino, "wb") as f:
                f.write(r.content)
            return
        except requests.RequestException as e:
            print(f"  falha ({e}); tentativa {i + 1}/{tentativas}")
            time.sleep(3)
    raise SystemExit("Nao foi possivel baixar: " + url)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ano", type=int, default=2025)
    ap.add_argument("--destino", default="dados_brutos")
    ap.add_argument("--listar", action="store_true")
    a = ap.parse_args()
    itens = list(urls_vra(a.ano)) + [("AerodromosPublicos.csv", URL_AERODROMOS)]
    if a.listar:
        for _, u in itens:
            print(u)
        return
    os.makedirs(a.destino, exist_ok=True)
    for nome, url in itens:
        print("baixando", nome)
        baixar(url, os.path.join(a.destino, nome))
    print("concluido em", a.destino)


if __name__ == "__main__":
    main()
