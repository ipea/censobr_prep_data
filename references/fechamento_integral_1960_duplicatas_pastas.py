"""Cinco pastas discrepantes: comparação literal e materializada, sem R."""

from collections import Counter, defaultdict
import gzip
import hashlib
import json
from pathlib import Path
import sqlite3

import pyarrow.parquet as pq
import psutil

import auditoria_recuperacao_cartoes_1960 as core

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas/pastas"
OUT.mkdir(parents=True, exist_ok=True)
TARGETS = {(14, 15004), (14, 15290), (40, 43234), (60, 60158), (60, 60718)}
SOURCE_TARGETS = TARGETS | {(14, 14990)}
INDEX = "tmp/fechamento_integral_1960/vinculos/reauditoria01/indice127.sqlite"
guides = core.load_guides(ROOT)
municipal = {(int(r["uf60"]), int(r["cod60"])): r for r in core.rows(ROOT / "read_guides/1960_municipios.csv")}
tracked = set(core.FIXED_SOURCES) | {INDEX, "read_guides/1960_municipios.csv",
    "read_guides/1960_amostra_127_cartoes_recuperados.json", "R/microdata_1960_amostra_127.R",
    "references/figuras/desenho_amostral_1960.R", "references/fechamento_integral_1960_duplicatas_pastas.py",
    "read_guides/1960_amostra_127_codigos.csv"}
INVENTORY = "references/fechamento_integral_1960_evidencias/inventario_final.json"
CE_PROOF = "references/resolucao_residuais_1960_evidencias/cartoes_fora_chave_integral20260923.json"
tracked.update({INVENTORY, CE_PROOF})
inventory = json.loads((ROOT / INVENTORY).read_text(encoding="utf-8"))
recovered = json.loads((ROOT / "read_guides/1960_amostra_127_cartoes_recuperados.json").read_text(encoding="utf-8"))["cartoes"]


def hash_file(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def clean(row):
    return {k: v for k, v in row.items() if k != "perfil"}


def profile(text, sample, family=False):
    names = core.FAMILY_NAMES if family else core.PERSON_NAMES
    values, bad = core.parse_profile(text, guides[sample, "familias" if family else "pessoas"], names)
    return list(values), bad


def signature(records, sample, omit=()):
    counts = Counter()
    for row in records:
        text = row.get("corrigido", row.get("texto"))
        values, bad = profile(text, sample)
        if bad:
            return None
        counts[tuple(v for name, v in zip(core.PERSON_NAMES, values) if name not in omit)] += 1
    return frozenset(counts.items())


def classify(rows, uf, situation, muni):
    urban = sum(r[situation] in (1, 3) for r in rows)
    rural = sum(r[situation] == 5 for r in rows)
    municipalities = Counter(r[muni] for r in rows)
    large = any(float(municipal.get((uf, code), {}).get("pop_urbana") or 0) >= 100000
                for code in municipalities if municipal.get((uf, code), {}).get("pop_urbana") not in ("NA",))
    group = None if not rows else "mista" if urban and rural else "rural" if not urban else "cidade grande" if large else "urbana menor"
    return {"n": len(rows), "urbana_suburbana": urban, "rural": rural,
        "situacoes": dict(Counter(str(r[situation]) for r in rows)), "grupo": group,
        "municipios": [{"codigo": m, "n": n, "nome": municipal.get((uf, m), {}).get("nome"),
                         "pop_urbana": municipal.get((uf, m), {}).get("pop_urbana")} for m, n in municipalities.items()]}


def parquet_rows(path, columns, ufname, pastaname, keys):
    tracked.add(path)
    found = defaultdict(list)
    pf = pq.ParquetFile(ROOT / path)
    columns = [c for c in columns if c in pf.schema.names]
    for batch in pf.iter_batches(batch_size=65536, columns=columns):
        for row in batch.to_pylist():
            folder = row[pastaname]
            if pastaname == "censobr_upa":
                folder = str(folder).split("-")[-1]
            # O legado exporta UF como double; integer() dos brutos rejeita 14.0.
            key = (int(row[ufname]) if row[ufname] is not None else None,
                   int(folder) if folder is not None else None)
            if key in keys and row.get("censobr_source", 2) == 2:
                found[key].append(row)
    return found


conn = sqlite3.connect((ROOT / INDEX).as_uri() + "?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
families127 = {}; people127 = {}
for key in TARGETS:
    fs = core.fetch(conn, "SELECT * FROM familias WHERE uf=? AND pasta=? ORDER BY linha", key)
    families127[key] = fs
    for f in fs:
        people127[f["linha"]] = core.fetch(conn,
            "SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (f["linha"],))

source25 = defaultdict(lambda: {"familias": [], "pessoas": []})
source_lines = {}
for uf in sorted({k[0] for k in SOURCE_TARGETS}):
    path = f"data/release_legacy/Censo.1960.amostra.25porcento.{core.UF[uf]}.gz"
    tracked.add(path)
    with gzip.open(ROOT / path, "rt", encoding="latin1") as stream:
        for line, text in enumerate(stream, 1):
            if (uf, core.integer(text[:5])) not in SOURCE_TARGETS:
                continue
            text = text.rstrip("\r\n")
            key = (uf, core.integer(text[:5]), core.integer(text[5:8]))
            row = {"linha": line, "texto": text}
            family = text[8:10] == "00"
            if family:
                row.update({"municipio": core.integer(text[29:33]), "distrito": core.integer(text[33:35]),
                            "situacao": core.integer(text[35:36])})
            source25[key]["familias" if family else "pessoas"].append(row)
        source_lines[uf] = line

legacy = parquet_rows("data/release_legacy/Censo.1960.brasil.domicilios.amostraCompilada.censobr.parquet",
    ["uf", "v001", "v002", "v116", "v117", "v118", "censobr_source", "censobr_estrato", "censobr_upa", "censobr_idhousehold"],
    "uf", "v001", SOURCE_TARGETS)
materialized = parquet_rows("data_raw/microdata/1960/amostra_127/domicilios_1960_amostra_127.parquet",
    ["UF", "linha", "pasta", "boletim", "V116", "V118", "V101", "distrito", "code_muni_1960", "censobr_upa",
     "censobr_estrato", "censobr_idhousehold", "censobr_familia_origem", "censobr_n_familias"], "UF", "censobr_upa", TARGETS)
raw25_materialized = defaultdict(list)
for uf in sorted({k[0] for k in TARGETS}):
    path = f"data_raw/microdata/1960/amostra_25/{core.UF[uf]}/domicilios.parquet"
    raw25_materialized.update(parquet_rows(path,
        ["UF", "linha", "v001", "v002", "V116", "V118", "V101", "code_muni_1960", "censobr_idhousehold"],
        "UF", "v001", SOURCE_TARGETS))

sig25 = defaultdict(list)
for key, group in source25.items():
    if len(group["familias"]) != 1:
        continue
    s = signature(group["pessoas"], "25", ("V216",))
    if s is not None:
        sig25[key[0], s].append(key)

cases = []
for uf, folder in sorted(TARGETS):
    fs = families127[uf, folder]
    rawfs = [dict(f, situacao=core.integer(f["original"][17]), municipio=core.integer(f["original"][2:6])) for f in fs]
    fs25 = [f for k, v in source25.items() if k[:2] == (uf, folder) for f in v["familias"]]
    selected = []
    allmatches = []
    for f in fs:
        people = people127[f["linha"]]
        s = signature(people, "127", ("V216",))
        matches = []
        for k in sig25.get((uf, s), []):
            other = source25[k]["familias"][0]
            a, bad_a = profile(f["corrigido"], "127", True)
            b, bad_b = profile(other["texto"], "25", True)
            matches.append({"chave25": list(k), "cartao25": other,
                "n_pessoas": len(source25[k]["pessoas"]),
                "exatos25_campos": signature(people, "127") == signature(source25[k]["pessoas"], "25"),
                "divergencias_familiares": {n: [x, y] for n, x, y in zip(core.FAMILY_NAMES, a, b) if x != y},
                "invalidos": [bad_a, bad_b]})
        allmatches.append({"cartao127": f["linha"], "boletim127": f["boletim"], "situacao127": f["situacao"], "correspondencias24": matches})
        # Sao os poucos cartoes que determinam a mudanca de grupo, alem de CE15004.
        decisive = (folder == 15290 and f["situacao"] in (1, 3)) or (folder not in (15004, 15290) and f["situacao"] == 5)
        if decisive:
            same = source25.get((uf, folder, f["boletim"]), {"familias": [], "pessoas": []})
            same_people = []
            for p in people:
                values, invalid = profile(p["corrigido"], "127")
                pp = []
                for q in same["pessoas"]:
                    other_values, other_invalid = profile(q["texto"], "25")
                    differences = {n: [a, b] for n, a, b in zip(core.PERSON_NAMES, values, other_values) if a != b}
                    pp.append({"linha25": q["linha"], "diferencas": differences,
                               "invalidos": [invalid, other_invalid]})
                same_people.append({"linha127": p["linha"], "candidatos25_por_diferencas": sorted(pp, key=lambda v: len(v["diferencas"]))})
            selected.append({"cartao127": clean(f), "pessoas127": [clean(p) for p in people],
                             "mesma_chave25": same, "correspondencias24": matches,
                             "comparacao_individual_mesma_chave": same_people,
                             "situacao_pessoas127": dict(Counter(str(p["situacao"]) for p in people)),
                             "conflitos_inventario192": {kind: [r for r in inventory[kind] if r["linha_cartao"] == f["linha"]]
                                  for kind in ("conflitos_municipais", "conflitos_situacao")}})
    old = materialized[uf, folder]
    cases.append({"UF": uf, "pasta": folder,
        "HHOLDA_literal_cartoes": classify(rawfs, uf, "situacao", "municipio"),
        "indice127_atual_cartoes": classify(fs, uf, "situacao", "municipio"),
        "parquet127_antigo_domicilios": classify(old, uf, "V118", "code_muni_1960"),
        "estratos127_exportados": dict(Counter(r["censobr_estrato"] for r in old)),
        "raw25_cartoes_mesma_pasta": classify(fs25, uf, "situacao", "municipio"),
        "raw25_pasta_renumerada_documentada": classify([f for k, v in source25.items() if k[:2] == (14, 14990)
                                                        for f in v["familias"]], uf, "situacao", "municipio") if folder == 15004 else None,
        "legado25_domicilios": classify(legacy[uf, folder], uf, "v118", "v116"),
        "legado25_pasta_renumerada_documentada": classify(legacy[14, 14990], uf, "v118", "v116") if folder == 15004 else None,
        "parquet25_bruto_atual_domicilios": classify(raw25_materialized[uf, folder], uf, "V118", "code_muni_1960"),
        "cartoes_recuperados_ja_aprovados": [r for r in recovered if int(r["UF"]) == uf and int(r["pasta"]) == folder],
        "resumo_pareamentos24": {"cartoes127": len(fs), "sem_par": sum(not p["correspondencias24"] for p in allmatches),
             "par_unico_nas_pastas_examinadas": sum(len(p["correspondencias24"]) == 1 for p in allmatches),
             "por_pasta25": dict(Counter(str(m["chave25"][1]) for p in allmatches for m in p["correspondencias24"])),
             "corpo15_geografia_distrito_exatos": sum(not m["divergencias_familiares"] and
                  m["cartao25"]["distrito"] == next(f["distrito"] for f in fs if f["linha"] == p["cartao127"])
                  for p in allmatches for m in p["correspondencias24"])},
        "domicilios127_nominais": old, "cartoes_decisivos": selected, "todos_pareamentos24": allmatches})
conn.close()
result = {"pastas": cases, "raw25_linhas_percorridas": source_lines,
    "fontes": [{"arquivo": p, "sha256": hash_file(ROOT / p)} for p in sorted(tracked)],
    "rss_bytes": psutil.Process().memory_info().rss,
    "limite": "Classificacao recontada; nao identifica desenho nem escolhe geografia verdadeira. Pareamentos24 preservam V216 e nao sao prova isolada de identidade."}
(OUT / "conferencia.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
# Produtos novos de auditoria; nenhum manifesto consumido pelo pipeline e alterado.
portable = ROOT / "references/fechamento_integral_1960_evidencias"
nominal_causes = {
    15004: "Comparacao numerica 15004-15004 inadequada sem crosswalk;145 pares com corpo/geografia exatos correspondem a14990 rural. UPA127 preservada.",
    15290: "Cinco cartoes urbanos127 versus rurais25; geografia pessoal interna divergente. Identidade nao decide V118 verdadeiro.",
    43234: "Um cartao rural127 versus urbano25; chefe e corpo domiciliar diferem e quatro pessoas127 trazem situacao urbana.",
    60158: "Um cartao rural127, municipio7234 invalido naUF60, versus urbano6234 na25. Identidade pessoal exata nao decide V118 ou tres quesitos domiciliares.",
    60718: "Um cartao rural127 versus urbano25; tres pessoas exatas25, duas com situacao urbana127. Conflito legivel sem direcao demonstrada."
}
index = {"versao": 1, "data": "2026-09-23", "escopo": "Cinco pastas, sem R ou alteracao de dados/estratos/pesos.",
         "fontes": result["fontes"], "pastas": [],
         "comando": "python references/fechamento_integral_1960_duplicatas_pastas.py",
         "limite": result["limite"], "rss_bytes": result["rss_bytes"]}
for case in cases:
    name = f"pasta_desenho_{case['UF']}_{case['pasta']}.json"
    item = {"data": "2026-09-23", "causa": nominal_causes[case["pasta"]],
            "decisao": "Nenhum reparo de V118 autorizado; nenhum estrato, UPA, ID ou fracao alterado.",
            "fontes": result["fontes"], "evidencia": case,
            "raw25_linhas_percorridas": source_lines, "limite": result["limite"]}
    (portable / name).write_text(json.dumps(item, ensure_ascii=False, indent=2), encoding="utf-8")
    index["pastas"].append({"UF": case["UF"], "pasta": case["pasta"], "causa": nominal_causes[case["pasta"]],
          "arquivo": "references/fechamento_integral_1960_evidencias/" + name,
          "sha256": hash_file(portable / name)})
(portable / "pastas_desenho.json").write_text(json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
for c in cases:
    print(json.dumps({k: v for k, v in c.items() if k not in {"domicilios127_nominais", "cartoes_decisivos", "todos_pareamentos24"}}, ensure_ascii=True))
