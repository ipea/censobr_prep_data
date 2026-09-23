"""Extrai paginas documentais e as identidades do quadro 6 sem alterar fontes."""
import hashlib
import json
from pathlib import Path

import fitz
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/conferencias"
OUT.mkdir(parents=True, exist_ok=True)
sources = [
    ("preliminares", ROOT / "references/fontes_1960/1965_resultados_preliminares_vol2.pdf", [6, 7, 8, 24, 25, 33, 41, 49],
     "https://www.ibge.gov.br/biblioteca/visualizacao/periodicos/68/cd_1960_v2_resultados_preliminares.pdf"),
    ("codigo", ROOT / "references/fontes_1960/1960_codigo_do_censo_demografico.pdf", [3, 24],
     "https://biblioteca.ibge.gov.br/visualizacao/instrumentos_de_coleta/doc231.pdf"),
    ("parana_definitivos", Path("D:/Dropbox/Bancos_Dados/Censos/Censo 1960/4 - Ponderação do Censo de 1960/3-Publicações Originais dos Resultados/cd_1960_v1_t14_pr.pdf"), [11, 47],
     "https://www.ibge.gov.br/biblioteca/visualizacao/periodicos/68/cd_1960_v1_t14_pr.pdf"),
    ("instrucoes_recenseador", Path("D:/Dropbox/Bancos_Dados/Censos/Censo 1960/2-Arquivos Auxiliares/Censo 1960 - Manual do recenseador (CD 1.09).pdf"), [25, 30, 39],
     "https://biblioteca.ibge.gov.br/visualizacao/instrumentos_de_coleta/doc94.pdf")]
metadata = []
for name, path, pages, url in sources:
    d = fitz.open(path)
    texts = []
    for page in pages:
        texts.append(f"PDF {page}\n{d[page - 1].get_text()}")
        d[page - 1].get_pixmap(matrix=fitz.Matrix(1.7, 1.7)).save(OUT / f"{name}_pdf{page}.png")
    (OUT / f"{name}_paginas.txt").write_text("\n\n".join(texts), encoding="utf-8")
    metadata.append({"fonte": name, "arquivo": str(path), "url": url, "pdf_paginas": pages,
                     "sha256": hashlib.file_digest(path.open("rb"), "sha256").hexdigest()})
g = pd.read_csv(ROOT / "references/censo_1960_resultados_preliminares_1965.csv")
g = g[g.quadro.eq(6)]
p = g.pivot(index=["regiao", "coluna"], columns="linha", values="valor")
bands = ["ate_500", "501_1000", "1001_2000", "2001_4000", "4001_6000", "6001_mais"]
p["soma_faixas"] = p[bands].sum(axis=1)
p["residuo_aluguel"] = p.alugados - p.soma_faixas
p["residuo_ocupacao"] = p.TOTAIS - p[["proprios", "alugados", "outra_condicao", "sem_declaracao"]].sum(axis=1)
p.to_csv(OUT / "q6_identidades_publicadas.csv")
(OUT / "fontes_metadados.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
print(p[["alugados", "soma_faixas", "residuo_aluguel"]].to_string())
