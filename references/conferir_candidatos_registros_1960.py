"""Segunda leitura dos candidatos: contagens completas e literais nas fontes.

Nao aplica decisoes. Os caminhos de auditoria sao argumentos, nao fontes de producao.
"""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path


def csv_records(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--duplicatas", required=True, type=Path)
    parser.add_argument("--vinculos", required=True, type=Path)
    parser.add_argument("--projecao", type=Path)
    parser.add_argument("--atributos", type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    guides = {(sample, kind): {r["variavel"]: r for r in csv_records(root / f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv")}
              for sample in ("127", "25") for kind in ("familias", "pessoas")}
    names = {kind: [name for name in guides[("127", kind)]
                   if name in guides[("25", kind)] and name not in {"UF", "BARRA", "ID", "REC_TYPE", "V100"}]
             for kind in ("familias", "pessoas")}
    assert len(names["pessoas"]) == 25 and len(names["familias"]) == 15

    def values(text, sample, kind):
        output = []
        for name in names[kind]:
            field = guides[(sample, kind)][name]
            raw = text[int(field["inicio"])-1:int(field["fim"])]
            if not raw.strip() or raw.strip() == "-":
                output.append(None)
            else:
                assert raw.isdigit(), (name, raw)
                allowed = set(field["valores_validos"].split(";")) - {"", "NA"}
                assert not allowed or raw in allowed, (name, raw)
                output.append(int(raw))
        return tuple(output)

    literals = defaultdict(dict)
    raw_path = "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    corrections = {int(r["linha"]): r for r in csv_records(root / "read_guides/1960_amostra_127_correcoes.csv")}

    def remember(path, line, text):
        path = path.replace("\\", "/")
        if line in literals[path]:
            assert literals[path][line] == text
        literals[path][line] = text

    def household(f127, p127, f25, p25, source, removed=(), projection=False, attributes=False):
        assert len(f127) == len(f25) == 1
        family_a = values(f127[0]["corrigido"], "127", "familias")
        family_b = values(f25[0]["texto"], "25", "familias")
        assert all(a == b for name, a, b in zip(names["familias"], family_a, family_b)
                   if not attributes or name in {"V101", "V116", "V118"})
        assert f127[0]["corrigido"][6:8] == f25[0]["texto"][33:35]
        after = [r for r in p127 if r["linha"] not in removed]
        a = [values(r["corrigido"], "127", "pessoas") for r in after]
        b = [values(r["texto"], "25", "pessoas") for r in p25]
        if projection:
            position = names["pessoas"].index("V216")
            maps = [defaultdict(set), defaultdict(set)]
            projected = [[], []]
            for j, profiles in enumerate((a, b)):
                for v in profiles:
                    key = v[:position] + v[position+1:]
                    maps[j][key].add(v[position]); projected[j].append(key)
            assert all(len(v) == 1 for m in maps for v in m.values())
            assert maps[0].keys() == maps[1].keys()
            assert all(maps[0][key] == maps[1][key] or maps[0][key] | maps[1][key] == {0, 63} for key in maps[0])
            a, b = projected
        assert Counter(a) == Counter(b)
        assert len(after) == len(p25) == int(f25[0]["texto"][11:13])
        assert [r["linha"] for r in p25] == list(range(f25[0]["linha"]+1, f25[0]["linha"]+len(p25)+1))
        assert sorted(int(r["texto"][8:10]) for r in p25) == list(range(1, len(p25)+1))
        for row in p25:
            text = row["texto"]
            assert text[8:11] == text[11:14] and text[23] == text[24] and text[51:] == "000"
        for row in f127 + p127:
            correction = corrections.get(row["linha"], {})
            assert row["corrigido"] == (correction.get("texto_corrigido") or row["original"])
            remember(raw_path, row["linha"], row["original"])
        for row in f25 + p25:
            remember(source, row["linha"], row["texto"])

    dup = json.loads((args.duplicatas / "resultado.json").read_text(encoding="utf-8"))
    decisions = csv_records(args.duplicatas / "decisoes_candidatas.csv")
    projected_groups = []
    rules = {}
    for folder, attributes in ((args.projecao, False), (args.atributos, True)):
        if folder:
            data = json.loads((folder / "projecao24.json").read_text(encoding="utf-8"))
            decisions += csv_records(folder / "propostas_condicionais.csv")
            for group in data["grupos"]:
                if group["proposta_condicional"]:
                    projected_groups.append(group)
                    rules[group["id"].rsplit("-linha", 1)[0]] = attributes
    assert len({int(r["linha"]) for r in decisions}) == len(decisions)
    contexts = {r["id"]: r for r in dup["contextos"]}
    selected = {r["contexto"] for r in dup["grupos"] if r["aprovavel"]}
    removed = {int(r["linha"]) for r in decisions if r["acao"] == "remover"}
    for key in selected:
        context = contexts[key]
        assert not context["motivos"]
        household(context["familias127"], context["pessoas127_apos_decisoes_anteriores"],
                  context["familias25"], context["pessoas25"], context["fonte25"], removed)
    for key, attributes in rules.items():
        context = contexts[key]
        household(context["familias127"], context["pessoas127_apos_decisoes_anteriores"],
                  context["familias25"], context["pessoas25"], context["fonte25"], removed, True, attributes)
    for group in projected_groups:
        chosen = [r for r in decisions if int(r["linha"]) in group["linhas127"]]
        assert len(chosen) == group["n127"]
        assert sum(r["acao"] == "manter" for r in chosen) == group["n25_por_24_campos"]
    for group in (r for r in dup["grupos"] if r["aprovavel"]):
        chosen = [r for r in decisions if int(r["linha"]) in group["linhas127"]]
        assert len(chosen) == group["n127"]
        assert sum(r["acao"] == "manter" for r in chosen) == group["n25"]
        assert all(int(r["n_antes"]) == group["n127"] and int(r["n_manter"]) == group["n25"] for r in chosen)

    links = json.loads((args.vinculos / "candidatos_vinculos.json").read_text(encoding="utf-8"))["candidatos"]
    targets = {r["linha_familia"] for r in links}
    seen_targets = set()
    with (args.vinculos / "evidencias_literais.jsonl").open(encoding="utf-8") as stream:
        for line in stream:
            context = json.loads(line)
            if not targets.intersection(r["linha"] for r in context["cartoes127"]):
                continue
            household(context["cartoes127"], context["pessoas127"], context["cartoes25"], context["pessoas25"], context["fonte25"])
            seen_targets.update(r["linha"] for r in context["cartoes127"])
    assert seen_targets == targets

    hashes = []
    for relative, expected in sorted(literals.items()):
        path = root / relative
        with path.open("rb") as stream:
            before = hashlib.file_digest(stream, "sha256").hexdigest()
        found = set()
        opener = gzip.open if path.suffix == ".gz" else open
        with opener(path, "rt", encoding="latin1") as stream:
            for number, text in enumerate(stream, 1):
                if number in expected:
                    assert text.rstrip("\r\n") == expected[number], (relative, number)
                    found.add(number)
        assert found == set(expected)
        with path.open("rb") as stream:
            assert hashlib.file_digest(stream, "sha256").hexdigest() == before
        hashes.append({"arquivo": relative, "sha256": before, "linhas_conferidas": len(found)})
    result = {"duplicatas_grupos": sum(r["aprovavel"] for r in dup["grupos"]) + len(projected_groups), "duplicatas_linhas": len(decisions),
              "remocoes": len(removed), "vinculos": len(links), "cartoes_vinculos": len(targets),
              "literais_conferidos": sum(len(x) for x in literals.values()), "fontes": hashes,
              "limite": "Conferencia dos candidatos estritos; nao aplica decisoes nem resolve os casos nao aprovados."}
    destination = args.out.resolve()
    assert destination.is_relative_to(root / "tmp")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("x", encoding="utf-8") as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
