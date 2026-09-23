"""Compara multiconjuntos por ID sem supor ordem individual nem desempatar iguais."""
import csv
import hashlib
import itertools
import json
from collections import Counter, defaultdict
from pathlib import Path

import psutil
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/fonte_cem/auditoria_integral"
RAW = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
CEM = ROOT / "tmp/fechamento_integral_1960/fonte_cem/leitura_sav/cem_original.parquet"
INV = ROOT / "references/resolucao_residuais_1960_evidencias/inventario_atual.json"
inventory = json.loads(INV.read_text(encoding="utf-8"))
groups = inventory["duplicatas_pendentes"]
categories = {
    "orfaos": {r["linha"] for r in inventory["vinculos_pendentes"]},
    "conflitos": {r["linha"] for k in ["conflitos_municipais", "conflitos_situacao"] for r in inventory[k]},
    "fragmentos": {r["linha"] for r in inventory["corrompidas_sem_grupo_identificavel"]},
    "danos": {760807, 760919, 760923, 760925, 761056, 761057, 761058, 806791, 806800, 806801},
    "duplicatas": {line for group in groups for line in group["linhas"]},
}
targets = set.union(*categories.values())
columns = pq.ParquetFile(CEM).schema.names
personal, household = columns[:30], columns[30:]
with (ROOT / "read_guides/readguide_1960_amostra_127_pessoas.csv").open(encoding="utf-8-sig", newline="") as stream:
    guide = {r["variavel"]: (int(r["inicio"])-1, int(r["fim"])) for r in csv.DictReader(stream)}
mapping = {name: name for name in personal}
mapping.update(STATE="UF", RECD="REC_TYPE", RURURBP="V118")
slices = [slice(*guide[mapping[name]]) for name in personal]
slices[personal.index("V210")] = slice(30, 31)
observed_numeric_coercions = []


def number(value):
    try:
        result = float(value)
        return result if result == result else None
    except ValueError:
        return None


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def raw_people():
    previous = None
    with RAW.open(encoding="latin1") as stream:
        for line, raw in enumerate(stream, 1):
            text = raw.rstrip("\r\n")
            if text[16] == "1":
                previous = line
                continue
            values = [number(text[part]) for part in slices]
            # Duas diferencas observadas na primeira passagem por multiconjuntos.
            # Nao e reparo de resposta: CEM apenas retira o hifen do campo literal.
            if text[46:49].strip() in {"4-", "34-"}:
                before = text[46:49]
                values[personal.index("V221")] = number(before.strip().rstrip("-"))
                observed_numeric_coercions.append({"linha_raw": line, "campo": "V221", "texto_raw": before, "valor_CEM": values[personal.index("V221")]})
            profile = tuple(values)
            yield profile[-1], line, profile, text, previous


def cem_people():
    count = 0
    for batch in pq.ParquetFile(CEM).iter_batches(batch_size=8192, columns=columns, use_threads=False):
        for values in batch.to_pandas().to_numpy():
            count += 1
            profile = tuple(number(v) for v in values)
            yield profile[29], count, profile[:30], profile[30:]


counts = Counter()
unmatched = []
affected = []
target_profiles = {}
reordered_examples = []
peak = 0
before = {str(path.relative_to(ROOT)): sha(path) for path in [RAW, CEM, INV]}
raw_groups = itertools.groupby(raw_people(), lambda r: r[0])
cem_groups = itertools.groupby(cem_people(), lambda r: r[0])
for raw_group, cem_group in itertools.zip_longest(raw_groups, cem_groups):
    assert raw_group is not None and cem_group is not None
    raw_id, rows_raw = raw_group
    cem_id, rows_cem = cem_group
    assert raw_id == cem_id, (raw_id, cem_id)
    rows_raw, rows_cem = list(rows_raw), list(rows_cem)
    assert len(rows_raw) == len(rows_cem)
    counts["blocos_ID"] += 1
    counts["pessoas"] += len(rows_raw)
    counts["pessoas_V210_1col_diferente_layout2col"] += sum(number(r[3][30:32]) != r[2][personal.index("V210")] for r in rows_raw)
    raw_profiles, cem_profiles = defaultdict(list), defaultdict(list)
    for _, line, profile, text, previous in rows_raw:
        raw_profiles[profile].append((line, text, previous))
    for _, row, profile, house in rows_cem:
        cem_profiles[profile].append((row, house))
    counter_raw = Counter({k: len(v) for k,v in raw_profiles.items()})
    counter_cem = Counter({k: len(v) for k,v in cem_profiles.items()})
    same = counter_raw == counter_cem
    counts["blocos_multiconjunto_30campos_exato"] += same
    counts["pessoas_em_blocos_multiconjunto_exato"] += len(rows_raw) * same
    house_profiles = {r[3] for r in rows_cem}
    counts["blocos_domicilio_unico"] += len(house_profiles) == 1
    counts["blocos_com_ordem_diferente"] += [r[2] for r in rows_raw] != [r[2] for r in rows_cem]
    if not same:
        unmatched.append({"ID": raw_id,
                          "apenas_raw": [{"campos": dict(zip(personal,k)), "n": n, "linhas": raw_profiles[k]} for k,n in (counter_raw-counter_cem).items()],
                          "apenas_cem": [{"campos": dict(zip(personal,k)), "n": n, "linhas": cem_profiles[k]} for k,n in (counter_cem-counter_raw).items()]})
    if len(reordered_examples) < 5 and [r[2] for r in rows_raw] != [r[2] for r in rows_cem]:
        reordered_examples.append({"ID": raw_id, "raw": [{"linha": r[1], "idade": r[2][7]} for r in rows_raw],
                                  "cem": [{"linha": r[1], "idade": r[2][7]} for r in rows_cem]})
    for profile, raw_matches in raw_profiles.items():
        cem_matches = cem_profiles.get(profile, [])
        if len(raw_matches) > 1:
            counts["perfis_com_multiplos_raw"] += 1
            counts["pessoas_em_perfis_multiplos_raw"] += len(raw_matches)
        for line, text, previous in raw_matches:
            if line not in targets:
                continue
            cem_houses = {match[1] for match in cem_matches}
            affected.append({"linha_raw": line, "ID": raw_id, "texto_raw": text,
                             "classes": [name for name, members in categories.items() if line in members],
                             "cartao_fisico_raw": previous,
                             "perfil30_pessoal_raw_spss": dict(zip(personal, profile)),
                             "linhas_raw_igualmente_compativeis": [r[0] for r in raw_matches],
                             "linhas_cem_compativeis": [r[0] for r in cem_matches],
                             "perfis_domiciliares_cem": [dict(zip(household,h)) for h in cem_houses],
                             "multiplicidade_preservada": len(raw_matches) == len(cem_matches)})
            target_profiles[line] = (profile, cem_houses, [r[0] for r in cem_matches])
    peak = max(peak, psutil.Process().memory_info().rss)
    if peak >= 2 * 1024**3:
        raise MemoryError("Auditoria CEM excedeu 2 GiB")
    if counts["blocos_ID"] % 20000 == 0:
        print(json.dumps(dict(counts)), flush=True)

assert {r["linha_raw"] for r in affected} == targets
duplicates = []
for group in groups:
    profiles = [target_profiles[line] for line in group["linhas"]]
    duplicates.append({**group,
                       "perfis_pessoais_CEM_distintos": len({p[0] for p in profiles}),
                       "perfis_domiciliares_CEM_distintos": len(set.union(*(p[1] for p in profiles))),
                       "linhas_CEM_compativeis": sorted(set.union(*(set(p[2]) for p in profiles)))})
result = {"contagens": dict(counts), "blocos_sem_pareamento_integral": unmatched,
          "coercoes_numericas_observadas": observed_numeric_coercions,
          "exemplos_reordenacao": reordered_examples, "pico_rss_bytes": peak,
          "cobertura": {name: len(lines) for name, lines in categories.items()},
          "fontes_sha256": before}
result["resultados_por_classe"] = {name: {"registros": len(lines),
    "registros_com_correspondencia_30campos": sum(bool(r["linhas_cem_compativeis"]) for r in affected if name in r["classes"]),
    "registros_com_multiplicidade_preservada": sum(r["multiplicidade_preservada"] for r in affected if name in r["classes"])} for name,lines in categories.items()}
for path_name, artifact in [("pareamento_integral.json", result), ("residuos_pareados.json", affected), ("duplicatas458_pareadas.json", duplicates)]:
    (OUT/path_name).write_text(json.dumps(artifact, ensure_ascii=False, indent=2), encoding="utf-8")
for name, signature in before.items():
    assert sha(ROOT/name) == signature
print(json.dumps({"contagens": dict(counts), "sem_pareamento": len(unmatched), "pico_rss_bytes": peak}, ensure_ascii=False))
