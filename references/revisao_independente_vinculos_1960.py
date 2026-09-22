"""Confere166vinculos por releitura integral das fontes e decisoes congeladas."""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path


NAMES = ["V202", "V203", "V204", "AGE", "V205", "V206", "V207", "V208", "V209", "V299",
         "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218", "V219",
         "V220", "V221", "V223", "V223B", "V224"]
FNAMES = [f"V{n}" for n in range(101, 114)] + ["V116", "V118"]
V216 = NAMES.index("V216")


def csvrows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def checksum(path):
    result = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def number(text):
    return int(text) if text.strip().isdigit() else None


def compile_guide(path, names):
    descriptor = {row["variavel"]: row for row in csvrows(path)}
    return [(name, int(descriptor[name]["inicio"]) - 1, int(descriptor[name]["fim"]),
             set(descriptor[name]["valores_validos"].split(";")) - {"", "NA"}) for name in names]


def signature(text, guide):
    values = []; bad = []
    for name, start, end, valid in guide:
        value = text[start:end]
        skip = len(text) == 62 and start in (19, 20, 32, 35, 46) and value.startswith("-") and not text[start + 1:54].strip()
        if not value.strip() or skip:
            values.append(None)
        elif value in valid or (not valid and value.isdigit()):
            values.append(int(value))
        else:
            values.append(None); bad.append(name)
    return tuple(values), bad


def scan127(path, corrections):
    with path.open(encoding="latin1") as f:
        for line, original in enumerate(f, 1):
            original = original.rstrip("\r\n")
            assert len(original) == 62
            decision = corrections.get(line, {})
            if decision:
                assert original == decision["texto_original"], line
            if decision.get("decisao") in ("corrompida", "cartao_uf"):
                continue
            text = decision.get("texto_corrigido") or original
            key = (number(text[:2]), number(text[8:13]), number(text[13:16]))
            yield line, original, text, key


def main(root, out):
    root = root.resolve(); out = out.resolve()
    assert out.is_relative_to(root / "tmp")
    out.mkdir(parents=True, exist_ok=False)
    folder = root / "tmp/fechamento_registros_1960_20260922/vinculos"
    delivery = folder / "entrega_02"
    inventory = json.loads((delivery / "indice.json").read_text(encoding="utf-8"))
    snapshots = {}; hashes = {}
    for entry in inventory["fontes_preservadas_antes_de_novas_decisoes"]:
        path = delivery / "fontes_decisoes_antes" / entry["snapshot"]
        assert checksum(path) == entry["sha256"]
        snapshots[entry["arquivo"]] = path
        hashes[str(path.relative_to(root))] = entry["sha256"]
    guides = {(sample, kind): compile_guide(snapshots[f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv"],
                                          NAMES if kind == "pessoas" else FNAMES)
              for sample in ("127", "25") for kind in ("pessoas", "familias")}
    corrections = {int(r["linha"]): r for r in csvrows(snapshots["read_guides/1960_amostra_127_correcoes.csv"])}
    duplicates = [r for name, path in snapshots.items() if "duplicatas" in name and name.endswith(".csv")
                  for r in csvrows(path)]
    assert len(duplicates) == 6451 and len({r["linha"] for r in duplicates}) == 6451
    removed = {int(r["linha"]) for r in duplicates if r["acao"] == "remover"}
    assert len(removed) == 2736
    previous_links = {int(r["linha"]): int(r["linha_familia"]) for r in csvrows(snapshots["read_guides/1960_amostra_127_vinculos.csv"])}
    rows = []; modes = {}
    for name, mode, count in (("vinculos_estritos_33.csv", "estrito", 33),
                              ("vinculos_condicionais_133.csv", "condicional", 133)):
        path = delivery / name; selected = csvrows(path)
        assert len(selected) == count
        hashes[str(path.relative_to(root))] = checksum(path)
        for row in selected:
            line = int(row["linha"]); target = int(row["linha_familia"])
            assert line not in removed and line not in modes
            modes[line] = mode; rows.append(row)
    proposed_links = {int(r["linha"]): int(r["linha_familia"]) for r in rows}
    assert len(proposed_links) == 166
    by_target = defaultdict(list)
    source_keys = defaultdict(set)
    for row in rows:
        by_target[int(row["linha_familia"])].append(row)
        text = row["texto_familia_corrigido"]
        key = (int(text[:2]), int(text[8:13]), int(text[13:16]))
        source_keys[row["fonte_25"]].add(key)
    expected_sources = {r["arquivo"]: r["sha256"] for r in json.loads((folder /
        "integral_02/candidatos_vinculos.json").read_text(encoding="utf-8"))["fontes"]}
    source_groups = defaultdict(list)
    wanted_signatures = defaultdict(set)
    for name, keys in source_keys.items():
        path = root / name
        assert checksum(path) == expected_sources[name]
        hashes[name] = expected_sources[name]
        uf = next(iter(keys))[0]
        with gzip.open(path, "rt", encoding="latin1") as f:
            for line, text in enumerate(f, 1):
                text = text.rstrip("\r\n")
                key = (uf, number(text[:5]), number(text[5:8]))
                if key not in keys:
                    continue
                source_groups[key].append({"linha": line, "texto": text})
                if text[8:10] != "00":
                    profile, bad = signature(text, guides["25", "pessoas"])
                    assert not bad
                    wanted_signatures[uf].add(profile)
        print("Fonte25 conferida:", name, flush=True)
    raw_path = root / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    raw_name = str(raw_path.relative_to(root)).replace("\\", "/")
    assert checksum(raw_path) == expected_sources[raw_name]
    hashes[raw_name] = expected_sources[raw_name]
    group_keys = {key for keys in source_keys.values() for key in keys}
    family_map = {}; families = defaultdict(list)
    for line, original, text, key in scan127(raw_path, corrections):
        if text[16] != "1":
            continue
        navigation = (key[0], text[6:16])
        assert navigation not in family_map
        family_map[navigation] = line
        if key in group_keys:
            families[key].append({"linha": line, "original": original, "corrigido": text})
    people = defaultdict(list); linked_before = defaultdict(list); linked_after = defaultdict(list)
    unique_counts = Counter(); matched_source_lines = defaultdict(list)
    for line, original, text, key in scan127(raw_path, corrections):
        if text[16] == "1" or line in removed:
            continue
        current = previous_links.get(line, family_map.get((key[0], text[6:16])))
        after = proposed_links.get(line, current)
        record = {"linha": line, "original": original, "corrigido": text, "familia_antes": current,
                  "familia_depois": after}
        if current in by_target:
            linked_before[current].append(line)
        if after in by_target:
            linked_after[after].append(line)
        if key[0] in wanted_signatures:
            profile, bad = signature(text, guides["127", "pessoas"])
            if not bad and profile in wanted_signatures[key[0]]:
                unique_counts[(key[0], profile)] += 1
                matched_source_lines[(key[0], profile)].append(line)
        if key in group_keys:
            people[key].append(record)
    proposal_path = folder / "existentes_proposta_integral_01/resultado.json"
    proposal = json.loads(proposal_path.read_text(encoding="utf-8"))
    conditional = {g["linha_familia"]: g for g in proposal["propostas_condicionais"]}
    hashes[str(proposal_path.relative_to(root))] = checksum(proposal_path)
    outcomes = []; all_person_differences = []; unmatched_civil = []
    for target, decisions in by_target.items():
        modes_group = {modes[int(r["linha"])] for r in decisions}
        assert len(modes_group) == 1
        mode = next(iter(modes_group)); text = decisions[0]["texto_familia_corrigido"]
        key = (int(text[:2]), int(text[8:13]), int(text[13:16]))
        fs = families[key]; ps = people[key]
        f25 = [r for r in source_groups[key] if r["texto"][8:10] == "00"]
        p25 = [r for r in source_groups[key] if r["texto"][8:10] != "00"]
        assert len(fs) == len(f25) == 1 and fs[0]["linha"] == target
        assert len(ps) == len(p25) == int(f25[0]["texto"][11:13])
        assert sorted(int(p["texto"][8:10]) for p in p25) == list(range(1, len(p25) + 1))
        assert [p["linha"] for p in p25] == list(range(f25[0]["linha"] + 1, f25[0]["linha"] + len(p25) + 1))
        assert f25[0]["texto"][36:] == "0" * 18
        for row in f25 + p25:
            assert len(row["texto"]) == 54
        for row in p25:
            source_text = row["texto"]
            assert source_text[8:11] == source_text[11:14] and source_text[23] == source_text[24] and source_text[51:] == "000"
        fp, bad = signature(fs[0]["corrigido"], guides["127", "familias"])
        fq, bad25 = signature(f25[0]["texto"], guides["25", "familias"])
        assert not bad and not bad25
        family_diffs = {n: [a, b] for n, a, b in zip(FNAMES, fp, fq) if a != b}
        assert not set(family_diffs) & {"V101", "V116", "V118"}
        assert text[6:8] == f25[0]["texto"][33:35]
        group_lines = {p["linha"] for p in ps}
        outside_before = set(linked_before[target]) - group_lines
        outside_after = set(linked_after[target]) - group_lines
        attributed_other = [p["linha"] for p in ps if p["familia_antes"] is not None and p["familia_antes"] != target]
        assert not outside_before and not outside_after and not attributed_other, (target, outside_before, outside_after, attributed_other)
        a = []; b = []
        for row in ps:
            sig, invalid = signature(row["corrigido"], guides["127", "pessoas"])
            assert not invalid; a.append(sig)
        for row in p25:
            sig, invalid = signature(row["texto"], guides["25", "pessoas"])
            assert not invalid; b.append(sig)
        if mode == "estrito":
            assert not family_diffs and Counter(a) == Counter(b)
        ca = defaultdict(list); cb = defaultdict(list)
        for i, sig in enumerate(a):
            ca[sig[:V216] + sig[V216 + 1:]].append(i)
        for i, sig in enumerate(b):
            cb[sig[:V216] + sig[V216 + 1:]].append(i)
        assert {p: len(v) for p, v in ca.items()} == {p: len(v) for p, v in cb.items()}
        witnesses = []
        for sig24, indexes in ca.items():
            source_indexes = cb[sig24]
            ac = Counter(a[i][V216] for i in indexes); bc = Counter(b[i][V216] for i in source_indexes)
            assert all(value in {0, 63} for value in (ac - bc).elements())
            assert all(value in {0, 63} for value in (bc - ac).elements())
            if len(indexes) == 1 and a[indexes[0]] == b[source_indexes[0]] and unique_counts[(key[0], a[indexes[0]])] == 1:
                witnesses.append(ps[indexes[0]]["linha"])
        if mode == "condicional":
            assert len(witnesses) >= 2
            assert set(witnesses) == set(conditional[target]["testemunhas_exatas_unicas127"])
            assert group_lines == {p["linha"] for p in conditional[target]["evidencias_literais"]["pessoas127"] if p["linha"] not in removed}
        links = []
        for decision in decisions:
            line = int(decision["linha"]); i = next(i for i, p in enumerate(ps) if p["linha"] == line)
            person = ps[i]
            assert (person["original"], person["corrigido"]) == (decision["texto_original"], decision["texto_corrigido"])
            assert (fs[0]["original"], fs[0]["corrigido"]) == (decision["texto_familia_original"], decision["texto_familia_corrigido"])
            assert int(decision["linha_familia_25"]) == f25[0]["linha"]
            candidates = cb[a[i][:V216] + a[i][V216 + 1:]] if mode == "condicional" else [j for j, sig in enumerate(b) if sig == a[i]]
            possible_lines = sorted(p25[j]["linha"] for j in candidates)
            assert possible_lines == sorted(int(x) for x in decision["linha_pessoa_25"].split(";"))
            differences = {n: [person["corrigido"][s:e], fs[0]["corrigido"][s:e]] for n, s, e in
                           (("UF", 0, 2), ("municipio", 2, 6), ("distrito", 6, 8), ("situacao", 17, 18))
                           if person["corrigido"][s:e] != fs[0]["corrigido"][s:e]}
            detail = {"linha127": line, "familia_antes": person["familia_antes"], "familia_depois": target,
                      "origens25_possiveis": possible_lines, "geografia_pessoal_divergente_preservada": differences,
                      "V216_preservado": a[i][V216]}
            links.append(detail)
            if differences:
                all_person_differences.append(detail)
            if len(possible_lines) != 1:
                unmatched_civil.append(detail)
        outcomes.append({"chave": key, "cartao127": target, "cartao25": f25[0]["linha"], "classe": mode,
            "pessoas127_e25": len(ps), "testemunhas_exatas_unicas_naUF127": witnesses,
            "outras_pessoas_ligadas_antes": sorted(outside_before), "outras_pessoas_ligadas_depois": sorted(outside_after),
            "pessoas_do_grupo_antes_ligadas_a_outro_cartao": attributed_other,
            "diferencas_domiciliares_preservadas": family_diffs, "vinculos": links})
    assert len(outcomes) == 82 and sum(len(g["vinculos"]) for g in outcomes) == 166
    assert len(unmatched_civil) == 1 and unmatched_civil[0]["linha127"] == 425558
    assert unmatched_civil[0]["origens25_possiveis"] == [898627, 898631]
    for name, digest in hashes.items():
        assert checksum(root / name) == digest, name
    result = {"vinculos_confirmados": 166, "grupos_confirmados": len(outcomes),
              "conflitos_geograficos_pessoais_preservados": len(all_person_differences),
              "origens_individuais_nao_unicas": unmatched_civil,
              "criterio_2_testemunhas_aplicado_a_condicionais": True,
              "grupos_estritos_com_menos_de_2_testemunhas_unicas": [g["cartao127"] for g in outcomes if g["classe"] == "estrito" and len(g["testemunhas_exatas_unicas_naUF127"]) < 2],
              "nenhuma_outra_pessoa_omitida": True, "nenhuma_resposta_alterada": True,
              "fontes_inalteradas": True, "grupos": outcomes, "fontes_sha256": hashes,
              "script_sha256": checksum(Path(__file__))}
    with (out / "revisao_independente166.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(json.dumps({k: v for k, v in result.items() if k not in {"grupos", "fontes_sha256"}}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    main(Path(__file__).resolve().parents[1], args.out)
