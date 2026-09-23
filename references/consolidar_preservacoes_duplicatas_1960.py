"""Consolida cinco preservacoes demonstradas; emite patch somente para as novas."""
import argparse
import csv
import io
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import rows, sha256
from conferir_preservacao_ce_1960 import approve_ce

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = "read_guides/1960_amostra_127_duplicatas.csv"
FIRST = "references/resolucao_residuais_duplicatas_1960_evidencias.json"
ALTERNATIVES = "references/resolucao_residuais_duplicatas_alternativos_1960_evidencias.json"
CE = "references/resolucao_residuais_duplicatas_ce_1960_evidencias.json"


def prepare(out, portable=None):
    out = out.resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    first = json.loads((ROOT / FIRST).read_text(encoding="utf-8"))
    alternatives = json.loads((ROOT / ALTERNATIVES).read_text(encoding="utf-8"))
    ce = json.loads((ROOT / CE).read_text(encoding="utf-8"))
    approve_ce(ce["conferencia"])
    cases = list(first["casos_completos"]); decisions = list(first["decisoes"])
    for candidate in alternatives["casos"]:
        if candidate["avaliacao_alvo"]["motivos"] or candidate["avaliacao_grupo_proprio_do_alternativo"]["motivos"] or not candidate["alternativo_excluido_por_grupo_proprio"]:
            raise ValueError("Alternativa nao excluida por prova propria")
        cases.append(candidate["grupo_alvo"])
    cases.append(ce["caso"])
    for case in cases[2:]:
        check = case["avaliacao"]
        proof_path = CE if check["chave127"][0] == 14 else ALTERNATIVES
        for group in check["grupos"]:
            if len(group["linhas127"]) != 2 or len(group["linhas25"]) != 2:
                raise ValueError("Duas pessoas por fonte nao conferidas")
            for person in case["pessoas127"]:
                if person["linha"] not in group["linhas127"]:
                    continue
                decisions.append({"grupo": group["grupo"], "linha": str(person["linha"]), "acao": "manter", "n_antes": "2", "n_manter": "2",
                    "texto_original": person["original"], "texto_corrigido": person["corrigido"],
                    "fonte_25": "data/release_legacy/Censo.1960.amostra.25porcento." + ("ce" if check["chave127"][0] == 14 else "sp" if check["chave127"][0] == 60 else "rs") + ".gz",
                    "linhas_25": ";".join(map(str, group["linhas25"])),
                    "justificativa": ("Preservacao localizada CE15004/034: adulto unico por24campos em ambasUFs, composicao9p/cartao/geografia exatos salvoV21600/63; renumeracao comprovada em145familias (144alemalvo), mapa univoco. Duas ocorrencias25; nenhuma resposta ou chave reescrita. Prova: " if proof_path == CE else
                        "Preservacao fora de chave: grupo integral/cartao/geografia e duas testemunhas exatas unicas conferidos; cartao alternativo excluido pela sua propria composicao25 e testemunhas. V21600/63, quando divergente, preservado. Duas ocorrencias25; nenhuma resposta ou chave reescrita. Prova: ") + proof_path})
    decisions.sort(key=lambda r: int(r["linha"]))
    if len(decisions) != 10 or len({r["linha"] for r in decisions}) != 10:
        raise ValueError("Consolidacao incompleta")
    current = {r["linha"]: r for r in rows(ROOT / MANIFEST)}
    if any(r["linha"] in current and r != current[r["linha"]] for r in decisions):
        raise ValueError("Decisao corrente discordante")
    sources = {}
    for source in first["fontes"] + alternatives["fontes"] + ce["fontes"]:
        path = ROOT / source["arquivo"]
        if sha256(path) != source["sha256"]:
            raise ValueError("Fonte mudou")
        sources[path.relative_to(ROOT).as_posix()] = source["sha256"]
    for path in [ROOT / FIRST, ROOT / ALTERNATIVES, ROOT / CE]:
        sources[path.relative_to(ROOT).as_posix()] = sha256(path)
    result = {"versao": 1, "resumo": {"grupos": 5, "linhas": 10, "manter": 10, "remover": 0,
        "restauracoes_contra_regra_antiga": 0, "novas_nesta_consolidacao": sum(r["linha"] not in current for r in decisions)},
        "decisoes": decisions, "casos_completos": cases,
        "fontes": [{"arquivo": name, "sha256": digest} for name, digest in sorted(sources.items())],
        "prova_alternativos": ALTERNATIVES, "prova_composta_CE": CE,
        "manifesto_base_sha256": sha256(ROOT / MANIFEST), "respostas_e_chaves_preservadas": True}
    (out / "preservacoes5.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(ROOT / "references") or portable.exists():
            raise ValueError("Prova portatil deve ser nova")
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps(result["resumo"]))


def patch(path):
    data = json.loads(path.read_text(encoding="utf-8")); current = rows(ROOT / MANIFEST)
    present = {r["linha"] for r in current}; add = [r for r in data["decisoes"] if r["linha"] not in present]
    if len(add) != 6 or sha256(ROOT / MANIFEST) != data["manifesto_base_sha256"]:
        raise ValueError("Manifesto mudou ou proposta ja aplicada")
    output = io.StringIO(newline="")
    csv.DictWriter(output, fieldnames=list(current[0]), quoting=csv.QUOTE_ALL, lineterminator="\n").writerows(add)
    last = (ROOT / MANIFEST).read_text(encoding="utf-8").rstrip("\n").splitlines()[-1]
    print("*** Begin Patch\n*** Update File: " + MANIFEST + "\n@@\n " + last + "\n" +
          "\n".join("+" + line for line in output.getvalue().splitlines()) + "\n*** End Patch")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("--out", type=Path); parser.add_argument("--portable", type=Path); parser.add_argument("--manifest-patch", type=Path)
    args = parser.parse_args()
    if args.manifest_patch:
        patch(args.manifest_patch)
    else:
        prepare(args.out, args.portable)
