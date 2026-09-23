"""Conferencia independente, somente leitura, de T7 nas 17 UFs de 25%."""
import gc
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import pandas as pd
import psutil
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--index", required=True, type=Path)
parser.add_argument("--report", required=True, type=Path)
parser.add_argument("--out", required=True, type=Path)
parser.add_argument("--require-limits", action="store_true")
args = parser.parse_args()
OUT = args.out.resolve()
OUT.mkdir(parents=True, exist_ok=False)
INDEX = args.index.resolve()
REPORT = args.report.resolve()
input_hashes = {str(p): hashlib.file_digest(p.open("rb"), "sha256").hexdigest() for p in [INDEX, REPORT]}
index = json.loads(INDEX.read_text(encoding="utf-8"))
report = pd.read_csv(REPORT)
if args.require_limits:
    assert {"valor_minimo", "valor_maximo"}.issubset(report.columns), "relatorio ainda sem limites T7"
weights = ["censobr_weight", "censobr_weight_ibge"]
summary = []
cells = []
patterns = []
files = []
peak = 0

for uf in index["ufs"]:
    print(uf, flush=True)
    paths = {a["arquivo"]: ROOT / a["caminho"] for a in index["arquivos"] if a["uf"] == uf}
    for path in paths.values():
        digest = hashlib.file_digest(path.open("rb"), "sha256").hexdigest()
        expected = next(a["sha256"] for a in index["arquivos"] if a["uf"] == uf and a["arquivo"] == path.name)
        assert digest == expected, (uf, path.name, "arquivo diverge do indice aprovado")
        files.append({"path": str(path.relative_to(ROOT)), "sha256": digest})
    cols = ["UF", "censobr_idhousehold", "linha", "V101", "V102", "V103", "V104", "V118", "censobr_tipo_unidade", "censobr_variaveis_anuladas"] + weights
    d = pq.read_table(paths["domicilios_pesos.parquet"], columns=cols, use_threads=False).to_pandas()
    d.sort_values("censobr_idhousehold", inplace=True)
    d.reset_index(drop=True, inplace=True)
    assert d.censobr_idhousehold.notna().all() and d.censobr_idhousehold.is_unique
    ids = d.censobr_idhousehold.to_numpy()
    size = len(ids)
    count = np.zeros((3, size), dtype=np.int64)
    person_sums = np.zeros((2, size), dtype=np.float64)
    orphan = 0
    persons = 0
    pcols = ["censobr_idhousehold", "V202"] + weights
    for batch in pq.ParquetFile(paths["pessoas_pesos.parquet"]).iter_batches(batch_size=65536, columns=pcols, use_threads=False):
        p = batch.to_pandas()
        loc = np.searchsorted(ids, p.censobr_idhousehold.to_numpy())
        found = loc < size
        found[found] &= ids[loc[found]] == p.censobr_idhousehold.to_numpy()[found]
        orphan += int((~found & (~p.V202.isin([5, 6]))).sum())
        assert found.all(), (uf, "pessoa sem domicilio")
        resident = p.V202.isin([1, 2, 3, 4]).to_numpy()
        uncertain = ~p.V202.isin([1, 2, 3, 4, 5, 6]).to_numpy()
        count[0] += np.bincount(loc, minlength=size)
        count[1] += np.bincount(loc[resident], minlength=size)
        count[2] += np.bincount(loc[uncertain], minlength=size)
        for j, weight in enumerate(weights):
            assert np.isfinite(p[weight]).all()
            person_sums[j] += np.bincount(loc[resident], weights=p[weight].to_numpy()[resident], minlength=size)
        persons += len(p)
        peak = max(peak, psutil.Process().memory_info().rss)
        assert peak < 2 * 1024**3
    assert not count[2].sum(), (uf, "presenca incerta requer logica adicional")
    d["n_lista"] = count[0]
    d["n_residentes"] = count[1]
    d["n_presenca_incerta"] = count[2]
    part = d.V101.isin([1, 2, 4, 5])
    part_u = ~d.V101.isin([1, 2, 3, 4, 5, 9])
    perm = d.V102.isin([4, 5])
    perm_u = ~d.V102.isin([4, 5, 6])
    occupied = d.n_residentes.gt(0)
    definite = part & perm & occupied
    possible = (part | part_u) & (perm | perm_u) & (occupied | d.n_lista.eq(0))
    unknown = possible & ~definite
    uf60 = int(d.UF.iloc[0])
    row = {"uf": uf, "uf60": uf60, "domicilios": size, "pessoas": persons,
           "domicilios_sem_lista": int(d.n_lista.eq(0).sum()), "pessoas_sem_domicilio": orphan,
           "t7_domicilios_incerto": int(unknown.sum()), "t7_residentes_incerto": int(d.n_residentes[unknown].sum()),
           "t7_v101_incerto": int((unknown & part_u).sum()), "t7_v102_incerto": int((unknown & perm_u).sum()),
           "t7_celulas_incompletas_por_peso": 0,
           "q6_alugados_ignorados": int((part & occupied & d.V103.eq(8) & d.V104.eq(9)).sum()),
           "q6_alugados_sem_classificacao": int((part & occupied & d.V103.eq(8) & ~d.V104.isin([0, 1, 2, 3, 4, 5, 6, 7, 9])).sum())}
    trouble = d.loc[unknown].copy()
    for keys, sub in trouble.groupby(["V101", "V102", "V118", "censobr_tipo_unidade", "censobr_variaveis_anuladas"], dropna=False):
        patterns.append({"uf": uf, **{name: None if pd.isna(value) else value for name, value in zip(["V101", "V102", "V118", "tipo", "anuladas"], keys)},
                         "domicilios": len(sub), "residentes": int(sub.n_residentes.sum())})
    trouble.to_csv(OUT / f"t7_registros_incerto_{uf}.csv", index=False)
    for item in ["total", "urbana", "rural"]:
        selected = pd.Series(True, index=d.index) if item == "total" else d.V118.isin([1, 3] if item == "urbana" else [5])
        assert d.V118.isin([1, 3, 5]).all()
        known = definite & selected
        pending = unknown & selected
        for measure in ["domicilios", "pessoas"]:
            for j, weight in enumerate(weights):
                nr = int(pending.sum()) if measure == "domicilios" else int(d.n_residentes[pending].sum())
                nk = int(known.sum()) if measure == "domicilios" else int(d.n_residentes[known].sum())
                val = float(d.loc[known, weight].sum()) if measure == "domicilios" else float(person_sums[j, known].sum())
                missing_weight = float(d.loc[pending, weight].sum()) if measure == "domicilios" else float(person_sums[j, pending].sum())
                ref = report[(report.uf60 == uf60) & (report.tabela == 7) & (report.item == item) & (report.medida == measure) & (report.peso == weight)]
                assert len(ref) == 1, (uf, measure, item, list(report.medida.unique()))
                r = ref.iloc[0]
                assert nr == r.n_sem_classificacao and nk == r.n_amostra, (uf, item, measure, nr, r.n_sem_classificacao)
                assert abs(val - r.valor_parcial) < 1e-6
                assert abs(missing_weight - r.peso_sem_classificacao) < 1e-6
                if "valor_minimo" in report.columns:
                    assert abs(val-r.valor_minimo) < 1e-6
                if "valor_maximo" in report.columns:
                    assert abs(val+missing_weight-r.valor_maximo) < 1e-6
                expected_status = "classificacao_incompleta" if nr else ("observada" if nk else "sem_observacoes")
                assert r.status_celula == expected_status, (uf, item, measure, r.status_celula)
                if nr and j == 0:
                    row["t7_celulas_incompletas_por_peso"] += 1
                cells.append({"uf": uf, "item": item, "medida": measure, "peso": weight, "n_amostra": nk, "n_sem_classificacao": nr,
                              "valor_parcial": val, "peso_sem_classificacao": missing_weight, "publicado": float(r.publicado),
                              "status": r.status_celula, "valor_minimo": val, "valor_maximo": val + missing_weight,
                              "diferenca_relativa_min_pct": 100 * (val / r.publicado - 1) if r.publicado else None,
                              "diferenca_relativa_max_pct": 100 * ((val + missing_weight) / r.publicado - 1) if r.publicado else None})
    summary.append(row)
    del d, p, trouble, count, person_sums
    gc.collect()

pd.DataFrame(summary).to_csv(OUT / "t7_resumo_17ufs.csv", index=False)
pd.DataFrame(patterns).to_csv(OUT / "t7_padrao_codigos.csv", index=False)
pd.DataFrame(cells).to_csv(OUT / "t7_celulas_17ufs.csv", index=False)
for entry in files:
    after = hashlib.file_digest((ROOT / entry["path"]).open("rb"), "sha256").hexdigest()
    assert after == entry["sha256"], entry["path"]
    entry["inalterado_apos_conferencia"] = True
assert all(hashlib.file_digest(Path(p).open("rb"), "sha256").hexdigest() == signature for p,signature in input_hashes.items())
result = {"status": "CONFERIDO_SEM_ALTERAR_DADOS", "peak_rss_bytes": peak, "ufs": summary,
          "indice": str(INDEX.relative_to(ROOT)), "relatorio": str(REPORT.relative_to(ROOT)),
          "assinaturas_indice_e_relatorio_antes_depois": input_hashes,
          "t7_celulas_incompletas_por_peso": sum(r["t7_celulas_incompletas_por_peso"] for r in summary),
          "domicilios_incerto": sum(r["t7_domicilios_incerto"] for r in summary),
          "residentes_incerto": sum(r["t7_residentes_incerto"] for r in summary),
          "arquivos": files}
(OUT / "t7_resultado.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps({k: v for k, v in result.items() if k not in ["ufs", "arquivos"]}, ensure_ascii=False))
