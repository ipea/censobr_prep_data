"""Criterio localizado CE15004/034: adulto unico e renumeracao independente."""
import argparse
from collections import Counter, defaultdict
import gzip
import json
from pathlib import Path
import sqlite3

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, load_guides, parse_profile, rows, sha256, source_structure,
)
from investigacao_residual_duplicatas_1960 import raw_signature, signature, multiplicities

ROOT = Path(__file__).resolve().parents[1]
INDEX = "tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite"


def approve_ce(check):
    requirements = (check["adulto24_ocorrencias127"] == 1, check["adulto24_ocorrencias25"] == 1,
        check["alternativas_grupo25"] == [701181], check["familias127_com_adulto24"] == [131521],
        check["n127"] == check["n25"] == 9, check["cartao_geografia_exatos"],
        check["V216_apenas00_63"], check["vizinhas_comprovadas"] == 145,
        check["vizinhas_independentes_do_alvo"] == 144,
        check["mapeamento_vizinhas_univoco"], check["respostas_alteradas"] == 0)
    if not all(requirements):
        raise ValueError("Prova composta CE insuficiente")
    return True


def main(out, portable=None):
    out = out.resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False); guides = load_guides(ROOT)
    proof_path = ROOT / "references/investigacao_residual_1960_evidencias/duplicatas_fora_chave.json"
    data = json.loads(proof_path.read_text(encoding="utf-8"))
    case = next(c for c in data["casos"] if c["avaliacao"]["chave127"] == [14, 15004, 34])
    neighborhood_path = ROOT / "references/investigacao_residual_1960_evidencias/duplicatas_vizinhancas1702.json"
    neighbors = json.loads(neighborhood_path.read_text(encoding="utf-8"))["coincidencias"]
    selected = [r for r in neighbors if r["chave127"][0:2] == [14, 15004] and r["chave25"][1] == 14990
                and r["chave127"][2] == r["chave25"][2] and r["corpo_cartao_exato"] and r["geografia_exata"]]
    con = sqlite3.connect((ROOT / INDEX).as_uri() + "?mode=ro", uri=True); con.row_factory = sqlite3.Row
    contexts = {}; literal127 = {}
    for neighbor in selected:
        line = neighbor["cartao127"]
        card = dict(con.execute("SELECT linha,original,corrigido FROM familias WHERE linha=?", (line,)).fetchone())
        people = [dict(r) for r in con.execute("SELECT linha,original,corrigido FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (line,))]
        contexts[neighbor["cartao25"]] = {"cartao127": card, "pessoas127": people, "chave25": neighbor["chave25"]}
        literal127.update({r["linha"]: r for r in [card] + people})
    if len(contexts) != len(selected):
        raise ValueError("Duas familias127 mapeadas ao mesmo cartao25")
    anchor = next(p for p in case["pessoas127"] if p["linha"] == 131522)
    anchor_profile = parse_profile(anchor["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0]
    anchor_signature = signature(anchor_profile, guides)
    target_counter = Counter(signature(parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0], guides) for p in case["pessoas127"])
    target_repeated = {s for s, n in target_counter.items() if n > 1}
    corrections = {int(r["linha"]): r for r in rows(ROOT / "read_guides/1960_amostra_127_correcoes.csv")}
    removed = {int(r["linha"]) for r in rows(ROOT / "read_guides/1960_amostra_127_duplicatas.csv") if r["acao"] == "remover"}
    anchors127 = []; seen127 = set()
    rawpath = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    with rawpath.open(encoding="latin1") as stream:
        for line, text in enumerate(stream, 1):
            text = text.rstrip("\r\n"); corrected = corrections.get(line, {}).get("texto_corrigido") or text
            if line in literal127:
                row = literal127[line]
                if row["original"] != text or row["corrigido"] != corrected:
                    raise ValueError("Literal127 do contexto divergente")
                seen127.add(line)
            if corrected[:2] == "14" and corrected[16] in "23" and line not in removed:
                profile, bad = parse_profile(corrected, guides[("127", "pessoas")], PERSON_NAMES)
                if not bad and signature(profile, guides) == anchor_signature:
                    anchors127.append(line)
    if seen127 != set(literal127):
        raise ValueError("Literal127 ausente")
    path25 = ROOT / "data/release_legacy/Censo.1960.amostra.25porcento.ce.gz"
    anchors25 = []; alternatives = []; family = None; people = []; verified = []

    def examine():
        if not family:
            return
        counter = Counter(raw_signature(p["texto"]) for p in people)
        if multiplicities(target_counter, counter, target_repeated):
            alternatives.append(family["linha"])
        if family["linha"] not in contexts:
            return
        context = contexts[family["linha"]]; card = context["cartao127"]
        if source_structure(family, people):
            raise ValueError("Estrutura25 da vizinhanca divergente")
        f127, ba = parse_profile(card["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
        f25, bb = parse_profile(family["texto"], guides[("25", "familias")], FAMILY_NAMES)
        parsed127 = [parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES) for p in context["pessoas127"]]
        parsed25 = [parse_profile(p["texto"], guides[("25", "pessoas")], PERSON_NAMES) for p in people]
        if any(bad for _, bad in parsed127 + parsed25):
            raise ValueError("Campo pessoal invalido na vizinhanca")
        pc = Counter(signature(p, guides) for p, _ in parsed127)
        if ba or bb or f127 != f25 or card["corrigido"][6:8] != family["texto"][33:35] or pc != counter:
            raise ValueError("Cartao/geografia/composicao de vizinha nao conferem")
        if int(card["corrigido"][8:13]) != 15004 or int(family["texto"][:5]) != 14990 or card["corrigido"][13:16] != family["texto"][5:8]:
            raise ValueError("Mapa de renumeracao divergente")
        context["cartao25"] = family; context["pessoas25"] = people
        verified.append(context)

    with gzip.open(path25, "rt", encoding="latin1") as stream:
        for line, text in enumerate(stream, 1):
            text = text.rstrip("\r\n"); row = {"linha": line, "texto": text}
            if text[8:10] == "00":
                examine(); family = row; people = []
            else:
                if raw_signature(text) == anchor_signature:
                    anchors25.append(line)
                people.append(row)
        examine()
    fresh = next(c for c in verified if c["cartao127"]["linha"] == 131521)
    if fresh["cartao25"] != case["cartao25"] or fresh["pessoas25"] != case["pessoas25"]:
        raise ValueError("Prova do alvo nao coincide com leitura fresca25")
    if any([(p["linha"], p["original"], p["corrigido"]) for p in fresh[kind]] !=
           [(p["linha"], p["original"], p["corrigido"]) for p in case[kind]] for kind in ["pessoas127"]):
        raise ValueError("Prova pessoal127 do alvo divergente")
    v216 = []
    for person in case["pessoas127"]:
        p, _ = parse_profile(person["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)
        compatible = [parse_profile(q["texto"], guides[("25", "pessoas")], PERSON_NAMES)[0] for q in case["pessoas25"] if raw_signature(q["texto"]) == signature(p, guides)]
        if not compatible:
            raise ValueError("Pessoa sem correspondente")
        for q in compatible:
            if p[16] != q[16]:
                v216.append([p[16], q[16]])
    check = {"adulto24_ocorrencias127": len(anchors127), "adulto24_ocorrencias25": len(anchors25),
        "linhas_adulto127": anchors127, "linhas_adulto25": anchors25,
        "alternativas_grupo25": alternatives,
        "familias127_com_adulto24": sorted({r[0] for line in anchors127 for r in con.execute("SELECT familia_atual FROM pessoas WHERE linha=?", (line,))}),
        "n127": len(case["pessoas127"]), "n25": len(case["pessoas25"]),
        "cartao_geografia_exatos": not case["avaliacao"]["diferencas_cartao"] and case["avaliacao"]["geografia127"] == [case["avaliacao"]["geografia25"]],
        "V216_apenas00_63": all(set(pair) == {0, 63} for pair in v216), "vizinhas_comprovadas": len(verified),
        "vizinhas_independentes_do_alvo": sum(c["cartao127"]["linha"] != 131521 for c in verified),
        "mapeamento_vizinhas_univoco": all(sum(x["cartao127"] == r["cartao127"] for x in neighbors) == 1 for r in selected),
        "respostas_alteradas": 0}
    approve_ce(check)
    result = {"criterio_localizado": "Exclusivamente CE15004/034; nao estende criterio a todos os perfis24.",
        "conferencia": check, "caso": case, "vizinhas_com_literais": verified,
        "fontes": [{"arquivo": p.relative_to(ROOT).as_posix(), "sha256": sha256(p)} for p in [rawpath, path25, proof_path, neighborhood_path]],
        "decisao_aplicada": False}
    (out / "prova_composta_ce.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(ROOT / "references") or portable.exists():
            raise ValueError("Prova portatil deve ser nova")
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps(check))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("--out", type=Path, required=True); parser.add_argument("--portable", type=Path)
    args = parser.parse_args(); main(args.out, args.portable)
