"""Unicidade familiar24 em127, sem usar atributos do cartao para restringir."""
from collections import Counter, defaultdict
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as base
from investigacao_residual_duplicatas_1960 import signature

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas"
guides = base.load_guides(ROOT)
data = json.loads((OUT / "alternativas_familias_e_concorrentes.json").read_text(encoding="utf-8"))
connection = sqlite3.connect((OUT / "indice127.sqlite").as_uri() + "?mode=ro", uri=True)
connection.row_factory = sqlite3.Row
targets = {int(line): case for line, case in data["casos"].items() if int(line) in {200309, 200562, 773909, 773767, 774008}}
profiles = defaultdict(set); candidates = defaultdict(lambda: defaultdict(set)); checked = Counter()
for line, case in targets.items():
    for p in case["ocorrencias24_por_perfil_na_UF25"]:
        profiles[p["assinatura24"]].add(line)
for row in connection.execute("SELECT uf,linha,corrigido,familia_atual,familia_fisica FROM pessoas WHERE uf IN (21,60) AND excluida=0"):
    checked[row["uf"]] += 1
    profile, invalid = base.parse_profile(row["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES)
    if invalid:
        continue
    sig = signature(profile, guides)
    for line in profiles.get(sig, ()):
        if row["uf"] != targets[line]["cartao"]["uf"]:
            continue
        for linkage in ("familia_atual", "familia_fisica"):
            if row[linkage] is not None:
                candidates[line][linkage].add(row[linkage])
result = []
for line, case in targets.items():
    own = Counter({p["assinatura24"]: p["quantidade127_no_alvo"] for p in case["ocorrencias24_por_perfil_na_UF25"]})
    hits = []
    for linkage in ("familia_atual", "familia_fisica"):
        for candidate in sorted(candidates[line][linkage]):
            people = [dict(p) for p in connection.execute(f"SELECT linha,corrigido FROM pessoas WHERE {linkage}=? AND excluida=0 ORDER BY linha", (candidate,))]
            parsed = [base.parse_profile(p["corrigido"], guides[("127", "pessoas")], base.PERSON_NAMES) for p in people]
            observed = Counter(signature(p, guides) for p, _ in parsed)
            if not any(bad for _, bad in parsed) and own == observed:
                hits.append({"agrupamento": linkage, "cartao": candidate, "pessoas": people})
    result.append({"cartao127": line, "correspondentes127_composicao24_sem_restricao_cartao": hits,
        "correspondentes25_composicao24_sem_restricao_cartao": [{"chave25": c["chave25"], "cartao25": c["cartao25"]["linha"], "avaliacao": c["avaliacao"]} for c in case["alternativas25"]],
        "nao_autoriza_decisao": True})
with (OUT / "unicidade_composicao24.json").open("x", encoding="utf-8") as stream:
    json.dump({"pessoas127_examinadas": dict(checked), "casos": result}, stream, ensure_ascii=False, indent=2)
print(json.dumps([{"cartao": c["cartao127"], "pares127": [(h["agrupamento"], h["cartao"]) for h in c["correspondentes127_composicao24_sem_restricao_cartao"]], "chaves25": [h["chave25"] for h in c["correspondentes25_composicao24_sem_restricao_cartao"]]} for c in result]))
