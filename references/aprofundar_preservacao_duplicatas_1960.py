"""Testa grupos proprios dos cartoes alternativos; somente novas evidencias."""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import sqlite3

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, UF, load_guides, parse_profile, profile_hash,
    read_source, rows, sha256, source_structure,
)

ROOT = Path(__file__).resolve().parents[1]
INDEX = "tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite"
TARGETS = {(60, 63788, 181): (774208, 63788, 215), (81, 82192, 31): (986881, 82192, 250)}


def compare(connection, card127, people127, card25, people25, guides):
    reasons = source_structure(card25, people25)
    fa, ba = parse_profile(card127["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
    fb, bb = parse_profile(card25["texto"], guides[("25", "familias")], FAMILY_NAMES)
    if ba or bb or fa != fb or card127["corrigido"][6:8] != card25["texto"][33:35]:
        reasons.append("cartao_ou_distrito_diverge")
    pa = [parse_profile(r["corrigido"], guides[("127", "pessoas")], PERSON_NAMES) for r in people127]
    pb = [parse_profile(r["texto"], guides[("25", "pessoas")], PERSON_NAMES) for r in people25]
    if any(bad for _, bad in pa + pb):
        reasons.append("perfil_invalido")
    a = Counter(p[:16] + p[17:] for p, _ in pa); b = Counter(p[:16] + p[17:] for p, _ in pb)
    if a != b:
        reasons.append("composicao_ou_quantidade_diverge")
    a_variants = defaultdict(set); b_variants = defaultdict(set)
    for p, _ in pa:
        a_variants[p[:16] + p[17:]].add(p[16])
    for p, _ in pb:
        b_variants[p[:16] + p[17:]].add(p[16])
    for p in a_variants.keys() & b_variants.keys():
        x = a_variants[p]; y = b_variants[p]
        if len(x) != 1 or len(y) != 1 or (x != y and x | y != {0, 63}):
            reasons.append("V216_ou_fusao_de_perfis")
    if any(p["corrigido"][:8] + p["corrigido"][17] != card127["corrigido"][:8] + card127["corrigido"][17] for p in people127):
        reasons.append("geografia_pessoal_diverge")
    exact = {p for p, _ in pa} & {p for p, _ in pb}; unique = []
    for row, (p, _) in zip(people127, pa):
        if p in exact and connection.execute("SELECT count(*) FROM pessoas WHERE uf=? AND perfil=? AND excluida=0",
                                            (int(card127["corrigido"][:2]), profile_hash(p))).fetchone()[0] == 1:
            unique.append(row["linha"])
    if len(unique) < 2:
        reasons.append("menos2testemunhas_exatas_unicas")
    return {"motivos": sorted(set(reasons)), "testemunhas_exatas_unicas_UF127": unique,
        "n127": len(pa), "n25": len(pb), "composicao24_exata": a == b,
        "composicao25_exata": Counter(p for p, _ in pa) == Counter(p for p, _ in pb)}


def main(out, portable=None):
    out = out.resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    guides = load_guides(ROOT)
    data = json.loads((ROOT / "references/investigacao_residual_1960_evidencias/duplicatas_fora_chave.json").read_text(encoding="utf-8"))
    connection = sqlite3.connect((ROOT / INDEX).as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    cases = []
    corrections = {int(r["linha"]): r for r in rows(ROOT / "read_guides/1960_amostra_127_correcoes.csv")}
    with (ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt").open("rb") as raw:
        for case in data["casos"]:
            key = tuple(case["avaliacao"]["chave127"])
            if key not in TARGETS:
                continue
            other, pasta, boletim = TARGETS[key]
            card = dict(connection.execute("SELECT linha,original,corrigido FROM familias WHERE linha=?", (other,)).fetchone())
            people = [dict(r) for r in connection.execute("SELECT linha,original,corrigido FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (other,))]
            for person in [card] + people + case["cartoes127"] + case["pessoas127"]:
                raw.seek((person["linha"] - 1) * 64)
                text = raw.read(64).decode("latin1").rstrip("\r\n")
                corrected = corrections.get(person["linha"], {}).get("texto_corrigido") or text
                if person["original"] != text or person["corrigido"] != corrected:
                    raise ValueError("Literal127 mudou")
            target25key = tuple(case["avaliacao"]["chave25"][1:])
            ff, pp = read_source(ROOT, key[0], {target25key, (pasta, boletim)})
            if len(ff[target25key]) != 1 or len(ff[(pasta, boletim)]) != 1:
                raise ValueError("Cartao25 nao unico")
            if ff[target25key][0] != case["cartao25"] or pp[target25key] != case["pessoas25"]:
                raise ValueError("Fonte25 mudou")
            main_check = compare(connection, case["cartoes127"][0], case["pessoas127"], case["cartao25"], case["pessoas25"], guides)
            other_check = compare(connection, card, people, ff[(pasta, boletim)][0], pp[(pasta, boletim)], guides)
            competing_check = compare(connection, card, people, case["cartao25"], case["pessoas25"], guides)
            cases.append({"chave127": list(key), "grupo_alvo": case,
                "avaliacao_alvo": main_check,
                "outro_cartao127": card, "outras_pessoas127": people,
                "fonte25_outro_cartao": ff[(pasta, boletim)][0], "fonte25_outras_pessoas": pp[(pasta, boletim)],
                "avaliacao_grupo_proprio_do_alternativo": other_check,
                "avaliacao_alternativo_como_se_fosse_alvo": competing_check,
                "alternativo_excluido_por_grupo_proprio": not other_check["motivos"] and bool(competing_check["motivos"]),
                "decisao_aplicada": False})
    result = {"casos": cases, "indice127_sha256": sha256(ROOT / INDEX),
        "fontes": [{"arquivo": f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz",
            "sha256": sha256(ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz")} for uf in (60, 81)]}
    (out / "alternativos_grupos_proprios.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(ROOT / "references") or portable.exists():
            raise ValueError("Prova portatil deve ser nova em references")
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps([{"chave": c["chave127"], "alvo": c["avaliacao_alvo"], "outro": c["avaliacao_grupo_proprio_do_alternativo"],
                      "alternativo_excluido": c["alternativo_excluido_por_grupo_proprio"]} for c in cases]))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(); parser.add_argument("--out", type=Path, required=True); parser.add_argument("--portable", type=Path)
    args = parser.parse_args(); main(args.out, args.portable)
