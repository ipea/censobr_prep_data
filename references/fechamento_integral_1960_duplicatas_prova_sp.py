"""Empacota a prova paulista autorizada; nao edita o manifesto de producao."""
from collections import Counter
from copy import deepcopy
import csv
import json
from pathlib import Path

import auditoria_recuperacao_cartoes_1960 as base

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas"
PORTABLE = ROOT / "references/fechamento_integral_1960_evidencias/duplicata_sp_composta.json"
guides = base.load_guides(ROOT)


def verify(case, uniqueness, exact25):
    card = case["cartao"]; candidates = case["alternativas25"]
    if len(candidates) != 1:
        raise ValueError("Fonte25 nao unica")
    candidate = candidates[0]; people = case["pessoas"]
    a = [base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES) for p in people]
    b = [base.parse_profile(p["texto"], guides[("25", "pessoas")], base.PERSON_NAMES) for p in candidate["pessoas25"]]
    if any(bad for _, bad in a + b):
        raise ValueError("Campo pessoal invalido")
    if base.source_structure(candidate["cartao25"], candidate["pessoas25"]):
        raise ValueError("Estrutura25 invalida")
    if exact25 and Counter(p for p, _ in a) != Counter(p for p, _ in b):
        raise ValueError("Grupo25 diverge")
    if Counter(p[:16] + p[17:] for p, _ in a) != Counter(p[:16] + p[17:] for p, _ in b):
        raise ValueError("Multiconjunto24 diverge")
    card25 = candidate["cartao25"]["texto"]
    f127, bad127 = base.parse_profile(card["corrigido"], guides[("127", "familias")], base.FAMILY_NAMES)
    f25, bad25 = base.parse_profile(card25, guides[("25", "familias")], base.FAMILY_NAMES)
    if bad127 or bad25 or f127 != f25 or card["corrigido"][6:8] != card25[33:35]:
        raise ValueError("Cartao ou distrito diverge")
    if any(p["corrigido"][:8] + p["corrigido"][17] != card["corrigido"][:8] + card["corrigido"][17] for p in people):
        raise ValueError("Geografia pessoal diverge")
    if any(p["corrigido"][:2] + p["corrigido"][8:16] != card["corrigido"][:2] + card["corrigido"][8:16] for p in people):
        raise ValueError("Chave pessoal diverge")
    for mode in ("familia_atual", "familia_fisica"):
        if [h["cartao"] for h in uniqueness["correspondentes127_composicao24_sem_restricao_cartao"] if h["agrupamento"] == mode] != [card["linha"]]:
            raise ValueError("Grupo127 nao unico")
    if len(uniqueness["correspondentes25_composicao24_sem_restricao_cartao"]) != 1:
        raise ValueError("Grupo25 nao unico")
    if candidate["chave25"][0] != card["uf"]:
        raise ValueError("UF difere")
    if not exact25 and candidate["avaliacao"]["motivos"]:
        raise ValueError("Contraprova nao passa criterio anterior")
    return True


data = json.loads((OUT / "alternativas_familias_e_concorrentes.json").read_text(encoding="utf-8"))
unique = {c["cartao127"]: c for c in json.loads((OUT / "unicidade_composicao24.json").read_text(encoding="utf-8"))["casos"]}
cases = {line: data["casos"][str(line)] for line in (773909, 773767, 774008)}
for line in cases:
    verify(cases[line], unique[line], line != 774008)
assert [c["chave25"] for c in cases[773909]["alternativas25"]] == [[60, 63788, 163]]
assert [c["chave25"] for c in cases[773767]["alternativas25"]] == [[60, 63788, 140]]
assert [c["chave25"] for c in cases[774008]["alternativas25"]] == [[60, 63788, 180]]
assert len(cases[774008]["alternativas25"][0]["avaliacao"]["testemunhas_exatas_unicas_UF127"]) == 3
assert cases[773909]["cartao"]["original"] == cases[773909]["cartao"]["corrigido"]
assert all(p["original"] == p["corrigido"] for c in cases.values() for p in c["pessoas"])
target_people = [p for p in cases[773909]["pessoas"] if p["linha"] in (773911, 773913)]
assert len(target_people) == 2 and target_people[0]["original"] == target_people[1]["original"]
source_lines = [p["linha"] for p in cases[773909]["alternativas25"][0]["pessoas25"]
    if base.parse_profile(p["texto"], guides[("25", "pessoas")], base.PERSON_NAMES)[0] ==
       base.parse_profile(target_people[0]["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)[0]]
assert source_lines == [3827374, 3827375]
decisions = [{"grupo": "60-63788-146-linha773911", "linha": str(p["linha"]), "acao": "manter",
    "n_antes": "2", "n_manter": "2", "texto_original": p["original"], "texto_corrigido": p["corrigido"],
    "fonte_25": "data/release_legacy/Censo.1960.amostra.25porcento.sp.gz", "linhas_25": "3827374;3827375",
    "justificativa": "Preservacao composta em 23/09/2026: grupo integral de quatro pessoas unico nas duas fontes; 25 campos, cartao, geografia e duas ocorrencias conferidos; concorrentes com grupos proprios independentes. Numeracao e respostas preservadas. Prova: references/fechamento_integral_1960_evidencias/duplicata_sp_composta.json; nao identifica civilmente pessoas."} for p in target_people]

negative = []
for defect in ("perda_pessoa", "idade", "cartao", "geografia", "chave", "duplicar_concorrente"):
    altered = deepcopy(cases[773909]); uniques = deepcopy(unique[773909])
    if defect == "perda_pessoa":
        altered["pessoas"].pop()
    elif defect in {"idade", "geografia", "chave"}:
        position = {"idade": 21, "geografia": 6, "chave": 8}[defect]
        text = altered["pessoas"][0]["corrigido"]
        altered["pessoas"][0]["corrigido"] = text[:position] + ("0" if text[position] != "0" else "1") + text[position+1:]
    elif defect == "cartao":
        text = altered["cartao"]["corrigido"]
        altered["cartao"]["corrigido"] = text[:20] + "8" + text[21:]
    else:
        uniques["correspondentes25_composicao24_sem_restricao_cartao"] *= 2
    try:
        verify(altered, uniques, True)
    except ValueError as error:
        negative.append({"alteracao": defect, "recusada": str(error)})
    else:
        raise AssertionError(defect)

needed = {p["linha"]: p for c in cases.values() for p in [c["cartao"]] + c["pessoas"]}
with (ROOT / base.FIXED_SOURCES[0]).open("rb") as raw:
    for line, p in needed.items():
        raw.seek((line - 1) * 64)
        assert raw.read(62).decode("latin1") == p["original"]
ff, pp = base.read_source(ROOT, 60, {(63788, k) for k in (140, 163, 180)})
for case in cases.values():
    candidate = case["alternativas25"][0]; key = tuple(candidate["chave25"][1:])
    assert ff[key] == [candidate["cartao25"]] and pp[key] == candidate["pessoas25"]
sources = data["fontes"] + [{"arquivo": p, "sha256": base.sha256(ROOT / p)} for p in [
    base.FIXED_SOURCES[0], "references/fechamento_integral_1960_duplicatas_prova_sp.py"] +
    [f"read_guides/readguide_1960_amostra_{s}_{k}.csv" for s in ("127", "25") for k in ("familias", "pessoas")]]
result = {"versao": 1, "situacao": "proposta_conferida_sem_manifesto_alterado", "resumo": {"grupos": 1, "linhas": 2,
    "manter": 2, "remover": 0, "literais127_relidos": len(needed), "negativos_recusados": len(negative)},
    "criterio": "Unicidade do multiconjunto familiar completo em ambas as fontes estaduais, 25 campos pessoais/cardinalidades/cartao/geografia exatos no alvo; alternativas independentes identificadas. Nao e identidade civil.",
    "decisoes": decisions, "casos": cases, "unicidade": {k: unique[k] for k in cases},
    "controles_negativos": negative, "fontes": sources,
    "manifesto_antes_sha256": base.sha256(ROOT / "read_guides/1960_amostra_127_duplicatas.csv")}
PORTABLE.parent.mkdir(parents=True, exist_ok=True)
with PORTABLE.open("x", encoding="utf-8") as stream:
    json.dump(result, stream, ensure_ascii=False, indent=2)
with (OUT / "duplicata_sp_decisoes_propostas.csv").open("x", encoding="utf-8", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(decisions[0]), quoting=csv.QUOTE_ALL)
    writer.writeheader(); writer.writerows(decisions)
print(json.dumps(result["resumo"]))
