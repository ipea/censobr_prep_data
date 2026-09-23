"""Segunda leitura literal das novas evidencias, sem importar os novos auditores."""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
UF = {25: "al", 31: "ba", 14: "ce", 97: "df", 24: "fn", 94: "go", 40: "mg", 91: "mt",
      19: "pb", 21: "pe", 71: "pr", 52: "rj", 17: "rn", 81: "rs", 50: "sa", 30: "se", 60: "sp"}
PNAMES = "V202 V203 V204 AGE V205 V206 V207 V208 V209 V299 V210 V211 V212 V213 V214 V215 V216 V217 V218 V219 V220 V221 V223 V223B V224".split()


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def guide(sample, kind):
    return {r["variavel"]: (int(r["inicio"]) - 1, int(r["fim"]),
                            set(r["valores_validos"].split(";")) - {"", "NA"})
            for r in rows(ROOT / f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv")}


def profile(text, layout, names):
    result = []
    for name in names:
        start, end, valid = layout[name]
        value = text[start:end]
        if len(text) == 62 and start in {19, 20, 32, 35, 46} and value.startswith("-") and not text[start + 1:54].strip():
            value = ""
        if not value.strip():
            result.append(None)
        else:
            if not value.strip().isdigit() or (valid and value not in valid):
                raise ValueError((name, value, text))
            result.append(int(value))
    return tuple(result)


def projected(counter):
    result = Counter()
    for p, n in counter.items():
        result[p[:16] + p[17:]] += n
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--portable", type=Path)
    args = parser.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida deve ficar em tmp")
    out.mkdir(parents=True, exist_ok=False)
    evidence = ROOT / "references/investigacao_residual_1960_evidencias"
    dups = read_json(evidence / "duplicatas_fora_chave.json")
    links = read_json(evidence / "vinculos_casos.json")
    corrections = {int(r["linha"]): r for r in rows(ROOT / "read_guides/1960_amostra_127_correcoes.csv")}
    want127 = {}; want25 = defaultdict(dict); groups = []

    def add127(row):
        number = row["linha"]
        original = row.get("original", row.get("texto_original"))
        corrected = row.get("corrigido", row.get("texto_corrigido", original))
        if number in want127:
            assert want127[number][1] == corrected
            if original is not None and want127[number][0] is not None:
                assert want127[number][0] == original
            original = original or want127[number][0]
        want127[number] = (original, corrected)

    def add25(uf, row):
        number = row["linha"]
        if number in want25[uf]:
            assert want25[uf][number] == row["texto"]
        want25[uf][number] = row["texto"]

    for case in dups["casos"]:
        check = case["avaliacao"]
        uf = check["chave25"][0]
        for row in case["pessoas127"] + case["cartoes127"]:
            add127(row)
        for row in case["pessoas25"] + [case["cartao25"]]:
            add25(uf, row)
        groups.append({"classe": "repeticao", "chave25": check["chave25"],
                       "p127": case["pessoas127"], "p25": case["pessoas25"],
                       "f25": case["cartao25"], "forte_no_auditor": check["candidato_forte_nao_aplicado"],
                       "repetidos": check["grupos"]})
    for case in links["casos_escolhidos_para_revisao"]:
        for row in case["pessoas127"]:
            add127(row)
        for match in case["composicoes_localizadas25"]:
            uf = match["chave25"][0]
            for row in match["pessoas25"] + match["cartoes25"]:
                add25(uf, row)
            assert len(match["cartoes25"]) == 1
            groups.append({"classe": "vinculo", "chave25": match["chave25"],
                           "p127": case["pessoas127"], "p25": match["pessoas25"],
                           "f25": match["cartoes25"][0], "repetidos": []})

    for case in links["cartoes_especiais"].values():
        uf = case["cartao127"]["uf"]
        add127(case["cartao127"])
        for row in case["pessoas127"]:
            add127(row)
        for row in case["cartoes25"] + case["pessoas25"]:
            add25(uf, row)
    partial_cases = links["chaves_parcialmente_ilegiveis"]
    for case in partial_cases:
        person = case["pessoa127"]
        add127(person)
        assert len(case["candidatos"]) == 1
        candidate = case["candidatos"][0]
        card127 = candidate["cartao127"]
        add127(card127)
        for row in candidate["pessoas127_ja_ligadas"]:
            add127(row)
        uf = person["uf"]
        for row in candidate["cartoes25"] + candidate["pessoas25"]:
            add25(uf, row)
        card25 = candidate["cartoes25"][0]
        family_names = [f"V{n}" for n in range(101, 114)] + ["V116", "V118"]
        assert profile(card127["corrigido"], guide("127", "familias"), family_names) == profile(card25["texto"], guide("25", "familias"), family_names)
        assert card127["corrigido"][6:8] == card25["texto"][33:35]
        groups.append({"classe": "chave_ilegivel", "chave25": [uf, card127["pasta"], card127["boletim"]],
                       "p127": candidate["pessoas127_ja_ligadas"] + [person], "p25": candidate["pessoas25"],
                       "f25": card25, "repetidos": []})

    texts = read_json(ROOT / "references/investigacao_residual_texto_1960_evidencias.json")
    assert {r["linha"] for r in texts["inventario124"]} == set(corrections)
    for row in texts["inventario124"]:
        add127({"linha": row["linha"], "original": row["texto_original"], "corrigido": row["texto_atual"]})

    def walk_text(value, state=None):
        if isinstance(value, list):
            for item in value:
                walk_text(item, state)
        elif isinstance(value, dict):
            key = value.get("chave")
            if isinstance(key, list) and len(key) == 3:
                state = key[0]
            if value.get("uf") in UF:
                state = value["uf"]
            if "arquivo" in value and str(value["arquivo"]).endswith(".gz"):
                abbrev = value["arquivo"].split(".")[-2]
                state = next(k for k, v in UF.items() if v == abbrev)
            text = value.get("texto", value.get("corrigido"))
            if "linha" in value and isinstance(text, str):
                if len(text) == 62:
                    add127({"linha": value["linha"], "corrigido": text, "original": value.get("original")})
                elif len(text) == 54:
                    assert state in UF, value
                    add25(state, {"linha": value["linha"], "texto": text})
            for item in value.values():
                if isinstance(item, (list, dict)):
                    walk_text(item, state)

    for field in ["residuos14_com_literais", "grupos_dez_falsas_igualdades", "guanabara611254"]:
        walk_text(texts[field])

    raw = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    with raw.open("rb") as f:
        for number, (original, corrected) in want127.items():
            f.seek((number - 1) * 64)
            value = f.read(64).decode("latin1").rstrip("\r\n")
            if original is not None:
                assert original == value, ("raw127", number)
            correction = corrections.get(number, {})
            expected = correction.get("texto_corrigido") or value
            assert expected == corrected, ("corrected127", number)
    source_hashes = {}
    for uf, wanted in want25.items():
        path = ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz"
        source_hashes[str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
        remaining = set(wanted)
        with gzip.open(path, "rt", encoding="latin1", newline="") as f:
            for n, value in enumerate(f, 1):
                if n in remaining:
                    assert value.rstrip("\r\n") == wanted[n], ("raw25", uf, n)
                    remaining.remove(n)
                    if not remaining:
                        break
        assert not remaining
    g127 = guide("127", "pessoas"); g25 = guide("25", "pessoas")
    summaries = []
    for group in groups:
        a = Counter(profile(r["corrigido"], g127, PNAMES) for r in group["p127"])
        b = Counter(profile(r["texto"], g25, PNAMES) for r in group["p25"])
        x = projected(a); y = projected(b)
        assert set(x) == set(y), group["chave25"]
        assert all(y[p] <= x[p] for p in x), group["chave25"]
        if group["classe"] == "vinculo":
            assert x == y
        if group["classe"] == "chave_ilegivel":
            assert a == b
        card = group["f25"]
        assert int(card["texto"][11:13]) == len(group["p25"])
        assert sorted(int(r["texto"][8:10]) for r in group["p25"]) == list(range(1, len(group["p25"]) + 1))
        assert all(r["texto"][:8] == card["texto"][:8] for r in group["p25"])
        for repeat in group["repetidos"]:
            person = next(r for r in group["p127"] if r["linha"] == repeat["linhas127"][0])
            p = profile(person["corrigido"], g127, PNAMES)
            projected_p = p[:16] + p[17:]
            assert y[projected_p] == repeat["quantidade25"]
        summaries.append({"classe": group["classe"], "chave25": group["chave25"],
                          "linhas127": [r["linha"] for r in group["p127"]],
                          "composicao24_mesmas_quantidades": x == y,
                          "composicao25_mesmas_quantidades": a == b,
                          "n127": sum(a.values()), "n25": sum(b.values())})
    inventory = read_json(ROOT / "references/fechamento_registros_1960_evidencias/inventario_final.json")
    expected_people = {r["linha"] for r in inventory["vinculos_pendentes"] + inventory["conflitos_municipais"] + inventory["conflitos_situacao"]}
    covered = {r["linha"] for r in links["cobertura_cada_pessoa"]}
    corrupt = set(links["resumo"]["registros_corrompidos_fora_de_busca_por_igualdade"])
    assert covered.isdisjoint(corrupt)
    assert covered | corrupt == expected_people
    result = {"modo": "segunda leitura independente; nenhuma decisao aplicada",
              "literais127": len(want127), "literais25": sum(map(len, want25.values())),
              "cobertura_correcoes_texto": len(texts["inventario124"]),
              "grupos_conferidos": summaries, "cobertura_vinculos_inventario": len(covered | corrupt),
              "fontes25_sha256": source_hashes,
              "limite": "Confere literais, composicoes e cobertura. Nao transforma candidatos em identidade comprovada nem repete todas as buscas globais."}
    (out / "qc.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if args.portable:
        target = (ROOT / args.portable).resolve()
        if not target.is_relative_to(evidence) or target.exists():
            raise ValueError("Evidencia portatil deve ser nova, dentro do caderno")
        target.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in result.items() if k not in {"grupos_conferidos", "fontes25_sha256"}}, ensure_ascii=False))


if __name__ == "__main__":
    main()
