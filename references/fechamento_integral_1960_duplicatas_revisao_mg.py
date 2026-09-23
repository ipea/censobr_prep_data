"""Revisao MG: ancora intacta, mascara literal e concorrentes independentes."""
from collections import Counter, defaultdict
import gzip
import itertools
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as base
from investigacao_residual_vinculos_1960 import canonical, signatures

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas"
INPUT = ROOT / "tmp/fechamento_integral_1960/vinculos/mg01/mg405458.json"
proof = json.loads(INPUT.read_text(encoding="utf-8"))
guides = base.load_guides(ROOT)
connection = sqlite3.connect((OUT / "indice127.sqlite").as_uri() + "?mode=ro", uri=True)
connection.row_factory = sqlite3.Row
people = [dict(r) for r in connection.execute("SELECT * FROM pessoas WHERE linha BETWEEN 405457 AND 405459 ORDER BY linha")]
assert [{k: v for k, v in p.items() if k != "perfil"} for p in people] == proof["pessoas127"]
assert all(p["original"] == p["corrigido"] and p["familia_atual"] is None for p in people)
assert connection.execute("SELECT count(*) FROM familias WHERE uf=40 AND pasta=40880 AND boletim=1").fetchone()[0] == 0
intact = {p["linha"]: canonical(base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)[0], guides)[0] for p in (people[0], people[2])}
damaged = signatures(people[1]["original"], "127")[0]
assert damaged[1] == " " and damaged[3:5] == " 9"
indices_preserved = [i for i in range(len(damaged)) if i not in {1, 3}]
hits = defaultdict(list); matches_damaged = []
own_targets = {}; own25 = defaultdict(list); own127 = defaultdict(list)
own_lines = set()
for line, case in proof["alternativas_explicadas_sem_usar_texto_alvo"].items():
    line = int(line)
    pp = [dict(r) for r in connection.execute("SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (line,))]
    assert [{k: v for k, v in p.items() if k != "perfil"} for p in pp] == case["pessoas127"]
    assert all(p["familia_fisica"] == line for p in pp)
    card = case["cartao127"]
    assert all((p["uf"], p["pasta"], p["boletim"]) == (card["uf"], card["pasta"], card["boletim"]) for p in pp)
    assert all(p["original"] == p["corrigido"] for p in pp)
    own_lines.update(p["linha"] for p in pp)
    sig = tuple(sorted(Counter(canonical(base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)[0], guides)[1] for p in pp).items()))
    own_targets[sig] = line
    for pair in case["pares_nova_busca"]:
        assert set(pair["diferencas"]) <= {"V216"}
        assert not pair["diferencas"] or set(pair["diferencas"]["V216"]) == {0, 63}
assert not own_lines & {405457, 405458, 405459}

query = "SELECT familia_atual,chave,linha,corrigido,invalidos FROM pessoas WHERE uf=40 AND excluida=0 ORDER BY familia_atual,chave,linha"
for key, iterator in itertools.groupby(connection.execute(query), lambda p: (p["familia_atual"], p["chave"] if p["familia_atual"] is None else "")):
    rows = list(iterator)
    if any(p["invalidos"] for p in rows):
        continue
    sig = tuple(sorted(Counter(canonical(base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)[0], guides)[1] for p in rows).items()))
    if sig in own_targets:
        own127[own_targets[sig]].append({"cartao": key[0], "linhas": [p["linha"] for p in rows]})
hashes = []
for uf, abbrev in sorted(base.UF.items()):
    path = ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{abbrev}.gz"
    with gzip.open(path, "rt", encoding="latin1") as stream:
        for key, iterator in itertools.groupby(enumerate(stream, 1), lambda r: r[1][:8]):
            pp = [(i, t.rstrip("\r\n")) for i, t in iterator if t[8:10] != "00"]
            for number, text in pp:
                full, partial = signatures(text, "25")
                found = [line for line, wanted in intact.items() if full == wanted]
                compatible = len(full) == len(damaged) and all(full[i] == damaged[i] for i in indices_preserved)
                if found or compatible:
                    profile, bad = base.parse_profile(text, guides[("25", "pessoas")], base.PERSON_NAMES)
                    assert canonical(profile, guides)[0] == full and not bad
                    item = {"UF": uf, "linha": number, "texto": text, "chave": [uf, int(key[:5]), int(key[5:])]}
                    for line in found:
                        hits[line].append(item)
                    if compatible:
                        matches_damaged.append(item)
            if uf == 40:
                sig = tuple(sorted(Counter(signatures(t, "25")[1] for _, t in pp).items()))
                if sig in own_targets:
                    own25[own_targets[sig]].append({"chave": key, "linhas": [i for i, _ in pp]})
    hashes.append({"arquivo": str(path.relative_to(ROOT)), "sha256": base.sha256(path)})
    print(f"MG independente: {abbrev}", flush=True)

assert {str(k): v for k, v in hits.items()} == proof["identificacao_sem_usar_405458"]["ocorrencias_completas25"]
assert matches_damaged == proof["consulta_independente_caracteres_legiveis_405458"]["ocorrencias_todas17UF"]
joint = set.intersection(*[{tuple(p["chave"]) for p in hits[line]} for line in intact])
assert joint == {(40, 40880, 1)} and len(matches_damaged) == 1
assert matches_damaged[0]["linha"] == 567047
for sig, line in own_targets.items():
    assert len(own127[line]) == len(own25[line]) == 1 and own127[line][0]["cartao"] == line
    card = proof["alternativas_explicadas_sem_usar_texto_alvo"][str(line)]["cartao127"]
    assert own25[line][0]["chave"] == f"{card['pasta']:05d}{card['boletim']:03d}"
ff, pp = base.read_source(ROOT, 40, {(40880, 1)} | {(c["cartao127"]["pasta"], c["cartao127"]["boletim"]) for c in proof["alternativas_explicadas_sem_usar_texto_alvo"].values()})
assert ff[40880, 1] == [proof["cartao25"]] and pp[40880, 1] == proof["pessoas25"]
assert not base.source_structure(proof["cartao25"], proof["pessoas25"])
proposal = proof["proposta_textual_nao_aplicada"]
assert proposal["antes"] == people[1]["original"]
assert [i + 1 for i, (a, b) in enumerate(zip(proposal["antes"], proposal["depois_apenas_em_memoria"])) if a != b] == [20, 22]
assert proposal["depois_apenas_em_memoria"][22] == "9"
for line, case in proof["alternativas_explicadas_sem_usar_texto_alvo"].items():
    key = (case["cartao127"]["pasta"], case["cartao127"]["boletim"])
    assert case["cartoes25"] == ff[key] and case["pessoas25"] == pp[key]
    assert not base.source_structure(ff[key][0], pp[key])
result = {"resultado": "sem circularidade identificada na prova nova", "intactos25": {k: len(v) for k, v in hits.items()},
    "chaves_conjuntas25": [list(k) for k in joint], "mascara_preserva_todos_caracteres_salvo20_22": True,
    "correspondencias_mascara": matches_damaged, "concorrentes_proprios127": dict(own127), "concorrentes_proprios25": dict(own25),
    "texto_original_relido_no_indice_independente": True, "respostas_alteradas": 0,
    "limite": "Prova sustenta proposta de recuperar somente dois caracteres e depois cartao; a guarda de recuperacao deve reexaminar todos os candidatos com o texto proposto, nao apenas retirar dois nomes da lista antiga.",
    "fontes": hashes, "prova_original_sha256": base.sha256(INPUT)}
with (OUT / "revisao_independente_mg405458.json").open("x", encoding="utf-8") as stream:
    json.dump(result, stream, ensure_ascii=False, indent=2)
print(json.dumps({k: result[k] for k in ["resultado", "intactos25", "chaves_conjuntas25"]}))
