"""Segunda leitura dos concorrentes e das chaves partidas; indice127 independente."""
from collections import Counter, defaultdict
import gzip
import itertools
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as base
from investigacao_residual_duplicatas_1960 import raw_signature, signature

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas"
PACKAGE = ROOT / "tmp/fechamento_integral_1960/vinculos/pacote01/pacote.json"
package = json.loads(PACKAGE.read_text(encoding="utf-8"))
guides = base.load_guides(ROOT)
connection = sqlite3.connect((OUT / "indice127.sqlite").as_uri() + "?mode=ro", uri=True)
connection.row_factory = sqlite3.Row
links = {int(r["linha"]) for r in base.rows(ROOT / "read_guides/1960_amostra_127_vinculos.csv")}
corrections = {int(r["linha"]): r for r in base.rows(ROOT / "read_guides/1960_amostra_127_correcoes.csv")}
pending = {n for g in json.loads((OUT / "inventario458.json").read_text(encoding="utf-8"))["grupos"] for n in g["linhas127"]}
target_lines = {p["linha"] for c in package["cartoes"] for p in c["pessoas"]}
own_lines = {p["linha"] for c in package["provas_compostas"].values() for p in c["pessoas127"]}
assert not target_lines & own_lines
assert not own_lines & pending
assert not own_lines & links
assert not own_lines & set(corrections)
cases = {}; signatures_by_uf = defaultdict(dict); tally127 = defaultdict(list); tally25 = defaultdict(list)


def group_signature(signatures):
    return tuple(sorted(Counter(signatures).items()))


for line, proof in package["provas_compostas"].items():
    line = int(line)
    card = dict(connection.execute("SELECT * FROM familias WHERE linha=?", (line,)).fetchone())
    people = [dict(p) for p in connection.execute("SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (line,))]
    assert {k: v for k, v in card.items() if k != "perfil"} == proof["cartao127"]
    assert [{k: v for k, v in p.items() if k != "perfil"} for p in people] == proof["pessoas127"]
    assert all(p["familia_fisica"] == line for p in people)
    key = (card["uf"], card["pasta"], card["boletim"])
    assert all((p["uf"], p["pasta"], p["boletim"]) == key for p in people)
    assert all((p["municipio"], p["distrito"], p["situacao"]) == (card["municipio"], card["distrito"], card["situacao"]) for p in people)
    profiles = [base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES) for p in people]
    assert all(not bad for _, bad in profiles)
    wanted = group_signature(signature(p, guides) for p, _ in profiles)
    signatures_by_uf[card["uf"]][wanted] = line
    cases[line] = {"chave": list(key), "assinatura24": wanted, "linhas127": [p["linha"] for p in people],
        "nao_usou_orfaos_ou_reparos_ou_vinculos_previos": True, "membros_fisicos_e_por_chave_concordam": True,
        "V216_adicionais": [pair for pair in proof["pares_nova_busca"] if pair["diferencas"] and
            set(pair["diferencas"].get("V216", [])) != {0, 63}]}

raw = (ROOT / base.FIXED_SOURCES[0]).open("rb")
for card in package["cartoes"]:
    key = tuple(map(int, (card["UF"], card["pasta"], card["boletim"])))
    assert connection.execute("SELECT count(*) FROM familias WHERE uf=? AND pasta=? AND boletim=?", key).fetchone()[0] == 0
    for row in card["pessoas"]:
        current = dict(connection.execute("SELECT * FROM pessoas WHERE linha=?", (row["linha"],)).fetchone())
        assert current["familia_atual"] is None
        assert current["original"] == row["texto_original"] and current["corrigido"] == row["texto_corrigido"]
        raw.seek((row["linha"] - 1) * 64)
        assert raw.read(62).decode("latin1") == row["texto_original"]
for proof in package["provas_compostas"].values():
    for row in [proof["cartao127"]] + proof["pessoas127"]:
        raw.seek((row["linha"] - 1) * 64)
        assert raw.read(62).decode("latin1") == row["original"] == row["corrigido"]
raw.close()

query = "SELECT uf,familia_atual,chave,linha,corrigido,invalidos FROM pessoas WHERE excluida=0 ORDER BY uf,familia_atual,chave,linha"
for key, iterator in itertools.groupby(connection.execute(query), lambda r: (r["uf"], r["familia_atual"], r["chave"] if r["familia_atual"] is None else "")):
    people = list(iterator)
    if key[0] not in signatures_by_uf or any(p["invalidos"] for p in people):
        continue
    parsed = [base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES) for p in people]
    if any(bad for _, bad in parsed):
        continue
    sig = group_signature(signature(p, guides) for p, _ in parsed)
    if sig in signatures_by_uf[key[0]]:
        tally127[signatures_by_uf[key[0]][sig]].append({"cartao": key[1], "chave": key[2], "pessoas": [p["linha"] for p in people]})

split = {}; source_hashes = []; samekeys = {}
for uf, abbrev in sorted(base.UF.items()):
    path = ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{abbrev}.gz"
    seen = set(); repeated = set()
    with gzip.open(path, "rt", encoding="latin1") as stream:
        for rawkey, iterator in itertools.groupby(enumerate(stream, 1), lambda r: r[1][:8]):
            if rawkey in seen:
                repeated.add(rawkey)
            seen.add(rawkey)
            people = [(i, t.rstrip("\r\n")) for i, t in iterator if t[8:10] != "00"]
            sig = group_signature(raw_signature(t) for _, t in people)
            if sig in signatures_by_uf.get(uf, {}):
                tally25[signatures_by_uf[uf][sig]].append({"chave": rawkey, "pessoas": [i for i, _ in people]})
    split[uf] = sorted(repeated)
    keys = {(c["chave"][1], c["chave"][2]) for c in cases.values() if c["chave"][0] == uf}
    keys.update((base.integer(k[:5]), base.integer(k[5:])) for k in repeated)
    if keys:
        ff, pp = base.read_source(ROOT, uf, keys)
        for rawkey in repeated:
            for line in cases:
                if cases[line]["chave"][0] == uf:
                    tally25[line] = [hit for hit in tally25[line] if hit["chave"] != rawkey]
            key = (base.integer(rawkey[:5]), base.integer(rawkey[5:]))
            sig = group_signature(raw_signature(p["texto"]) for p in pp[key])
            if sig in signatures_by_uf.get(uf, {}):
                tally25[signatures_by_uf[uf][sig]].append({"chave": rawkey, "pessoas": [p["linha"] for p in pp[key]], "reagrupada": True})
            samekeys[f"partida:{uf}:{rawkey}"] = {"cartoes": ff[key], "pessoas": pp[key]}
        for line, case in cases.items():
            if case["chave"][0] != uf:
                continue
            key = tuple(case["chave"][1:]); proof = package["provas_compostas"][str(line)]
            assert ff[key] == proof["cartoes25"] and pp[key] == proof["pessoas25"]
            assert not base.source_structure(ff[key][0], pp[key])
            f127, bad127 = base.parse_profile(proof["cartao127"]["corrigido"], guides[("127", "familias")], base.FAMILY_NAMES)
            f25, bad25 = base.parse_profile(ff[key][0]["texto"], guides[("25", "familias")], base.FAMILY_NAMES)
            assert not bad127 and not bad25 and f127 == f25
            assert proof["cartao127"]["distrito"] == base.integer(ff[key][0]["texto"][33:35])
            sig = group_signature(signature(base.parse_profile(p["texto"], guides[("25", "pessoas")], base.PERSON_NAMES)[0], guides) for p in pp[key])
            assert sig == case["assinatura24"]
    source_hashes.append({"arquivo": str(path.relative_to(ROOT)), "sha256": base.sha256(path)})
    print(f"Revisao independente: {abbrev}", flush=True)

for line, case in cases.items():
    assert len(tally127[line]) == len(tally25[line]) == 1
    assert tally127[line][0]["cartao"] == line
    assert tally25[line][0]["chave"] == f"{case['chave'][1]:05d}{case['chave'][2]:03d}"
    case.pop("assinatura24")
    case["contagem127"] = tally127[line]; case["contagem25"] = tally25[line]
assert {uf: keys for uf, keys in split.items() if keys} == {60: ["64150005"]}

split_sp = samekeys["partida:60:64150005"]
sp_proof = json.loads((ROOT / "references/fechamento_integral_1960_evidencias/duplicata_sp_composta.json").read_text(encoding="utf-8"))
split_sig = group_signature(raw_signature(p["texto"]) for p in split_sp["pessoas"])
split_sp["nao_coincide_grupos_SP_duplicata"] = []
for line, case in sp_proof["casos"].items():
    sig = group_signature(signature(base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)[0], guides) for p in case["pessoas"])
    assert sig != split_sig
    split_sp["nao_coincide_grupos_SP_duplicata"].append(int(line))
search = json.loads((OUT / "nacional/resultado.json").read_text(encoding="utf-8"))
matches = []
for c in search["contextos"]:
    sig = group_signature(signature(base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)[0], guides) for p in c["pessoas127"])
    if sig == split_sig:
        matches.append(c["chave"])
split_sp["contextos_pessoais_residuais_coincidentes"] = matches
assert not matches
result = {"revisor": "segunda_leitura_por_indice_atual_e_parsers", "cartoes_propostos": 10,
    "pessoas_propostas": 27, "concorrentes_decisivos": cases,
    "grupo_de_8_cartoes_20_pessoas_sem_obstaculo_identificado": True,
    "grupo_PR_2_cartoes_7_pessoas_nao_aprovado": "Concorrente866162 exige preservar V21619/17; esse criterio adicional nao foi homologado.",
    "nao_e_prova_de_inexistencia_absoluta": "Busca cobre os candidatos do auditor vigente; nao todos os possiveis erros historicos de chave e cartao.",
    "chaves_partidas_todas17fontes": split, "chave_partida_SP_relida": split_sp,
    "invariante_adicional_recomendada": "Conferir explicitamente chave pessoal de cada concorrente, inclusive ao usar unicidade24; todos os6decisivos atuais passam.",
    "fontes": source_hashes, "pacote_sha256": base.sha256(PACKAGE),
    "indice127_independente_sha256": base.sha256(OUT / "indice127.sqlite")}
with (OUT / "revisao_independente_vinculos.json").open("x", encoding="utf-8") as stream:
    json.dump(result, stream, ensure_ascii=False, indent=2)
print(json.dumps({"concorrentes": len(cases), "UFs25": len(source_hashes), "chaves_partidas": split,
    "8cartoes20pessoas": "sem obstaculo identificado", "2cartoes7pessoasPR": "fora do criterio00_63"}))
