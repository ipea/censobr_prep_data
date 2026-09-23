"""Confere duas preservacoes RS e emite patch; nunca reescreve microdados."""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import io
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, load_guides, parse_profile, rows, sha256,
    source_structure,
)

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = "references/investigacao_residual_1960_evidencias/duplicatas_fora_chave.json"
MANIFEST = "read_guides/1960_amostra_127_duplicatas.csv"
APPROVED = {(81, 82894, 10), (81, 82974, 221)}


def without_v216(p):
    return p[:16] + p[17:]


def verify_case(case, guides, witnesses):
    check = case["avaliacao"]
    key127 = tuple(check["chave127"]); key25 = tuple(check["chave25"])
    if key127 not in APPROVED or key25[0] != key127[0]:
        raise ValueError("Contexto nao aprovado")
    if len(case["cartoes127"]) != 1:
        raise ValueError("Cartao127 nao unico")
    card127 = case["cartoes127"][0]; card25 = case["cartao25"]
    if source_structure(card25, case["pessoas25"]):
        raise ValueError("Estrutura fonte25 invalida")
    f127, bad127 = parse_profile(card127["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
    f25, bad25 = parse_profile(card25["texto"], guides[("25", "familias")], FAMILY_NAMES)
    if bad127 or bad25 or f127 != f25 or card127["corrigido"][6:8] != card25["texto"][33:35]:
        raise ValueError("Cartao ou distrito discordante")
    geo25 = card25["texto"][29:35] + card25["texto"][35:36]
    if any(p["corrigido"][2:8] + p["corrigido"][17] != geo25 for p in case["pessoas127"]):
        raise ValueError("Geografia pessoal discordante")
    a = []; b = []
    for which, name, target in (("127", "pessoas127", a), ("25", "pessoas25", b)):
        for person in case[name]:
            text = person["corrigido"] if which == "127" else person["texto"]
            profile, invalid = parse_profile(text, guides[(which, "pessoas")], PERSON_NAMES)
            if invalid:
                raise ValueError("Pessoa com campo invalido")
            target.append(profile)
    if Counter(without_v216(p) for p in a) != Counter(without_v216(p) for p in b):
        raise ValueError("Composicao ou multiplicidades divergentes")
    variants_a = defaultdict(set); variants_b = defaultdict(set)
    for p in a:
        variants_a[without_v216(p)].add(p)
    for p in b:
        variants_b[without_v216(p)].add(p)
    for p in variants_a:
        if len(variants_a[p]) != 1 or len(variants_b[p]) != 1:
            raise ValueError("Projecao24 funde perfis")
        x = next(iter(variants_a[p]))[16]; y = next(iter(variants_b[p]))[16]
        if x != y and {x, y} != {0, 63}:
            raise ValueError("Ano de casamento fora da divergencia documentada")
    anchors = [p["linha"] for p, profile in zip(case["pessoas127"], a)
               if profile in b and witnesses[profile] == 1]
    if len(anchors) < 2:
        raise ValueError("Menos de duas testemunhas exatas unicas naUF")
    if check["outras_familias127_composicao24"] or check["cartoes127_na_chave25"]:
        raise ValueError("Familia alternativa nao excluida")
    proposals = []
    for group in check["grupos"]:
        selected = [p for p in case["pessoas127"] if p["linha"] in group["linhas127"]]
        if len(selected) != 2 or len({p["corrigido"] for p in selected}) != 1:
            raise ValueError("Par127 nao conferido")
        profile = parse_profile(selected[0]["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0]
        sources = [p["linha"] for p, q in zip(case["pessoas25"], b) if without_v216(q) == without_v216(profile)]
        if len(sources) != 2 or sources != group["linhas25"]:
            raise ValueError("Duas ocorrencias25 nao demonstradas")
        for person in selected:
            proposals.append({"grupo": group["grupo"], "linha": str(person["linha"]), "acao": "manter",
                "n_antes": "2", "n_manter": "2", "texto_original": person["original"],
                "texto_corrigido": person["corrigido"], "fonte_25": "data/release_legacy/Censo.1960.amostra.25porcento.rs.gz",
                "linhas_25": ";".join(map(str, sources)),
                "justificativa": "Preservacao conferida em 22/09/2026: composicao integral fora da chave, cartao/geografia exatos, duas testemunhas pessoais exatas unicas na UF127 e duas ocorrencias25. Pasta/boletim e V21600/63 permanecem originais. Prova: references/resolucao_residuais_duplicatas_1960_evidencias.json; nao identifica civilmente cada pessoa."})
    return {"chave127": list(key127), "chave25": list(key25), "testemunhas_exatas_unicas": anchors,
            "n_pessoas127": len(a), "n_pessoas25": len(b), "decisoes": proposals}


def prepare(out, portable=None):
    out = out.resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida deve ficar em tmp")
    out.mkdir(parents=True, exist_ok=False)
    data = json.loads((ROOT / EVIDENCE).read_text(encoding="utf-8"))
    cases = [c for c in data["casos"] if tuple(c["avaliacao"]["chave127"]) in APPROVED]
    if len(cases) != 2:
        raise ValueError("Quantidade inesperada de provas")
    guides = load_guides(ROOT)
    corrections = {int(r["linha"]): r for r in rows(ROOT / "read_guides/1960_amostra_127_correcoes.csv")}
    decisions = rows(ROOT / MANIFEST); excluded = {int(r["linha"]) for r in decisions if r["acao"] == "remover"}
    needed127 = {p["linha"]: p for c in cases for p in c["cartoes127"] + c["pessoas127"]}
    needed25 = {p["linha"]: p["texto"] for c in cases for p in [c["cartao25"]] + c["pessoas25"]}
    witnesses = Counter(); found127 = set(); found25 = set()
    profiles = {parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0] for c in cases for p in c["pessoas127"]}
    raw_path = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    with raw_path.open(encoding="latin1") as stream:
        for line, text in enumerate(stream, 1):
            text = text.rstrip("\r\n"); corrected = corrections.get(line, {}).get("texto_corrigido") or text
            if line in needed127:
                row = needed127[line]
                if row["original"] != text or row["corrigido"] != corrected:
                    raise ValueError("Literal127 diverge da prova")
                found127.add(line)
            if line not in excluded and corrected[:2] == "81" and corrected[16] in "23":
                p, invalid = parse_profile(corrected, guides[("127", "pessoas")], PERSON_NAMES)
                if not invalid and p in profiles:
                    witnesses[p] += 1
    path25 = ROOT / "data/release_legacy/Censo.1960.amostra.25porcento.rs.gz"
    with gzip.open(path25, "rt", encoding="latin1") as stream:
        for line, text in enumerate(stream, 1):
            if line in needed25:
                if text.rstrip("\r\n") != needed25[line]:
                    raise ValueError("Literal25 diverge da prova")
                found25.add(line)
    if found127 != set(needed127) or found25 != set(needed25):
        raise ValueError("Linhas de prova ausentes")
    proofs = [verify_case(c, guides, witnesses) for c in cases]
    proposed = sorted([r for proof in proofs for r in proof["decisoes"]], key=lambda r: int(r["linha"]))
    present = {r["linha"]: r for r in decisions}
    for r in proposed:
        if r["linha"] in present and r != present[r["linha"]]:
            raise ValueError("Decisao existente discordante")
    result = {"versao": 1, "resumo": {"grupos": 2, "linhas": 4, "manter": 4, "remover": 0,
        "novas": sum(r["linha"] not in present for r in proposed)}, "decisoes": proposed,
        "provas": proofs, "casos_completos": cases,
        "fontes": [{"arquivo": str(p.relative_to(ROOT)), "sha256": sha256(p)} for p in
            [raw_path, path25, ROOT / EVIDENCE] + [ROOT / f"read_guides/readguide_1960_amostra_{s}_{k}.csv" for s in ("127", "25") for k in ("familias", "pessoas")]],
        "manifesto_antes_sha256": sha256(ROOT / MANIFEST), "script_sha256": sha256(Path(__file__))}
    target = out / "decisoes_e_provas.json"
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(ROOT / "references") or portable.exists():
            raise ValueError("Prova portatil deve ser nova em references")
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps(result["resumo"]))
    return result


def manifest_patch(proof):
    data = json.loads(proof.read_text(encoding="utf-8")); current = rows(ROOT / MANIFEST)
    present = {r["linha"]: r for r in current}
    add = [r for r in data["decisoes"] if r["linha"] not in present]
    if len(add) != 4 or sha256(ROOT / MANIFEST) != data["manifesto_antes_sha256"]:
        raise ValueError("Manifesto mudou ou proposta ja foi aplicada")
    output = io.StringIO(newline=""); writer = csv.DictWriter(output, fieldnames=list(current[0]), quoting=csv.QUOTE_ALL, lineterminator="\n")
    writer.writerows(add)
    last = (ROOT / MANIFEST).read_text(encoding="utf-8").rstrip("\n").splitlines()[-1]
    print("*** Begin Patch\n*** Update File: " + MANIFEST + "\n@@\n " + last + "\n" +
          "\n".join("+" + line for line in output.getvalue().splitlines()) + "\n*** End Patch")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path)
    parser.add_argument("--portable", type=Path)
    parser.add_argument("--manifest-patch", type=Path)
    args = parser.parse_args()
    if args.manifest_patch:
        manifest_patch(args.manifest_patch)
    else:
        prepare(args.out, args.portable)
