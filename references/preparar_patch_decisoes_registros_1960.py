"""Emite patch auditavel de decisoes aprovadas; nao grava arquivos.

Aplicar apenas depois da conferencia independente e dos testes R em microlotes.
"""
import argparse
import csv
import io
import json
from pathlib import Path


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def csv_line(row, fields):
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fields, quoting=csv.QUOTE_ALL, lineterminator="\n")
    writer.writerow(row)
    return stream.getvalue().rstrip("\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kind", choices=["duplicatas", "vinculos", "correcoes"])
    parser.add_argument("--limit", type=int, default=200)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    base = root / "tmp/fechamento_registros_1960_20260922"
    path = root / f"read_guides/1960_amostra_127_{args.kind}.csv"
    old = rows(path); fields = list(old[0]); known = {r["linha"]: r for r in old}
    assert len(known) == len(old)
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    patch = ["*** Begin Patch", "*** Update File: " + str(path).replace("\\", "/")]
    if args.kind == "correcoes":
        data = json.loads((root / "read_guides/1960_amostra_127_reparos_fonte25.json").read_text(encoding="utf-8"))
        changes = []
        for proof in data["reparos"]:
            before = known[str(proof["linha127"])]; after = dict(before)
            assert before["texto_original"] == proof["texto_original"]
            after["decisao"] = "reparo_fonte25"
            after["texto_corrigido"] = proof["texto_corrigido_proposto"]
            after["explicacao"] = ("Campo danificado recuperado na fonte de 25%, com correspondencia do grupo familiar conferida. "
                "Preservar todos os outros caracteres. Campos: " + "; ".join(p["campo"] for p in proof["propostas"]) +
                ". Evidencia literal e localizadores: read_guides/1960_amostra_127_reparos_fonte25.json, linha127=" + str(proof["linha127"]) + ".")
            if before == after:
                continue
            # O CSV historico deixa apenas a primeira coluna sem aspas.
            original_line = next(line for line in lines if line.startswith(str(proof["linha127"]) + ",") or line.startswith('"' + str(proof["linha127"]) + '",'))
            changes += ["@@", "-" + original_line, "+" + csv_line(after, fields)]
        patch += changes
    else:
        if args.kind == "duplicatas":
            files = [base / "duplicatas/completa_01/decisoes_candidatas.csv",
                     base / "duplicatas/projecao_completa_03/propostas_condicionais.csv",
                     base / "duplicatas/atributos_completa_02/propostas_condicionais.csv"]
        else:
            files = [base / "vinculos/entrega_02/vinculos_estritos_33.csv", base / "vinculos/entrega_02/vinculos_condicionais_133.csv"]
        candidates = [r for filename in files for r in rows(filename)]
        assert len({r["linha"] for r in candidates}) == len(candidates)
        pending = []
        for row in candidates:
            row["justificativa"] = row["justificativa"].replace("PROPOSTA SOB REVISAO: ", "Decisao conferida em 22/09/2026: ")
            row["justificativa"] = row["justificativa"].replace("confirmavel", "conferida").replace(" Proposta sujeita a revisao do criterio.", " Criterio revisto e evidencia preservada em fechamento_registros_1960_20260922.")
            if row["linha"] in known:
                assert all(known[row["linha"]][field] == row[field] for field in fields if field != "justificativa"), row["linha"]
            else:
                pending.append(row)
        selected = sorted(pending, key=lambda r: int(r["linha"]))[:args.limit]
        if selected:
            patch += ["@@"] + [" " + line for line in lines[-2:]]
            patch += ["+" + csv_line(row, fields) for row in selected]
    if len(patch) == 2:
        print("SEM_ALTERACOES")
    else:
        print("\n".join(patch + ["*** End Patch"]))


if __name__ == "__main__":
    main()
