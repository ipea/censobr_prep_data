"""Reexame integral usando os auditores existentes; sem decisoes de producao."""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import sqlite3

import psutil

import auditoria_recuperacao_cartoes_1960 as base
import auditoria_pendencias_duplicatas_1960 as counts
import investigacao_residual_duplicatas_1960 as search

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas"
CURRENT = "references/resolucao_residuais_1960_evidencias/inventario_atual.json"
HISTORIC = "references/fechamento_registros_1960_evidencias/duplicatas_residuais463.json"


def save(path, data):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(data, stream, ensure_ascii=False, indent=2)


def prepare():
    OUT.mkdir(parents=True, exist_ok=False)
    current = json.loads((ROOT / CURRENT).read_text(encoding="utf-8"))
    historic = json.loads((ROOT / HISTORIC).read_text(encoding="utf-8"))
    wanted = {tuple(sorted(g["linhas"])) for g in current["duplicatas_pendentes"]}
    historic["grupos"] = [g for g in historic["grupos"] if tuple(sorted(g["linhas127"])) in wanted]
    assert {tuple(sorted(g["linhas127"])) for g in historic["grupos"]} == wanted
    assert len(wanted) == 458
    assert sum(len(g["linhas127"]) for g in historic["grupos"]) == 918
    assert sum(len(g["exclusoes_antigas_sem_prova"]) for g in historic["grupos"]) == 127
    historic["nota_reexame"] = "Selecao nominal por todas as 458 listas atuais, nao por categoria anterior."
    save(OUT / "inventario458.json", historic)
    connection = base.build_index(ROOT, OUT / "indice127.sqlite", base.load_guides(ROOT))
    summary = {
        "grupos": 458, "linhas": 918, "exclusoes_historicas": 127,
        "pessoas_indice": connection.execute("SELECT count(*) FROM pessoas").fetchone()[0],
        "cartoes_indice": connection.execute("SELECT count(*) FROM familias").fetchone()[0],
        "fontes": [{"arquivo": p, "sha256": base.sha256(ROOT / p)} for p in base.FIXED_SOURCES],
        "memoria_rss_bytes": psutil.Process().memory_info().rss,
    }
    connection.close()
    save(OUT / "preparacao.json", summary)
    print(json.dumps(summary, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["prepare", "pilot", "search", "evaluate"])
    args = parser.parse_args()
    if args.mode == "prepare":
        prepare()
        return
    search.INDEX = str((OUT / "indice127.sqlite").relative_to(ROOT))
    search.INVENTORY = str((OUT / "inventario458.json").relative_to(ROOT))
    if args.mode in {"pilot", "search"}:
        search.audit(ROOT, OUT / ("piloto_rn" if args.mode == "pilot" else "nacional"),
                     17 if args.mode == "pilot" else None)
        return
    folder = OUT / "nacional"
    search.deepen(ROOT, folder)
    search.relaxed(ROOT, folder)
    data = json.loads((folder / "resultado.json").read_text(encoding="utf-8"))
    groups = defaultdict(list)
    for g in data["grupos"]:
        if g["chave"]:
            groups[tuple(g["chave"])].append(g)
    guides = base.load_guides(ROOT)
    context_checks = []
    for context in data["contextos"]:
        key = tuple(context["chave"])
        pending = [{"linhas": g["linhas127"]} for g in groups[key]]
        same = context["mesma_chave25"]
        reasons = ["fonte25_indisponivel"] if key[0] not in base.UF else ["cartao25_ausente_ou_nao_unico"]
        detail = {}
        if same:
            reasons, detail = counts.evaluate_context(key, context["cartoes127"], context["pessoas127"],
                [s["cartao25"] for s in same], [p for s in same for p in s["pessoas25"]],
                pending, guides, match_without_v216=True, allow_family_attribute_differences=True)
        context_checks.append({"chave": list(key), "grupos": [g["id"] for g in groups[key]],
            "motivos_criterio_vigente": reasons, "contagens": detail,
            "n_pessoas127": len(context["pessoas127"]), "n_pessoas25": sum(len(s["pessoas25"]) for s in same)})
    previous = json.loads((ROOT / "tmp/investigacao_residual_1960_20260922/duplicatas/nacional_01/resultado.json").read_text(encoding="utf-8"))
    previous = {tuple(c["chave"]): c for c in previous["contextos"]}
    changes = []
    for context in data["contextos"]:
        old = previous[tuple(context["chave"])]
        fields = ["linha", "original", "corrigido", "familia_atual", "familia_fisica"]
        old_rows = [{k: r.get(k) for k in fields} for r in old["pessoas127"]]
        new_rows = [{k: r.get(k) for k in fields} for r in context["pessoas127"]]
        if old_rows != new_rows or old["cartoes127"] != context["cartoes127"]:
            changes.append({"chave": context["chave"], "pessoas_antes": old_rows, "pessoas_agora": new_rows,
                "cartoes_antes": old["cartoes127"], "cartoes_agora": context["cartoes127"]})
    summary = {"contextos": len(context_checks), "contextos_atualizados_desde_busca_anterior": len(changes),
        "contextos_agora_aprovados_pelo_criterio_vigente": sum(not c["motivos_criterio_vigente"] for c in context_checks),
        "motivos_sobrepostos": dict(Counter(r for c in context_checks for r in c["motivos_criterio_vigente"])),
        "memoria_rss_bytes": psutil.Process().memory_info().rss}
    save(OUT / "reavaliacao_integral.json", {"resumo": summary, "contextos": context_checks, "mudancas": changes})
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    main()
