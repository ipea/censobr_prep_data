"""Procura cópias exatas dos grupos MG4096 na própria fonte25, sem inferir distrito."""

from collections import defaultdict
import gzip
import hashlib
import json
from pathlib import Path

import auditoria_recuperacao_cartoes_1960 as core

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas/itutinga"
SOURCE = ROOT / "data/release_legacy/Censo.1960.amostra.25porcento.mg.gz"
guides = core.load_guides(ROOT)


def stream_groups():
    group = []
    key = None
    seen = set()
    with gzip.open(SOURCE, "rt", encoding="latin1") as stream:
        for line, text in enumerate(stream, 1):
            text = text.rstrip("\r\n")
            next_key = text[:8]
            if next_key != key:
                if group:
                    yield key, group
                if next_key in seen:
                    raise ValueError("Chave partida em MG: reagrupamento necessário")
                seen.add(next_key)
                key, group = next_key, []
            group.append({"linha": line, "texto": text})
        if group:
            yield key, group


def describe(key, records):
    cards = [r for r in records if r["texto"][8:10] == "00"]
    people = [r for r in records if r["texto"][8:10] != "00"]
    if len(cards) != 1:
        return None, {"chave": key, "motivo": "numero_cartoes", "n": len(cards)}
    reasons = core.source_structure(cards[0], people)
    profiles = [core.parse_profile(r["texto"], guides["25", "pessoas"], core.PERSON_NAMES) for r in people]
    invalid = sorted({field for _, bad in profiles for field in bad})
    if reasons or invalid:
        return None, {"chave": key, "estrutura": reasons, "pessoal_invalido": invalid}
    # Cada pessoa ocupa uma entrada. Não converter o multiconjunto em conjunto.
    parts = sorted(json.dumps(profile, separators=(",", ":")) for profile, _ in profiles)
    signature = hashlib.sha256(json.dumps(parts, separators=(",", ":")).encode()).hexdigest()
    fields = [field for field in core.FAMILY_NAMES if field != "V116"]
    family, bad = core.parse_profile(cards[0]["texto"], guides["25", "familias"], fields)
    text = cards[0]["texto"]
    return {"chave": key, "municipio": text[29:33], "distrito": text[33:35], "situacao": text[35],
            "cartao": cards[0], "pessoas": people, "n_pessoas": len(people),
            "perfil_pessoal_25_sha256": signature, "familia14_sem_municipio": family,
            "familia14_invalidos": bad}, None


def main():
    OUT.mkdir(parents=True, exist_ok=False)
    digest = core.sha256(SOURCE)
    target = []
    excluded_targets = []
    for key, records in stream_groups():
        if not any(r["texto"][8:10] == "00" and r["texto"][29:33] == "4096" for r in records):
            continue
        record, error = describe(key, records)
        if error:
            excluded_targets.append(error)
        else:
            target.append(record)
    by_signature = defaultdict(list)
    for record in target:
        by_signature[record["perfil_pessoal_25_sha256"]].append(record)
    hits = []
    groups = invalid_groups = 0
    target_keys = {r["chave"] for r in target}
    for key, records in stream_groups():
        groups += 1
        record, error = describe(key, records)
        if error:
            invalid_groups += 1
            continue
        matching = by_signature.get(record["perfil_pessoal_25_sha256"], [])
        for other in matching:
            if key == other["chave"]:
                continue
            hits.append({"alvo": other, "copia_pessoal_exata": record,
                         "mesmos14_campos_familiares": other["familia14_sem_municipio"] == record["familia14_sem_municipio"],
                         "outro_municipio": other["municipio"] != record["municipio"]})
    assert core.sha256(SOURCE) == digest
    result = {"fonte": SOURCE.relative_to(ROOT).as_posix(), "sha256": digest,
              "grupos_MG_examinados": groups, "grupos_MG_excluidos_por_dano_ou_estrutura": invalid_groups,
              "alvos4096_validos": len(target), "alvos4096_excluidos": excluded_targets,
              "alvos_distrito03": sum(r["distrito"] == "03" for r in target),
              "coincidencias_pessoais_completas": hits,
              "cartoes_alvo": [{k: v for k, v in r.items() if k != "pessoas"} for r in target],
              "limite": "Composição pessoal íntegra dos25campos; ausência de cópia não identifica distrito nem prova correção da geografia. Nenhuma correção ou exclusão autorizada por este resultado.",
              "script_sha256": core.sha256(Path(__file__))}
    (OUT / "resultado.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k not in {"coincidencias_pessoais_completas", "cartoes_alvo"}}, ensure_ascii=False))
    print("Coincidências pessoais completas:", len(hits))


if __name__ == "__main__":
    main()
