"""QC independente: dez reparos adicionais e geografia derivada de duas linhas.

Nao aplica decisoes. Rele fontes integrais, com decisoes anteriores congeladas,
e enumera todas as bijecoes do grupo. Nao aceita dano convertido em ausente;
nao altera digitos legiveis nem equipara os valores substantivos V216=00 e 63.
O contexto pode divergir somente nesse campo; o alvo pessoal nao pode.
"""
import argparse
from collections import defaultdict
import gzip
import json
from pathlib import Path

from revisao_independente_reparos_1960 import (
    FNAMES, NAMES, checksum, csvrows, enumerate_matchings, parse,
)


NEW = {607903, 607904, 803760, 994324, 1002257, 1002771,
       1005344, 1005687, 1005952, 1026174}
BASE = Path("tmp/fechamento_registros_1960_20260922")


def check_fix(fix, guides):
    kind = fix["tipo"]
    names = NAMES if kind == "pessoas" else FNAMES
    guide = guides["127", kind]
    before, after = fix["texto_antes"], fix["texto_corrigido_proposto"]
    assert len(before) == len(after) == 62
    assert (before[16] in "23") == (kind == "pessoas")
    values, invalid = parse(before, guide, names)
    changed = {p["campo"] for p in fix["propostas"]}
    assert len(changed) == len(fix["propostas"]) > 0
    composed = before
    for proposal in fix["propostas"]:
        field = proposal["campo"]
        descriptor = guide[field]
        start, end = int(descriptor["inicio"]) - 1, int(descriptor["fim"])
        assert (proposal["inicio"], proposal["fim"]) == (start + 1, end)
        old, new = proposal["antes"], proposal["depois"]
        assert old == before[start:end] and len(old) == len(new) == end - start
        assert values[field] is None, (fix["linha127"], "valor valido seria alterado", field)
        assert new in descriptor["valores_validos"].split(";")
        assert all(not char.isdigit() or char == new[i] for i, char in enumerate(old)), (
            fix["linha127"], "digito parcial legivel seria alterado", field)
        composed = composed[:start] + new + composed[end:]
    assert composed == after, "Mudanca fora dos campos autorizados"
    final, bad = parse(after, guide, names)
    assert not bad and invalid <= changed
    assert all(final[n] == values[n] for n in names if n not in changed)
    return changed


def check_group(rg, sg, fixes, guides, geo=False):
    assert len({r["linha"] for r in rg}) == len(rg)
    assert len({r["linha"] for r in sg}) == len(sg)
    f127 = [r for r in rg if r["texto"][16] == "1"]
    p127 = [r for r in rg if r["texto"][16] in "23"]
    f25 = [r for r in sg if r["texto"][8:10] == "00"]
    p25 = [r for r in sg if r["texto"][8:10] != "00"]
    assert len(f127) == len(f25) == 1, "Cartao nao unico"
    assert len(rg) == len(p127) + 1 and len(sg) == len(p25) + 1
    assert len(p127) == len(p25) == int(f25[0]["texto"][11:13]), "Composicao incompleta"
    assert [r["linha"] for r in p25] == list(range(f25[0]["linha"] + 1, f25[0]["linha"] + len(p25) + 1))
    assert [int(r["texto"][8:10]) for r in p25] == list(range(1, len(p25) + 1))
    assert all(len(r["texto"]) == 62 for r in rg)
    assert all(len(r["texto"]) == 54 for r in sg)
    assert f25[0]["texto"][36:] == "0" * 18
    for row in p25:
        text = row["texto"]
        assert text[8:11] == text[11:14] and text[23] == text[24] and text[51:] == "000"
    card = f127[0]; other_card = f25[0]
    key = (int(card["texto"][:2]), int(card["texto"][8:13]), int(card["texto"][13:16]))
    for row in rg:
        assert (int(row["texto"][:2]), int(row["texto"][8:13]), int(row["texto"][13:16])) == key
    for row in sg:
        assert (int(row["texto"][:5]), int(row["texto"][5:8])) == key[1:]
    masks = {line: check_fix(fix, guides) for line, fix in fixes.items()}
    assert set(fixes) <= {r["linha"] for r in rg}
    a, bad = parse(card["texto"], guides["127", "familias"], FNAMES)
    b, bad25 = parse(other_card["texto"], guides["25", "familias"], FNAMES)
    assert not bad25
    allowed = masks.get(card["linha"], set()) | ({"V116"} if geo else set())
    assert bad <= allowed, (card["linha"], bad)
    differences = {n: [a[n], b[n]] for n in FNAMES if a[n] != b[n]}
    context_family = {n: v for n, v in differences.items() if n not in allowed}
    # This sole pre-existing difference was independently checked in QC6.
    assert not context_family or (541238 in fixes and context_family == {"V102": [5, 4]})
    for row in rg:
        text = row["texto"]; source = other_card["texto"]
        assert (text[6:8], text[17]) == (source[33:35], source[35]), "Distrito/situacao divergem"
        if geo and row["linha"] in (887255, 887256):
            assert text[2:6] == "724Z" and source[29:33] == "7240"
            assert all(not char.isdigit() or char == source[29 + i]
                       for i, char in enumerate(text[2:6]))
        else:
            assert text[2:6] == source[29:33], "Municipio diverge"
    if geo:
        assert {r["linha"] for r in rg} == {887255, 887256, 888718, 888719}
        assert card["linha"] == 887255 and not fixes
        assert differences == {"V116": [None, 7240]}
    values25 = [parse(r["texto"], guides["25", "pessoas"], NAMES) for r in p25]
    assert not any(bad for _, bad in values25)
    values127 = []; edges = []
    for row in p127:
        values, bad = parse(row["texto"], guides["127", "pessoas"], NAMES)
        values127.append(values)
        changed = masks.get(row["linha"], set())
        assert bad <= changed, (row["linha"], "contexto invalido", sorted(bad - changed))
        target = row["linha"] in fixes or (geo and row["linha"] == 887256)
        edges.append({i for i, (other, _) in enumerate(values25)
                      if all(values[n] == other[n] or
                             (not target and n == "V216" and {values[n], other[n]} == {0, 63})
                             for n in NAMES if n not in changed)})
    matches = enumerate_matchings(edges)
    assert matches, "Sem bijecao da composicao completa"
    decisions = []
    for line, fix in sorted(fixes.items()):
        if fix["tipo"] == "familias":
            possible_lines = {other_card["linha"]}
            alternatives = [b]
        else:
            pos = next(i for i, r in enumerate(p127) if r["linha"] == line)
            possible = {match[pos] for match in matches}
            possible_lines = {p25[i]["linha"] for i in possible}
            alternatives = [values25[i][0] for i in possible]
        assert possible_lines == {r["linha"] for r in fix["fontes25_possiveis"]}
        for proposal in fix["propostas"]:
            assert possible_lines == set(proposal["linhas25"])
            assert {v[proposal["campo"]] for v in alternatives} == {int(proposal["depois"])}
        decisions.append({"linha127": line, "tipo": fix["tipo"],
                          "linhas25_possiveis": sorted(possible_lines),
                          "propostas": fix["propostas"], "texto_antes": fix["texto_antes"],
                          "texto_depois": fix["texto_corrigido_proposto"]})
    context = []
    for i, row in enumerate(p127):
        alternatives = {m[i] for m in matches}
        context.append({"linha127": row["linha"], "linhas25_possiveis": sorted(p25[j]["linha"] for j in alternatives),
                        "diferencas": [{n: [values127[i][n], values25[j][0][n]]
                                        for n in NAMES if values127[i][n] != values25[j][0][n]}
                                       for j in sorted(alternatives)]})
    return {"chave": key, "pessoas": len(p127), "bijecoes_possiveis": len(matches),
            "reparos": decisions, "diferencas_cartao_antes": differences,
            "diferencas_cartao_nao_alteradas": context_family,
            "correspondencias_contexto": context,
            "pessoas_com_perfil_25_exato": sum(any(values127[i] == values25[j][0] for j in edges[i])
                                              for i in range(len(p127)))}


def check_geo_delivery(manifest, links, rg, sg, result):
    assert manifest["code_muni_1960"] == 7240
    assert manifest["local"] == {"UF": "71", "distrito": "07", "pasta": "71038",
                                  "boletim": "216", "chave": "0771038216", "V118": "5"}
    assert {(r["linha"], r["texto"]) for r in manifest["registros127"]} == {(r["linha"], r["texto"]) for r in rg}
    assert {(r["linha"], r["texto"]) for r in manifest["registros25"]} == {(r["linha"], r["texto"]) for r in sg}
    assert {r["linha"] for r in manifest["registros127"] if r["derivar_municipio"]} == {887255, 887256}
    expected = {r["linha127"]: r["linhas25_possiveis"][0] for r in result["correspondencias_contexto"]}
    assert expected == {887256: 708707, 888718: 708709, 888719: 708708}
    assert {r["linha127"]: r["linha25"] for r in manifest["correspondencias"]} == expected
    for correspondence in manifest["correspondencias"]:
        actual = next(r for r in result["correspondencias_contexto"] if r["linha127"] == correspondence["linha127"])
        assert actual["diferencas"] == [correspondence["diferencas_preservadas"]]
    assert len(links) == 3 and {int(r["linha"]) for r in links} == set(expected)
    texts = {r["linha"]: r["texto"] for r in rg}
    for link in links:
        line = int(link["linha"])
        assert int(link["linha_familia"]) == 887255
        assert int(link["linha_pessoa_25"]) == expected[line] and int(link["linha_familia_25"]) == 708706
        assert link["fonte_25"] == "data/release_legacy/Censo.1960.amostra.25porcento.pr.gz"
        assert link["texto_original"] == link["texto_corrigido"] == texts[line]
        assert link["texto_familia_original"] == link["texto_familia_corrigido"] == texts[887255]
    return {"vinculos_confirmados": 3, "destino": 887255, "pessoas_e_fontes": expected,
            "campos_originais_preservados": True}


def main(root, out, all_repairs=False):
    root = root.resolve(); out = out.resolve()
    assert out.is_relative_to(root / "tmp")
    out.mkdir(parents=True, exist_ok=False)
    manifest_path = root / BASE / "texto/selecao_final02/selecao_final_reparos.json"
    geo_path = root / BASE / "texto/inferencias04/candidatos_geografia_pr.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    geography = json.loads(geo_path.read_text(encoding="utf-8"))
    selected = [r for r in manifest["reparos"] if all_repairs or r["linha127"] in NEW]
    assert len(selected) == (33 if all_repairs else 10)
    fixes = {r["linha127"]: r for r in selected}
    grouped = defaultdict(list)
    for fix in selected:
        grouped[tuple(fix["chave"])].append(fix)
    geo_key = (71, 71038, 216)
    keys = set(grouped) | {geo_key}
    digests = {}

    def record(path, expected=None):
        digest = checksum(path)
        assert expected is None or digest == expected, path
        digests[str(path.relative_to(root)).replace("\\", "/")] = digest

    record(manifest_path); record(geo_path)
    delivery = root / BASE / "vinculos/entrega_02"
    inventory_path = delivery / "indice.json"
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    record(inventory_path)
    snapshots = {}
    for entry in inventory["fontes_preservadas_antes_de_novas_decisoes"]:
        path = delivery / "fontes_decisoes_antes" / entry["snapshot"]
        record(path, entry["sha256"])
        snapshots[entry["arquivo"]] = path
    corrections = {int(r["linha"]): r for r in csvrows(snapshots["read_guides/1960_amostra_127_correcoes.csv"])}
    duplicate_rows = [r for name, path in snapshots.items() if name.endswith(".csv") and "duplicatas" in name
                      for r in csvrows(path)]
    assert len(duplicate_rows) == len({r["linha"] for r in duplicate_rows}) == 6451
    removed = {int(r["linha"]) for r in duplicate_rows if r["acao"] == "remover"}
    assert len(removed) == 2736
    guides = {}
    for sample in ("127", "25"):
        for kind in ("pessoas", "familias"):
            path = snapshots[f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv"]
            guides[sample, kind] = {r["variavel"]: r for r in csvrows(path)}
    expected_sources = {name.replace("\\", "/"): digest for m in (manifest, geography)
                        for name, digest in m["fontes_sha256"].items()
                        if name.replace("\\", "/").startswith(("data/", "data_raw/"))}
    raw = root / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    record(raw, expected_sources[str(raw.relative_to(root)).replace("\\", "/")])
    raw_groups = defaultdict(list); found = set()
    with raw.open(encoding="latin1") as f:
        for line, original in enumerate(f, 1):
            original = original.rstrip("\r\n")
            if line in removed:
                continue
            correction = corrections.get(line, {})
            if correction:
                assert correction["texto_original"] == original
            if correction.get("decisao") in {"corrompida", "cartao_uf"}:
                continue
            text = correction.get("texto_corrigido") or original
            if line in fixes:
                fix = fixes[line]
                assert original == fix["texto_original"] and text == fix["texto_antes"]
                found.add(line)
            try:
                key = (int(text[:2]), int(text[8:13]), int(text[13:16]))
            except ValueError:
                continue
            if key in keys:
                raw_groups[key].append({"linha": line, "texto": text})
    assert found == set(fixes)
    file_keys = defaultdict(set)
    for fix in selected:
        for row in fix["grupo25"]:
            file_keys[row["arquivo"].replace("\\", "/")].add(tuple(fix["chave"]))
    for row in geography["candidatos"][0]["grupo25"]:
        file_keys[row["arquivo"].replace("\\", "/")].add(geo_key)
    source_groups = defaultdict(list)
    for filename, source_keys in file_keys.items():
        path = root / filename; record(path, expected_sources[filename])
        ufs = {key[0] for key in source_keys}; assert len(ufs) == 1
        uf = next(iter(ufs))
        with gzip.open(path, "rt", encoding="latin1") as f:
            for line, text in enumerate(f, 1):
                text = text.rstrip("\r\n")
                key = (uf, int(text[:5]), int(text[5:8]))
                if key in source_keys:
                    source_groups[key].append({"linha": line, "texto": text})
        print("Fonte relida:", filename, flush=True)
    outcomes = []
    for key, group_fixes in grouped.items():
        rg = raw_groups[key]; sg = source_groups[key]
        for fix in group_fixes:
            assert {(r["linha"], r["texto"]) for r in rg} == {(r["linha"], r["texto"]) for r in fix["grupo127"]}
            assert {(r["linha"], r["texto"]) for r in sg} == {(r["linha"], r["texto"]) for r in fix["grupo25"]}
        outcomes.append(check_group(rg, sg, {r["linha127"]: r for r in group_fixes}, guides))
    assert {c["linha127"] for c in geography["candidatos"]} == {887255, 887256}
    for candidate in geography["candidatos"]:
        assert candidate["campo_literal_danificado"] == {"V116": "724Z"}
        assert candidate["valor_geografico_proposto"] == {"code_muni_1960": 7240}
        assert {(r["linha"], r["texto"]) for r in raw_groups[geo_key]} == {(r["linha"], r["texto"]) for r in candidate["grupo127"]}
        assert {(r["linha"], r["texto"]) for r in source_groups[geo_key]} == {(r["linha"], r["texto"]) for r in candidate["grupo25"]}
        assert candidate["texto_original"] == next(r["texto"] for r in raw_groups[geo_key] if r["linha"] == candidate["linha127"])
    geo_result = check_group(raw_groups[geo_key], source_groups[geo_key], {}, guides, geo=True)
    geo_result["campos_derivados_confirmados"] = [{"linha127": line, "V116_literal_preservado": "724Z",
                                                   "code_muni_1960_derivado": 7240} for line in (887255, 887256)]
    stable_geo_path = root / "read_guides/1960_amostra_127_geografia_fonte25.json"
    geo_links_path = root / BASE / "texto/inferencias04/vinculos_geografia_pr.csv"
    record(stable_geo_path); record(geo_links_path)
    stable_geo = json.loads(stable_geo_path.read_text(encoding="utf-8"))
    for source in stable_geo["fontes"]:
        assert expected_sources[source["arquivo"]] == source["sha256"]
    geo_result["entrega_conferida"] = check_geo_delivery(stable_geo, csvrows(geo_links_path),
                                                         raw_groups[geo_key], source_groups[geo_key], geo_result)
    current_links_path = root / "read_guides/1960_amostra_127_vinculos.csv"
    record(current_links_path)
    existing = csvrows(current_links_path)
    for row in existing:
        if int(row["linha"]) in (887256, 888718, 888719):
            assert int(row["linha_familia"]) == 887255, "Vinculo previo para outro cartao"
        if int(row["linha_familia"]) == 887255:
            assert int(row["linha"]) in (887256, 888718, 888719), "Pessoa externa ja ligada ao cartao"
    geo_result["sem_vinculos_explicitos_conflitantes"] = True
    for name, digest in digests.items():
        assert checksum(root / name) == digest, "Fonte alterada: " + name
    result = {"reparos_confirmados": len(selected), "grupos_confirmados": len(outcomes),
              "municipios_derivados_confirmados": 2, "nenhuma_fonte_alterada": True,
              "decisoes_de_duplicatas_consideradas": len(duplicate_rows), "linhas_removidas_consideradas": len(removed),
              "grupos": outcomes, "geografia": geo_result, "fontes_sha256": digests,
              "script_sha256": checksum(Path(__file__))}
    with (out / "revisao_independente.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(json.dumps({k: v for k, v in result.items() if k not in {"grupos", "geografia", "fontes_sha256"}}, ensure_ascii=False))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--all33", action="store_true")
    args = parser.parse_args()
    main(Path(__file__).resolve().parents[1], args.out, args.all33)
