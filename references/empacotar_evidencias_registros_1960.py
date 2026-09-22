"""Emite patch de fixtures/evidencias pequenas; nunca escreve fontes ou producao.

O JSON de fixtures usa colunas e linhas e dicionario de justificativas repetidas.
Todos os valores das tabelas continuam strings, como read.csv(colClasses='character').
Executar --check para conferir o pacote contra as entregas locais, quando presentes.
--patch apenas imprime um patch; a criacao dos arquivos cabe a apply_patch.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = Path("tmp/fechamento_registros_1960_20260922")
DEST = Path("references/fechamento_registros_1960_evidencias")
DUP = [BASE / "duplicatas/completa_01/decisoes_candidatas.csv",
       BASE / "duplicatas/projecao_completa_03/propostas_condicionais.csv",
       BASE / "duplicatas/atributos_completa_02/propostas_condicionais.csv"]
LINK = [BASE / "vinculos/entrega_02/vinculos_estritos_33.csv",
        BASE / "vinculos/entrega_02/vinculos_condicionais_133.csv"]
PR = BASE / "texto/inferencias04/vinculos_geografia_pr.csv"
IDS = BASE / "vinculos/fixture_166_01/linhas127.json"
EVIDENCE = {
    "duplicatas_residuais463.json": BASE / "duplicatas/residuais_01/residuais463.json",
    "texto_selecao_final33.json": BASE / "texto/selecao_final02/selecao_final_reparos.json",
    "geografia_pr_candidatos.json": BASE / "texto/inferencias04/candidatos_geografia_pr.json",
    "qc33_reparos_geografia.json": BASE / "duplicatas/revisao33_geo_01/revisao_independente.json",
    "qc10_reparos_geografia_vinculos.json": BASE / "duplicatas/revisao10_geo_02/revisao_independente.json",
    "qc166_vinculos.json": BASE / "vinculos/revisao_independente_02/revisao_independente166.json",
    "qc954_duplicatas.json": BASE / "conferencia_954_01.json",
}


def read_json(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def read_csv(path):
    with (ROOT / path).open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def description(path):
    data = (ROOT / path).read_bytes()
    return {"arquivo": path.as_posix(), "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}


def compact_table(rows):
    columns = list(rows[0]); reasons = []
    packed = []
    for row in rows:
        assert list(row) == columns and all(isinstance(v, str) for v in row.values())
        reason = row["justificativa"]
        if reason not in reasons:
            reasons.append(reason)
        packed.append([str(reasons.index(reason)) if field == "justificativa" else row[field] for field in columns])
    return {"colunas": columns, "linhas": packed, "justificativas": reasons}


def expand_table(table):
    result = []
    for row in table["linhas"]:
        item = dict(zip(table["colunas"], row, strict=True))
        item["justificativa"] = table["justificativas"][int(item["justificativa"])]
        result.append(item)
    return result


def build():
    duplicates = [r for path in DUP for r in read_csv(path)]
    links = [r for path in LINK for r in read_csv(path)]
    pr = read_csv(PR); ids = read_json(IDS)
    assert len(duplicates) == 1908 and len({r["grupo"] for r in duplicates}) == 954
    assert len({r["linha"] for r in duplicates}) == 1908
    assert sum(r["acao"] == "remover" for r in duplicates) == 490
    assert len(links) == len({r["linha"] for r in links}) == 166
    assert len(pr) == 3 and len(ids) == len(set(ids)) == 653
    fixture = {"versao": 1, "nota": "Fixture de testes, nao manifesto de producao. Literais subsetados; nenhum arquivo-fonte completo.",
               "duplicatas954": compact_table(duplicates), "vinculos166": compact_table(links),
               "vinculos_pr3": compact_table(pr), "linhas127_contexto_vinculos166": ids,
               "fontes": [description(path) for path in DUP + LINK + [PR, IDS]]}
    assert expand_table(fixture["duplicatas954"]) == duplicates
    assert expand_table(fixture["vinculos166"]) == links
    assert expand_table(fixture["vinculos_pr3"]) == pr
    return fixture


def patch_file(name, data):
    body = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    return f"*** Add File: {(DEST / name).as_posix()}\n+{body}\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--patch", action="store_true")
    parser.add_argument("--evidence-patch", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    assert sum((args.patch, args.evidence_patch, args.check)) == 1
    if args.patch:
        print("*** Begin Patch\n" + patch_file("fixtures_decisoes.json", build()) + "*** End Patch")
    elif args.evidence_patch:
        index = {"versao": 1, "arquivos": [{"arquivo_versionado": name, **description(path)} for name, path in EVIDENCE.items()],
                 "limite": "Resultados e casos selecionados. Reexecucao forense integral requer fontes locais e indices reconstruidos; nenhum indice SQLite foi incluido."}
        print("*** Begin Patch\n" + "".join(patch_file(name, read_json(path)) for name, path in EVIDENCE.items())
              + patch_file("indice_evidencias.json", index) + "*** End Patch")
    else:
        assert read_json(DEST / "fixtures_decisoes.json") == build()
        for name, path in EVIDENCE.items():
            assert read_json(DEST / name) == read_json(path)
        print(json.dumps({"fixture_tabelas_e_literais_identicos": True, "duplicatas_linhas": 1908,
                          "vinculos": 166, "vinculos_pr": 3, "contexto_ids": 653,
                          "evidencias_identicas": len(EVIDENCE)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
