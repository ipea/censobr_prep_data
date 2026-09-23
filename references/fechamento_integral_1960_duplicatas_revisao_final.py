"""Revisão independente da cadeia portátil e dos sete concorrentes atuais."""

from collections import Counter, defaultdict
from pathlib import Path
import argparse
import hashlib
import itertools
import json
import sqlite3

import auditoria_recuperacao_cartoes_1960 as core
from investigacao_residual_duplicatas_1960 import signature

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--out", default="tmp/fechamento_integral_1960/duplicatas/revisao_final")
args = parser.parse_args()
OUT = (ROOT / args.out).resolve()
if not OUT.is_relative_to(ROOT / "tmp/fechamento_integral_1960/duplicatas"):
    raise ValueError("A saida deve permanecer no diretorio de auditoria das duplicatas.")
OUT.mkdir(parents=True, exist_ok=True)
INDEX = ROOT / "tmp/fechamento_integral_1960/vinculos/reauditoria01/indice127.sqlite"
hashes = {}


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))


def digest(path):
    if path not in hashes:
        sha = hashlib.sha256()
        with (ROOT / path).open("rb") as stream:
            while block := stream.read(1024 * 1024):
                sha.update(block)
        hashes[path] = sha.hexdigest()
    return hashes[path]


def sig(people):
    return tuple(sorted(Counter(signature(p, guides) for p in people).items()))


manifest_path = "read_guides/1960_amostra_127_cartoes_recuperados.json"
manifest = read(manifest_path)
cards = {x["id_recuperacao"]: x for x in manifest["cartoes"]}
assert len(cards) == len(manifest["cartoes"]) == 41
assert sum(x["n_pessoas"] for x in cards.values()) == 103
assert len({p["linha"] for c in cards.values() for p in c["pessoas"]}) == 103
assert len({(c["UF"], c["pasta"], c["boletim"]) for c in cards.values()}) == 41
assert len({(c["arquivo_25"], c["linha_25"]) for c in cards.values()}) == 41

proof_paths = {c[k]["prova_arquivo"] for c in cards.values()
               for k in ("prova_composta", "reconciliacao_chave") if k in c}
proof_paths.update({manifest_path, "read_guides/1960_amostra_127_reparos_fonte25.json",
    "references/fechamento_integral_1960_evidencias/cartoes_compostos.json",
    "references/fechamento_integral_1960_evidencias/mg405458_identidade.json",
    "references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"})
links = []
for path in sorted(proof_paths):
    data = read(path)
    sources = data.get("fontes", [])
    assert len({s["arquivo"] for s in sources}) == len(sources), path
    for source in sources:
        actual = digest(source["arquivo"])
        assert actual == source["sha256"], (path, source["arquivo"], actual, source["sha256"])
        assert not source["arquivo"].replace("\\", "/").startswith("tmp/"), (path, source["arquivo"])
        links.append({"prova": path, "arquivo": source["arquivo"], "sha256": actual})
    digest(path)

guides = core.load_guides(ROOT)
conn = sqlite3.connect(INDEX.as_uri() + "?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
targets = {p["linha"] for c in cards.values() for p in c["pessoas"]}
compound = {}
cases = []
for path in sorted(proof_paths):
    data = read(path)
    for c in data.get("cartoes", []):
        if path == manifest_path:
            continue
        assert c == cards[c["id_recuperacao"]], (path, c["id_recuperacao"])
    for key, cp in data.get("provas_compostas", {}).items():
        line = int(key)
        if line in compound:
            assert compound[line] == cp
        compound[line] = cp
    for analysis in data.get("analises", []):
        case = cards[analysis["id_recuperacao"]]
        assert len(analysis["cartoes_examinados"]) == case["verificacoes"]["cartoes127_examinados"]
        assert case["verificacoes"]["alternativas_plausiveis"] == 0
        cases.append({"id": case["id_recuperacao"], "examinados": len(analysis["cartoes_examinados"])})

expected = {405480, 405486, 700142, 794622, 1060560, 1060755, 1060763}
assert set(compound) == expected
signatures = defaultdict(dict)
for line, cp in compound.items():
    card = dict(conn.execute("SELECT * FROM familias WHERE linha=?", (line,)).fetchone())
    people = [dict(p) for p in conn.execute(
        "SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (line,))]
    assert {k: v for k, v in card.items() if k != "perfil"} == cp["cartao127"]
    assert [{k: v for k, v in p.items() if k != "perfil"} for p in people] == cp["pessoas127"]
    assert all(p["familia_fisica"] == line and not p["invalidos"] for p in people)
    assert all((p["uf"], p["pasta"], p["boletim"], p["municipio"], p["distrito"], p["situacao"]) ==
               (card["uf"], card["pasta"], card["boletim"], card["municipio"], card["distrito"], card["situacao"]) for p in people)
    assert not targets & {p["linha"] for p in people}
    assert card["original"] == card["corrigido"]
    assert all(p["original"] == p["corrigido"] for p in people)
    parsed = [core.parse_profile(p["corrigido"], guides["127", "pessoas"], core.PERSON_NAMES) for p in people]
    assert all(not bad for _, bad in parsed)
    key = sig(p for p, _ in parsed)
    assert key not in signatures[card["uf"]]
    signatures[card["uf"]][key] = line
    for pair in cp["pares_nova_busca"]:
        assert set(pair["diferencas"]) <= {"V216"}
        assert not pair["diferencas"] or set(pair["diferencas"]["V216"]) == {0, 63}

hits = defaultdict(list)
query = "SELECT uf,familia_atual,chave,linha,corrigido,invalidos FROM pessoas WHERE excluida=0 ORDER BY uf,familia_atual,chave,linha"
for group, iterator in itertools.groupby(conn.execute(query), lambda r: (
        r["uf"], r["familia_atual"], r["chave"] if r["familia_atual"] is None else "")):
    people = list(iterator)
    if group[0] not in signatures or any(p["invalidos"] for p in people):
        continue
    parsed = [core.parse_profile(p["corrigido"], guides["127", "pessoas"], core.PERSON_NAMES) for p in people]
    if any(bad for _, bad in parsed):
        continue
    key = sig(p for p, _ in parsed)
    if key in signatures[group[0]]:
        hits[signatures[group[0]][key]].append({"cartao": group[1], "chave": group[2], "linhas": [p["linha"] for p in people]})
conn.close()
for line in expected:
    assert len(hits[line]) == 1 and hits[line][0]["cartao"] == line
result = {"status": "PASS", "cartoes": 41, "pessoas_existentes": 103,
    "provas_json": len(proof_paths), "arestas_hash_conferidas": len(links), "fontes": links,
    "hashes_arquivos": hashes, "indice127_sha256": digest(INDEX.relative_to(ROOT).as_posix()),
    "concorrentes_compostos": sorted(expected), "unicidade24_recontada127_atual": hits,
    "concorrentes_nao_dependem_de_alvos_ou_reparos": True,
    "somente_divergencias_V216_00_63": True,
    "limite": "Recontagem nacional25 anterior preservada porque os hashes das fontes nao mudaram; nao reexecutada nesta etapa.",
    "analises_portateis": cases}
(OUT / "resultado.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({k: v for k, v in result.items() if k not in {"fontes", "hashes_arquivos"}}, ensure_ascii=False))
