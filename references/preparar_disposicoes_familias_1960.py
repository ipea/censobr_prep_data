"""Dispoe coincidencias sem excluir familias nem transformar igualdade em identidade."""
import argparse
from collections import Counter, defaultdict
import gzip
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, UF, load_guides, parse_profile, rows, sha256,
    source_structure,
)

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = "references/investigacao_residual_1960_evidencias/familias_coincidentes.json"
MANIFEST = "read_guides/1960_amostra_127_familias_coincidentes.json"


def inspect_card(card, guides):
    source = card.get("registros25_da_chave")
    if not source:
        return {"linha_cartao127": card["linha"], "suficiente_para_preservar": False,
                "motivos": ["fonte25_nao_disponivel"]}
    cards25 = [r for r in source if r["texto"][8:10] == "00"]
    people25 = [r for r in source if r["texto"][8:10] != "00"]
    reasons = []
    if len(cards25) != 1:
        return {"linha_cartao127": card["linha"], "suficiente_para_preservar": False,
                "motivos": ["cartao25_nao_unico"]}
    source_card = cards25[0]; text = source_card["texto"]
    reasons.extend(source_structure(source_card, people25))
    if (int(text[:5]), int(text[5:8])) != (card["pasta"], card["boletim"]):
        reasons.append("chave25_diverge")
    if text[33:35] != card["corrigido"][6:8]:
        reasons.append("distrito_diverge")
    a, bad_a = parse_profile(card["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
    b, bad_b = parse_profile(text, guides[("25", "familias")], FAMILY_NAMES)
    differences = [{"campo": name, "valor127": x, "valor25": y}
                   for name, x, y in zip(FAMILY_NAMES, a, b) if x != y]
    if bad_a or bad_b:
        reasons.append("cartao_codigo_invalido")
    if differences:
        reasons.append("respostas_cartao_divergem")
    profiles127 = []; profiles25 = []; variants127 = defaultdict(set); variants25 = defaultdict(set)
    for sample, people, output, variants in (("127", card["pessoas_literais"], profiles127, variants127),
                                              ("25", people25, profiles25, variants25)):
        for person in people:
            literal = person["corrigido"] if sample == "127" else person["texto"]
            p, bad = parse_profile(literal, guides[(sample, "pessoas")], PERSON_NAMES)
            if bad:
                reasons.append("pessoa_codigo_invalido")
            if sample == "127" and literal[:8] + literal[17] != card["corrigido"][:8] + card["corrigido"][17]:
                reasons.append("geografia_pessoal_diverge")
            output.append(p); variants[p[:16] + p[17:]].add(p)
    if Counter(p[:16] + p[17:] for p in profiles127) != Counter(p[:16] + p[17:] for p in profiles25):
        reasons.append("composicao24_diverge")
    v216 = []
    for p in variants127.keys() & variants25.keys():
        if len(variants127[p]) != 1 or len(variants25[p]) != 1:
            reasons.append("projecao24_funde_perfis"); continue
        x = next(iter(variants127[p]))[16]; y = next(iter(variants25[p]))[16]
        if x != y:
            v216.append({"valor127": x, "valor25": y})
            if {x, y} != {0, 63}:
                reasons.append("V216_fora00_63")
    if len(profiles127) != len(profiles25):
        reasons.append("quantidade_pessoal_diverge")
    return {"linha_cartao127": card["linha"], "linha_cartao25": source_card["linha"],
        "chave25": [card["uf"], int(text[:5]), int(text[5:8])],
        "suficiente_para_preservar": not reasons, "motivos": sorted(set(reasons)),
        "diferencas_cartao": differences, "diferencasV216_preservadas": v216,
        "composicao25_exata": Counter(profiles127) == Counter(profiles25),
        "n_pessoas127": len(profiles127), "n_pessoas25": len(profiles25)}


def disposition(cards, guides):
    checks = [inspect_card(c, guides) for c in cards]
    identities = [(c["uf"], check.get("linha_cartao25")) for c, check in zip(cards, checks)]
    coherent = all(c["suficiente_para_preservar"] for c in checks) and len(set(identities)) == len(cards)
    return ("preservar_distintos_entre_fontes" if coherent else "pendente"), checks


def prepare(out):
    out = out.resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida deve ficar em tmp")
    out.mkdir(parents=True, exist_ok=False)
    evidence = json.loads((ROOT / EVIDENCE).read_text(encoding="utf-8"))
    guides = load_guides(ROOT)
    corrections = {int(r["linha"]): r for r in rows(ROOT / "read_guides/1960_amostra_127_correcoes.csv")}
    rawpath = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    wanted25 = defaultdict(dict); records127 = {}
    with rawpath.open("rb") as raw:
        for group in evidence["conjuntos"]:
            for card in group["cartoes"]:
                for person in [{"linha": card["linha"], "corrigido": card["corrigido"]}] + card["pessoas_literais"]:
                    raw.seek((person["linha"] - 1) * 64)
                    text = raw.read(64).decode("latin1").rstrip("\r\n")
                    corrected = corrections.get(person["linha"], {}).get("texto_corrigido") or text
                    if len(text) != 62 or corrected != person["corrigido"] or person.get("original", text) != text:
                        raise ValueError("Literal127 diverge do caderno historico")
                    records127[person["linha"]] = {"linha": person["linha"], "texto_original": text, "texto_corrigido": corrected}
                for record in card.get("registros25_da_chave") or []:
                    wanted25[card["uf"]][record["linha"]] = record["texto"]
    source_paths = [rawpath, ROOT / EVIDENCE]
    source_paths.extend(ROOT / f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv"
                        for sample in ("127", "25") for kind in ("familias", "pessoas"))
    for uf, wanted in wanted25.items():
        path = ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz"
        source_paths.append(path); seen = set()
        with gzip.open(path, "rt", encoding="latin1") as stream:
            for line, text in enumerate(stream, 1):
                if line in wanted:
                    if text.rstrip("\r\n") != wanted[line]:
                        raise ValueError("Literal25 diverge do caderno historico")
                    seen.add(line)
        if seen != set(wanted):
            raise ValueError("Registro25 nao localizado")
    dispositions = []
    for group in evidence["conjuntos"]:
        cards = group["cartoes"]; action, checks = disposition(cards, guides)
        card_rows = [records127[c["linha"]] for c in cards]
        personal_rows = [dict(records127[p], linha_cartao=c["linha"]) for c in cards for p in c["pessoas"]]
        sources = [{"arquivo": f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[c['uf']]}.gz",
            "linha_cartao": next(r["linha"] for r in c["registros25_da_chave"] if r["texto"][8:10] == "00"),
            "registros": c["registros25_da_chave"]} for c in cards if c.get("registros25_da_chave")]
        reason = ("Preservar boletins separados: a outra copia conserva cartoes distintos com mesma chave, geografia, composicao e quantidades; divergencia00/63 emV216, quando existente, permanece. Isto corrobora a separacao entre arquivos, nao prova identidade civil nem ausencia absoluta de erro na coleta. Nenhum cartao ou pessoa e excluido."
                  if action != "pendente" else
                  "Coincidencia de respostas sob chaves diferentes, sem contraprova integral suficiente. Preservar textos e registros, mas nao homologar nem excluir. Motivos especificos nas conferencias.")
        dispositions.append({"id": f"familias-{group['UF']:02d}-{min(c['linha'] for c in cards)}",
            "UF": group["UF"], "distrito": group["distrito"], "n_pessoas_por_cartao": group["n_pessoas_por_grupo"],
            "linhas_cartoes": [c["linha"] for c in cards], "linhas_pessoas": [p["linha"] for p in personal_rows],
            "acao": action, "justificativa": reason, "cartoes127": card_rows, "pessoas127": personal_rows,
            "fontes25": sources, "conferencias": checks})
    summary = {"conjuntos": len(dispositions), "cartoes": sum(len(c["cartoes127"]) for c in dispositions),
        "pessoas": sum(len(c["pessoas127"]) for c in dispositions),
        "conjuntos_preservar_distintos_entre_fontes": sum(c["acao"] != "pendente" for c in dispositions),
        "conjuntos_pendentes": sum(c["acao"] == "pendente" for c in dispositions),
        "cartoes_preservados_com_contraprova": sum(len(c["cartoes127"]) for c in dispositions if c["acao"] != "pendente"),
        "pessoas_preservadas_com_contraprova": sum(len(c["pessoas127"]) for c in dispositions if c["acao"] != "pendente"),
        "exclusoes": 0}
    result = {"versao": 1, "criterio": "MesmoUF/distrito,15camposcartao e multiconjunto25campospessoais. Pasta/boletim/id_arquivo nao identificam a assinatura. Dano nao pode virar igualdade artificial deNA.",
        "nao_e_identidade_civil": True, "resumo": summary,
        "fontes": [{"arquivo": p.relative_to(ROOT).as_posix(), "sha256": sha256(p)} for p in source_paths],
        "conjuntos": dispositions}
    (out / "manifesto_proposto.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary))
    return result


def manifest_patch(path):
    if (ROOT / MANIFEST).exists():
        raise ValueError("Manifesto de producao ja existe")
    data = json.loads(path.read_text(encoding="utf-8"))
    text = json.dumps(data, ensure_ascii=False, indent=2)
    print("*** Begin Patch\n*** Add File: " + MANIFEST + "\n" + "\n".join("+" + line for line in text.splitlines()) + "\n*** End Patch")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path)
    parser.add_argument("--manifest-patch", type=Path)
    args = parser.parse_args()
    if args.manifest_patch:
        manifest_patch(args.manifest_patch)
    else:
        prepare(args.out)
