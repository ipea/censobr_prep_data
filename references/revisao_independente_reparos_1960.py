"""Releitura independente dos17reparos: literais, grupo inteiro e todas bijecoes."""
import argparse
from collections import defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path


NAMES = ["V202", "V203", "V204", "AGE", "V205", "V206", "V207", "V208", "V209", "V299",
         "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218", "V219",
         "V220", "V221", "V223", "V223B", "V224"]
FNAMES = [f"V{n}" for n in range(101, 114)] + ["V116", "V118"]


def csvrows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def checksum(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def parse(text, guide, names):
    values = {}; invalid = set()
    for name in names:
        row = guide[name]; start = int(row["inicio"]) - 1; end = int(row["fim"])
        literal = text[start:end]; valid = set(row["valores_validos"].split(";")) - {"", "NA"}
        skip = len(text) == 62 and start in (19, 20, 32, 35, 46) and literal.startswith("-") and not text[start + 1:54].strip()
        if not literal.strip() or skip:
            value = None
        elif literal in valid or (not valid and literal.isdigit()):
            value = int(literal)
        else:
            value = None; invalid.add(name)
        values[name] = value
    return values, invalid


def enumerate_matchings(edges):
    order = sorted(range(len(edges)), key=lambda i: len(edges[i]))
    results = []; assigned = [-1] * len(edges)

    def visit(position, used):
        if position == len(order):
            results.append(tuple(assigned))
            return
        left = order[position]
        for right in sorted(edges[left] - used):
            assigned[left] = right
            visit(position + 1, used | {right})
        assigned[left] = -1

    visit(0, set())
    return results


def main(root, out, additional=False):
    root = root.resolve(); out = out.resolve()
    assert out.is_relative_to(root / "tmp")
    out.mkdir(parents=True, exist_ok=False)
    if additional:
        paths = [root / "tmp/fechamento_registros_1960_20260922/texto/inferencias03/candidatos_nacionalidade_adicionais.json",
                 root / "tmp/fechamento_registros_1960_20260922/texto/provas_contexto01/provas_reparo.json"]
        a, b = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
        extra = a["reparos"] + [r for r in b["casos"] if r["linha127"] in (675159, 706676, 760804)]
        digests = {name.replace("\\", "/"): digest for data in (a, b) for name, digest in data["fontes_sha256"].items()
                   if name.replace("\\", "/").startswith(("data/", "data_raw/"))}
        manifest = {"reparos": extra, "fontes": [{"arquivo": n, "sha256": h} for n, h in digests.items()]}
        for path in paths:
            digests[str(path.relative_to(root)).replace("\\", "/")] = checksum(path)
    else:
        manifest_path = root / "read_guides/1960_amostra_127_reparos_fonte25.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        digests = {r["arquivo"].replace("\\", "/"): r["sha256"] for r in manifest["fontes"]}
        digests[str(manifest_path.relative_to(root)).replace("\\", "/")] = checksum(manifest_path)
    guides = {}
    for sample in ("127", "25"):
        for kind in ("pessoas", "familias"):
            path = root / f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv"
            guides[sample, kind] = {r["variavel"]: r for r in csvrows(path)}
            digests[str(path.relative_to(root)).replace("\\", "/")] = checksum(path)
    for path, digest in digests.items():
        assert checksum(root / path) == digest, path
    fixes = {r["linha127"]: r for r in manifest["reparos"]}
    assert len(fixes) == (7 if additional else 17)
    grouped = defaultdict(list)
    for fix in fixes.values():
        grouped[tuple(fix["chave"])].append(fix)
        before = fix["texto_antes"]; after = fix["texto_corrigido_proposto"]
        assert len(before) == len(after) == 62
        composed = before
        values, invalid = parse(before, guides["127", "pessoas"], NAMES)
        for proposal in fix["propostas"]:
            name = proposal["campo"]; descriptor = guides["127", "pessoas"][name]
            start = int(descriptor["inicio"]) - 1; end = int(descriptor["fim"])
            assert (proposal["inicio"], proposal["fim"]) == (start + 1, end)
            assert before[start:end] == proposal["antes"]
            assert values[name] is None, (fix["linha127"], "campo legivel alterado", name)
            assert proposal["depois"] in descriptor["valores_validos"].split(";")
            composed = composed[:start] + proposal["depois"] + composed[end:]
        assert composed == after
        final, bad = parse(after, guides["127", "pessoas"], NAMES)
        assert not bad
        assert all(final[n] == v for n, v in values.items() if n not in {p["campo"] for p in fix["propostas"]})
    corrections_path = root / "read_guides/1960_amostra_127_correcoes.csv"
    dup_path = root / "read_guides/1960_amostra_127_duplicatas.csv"
    corrections = {int(r["linha"]): r for r in csvrows(corrections_path)}
    removed = {int(r["linha"]) for r in csvrows(dup_path) if r["acao"] == "remover"}
    for path in (corrections_path, dup_path):
        digests[str(path.relative_to(root)).replace("\\", "/")] = checksum(path)
    raw_groups = defaultdict(list)
    raw = root / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    found = set()
    with raw.open(encoding="latin1") as f:
        for line, original in enumerate(f, 1):
            original = original.rstrip("\r\n")
            if line in removed:
                continue
            decision = corrections.get(line, {})
            text = decision.get("texto_corrigido") or original
            if line in fixes:
                fix = fixes[line]
                assert original == fix["texto_original"]
                assert text in {fix["texto_antes"], fix["texto_corrigido_proposto"]}
                text = fix["texto_antes"]; found.add(line)
            try:
                key = (int(text[:2]), int(text[8:13]), int(text[13:16]))
            except ValueError:
                continue
            if key in grouped:
                raw_groups[key].append({"linha": line, "texto": text})
    assert found == set(fixes)
    source_groups = defaultdict(list)
    for source in manifest["fontes"]:
        if not source["arquivo"].endswith(".gz"):
            continue
        relevant = {tuple(fix["chave"]): fix for fix in fixes.values()
                    if any(r["arquivo"].replace("\\", "/") == source["arquivo"] for r in fix["grupo25"])}
        if not relevant:
            continue
        uf = next(iter(relevant))[0]
        with gzip.open(root / source["arquivo"], "rt", encoding="latin1") as f:
            for line, text in enumerate(f, 1):
                text = text.rstrip("\r\n")
                key = (uf, int(text[:5]), int(text[5:8]))
                if key in relevant:
                    source_groups[key].append({"linha": line, "texto": text})
    outcomes = []; rejected = []
    for key, group_fixes in grouped.items():
        rg = raw_groups[key]; sg = source_groups[key]
        expected127 = {(r["linha"], r["texto"]) for r in group_fixes[0]["grupo127"]}
        expected25 = {(r["linha"], r["texto"]) for r in group_fixes[0]["grupo25"]}
        assert {(r["linha"], r["texto"]) for r in rg} == expected127
        assert {(r["linha"], r["texto"]) for r in sg} == expected25
        f127 = [r for r in rg if r["texto"][16] == "1"]
        p127 = [r for r in rg if r["texto"][16] in "23"]
        f25 = [r for r in sg if r["texto"][8:10] == "00"]
        p25 = [r for r in sg if r["texto"][8:10] != "00"]
        assert len(f127) == len(f25) == 1
        assert len(p127) == len(p25) == int(f25[0]["texto"][11:13])
        assert [r["linha"] for r in p25] == list(range(f25[0]["linha"] + 1, f25[0]["linha"] + len(p25) + 1))
        assert sorted(int(r["texto"][8:10]) for r in p25) == list(range(1, len(p25) + 1))
        assert f25[0]["texto"][36:] == "0" * 18
        for row in sg:
            assert len(row["texto"]) == 54
        for row in p25:
            text = row["texto"]
            assert text[8:11] == text[11:14] and text[23] == text[24] and text[51:] == "000"
        a, bad = parse(f127[0]["texto"], guides["127", "familias"], FNAMES)
        b, bad25 = parse(f25[0]["texto"], guides["25", "familias"], FNAMES)
        family_differences = {n: [a[n], b[n]] for n in FNAMES if a[n] != b[n]}
        if additional and any(r["linha127"] == 541238 for r in group_fixes):
            assert family_differences == {"V102": [5, 4]}
        else:
            assert not family_differences
        assert not bad and not bad25
        for row in rg:
            text = row["texto"]; family = f25[0]["texto"]
            assert (text[2:6], text[6:8], text[17]) == (family[29:33], family[33:35], family[35])
        values25 = [parse(row["texto"], guides["25", "pessoas"], NAMES) for row in p25]
        assert not any(bad for _, bad in values25)
        edges = []
        bad_context = []
        for row in p127:
            values, bad = parse(row["texto"], guides["127", "pessoas"], NAMES)
            changed = {p["campo"] for p in fixes.get(row["linha"], {}).get("propostas", [])}
            if not bad <= changed:
                bad_context.append({"linha127": row["linha"], "campos_invalidos_nao_autorizados": sorted(bad - changed),
                                    "texto127": row["texto"]})
                edges.append(set())
                continue
            edges.append({i for i, (other, _) in enumerate(values25)
                          if all(values[n] == other[n] or
                              (additional and row["linha"] not in fixes and n == "V216" and {values[n], other[n]} == {0, 63})
                              for n in NAMES if n not in changed)})
        if additional and any(fix["linha127"] == 760804 for fix in group_fixes):
            assert len(bad_context) == 1 and bad_context[0]["linha127"] == 760807
            assert not enumerate_matchings(edges)
            rejected.append({"linha127": 760804, "motivo": "contexto_invalido_nao_pode_virar_NA_para_forcar_igualdade",
                             "evidencia": bad_context})
            continue
        assert not bad_context, bad_context
        matches = enumerate_matchings(edges)
        assert matches, key
        decisions = []
        for fix in group_fixes:
            pos = next(i for i, row in enumerate(p127) if row["linha"] == fix["linha127"])
            possible = {permutation[pos] for permutation in matches}
            possible_lines = {p25[index]["linha"] for index in possible}
            assert possible_lines == {r["linha"] for r in fix["fontes25_possiveis"]}
            for proposal in fix["propostas"]:
                vals = {values25[i][0][proposal["campo"]] for i in possible}
                assert vals == {int(proposal["depois"])}
                assert possible_lines == set(proposal["linhas25"])
            decisions.append({"linha127": fix["linha127"], "linhas25_possiveis": sorted(possible_lines),
                              "campos": [p["campo"] for p in fix["propostas"]]})
        outcomes.append({"chave": key, "pessoas": len(p25), "bijecoes_possiveis": len(matches),
                         "todos_valores_invariantes": True, "reparos": decisions,
                         "divergencias_cartao_preservadas": family_differences})
    for path, digest in digests.items():
        assert checksum(root / path) == digest, "Fonte alterada: " + path
    result = {"reparos_confirmados": sum(len(g["reparos"]) for g in outcomes), "grupos_confirmados": len(outcomes),
              "campos_legiveis_preservados": True, "nenhuma_fonte_alterada": True,
              "metodo": "Todos pareamentos bijetivos; campos legiveis do alvo integralmente iguais; contexto permite somente diferencaV21600/63 quando modo adicional, preservada.",
              "grupos": outcomes, "rejeitados": rejected, "fontes_sha256": digests, "script_sha256": checksum(Path(__file__))}
    with (out / "revisao_independente.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--additional", action="store_true")
    args = parser.parse_args()
    main(Path(__file__).resolve().parents[1], args.out, args.additional)
