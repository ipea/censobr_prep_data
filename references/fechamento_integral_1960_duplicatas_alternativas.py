"""Busca global das familias coincidentes e de concorrentes PE/SP pendentes."""
from collections import Counter, defaultdict
import gzip
import json
from pathlib import Path
import sqlite3
import time

import psutil

import auditoria_recuperacao_cartoes_1960 as base
from aprofundar_preservacao_duplicatas_1960 import compare
from investigacao_residual_duplicatas_1960 import differences, raw_signature, signature

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas"
guides = base.load_guides(ROOT)
connection = sqlite3.connect((OUT / "indice127.sqlite").as_uri() + "?mode=ro", uri=True)
connection.row_factory = sqlite3.Row
manifest = json.loads((ROOT / "read_guides/1960_amostra_127_familias_coincidentes.json").read_text(encoding="utf-8"))
pending = [g for g in manifest["conjuntos"] if g["acao"] == "pendente"]
cards = {line for g in pending for line in g["linhas_cartoes"]} | {200309, 200562, 773909, 774008, 773767}
targets = {}
profile_targets = defaultdict(set)
profile_counts25 = Counter()
for line in sorted(cards):
    card = dict(connection.execute("SELECT * FROM familias WHERE linha=?", (line,)).fetchone())
    people = [dict(r) for r in connection.execute("SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (line,))]
    profiles = [base.parse_profile(r["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES) for r in people]
    assert all(not bad for _, bad in profiles)
    counts = Counter(signature(p, guides) for p, _ in profiles)
    targets[line] = {"cartao": card, "pessoas": people, "contagens24": counts, "alternativas25": [], "mesma_chave25": []}
    for s in counts:
        profile_targets[s].add(line)

sources = []; total = 0; started = time.monotonic()
for uf, abbrev in sorted(base.UF.items()):
    path = ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{abbrev}.gz"
    fingerprint = base.sha256(path)
    family = None; people25 = []

    def examine():
        if family is None:
            return
        key25 = (uf, base.integer(family["texto"][:5]), base.integer(family["texto"][5:8]))
        count25 = Counter(raw_signature(p["texto"]) for p in people25)
        candidates = set()
        for s, n in count25.items():
            candidates.update(profile_targets.get(s, ()))
            if s in profile_targets:
                profile_counts25[(uf, s)] += n
        for line, target in targets.items():
            card = target["cartao"]
            if key25 == (card["uf"], card["pasta"], card["boletim"]):
                target["mesma_chave25"].append({"UF25": uf, "cartao25": family, "pessoas25": people25})
        for line in candidates:
            target = targets[line]
            if count25 != target["contagens24"]:
                continue
            card = target["cartao"]
            check = compare(connection, card, target["pessoas"], family, people25, guides)
            if uf != card["uf"]:
                check["motivos"].append("outra_UF")
            family25, bad = base.parse_profile(family["texto"], guides[("25", "familias")], base.FAMILY_NAMES)
            family127, _ = base.parse_profile(card["corrigido"], guides[("127", "familias")], base.FAMILY_NAMES)
            check["diferencas_cartao"] = [{"campo": n, "valor127": a, "valor25": b}
                for n, a, b in zip(base.FAMILY_NAMES, family127, family25) if a != b]
            target["alternativas25"].append({"chave25": list(key25), "cartao25": family, "pessoas25": people25, "avaliacao": check})

    with gzip.open(path, "rt", encoding="latin1") as stream:
        for line25, text in enumerate(stream, 1):
            row = {"linha": line25, "texto": text.rstrip("\r\n")}
            if row["texto"][8:10] == "00":
                examine(); family = row; people25 = []
            else:
                people25.append(row)
        examine()
    assert base.sha256(path) == fingerprint
    total += line25
    sources.append({"arquivo": str(path.relative_to(ROOT)), "sha256": fingerprint, "linhas": line25})
    print(json.dumps({"UF": abbrev, "linhas_acumuladas": total, "segundos": round(time.monotonic() - started, 1)}), flush=True)

for line, target in targets.items():
    card = target["cartao"]
    own_profiles = Counter(base.profile_hash(base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)[0]) for p in target["pessoas"])
    candidates127 = []
    for row in connection.execute("SELECT linha,corrigido FROM familias WHERE uf=? AND distrito=? AND perfil=?", (card["uf"], card["distrito"], card["perfil"])):
        candidate_people = [dict(p) for p in connection.execute("SELECT linha,corrigido,perfil FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (row["linha"],))]
        if Counter(p["perfil"] for p in candidate_people) == own_profiles:
            candidates127.append({"linha_cartao": row["linha"], "texto_cartao": row["corrigido"],
                "pessoas": [{"linha": p["linha"], "corrigido": p["corrigido"]} for p in candidate_people]})
    target["cartoes127_mesmo_cartao_geografia_composicao25"] = candidates127
    target["ocorrencias24_por_perfil_na_UF25"] = [{"assinatura24": s, "quantidade127_no_alvo": n,
        "quantidade25_UF": profile_counts25[(card["uf"], s)]} for s, n in target.pop("contagens24").items()]
    for person in [card] + target["pessoas"]:
        person.pop("perfil", None)
    for candidate in target["mesma_chave25"]:
        candidate["avaliacao"] = compare(connection, card, target["pessoas"], candidate["cartao25"], candidate["pessoas25"], guides)
        candidate["pessoas127_diferencas_minimas"] = []
        for p in target["pessoas"]:
            a, _ = base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)
            pairs = [(q["linha"], differences(a, base.parse_profile(q["texto"], guides[("25", "pessoas")], base.PERSON_NAMES)[0])) for q in candidate["pessoas25"]]
            distance = min((len(d) for _, d in pairs), default=None)
            candidate["pessoas127_diferencas_minimas"].append({"linha127": p["linha"], "distancia": distance,
                "alternativas_minimas": [{"linha25": line25, "diferencas": d} for line25, d in pairs if len(d) == distance]})

result = {"resumo": {"conjuntos_familiares_pendentes": len(pending), "cartoes_investigados": len(targets),
    "fontes25": len(sources), "linhas25": total, "memoria_rss_bytes": psutil.Process().memory_info().rss,
    "alternativas24": sum(len(t["alternativas25"]) for t in targets.values()), "decisoes_aplicadas": 0},
    "fontes": sources, "casos": targets,
    "limite": "Busca integral de composicao24 exata e quantidades nas 17 fontes locais; nao equipara V216 nem outros campos, nao imputa geografia, nao prova identidade civil."}
with (OUT / "alternativas_familias_e_concorrentes.json").open("x", encoding="utf-8") as stream:
    json.dump(result, stream, ensure_ascii=False, indent=2)
print(json.dumps(result["resumo"], ensure_ascii=False))
