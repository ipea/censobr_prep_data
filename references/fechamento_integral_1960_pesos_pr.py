"""Recalcula UFs com controle corrigido e registra novo indice das17UFs."""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import subprocess
import sys

import recalibrar_pesos_25_reduzido_1960 as monitor
import reunir_pesos_25_1960 as reunir

ROOT = Path(__file__).resolve().parents[1]
OLD_INDEX = ROOT / "tmp/execucao_1960_20260922/pesos25_completo_15_fixo_01/indice_34_parquets_completos.json"


def index(complete, destination, units):
    previous = json.loads(OLD_INDEX.read_text(encoding="utf-8"))
    approvals = {uf: json.loads((complete / uf / "APROVADO.json").read_text(encoding="utf-8")) for uf in units}
    for approval in approvals.values():
        assert approval["status"] == "concluido_staging_nao_promovido"
        assert approval["entradas"] == approval["hashes_entradas_depois"]
    guard = reunir.MemoryGuard()
    guard.check("indice", start=True)
    entries = []
    for row in previous["arquivos"]:
        current = dict(row)
        path = complete / row["uf"] / row["arquivo"] if row["uf"] in units else ROOT / row["caminho"]
        actual = reunir.hashes(path, guard)
        if row["uf"] in units:
            approval = approvals[row["uf"]]
            proof = next(p for p in approval["arquivos"] if p["arquivo"] == row["arquivo"])
            assert actual == proof["hash_saida"] and row["linhas"] == proof["linhas"]
            assert proof["bruto_preservado_exato"] and proof["pesos_preservados_exatos"] and proof["ordem_preservada"]
            current.update(caminho=reunir.label(path), caminho_absoluto=str(path.resolve()),
                aprovacao=reunir.label(complete / row["uf"] / "APROVADO.json"), **actual)
        else:
            assert all(actual[k] == row[k] for k in actual), (row["uf"], path)
        entries.append(current)
    originals = previous["originais_reconferidos"]
    for item in originals:
        actual = reunir.hashes(ROOT / item["arquivo"], guard)
        assert all(actual[k] == item[k] for k in actual)
    assert len(entries) == 34 and len({(p["uf"], p["arquivo"]) for p in entries}) == 34
    result = {**previous, "arquivos": entries, "indice_anterior": reunir.label(OLD_INDEX),
        "controle_municipal_atual_sha256": reunir.hashes(ROOT / "read_guides/1960_municipios.csv", guard)["sha256"],
        "ufs_recalculadas_nesta_rodada": units, "ufs_reutilizadas_sem_alteracao": sorted(set(previous["ufs"]) - set(units)),
        "nota": "34 arquivos completos em staging. UFs selecionadas recalculadas depois das correcoes comprovadas nos controles municipais. Demais arquivos identicos. Nao e compilacao nacional nem publicacao."}
    reunir.write_json(destination, result)
    print("INDICE", reunir.label(destination), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--autorizar-execucao", action="store_true", required=True)
    parser.add_argument("--uf", nargs="+", choices=sorted(reunir.UF), default=["pr"])
    args = parser.parse_args()
    os.chdir(ROOT)
    if len(args.uf) != len(set(args.uf)):
        parser.error("UF repetida")
    stage = ROOT / "tmp/fechamento_integral_1960" / ("pesos_municipais_" + datetime.now().strftime("%Y%m%d_%H%M%S_%f"))
    stage.mkdir(parents=True, exist_ok=False)
    sources = monitor.hashes(monitor.FONTES)
    monitor.write_json(stage / "fontes_inicio.json", sources)
    print("RAIZ_PESOS", reunir.label(stage), flush=True)
    for uf in args.uf:
        result = monitor.run_uf(uf, stage, sources, 900)
        if result["status"] != "concluido_auxiliar_parcial":
            raise SystemExit(1)
    complete = stage.parent / (stage.name + "_completo")
    command = [sys.executable, "references/reunir_pesos_25_1960.py", "--uf", *args.uf,
        "--partial-run", str(stage), "--out", str(complete)]
    subprocess.run(command, check=True)
    index(complete, complete / "indice_34_parquets_completos.json", args.uf)
