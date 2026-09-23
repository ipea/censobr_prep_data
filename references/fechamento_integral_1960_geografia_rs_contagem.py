"""Contagem literal de RS8405, sem imputação de nomes ou pesos."""

from collections import Counter, defaultdict
import gzip
import json
from pathlib import Path
import sqlite3

from auditoria_recuperacao_cartoes_1960 import load_guides, integer, sha256

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/geografia_rs"
OUT.mkdir(parents=True, exist_ok=True)
guides = load_guides(ROOT)
source = ROOT / "data/release_legacy/Censo.1960.amostra.25porcento.rs.gz"
groups = {}
families = []
with gzip.open(source, "rt", encoding="latin1") as stream:
    for line, text in enumerate(stream, 1):
        text = text.rstrip("\r\n")
        if text[8:10] != "00" or text[29:33] != "8405":
            continue
        values = {name: integer(text[start:end]) for name, (start, end, _) in guides[("25", "familias")].items()}
        record = {"linha": line, "texto": text, "valores": values, "pessoas": []}
        families.append(record)
        if text[:8] in groups:
            raise ValueError("Mais de um cartão na chave")
        groups[text[:8]] = record
with gzip.open(source, "rt", encoding="latin1") as stream:
    for line, text in enumerate(stream, 1):
        text = text.rstrip("\r\n")
        if text[8:10] == "00" or text[:8] not in groups:
            continue
        groups[text[:8]]["pessoas"].append({"linha": line, "sexo_presenca": integer(text[14:15])})
summary = []
for district in sorted({r["valores"]["V117"] for r in families}):
    selected = [r for r in families if r["valores"]["V117"] == district]
    counts = Counter()
    for record in selected:
        counts.update(str(p["sexo_presenca"]) for p in record["pessoas"])
        if len(record["pessoas"]) != record["valores"]["v100"]:
            raise ValueError("Cardinalidade do cartão divergente")
    summary.append({
        "distrito": district,
        "cartoes": len(selected),
        "pessoas": sum(len(r["pessoas"]) for r in selected),
        "pessoas_sexo_presenca": dict(sorted(counts.items())),
        "cartoes_situacao": dict(sorted(Counter(str(r["valores"]["V118"]) for r in selected).items())),
        "pastas": sorted({r["valores"]["v001"] for r in selected}),
        "primeiro_cartao": selected[0],
        "ultimo_cartao": selected[-1],
    })
database = ROOT / "tmp/fechamento_integral_1960/duplicatas/indice127.sqlite"
connection = sqlite3.connect(f"file:{database.as_posix()}?mode=ro", uri=True)
connection.row_factory = sqlite3.Row
sample127 = [dict(row) for row in connection.execute(
    "SELECT distrito,situacao,COUNT(*) cartoes FROM familias WHERE uf=81 AND municipio=8405 GROUP BY distrito,situacao")]
result = {"fonte25": str(source), "sha256": sha256(source), "distritos25": summary,
          "cartoes127_indice_anterior_integracao": sample127,
          "nota": "Contagem de cartões/boletins, não prova de domicílios físicos distintos; sem atribuir nome por inferência."}
(OUT / "contagem_rs8405.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({"distritos25": [{k: v for k, v in r.items() if k not in {"primeiro_cartao", "ultimo_cartao"}} for r in summary], "amostra127": sample127}, ensure_ascii=False))
