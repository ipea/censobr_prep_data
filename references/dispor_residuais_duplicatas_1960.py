"""Cobertura nominal da decisao nova sem reescrever o inventario investigativo."""
import argparse
from collections import Counter
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import rows, sha256

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = "references/investigacao_residual_1960_evidencias/duplicatas_cobertura463.json"
PROOF = "references/resolucao_residuais_duplicatas5_1960_evidencias.json"
MANIFEST = "read_guides/1960_amostra_127_duplicatas.csv"


def dispositions():
    inventory = json.loads((ROOT / INVENTORY).read_text(encoding="utf-8"))
    proof = json.loads((ROOT / PROOF).read_text(encoding="utf-8"))
    current = {r["linha"]: r for r in rows(ROOT / MANIFEST)}
    decisions = {}
    for decision in proof["decisoes"]:
        if current.get(decision["linha"]) != decision:
            raise ValueError("Decisao atual difere da prova")
        decisions.setdefault(decision["grupo"], []).append(decision)
    output = []
    for group in inventory["grupos"]:
        approved = decisions.get(group["id"], [])
        if approved and {int(r["linha"]) for r in approved} != set(group["linhas127"]):
            raise ValueError("Grupo nao foi decidido integralmente")
        output.append({"grupo": group["id"], "chave": group["chave"], "linhas127": group["linhas127"],
            "disposicao": "preservar_ambas_com_prova" if approved else "pendente_sem_prova_suficiente",
            "razao_inventario_anterior": group["razao_principal"],
            "exclusoes_historicas_sem_prova": group["exclusoes_antigas_sem_prova"],
            "decisoes_aplicadas": approved,
            "referencia_detalhe_anterior": INVENTORY + "#" + group["id"],
            "busca_fora_chave_executada": group["investigado_fora_chave"],
            "alternativas_composicao24": group.get("alternativas_composicao24", []),
            "nao_autoriza_exclusao": True})
    pending = [r for r in output if r["disposicao"].startswith("pendente")]
    summary = {"inventario_grupos": len(output), "inventario_linhas": sum(len(r["linhas127"]) for r in output),
        "grupos_preservados": len(decisions), "linhas_preservadas": sum(len(x) for x in decisions.values()),
        "grupos_ainda_sem_decisao": len(pending), "linhas_ainda_sem_decisao": sum(len(r["linhas127"]) for r in pending),
        "exclusoes_novas": 0, "razoes_anteriores_dos_pendentes": dict(Counter(r["razao_inventario_anterior"] for r in pending)),
        "linhas_excluidas_na_regra_historica_ainda_sem_prova": sum(len(r["exclusoes_historicas_sem_prova"]) for r in pending)}
    if (summary["inventario_grupos"], summary["grupos_preservados"], summary["grupos_ainda_sem_decisao"],
            summary["linhas_ainda_sem_decisao"]) != (463, 5, 458, 918):
        raise ValueError("Balanco inesperado")
    return {"versao": 1, "resumo": summary,
        "escopo": "Disposicoes sobre os 463 grupos do inventario anterior. Nao substitui reparse/recontagem integrada apos reparos de texto e vinculos desta rodada.",
        "limites": inventory["limites"],
        "fontes": [{"arquivo": path, "sha256": sha256(ROOT / path)} for path in (INVENTORY, PROOF, MANIFEST)],
        "grupos": output}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--portable", type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    result = dispositions()
    text = json.dumps(result, ensure_ascii=False, indent=2)
    (out / "disposicoes463.json").write_text(text, encoding="utf-8")
    if args.portable:
        path = args.portable.resolve()
        if not path.is_relative_to(ROOT / "references") or path.exists():
            raise ValueError("Prova portatil deve ser nova")
        path.write_text(text, encoding="utf-8")
    print(json.dumps(result["resumo"]))
