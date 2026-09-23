"""QC somente leitura, por UF/lotes, sem R e sem concatenacao nacional."""
from pathlib import Path
import csv
import argparse
import hashlib
import psutil
import gc
import json
import math
import sys
import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument("--partial-run", required=True, type=Path)
PARSER.add_argument("--out", required=True, type=Path)
PARSER.add_argument("--uf", choices=["mg", "sp", "mt", "pr"], default="pr")
ARGS = PARSER.parse_args()
RED = ARGS.partial_run.resolve()
OUT = ARGS.out.resolve()
GUIDE = ROOT / "read_guides/1960_municipios.csv"
DEFINITIVE = ROOT / "references/censo_1960_resultados_definitivos_serie_nacional.csv"
UF = dict(al=25, ba=31, ce=14, df=97, fn=24, go=94, mg=40, mt=91,
          pb=19, pe=21, pr=71, rj=52, rn=17, rs=81, sa=50, se=30, sp=60)
W = ["censobr_weight", "censobr_weight_ibge", "censobr_weight_desenho", "censobr_weight_fator"]
DK = ["UF", "censobr_idhousehold"]
PK = DK + ["linha"]
PCLASS = ["V202", "V204", "V204B", "V211", "V118", "code_muni_1960"]
BATCH = 131072
pa.set_cpu_count(1)
pa.set_io_thread_count(1)


def array(table, name):
    col = table[name]
    assert col.null_count == 0, (name, "ausente")
    return col.to_numpy(zero_copy_only=False)


def check_weights(table):
    vals = {name: array(table, name) for name in W}
    for name, values in vals.items():
        assert np.all(np.isfinite(values) & (values > 0)), (name, "nao positivo/finito")
    assert np.all((vals[W[0]] >= 1-1e-10) & (vals[W[0]] <= 12+1e-10)), "peso fora [1,12]"
    assert np.all(vals[W[2]] == 4), "base diferente de 4"
    assert np.array_equal(vals[W[0]] / 4, vals[W[3]]), "fator incoerente"
    return vals


def file_hash(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024*1024), b""):
            digest.update(block)
    return digest.hexdigest()


def reconstruct_targets(uf, source_d, controls):
    """Reconstrucao dos alvos a partir do guia, definitivos e suporte D bruto.

    Nao usa os alvos publicados para decidir colapsos, escala ou celula omitida.
    A ordem da primeira aparicao no arquivo preserva o desempate de which.min.
    """
    guide = [r for r in csv.DictReader(GUIDE.open(encoding="utf-8-sig")) if int(r["uf60"]) == UF[uf]]
    by_code = {int(r["cod60"]): r for r in guide}
    assert len(by_code) == len(guide), "municipio duplicado no guia da UF"
    def value(raw):
        return float(raw) if raw else float("nan")
    universes = {}
    for code, row in by_code.items():
        nums = [value(row[f]) for f in ["pop_total", "pop_urbana", "pop_rural"]]
        assert all(np.isnan(n) or (np.isfinite(n) and n >= 0) for n in nums)
        if all(np.isfinite(nums)):
            assert nums[0] == nums[1]+nums[2], (code, "soma inconsistente no guia")
        universes[code] = nums[1:]
    definite = [r for r in csv.DictReader(DEFINITIVE.open(encoding="utf-8-sig"))
                if r["nivel"] == "uf" and r["uf60"] == str(UF[uf])]
    assert len({tuple(r[f] for f in ["tabela", "uf60", "item", "sexo", "medida"]) for r in definite}) == len(definite)
    present = [r for r in definite if r["tabela"] == "32" and r["item"] == "presente" and r["sexo"] in ["homens", "mulheres"]]
    assert len(present) == 2
    state_target = sum(float(r["valor"]) for r in present)
    assert np.isfinite(state_target) and state_target > 0
    muni = array(source_d, "code_muni_1960").astype(np.int64)
    rural = array(source_d, "V118") == 5
    n_present = array(source_d, "censobr_n_presentes")
    assert np.all(n_present >= 0) and np.all(n_present == np.floor(n_present))
    groups, first, inverse = np.unique(muni*2+rural, return_index=True, return_inverse=True)
    amounts = np.bincount(inverse, weights=n_present)
    order = np.argsort(first)
    cells = [(int(groups[i])//2, int(groups[i])%2, float(amounts[i])) for i in order]
    sample_sits = {code: sum(c == code for c, _, _ in cells) for code in np.unique(muni)}
    collapse_reasons = {}
    for code, sit, count in cells:
        uv = universes.get(code, [float("nan"), float("nan")])
        target = uv[sit]
        ratio = target/count if count else (float("nan") if np.isnan(target) or target == 0 else float("inf"))
        reasons = []
        if np.isnan(ratio): reasons.append("fator_ausente")
        if target < 100: reasons.append("universo_menor_100")
        if ratio < 2 or ratio > 8: reasons.append("fator_fora_2_8")
        if sample_sits[code] < sum(np.isfinite(v) and v > 0 for v in uv): reasons.append("situacao_sem_amostra")
        if reasons:
            collapse_reasons.setdefault(code, []).append({"situacao": ["urbana", "rural"][sit], "motivos": reasons})
    m1_raw = {}
    without = []
    for code, sit, _ in cells:
        uv = universes.get(code, [float("nan"), float("nan")])
        collapsed = code in collapse_reasons
        target = float(np.nansum(uv)) if collapsed and code in universes else uv[sit]
        name = "mun_" + str(code) + ("" if collapsed else "_"+["urbana", "rural"][sit])
        if not np.isfinite(target) or target <= 0:
            without.append({"municipio": code, "situacao": ["urbana", "rural"][sit]})
            continue
        if name in m1_raw: assert m1_raw[name] == target
        m1_raw[name] = target
    denominator = sum(m1_raw.values())
    assert denominator > 0
    m1 = {name: raw*state_target/denominator for name, raw in m1_raw.items()}
    removed = min(m1, key=m1.get)
    m2 = {"sx_"+r["sexo"]+"_"+r["item"]: float(r["valor"]) for r in definite
          if r["tabela"] == "33" and r["sexo"] in ["homens", "mulheres"] and r["item"] not in ["total", "ignorada"]}
    sex_only = len(source_d) < 40*(len(m1)+len(m2))
    if sex_only:
        m2 = {"sx_"+r["sexo"]: float(r["valor"]) for r in present}
    m3 = {"lit_"+r["sexo"]: float(r["valor"]) for r in definite
          if r["tabela"] == "40" and r["item"] == "sabem" and r["sexo"] in ["homens", "mulheres"]}
    expected = {**{name:v for name,v in m1.items() if name != removed}, **m2, **m3}
    assert len(expected) == len(m1)-1+len(m2)+len(m3)
    assert all(np.isfinite(v) and v >= 0 for v in expected.values())
    expected = {name:v for name,v in expected.items() if v > 0}
    actual = {r["celula"]: float(r["alvo"]) for r in controls}
    assert set(actual) == set(expected), {"alvos_faltam": sorted(set(expected)-set(actual)), "alvos_sobram": sorted(set(actual)-set(expected))}
    diffs = {name: abs(actual[name]-value) for name, value in expected.items()}
    assert all(np.isclose(actual[name], value, rtol=1e-12, atol=1e-7) for name, value in expected.items()), {"alvos_divergentes": {name:{"atual":actual[name], "esperado":value} for name,value in expected.items() if not np.isclose(actual[name],value,rtol=1e-12,atol=1e-7)}}
    totals = {sit: sum(uv[i] for uv in universes.values() if np.isfinite(uv[i])) for i,sit in enumerate(["urbana", "rural"])}
    return {"guia_sha256":file_hash(GUIDE), "definitivos_sha256":file_hash(DEFINITIVE),
            "municipios_no_guia":len(guide), "municipios_na_amostra":len(np.unique(muni)),
            "populacao_guia_por_situacao":totals, "populacao_guia_soma_situacoes":sum(totals.values()),
            "denominador_reescala_ancoras_com_suporte":denominator, "total_presente_definitivo":state_target,
            "fator_reescala":state_target/denominator, "municipios_colapsados":collapse_reasons,
            "celulas_sem_ancora":without, "celula_municipal_omitida":removed,
            "alvo_omitido":m1[removed], "margem_sexo_sem_idade":sex_only,
            "numero_controles_reconstruidos":len(expected), "max_diferenca_absoluta_alvo":max(diffs.values()),
            "alvos_reconstruidos":expected}


def audit_ibge(source_d, dom, proof):
    rural = array(source_d, "V118") == 5
    counts = array(source_d, "censobr_n_presentes")
    weights = array(dom, "censobr_weight_ibge")
    assert np.all(weights == np.floor(weights)), "peso IBGE nao inteiro"
    result = {}
    for sit, mask in [("urbana", ~rural), ("rural", rural)]:
        n = counts[mask]
        w = weights[mask]
        assert len(n) and n.sum() > 0
        target = proof["populacao_guia_por_situacao"][sit]
        base = math.floor(target/n.sum())
        assert np.all((w == base) | (w == base+1)), (sit, "peso IBGE fora dos dois inteiros implicitos")
        observed = float(np.sum(n*w))
        residual = target-observed
        assert residual >= 0, (sit, "peso IBGE excede alvo")
        bound = int(n[w == base].max()) if np.any(w == base) else 0
        assert residual == 0 or residual < bound, (sit, "residuo IBGE incompativel com prefixo sorteado")
        result[sit] = {"alvo_atual":target, "presentes":int(n.sum()), "inteiros":[base,base+1],
                       "soma_ponderada":observed, "residuo":residual, "limite_aberto_residuo":bound,
                       "nao_reproduz_rng_R":True}
    return result


def audit(uf):
    status = json.loads((RED / "resultados" / (uf + ".json")).read_text(encoding="utf-8"))
    assert status["status"] == "concluido_auxiliar_parcial" and status["exit_runner"] == 0
    assert not status["hashes_alterados"] and not status["interrupcao_recursos"]
    folder = RED / "pesos_com_chaves" / uf
    diag = RED / "diagnosticos" / uf
    original = ROOT / "data_raw/microdata/1960/amostra_25" / uf
    evidence_paths = [GUIDE, DEFINITIVE, original/"domicilios.parquet", original/"pessoas_geo.parquet",
                      folder/"domicilios_pesos.parquet", folder/"pessoas_pesos.parquet", diag/"controles.csv"]
    initial_hashes = {str(path): file_hash(path) for path in evidence_paths}
    peak_rss = psutil.Process().memory_info().rss
    with (diag / "controles.csv").open(encoding="utf-8-sig", newline="") as stream:
        controls = list(csv.DictReader(stream))
    names = [r["celula"] for r in controls]
    assert len(names) == len(set(names)) > 0
    targets = np.array([float(r["alvo"]) for r in controls])
    before = np.array([float(r["soma_antes"]) for r in controls])
    after = np.array([float(r["soma_depois"]) for r in controls])
    support = np.array([float(r["suporte_pessoas"]) for r in controls])
    support_d = np.array([float(r["suporte_domicilios"]) for r in controls])
    for values in [targets, before, after, support, support_d]:
        assert np.all(np.isfinite(values) & (values > 0)), "controle sem suporte/finito/positivo"
    assert np.all(support_d <= support)
    assert all(r["status"] == "convergente" and r["UF"] == uf for r in controls)
    assert np.all(targets >= support-1e-7) and np.all(targets <= support*12+1e-7)
    reported_residual = (after - targets) / targets
    assert np.max(np.abs(reported_residual)) <= 1e-6
    recorded = np.array([float(r["residuo_relativo_depois"]) for r in controls])
    assert np.max(np.abs(recorded - reported_residual)) < 1e-12
    assert np.allclose([float(r["soma_desenho"]) for r in controls], support*4, rtol=0, atol=0)

    dompath = folder / "domicilios_pesos.parquet"
    pespath = folder / "pessoas_pesos.parquet"
    dom = pq.read_table(dompath, columns=DK+W, use_threads=False)
    source_d = pq.read_table(original / "domicilios.parquet", columns=DK+["censobr_n_presentes", "code_muni_1960", "V118"], use_threads=False)
    municipal_proof = reconstruct_targets(uf, source_d, controls)
    ibge_proof = audit_ibge(source_d, dom, municipal_proof)
    assert dom.select(DK).equals(source_d.select(DK)), "chaves/ordem D mudaram"
    did = array(dom, "censobr_idhousehold")
    assert np.all(array(dom, "UF") == UF[uf])
    assert len(np.unique(did)) == len(did)
    dweights = check_weights(dom)
    order = np.argsort(did)
    ids_sorted = did[order]
    dweights = {name: vals[order] for name, vals in dweights.items()}
    n_d = len(did)
    n_p = pq.read_metadata(pespath).num_rows
    assert n_p == pq.read_metadata(original / "pessoas_geo.parquet").num_rows
    lines = np.empty(n_p, dtype=np.int64)
    direct_present = np.zeros(n_d, dtype=np.int64)
    n_listed = np.zeros(n_d, dtype=np.int64)
    calculated = np.zeros(len(names))
    household_support_seen = np.zeros((len(names), n_d), dtype=bool)
    n_support = np.zeros(len(names), dtype=np.int64)
    lookup = dict(zip(names, range(len(names))))
    edges = np.array([5, 10, 15, 20, 25, 30, 40, 50, 60, 70])
    labels = ["0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29",
              "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais"]
    data_iter = pq.ParquetFile(pespath).iter_batches(batch_size=BATCH, columns=PK+W, use_threads=False)
    original_iter = pq.ParquetFile(original / "pessoas_geo.parquet").iter_batches(batch_size=BATCH, columns=PK+PCLASS, use_threads=False)
    partial_iter = None
    if uf != "fn":
        partial_d = pq.read_table(RED / "saidas_parciais" / uf / dompath.name, columns=DK+W, use_threads=False)
        assert partial_d.equals(dom), "extracao D difere da saida parcial"
        assert pq.read_schema(dompath).names == DK+W and pq.read_schema(pespath).names == PK+W
        partial_iter = pq.ParquetFile(RED / "saidas_parciais" / uf / pespath.name).iter_batches(batch_size=BATCH, columns=PK+W, use_threads=False)
    offset = 0
    for batch in data_iter:
        source = next(original_iter)
        assert batch.select(PK).equals(source.select(PK)), "chaves/ordem P mudaram"
        if partial_iter is not None:
            assert batch.equals(next(partial_iter)), "extracao P difere da saida parcial"
        pw = check_weights(batch)
        pid = array(batch, "censobr_idhousehold")
        positions = np.searchsorted(ids_sorted, pid)
        assert np.all(positions < n_d) and np.array_equal(ids_sorted[positions], pid), "P sem D"
        assert np.all(array(batch, "UF") == UF[uf])
        for name in W:
            assert np.array_equal(pw[name], dweights[name][positions]), (name, "peso P difere D")
        line = array(batch, "linha")
        assert np.all(line > 0)
        lines[offset:offset+len(line)] = line
        offset += len(line)
        p202 = array(source, "V202")
        assert np.all(np.isin(p202, np.arange(1, 7)))
        present = np.isin(p202, [1, 2, 5, 6])
        n_listed += np.bincount(positions, minlength=n_d)
        direct_present += np.bincount(positions[present], minlength=n_d)
        sex = np.where(np.isin(p202, [1, 3, 5]), "homens", "mulheres")
        # V204B pode ser nulo quando V204 e 5/9: nao confundir com idade danificada.
        v204 = source["V204"].to_numpy(zero_copy_only=False)
        v204b = source["V204B"].to_numpy(zero_copy_only=False)
        valid_age = np.isin(v204, [0, 1]) & np.isfinite(v204b) & (v204b >= 0) & (v204b <= 99)
        assert np.all(~present | valid_age | np.isin(v204, [5, 9])), "idade presente danificada"
        age = np.where(v204 == 5, 100, np.where(v204 == 0, 0, v204b))
        eligible_age = (v204 == 9) | ((v204 != 9) & (age >= 5))
        assert np.all(~(present & eligible_age) | np.isin(source["V211"].to_numpy(zero_copy_only=False), np.arange(5))), "alfabetizacao elegivel danificada"
        literate = present & eligible_age & np.isin(source["V211"].to_numpy(zero_copy_only=False), [0, 1])
        for sx in ["homens", "mulheres"]:
            masks = [("lit_"+sx, literate & (sex == sx)), ("sx_"+sx, present & (sex == sx))]
            agegroup = np.searchsorted(edges, age, side="right")
            masks += [("sx_"+sx+"_"+label, present & (sex == sx) & (v204 != 9) & (agegroup == j)) for j, label in enumerate(labels)]
            for name, mask in masks:
                if name in lookup:
                    j = lookup[name]
                    n_support[j] += np.count_nonzero(mask)
                    calculated[j] += np.sum(pw[W[0]][mask])
                    household_support_seen[j, positions[mask]] = True
        mun = array(source, "code_muni_1960")
        rural = array(source, "V118") == 5
        codes, inverse = np.unique(mun[present].astype(np.int64)*2+rural[present], return_inverse=True)
        counts = np.bincount(inverse)
        sums = np.bincount(inverse, weights=pw[W[0]][present])
        for group, (code, count, weight_sum) in enumerate(zip(codes, counts, sums)):
            base = "mun_" + str(int(code)//2)
            exact = base + ("_rural" if code%2 else "_urbana")
            index = lookup.get(exact, lookup.get(base))
            if index is not None:
                n_support[index] += int(count)
                calculated[index] += float(weight_sum)
                household_support_seen[index, positions[present][inverse == group]] = True
        peak_rss = max(peak_rss, psutil.Process().memory_info().rss)
        assert peak_rss < 2 * 1024**3, "memoria acima de 2GiB"
    assert offset == n_p and next(original_iter, None) is None
    assert partial_iter is None or next(partial_iter, None) is None
    assert len(np.unique(lines)) == n_p, "linha duplicada"
    assert np.all(n_listed > 0), "D sem lista P"
    assert np.array_equal(direct_present, array(source_d, "censobr_n_presentes")[order]), "contagem presentes diverge"
    assert np.array_equal(n_support, support), "suporte pessoal recomputado diverge"
    assert np.array_equal(household_support_seen.sum(axis=1), support_d), "suporte domiciliar recomputado diverge"
    discrepancy = np.abs(calculated-after) / np.maximum(1, np.abs(after))
    assert np.max(discrepancy) <= 1e-10, "somas diretas diferem do diagnostico"
    direct_residual = np.abs(calculated-targets)/targets
    assert np.max(direct_residual) <= 1e-6, "residuo direto acima tolerancia"
    worst = int(np.argmax(direct_residual))
    assert all(file_hash(path) == initial_hashes[str(path)] for path in evidence_paths), "entrada mudou durante QC"
    return {"uf": uf, "aprovado": True, "domicilios": n_d, "pessoas": n_p,
            "presentes": int(direct_present.sum()), "controles": len(controls),
            "peso_min": float(np.min(dweights[W[0]])), "peso_max": float(np.max(dweights[W[0]])),
            "peso_ibge_min": int(np.min(dweights[W[1]])), "peso_ibge_max": int(np.max(dweights[W[1]])),
            "residuo_relativo_max_publicado_recomputado": float(np.max(np.abs(reported_residual))),
            "residuo_relativo_max_pessoas_direto": float(direct_residual[worst]),
            "pior_controle_direto": names[worst], "diferenca_relativa_max_direto_diagnostico": float(np.max(discrepancy)),
            "schemas_pesos": {"dom": str(pq.read_schema(dompath).select(DK+W)) if hasattr(pq.read_schema(dompath), "select") else [(n,str(pq.read_schema(dompath).field(n).type)) for n in DK+W],
                               "pes": [(n,str(pq.read_schema(pespath).field(n).type)) for n in PK+W]},
            "chaves_contagens_alinhamento_e_pesos_conferidos": True,
            "comparacao_colunas_extraidas_exata": True,
            "alvos_reconstruidos": municipal_proof, "peso_ibge_por_situacao": ibge_proof,
            "suporte_domiciliar_recontado": True, "hashes_entradas_antes_depois_iguais":initial_hashes,
            "rss_maximo_observado_bytes":peak_rss}


results = []
for state in [ARGS.uf]:
    print("CONFERINDO", state, flush=True)
    try:
        result = audit(state)
    except Exception as error:
        result = {"uf": state, "aprovado": False, "erro": repr(error)}
    results.append(result)
    print(json.dumps({k:v for k,v in result.items() if k not in ["schemas_pesos", "alvos_reconstruidos", "hashes_entradas_antes_depois_iguais"]}), flush=True)
    gc.collect()
report = {"aprovado": all(r["aprovado"] for r in results), "resultados": results,
          "metodo": "Leitura integral de chaves e quatro pesos; pessoas em lotes de 131072, uma UF por vez. Recontagem pessoal direta dos controles existentes, sem recalibracao.",
          "limites": ["Nao valida historicamente vinculos familiares", "Nao homologa microdados completos ou publicacao"]}
if report["aprovado"]:
    report["totais"] = {key: sum(r[key] for r in results) for key in ["domicilios", "pessoas", "presentes", "controles"]}
OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("x", encoding="utf-8") as stream:
    json.dump(report, stream, ensure_ascii=False, indent=2)
print("RESULTADO", OUT.as_posix(), "APROVADO", report["aprovado"], flush=True)
sys.exit(0 if report["aprovado"] else 1)
