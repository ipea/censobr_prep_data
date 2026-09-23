"""Compara integralmente CEM com os campos literais de HHOLDA, em ordem testada."""
import csv
import hashlib
import itertools
import json
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
import psutil
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/fonte_cem/auditoria_integral"
OUT.mkdir(parents=True, exist_ok=True)
RAW = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
CEM = ROOT / "tmp/fechamento_integral_1960/fonte_cem/leitura_sav/cem_original.parquet"
SAV = ROOT / "tmp/fechamento_integral_1960/fonte_cem/copia_sav/Censo.1960.brasil.amostra.1.25porcento.sav"
INV = ROOT / "references/resolucao_residuais_1960_evidencias/inventario_atual.json"
inventory = json.loads(INV.read_text(encoding="utf-8"))
groups = inventory["duplicatas_pendentes"]
pending = {r["linha"] for r in inventory["vinculos_pendentes"]}
conflicts = {r["linha"] for k in ["conflitos_municipais", "conflitos_situacao"] for r in inventory[k]}
fragments = {r["linha"] for r in inventory["corrompidas_sem_grupo_identificavel"]}
damage = {760807, 760919, 760923, 760925, 761056, 761057, 761058, 806791, 806800, 806801}
duplicates = {line for g in groups for line in g["linhas"]}
target = pending | conflicts | fragments | damage | duplicates


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def numeric(text):
    try:
        return float(text.strip())
    except ValueError:
        return np.nan


def portable(value):
    if isinstance(value, float) and not np.isfinite(value):
        return None
    if isinstance(value, np.generic):
        return portable(value.item())
    return value


guides = {}
for name in ["pessoas", "familias"]:
    with (ROOT / f"read_guides/readguide_1960_amostra_127_{name}.csv").open(encoding="utf-8-sig", newline="") as stream:
        guides[name] = {r["variavel"]: (int(r["inicio"]) - 1, int(r["fim"])) for r in csv.DictReader(stream)}
mapping = {name: name for name in pq.ParquetFile(CEM).schema.names[:30]}
mapping.update(STATE="UF", RECD="REC_TYPE", RURURBP="V118")
personal = list(mapping)
household = ["RURURB"] + [f"V{n}" for n in range(101, 114)]
housemap = {name: ("V118" if name == "RURURB" else name) for name in household}
hashes = {str(p.relative_to(ROOT)): sha(p) for p in [RAW, CEM, SAV, INV]}
counts = Counter()
column_counts = Counter()
v210_cases = Counter()
examples = defaultdict(list)
affected = []
all_mismatch_rows = []
cards = {}
duplicate_card_ids = Counter()

# A familia fisica e somente uma hipotese a conferir, nunca vinculo aprovado.
def raw_people():
    previous = None
    with RAW.open("r", encoding="latin1", newline="") as stream:
        for line, raw in enumerate(stream, 1):
            text = raw.rstrip("\r\n")
            assert len(text) == 62
            counts["linhas_raw"] += 1
            if text[16] == "1":
                previous = (line, text)
                ident = numeric(text[55:62])
                if np.isfinite(ident):
                    duplicate_card_ids[ident] += 1
                    cards.setdefault(ident, []).append((line, text))
                counts["cartoes_raw"] += 1
            else:
                yield line, text, previous


people = raw_people()
row_cem = 0
peak = 0
last_card_line = None
last_household = np.full(len(household), np.nan)
for batch in pq.ParquetFile(CEM).iter_batches(batch_size=8192, use_threads=False):
    data = batch.to_pandas()
    all_cem = data.to_numpy()
    actual_households = data[household].to_numpy()
    actual_ids = data["ID"].to_numpy()
    source = list(itertools.islice(people, len(data)))
    assert len(source) == len(data), "CEM tem mais linhas pessoais que HHOLDA"
    original = np.array([[numeric(text[slice(*guides["pessoas"][mapping[name]])]) for name in personal] for _, text, _ in source])
    original_spss = original.copy()
    original_spss[:, personal.index("V210")] = [numeric(text[30:31]) for _, text, _ in source]
    cem = data[personal].to_numpy()
    same = (cem == original) | (np.isnan(cem) & np.isnan(original))
    same_spss = (cem == original_spss) | (np.isnan(cem) & np.isnan(original_spss))
    for j, name in enumerate(personal):
        column_counts[name] += int((~same[:, j]).sum())
        for i in np.flatnonzero(~same[:, j])[:5]:
            if len(examples[name]) < 5:
                examples[name].append({"linha_raw": source[i][0], "linha_cem": row_cem + int(i) + 1,
                                       "raw_valor": portable(original[i, j]), "cem_valor": portable(cem[i, j]),
                                       "raw_texto": source[i][1]})
    counts["pessoas_com_30_campos_iguais_layout_integral"] += int(same.all(axis=1).sum())
    counts["pessoas_com_30_campos_iguais_layout_spss_V210_1coluna"] += int(same_spss.all(axis=1).sum())
    counts["pessoas_cem"] += len(data)
    columns_without210 = [j for j, name in enumerate(personal) if name != "V210"]
    counts["pessoas_com_29_campos_iguais_exceto_V210"] += int(same[:, columns_without210].all(axis=1).sum())
    for i, (line, text, previous) in enumerate(source):
        if not same_spss[i].all():
            mismatch = {name: {"raw": portable(original_spss[i, j]), "cem": portable(cem[i, j])}
                        for j, name in enumerate(personal) if not same_spss[i, j]}
            all_mismatch_rows.append({"linha_raw": line, "linha_cem": row_cem + i + 1, "texto_raw": text, "diferencas": mismatch})
        if previous is not None:
            card_line, card_text = previous
            if card_line != last_card_line:
                last_household = np.array([numeric(card_text[slice(*guides["familias"][housemap[name]])]) for name in household])
                last_card_line = card_line
            h = last_household
            actual = actual_households[i]
            equal = (h == actual) | (np.isnan(h) & np.isnan(actual))
            counts["domicilio_14campos_igual_cartao_fisico_anterior"] += int(equal.all())
            ident = portable(float(actual_ids[i]))
            counts["id_cem_igual_id_cartao_fisico_anterior"] += int(ident is not None and ident == numeric(card_text[55:62]))
        else:
            h = np.full(len(household), np.nan)
            actual = actual_households[i]
            equal = np.isnan(actual)
            card_line = None
        if not equal.all() or line in target:
            if line in target:
                affected.append({"linha_raw": line, "linha_cem": row_cem + i + 1, "texto_raw": text,
                  "classes": [name for name, members in [("orfao", pending), ("conflito", conflicts), ("fragmento", fragments), ("dano", damage), ("duplicata", duplicates)] if line in members],
                  "campos_cem": {name: portable(float(all_cem[i, j])) for j, name in enumerate(data.columns)},
                  "pessoais_iguais_raw_spss": bool(same_spss[i].all()), "cartao_fisico_anterior": card_line,
                  "domiciliares_iguais_cartao_fisico": bool(equal.all()),
                  "diferencas_domiciliares": {name: {"raw_fisico": portable(h[j]), "cem": portable(actual[j])} for j, name in enumerate(household) if not equal[j]}})
            if not equal.all():
                counts["domicilio_diverge_cartao_fisico"] += 1
                if len(examples["domicilio_diverge_cartao_fisico"]) < 30:
                    examples["domicilio_diverge_cartao_fisico"].append({"linha_raw": line, "linha_cem": row_cem+i+1, "cartao_fisico": card_line})
    row_cem += len(data)
    peak = max(peak, psutil.Process().memory_info().rss)
    if peak >= 2 * 1024**3:
        raise MemoryError("Auditoria CEM excedeu 2 GiB")
    if row_cem % 81920 == 0:
        print(row_cem, flush=True)

assert next(people, None) is None, "HHOLDA tem mais pessoas que CEM"
assert {r["linha_raw"] for r in affected} == target
result = {"contagens": dict(counts), "diferenças_por_campo_layout_integral": dict(column_counts),
          "exemplos": dict(examples), "diferencas_layout_spss": all_mismatch_rows,
          "cobertura": {"orfaos": len(pending), "conflitos": len(conflicts), "fragmentos": len(fragments), "danos": len(damage), "duplicatas_grupos": len(groups), "duplicatas_linhas": len(duplicates), "uniao": len(target)},
          "pico_rss_bytes": peak, "cartoes_ID_repetido": {str(k): v for k, v in duplicate_card_ids.items() if v > 1},
          "fontes_sha256": hashes}
(OUT / "comparacao_integral.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
(OUT / "registros_pendentes_cem.json").write_text(json.dumps(affected, ensure_ascii=False, indent=2), encoding="utf-8")
(OUT / "cartoes_raw_por_id.json").write_text(json.dumps({str(int(k)): v for k,v in cards.items()}, ensure_ascii=False), encoding="utf-8")
for name, before in hashes.items():
    assert sha(ROOT / name) == before, name
print(json.dumps({"contagens": dict(counts), "diferencas": dict(column_counts), "pico_rss_bytes": peak}, ensure_ascii=False))
