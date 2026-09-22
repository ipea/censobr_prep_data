"""Audit the materialized 1960 1.27% sample without starting R or targets.

Rebuilds the regional 1965 and state definitive comparison grids independently
with pandas/pyarrow. Writes only a separate audit directory, never production
parquets or validation CSVs. The new policy is explicit: unknown V202 supplies
neither sex nor presence; V204=9 is included in the explicit final bands of Q1
and Q2, including Q2's cumulative rows. Other age thresholds require known age.
Table 33 retains the original separate 70+ and declared-unknown rows. Existing
weights are used unchanged; this is NOT a recalibration or an R runtime test.

Run from any directory: python references/auditoria_validacao_1960.py
Requires pandas, numpy and pyarrow. --self-test runs only in-memory regressions.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import pandas as pd
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
WEIGHTS = ("censobr_weight", "censobr_weight_1965")
BAD = tuple(f"bad_{w}" for w in WEIGHTS)
UNKNOWN = "__nao_classificado__"
REGIONS = {
    **dict.fromkeys((0, 1, 2, 3, 4, 6, 91, 94, 97), "Norte e Centro-Oeste"),
    **dict.fromkeys((10, 12, 14, 17, 19, 21, 24, 25), "Nordeste"),
    **dict.fromkeys((30, 31, 40, 50, 51, 52, 54), "Leste"),
    **dict.fromkeys((60, 71, 74, 81), "Sul"),
}
UNIVERSE_STATES = {0, 1, 2, 3, 4, 6, 10, 12, 51, 54, 74}
AGES = (0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, np.inf)
AGE_LABELS = ("0 a 4", "5 a 9", "10 a 14", "15 a 19", "20 a 24", "25 a 29",
              "30 a 39", "40 a 49", "50 a 59", "60 a 69", "70 e mais")
Q2_LABELS = ("5 a 6", "7 a 12", "13 a 19", "20 a 24", "25 a 29", "30 a 39",
             "40 a 49", "50 a 59", "60 e mais e ignorada")


def metric_columns(frame: pd.DataFrame) -> pd.DataFrame:
    frame = frame.copy()
    frame["n"] = 1
    for w, bad in zip(WEIGHTS, BAD):
        frame[bad] = (~np.isfinite(frame[w])).astype(int)
        frame.loc[frame[bad].eq(1), w] = np.nan
    return frame


def grouped(frame: pd.DataFrame, by: list[str]) -> pd.DataFrame:
    """Keep counts of contributors and nonfinite weights through aggregations."""
    cols = ["n", *WEIGHTS, *BAD]
    out = frame.groupby(by, dropna=False, observed=True, sort=False)[cols].sum().reset_index()
    for w, bad in zip(WEIGHTS, BAD):
        out.loc[out[bad].gt(0), w] = np.nan
    return out


def measure(frame: pd.DataFrame, weight: str) -> tuple[float, int, int]:
    n, bad = int(frame["n"].sum()), int(frame[f"bad_{weight}"].sum())
    return (np.nan if bad else float(frame[weight].sum()), n, bad)


def classified(p: pd.DataFrame, d: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    p, d = metric_columns(p), metric_columns(d)
    for frame in (p, d):
        frame["regiao"] = frame.UF.map(REGIONS).fillna(UNKNOWN)
        frame["situacao"] = frame.V118.map({1: "urbana", 3: "urbana", 5: "rural"}).fillna(UNKNOWN)
    p["sexo"] = p.V202.map({1: "homens", 3: "homens", 5: "homens", 2: "mulheres", 4: "mulheres", 6: "mulheres"}).fillna(UNKNOWN)
    p["presente"] = p.V202.isin((1, 2, 5, 6))
    p["residente"] = p.V202.isin((1, 2, 3, 4))
    p["idade"] = np.nan
    good_value = p.V204B.isin(range(100))
    p.loc[p.V204.eq(0) & good_value, "idade"] = 0
    p.loc[p.V204.eq(1) & good_value, "idade"] = p.loc[p.V204.eq(1) & good_value, "V204B"]
    p.loc[p.V204.eq(5), "idade"] = 100  # sufficient for every published band/threshold
    p["ignorada"] = p.V204.eq(9)
    p["faixa"] = pd.cut(p.idade, AGES, right=False, labels=AGE_LABELS).astype(object).fillna(UNKNOWN)
    p.loc[p.ignorada, "faixa"] = "ignorada"
    p["faixa1"] = p.faixa.replace({"70 e mais": "70 e mais e ignorada", "ignorada": "70 e mais e ignorada"})
    p["alf"] = p.V211.map({0: "sabem", 1: "sabem", 2: "nao sabem", 3: "nao sabem"}).fillna(UNKNOWN)
    p["cor"] = p.V206.map({4: "brancos", 5: "pretos", 6: "amarelos", 7: "pardos", 8: "india", 9: "sem declaracao"}).fillna(UNKNOWN)
    return p, d


def housing(p: pd.DataFrame, d: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Resident denominators count people; a household with none contributes 0."""
    resident = grouped(p.loc[p.residente], ["censobr_idhousehold"])
    resident = resident.rename(columns={c: f"resident_{c}" for c in ["n", *WEIGHTS, *BAD]})
    d = d.loc[d.V101.isin((1, 2, 4, 5))].merge(resident, how="left", on="censobr_idhousehold", validate="one_to_one")
    no_resident = d.resident_n.isna()
    for col in ["n", *WEIGHTS, *BAD]:
        d.loc[no_resident, f"resident_{col}"] = 0
    r = d.copy()
    for col in ["n", *WEIGHTS, *BAD]:
        r[col] = r[f"resident_{col}"]
    return d, r


def build_frames(p: pd.DataFrame, d: pd.DataFrame) -> dict:
    frames = {}
    present, resident = p.loc[p.presente], p.loc[p.residente]
    frames["q1"] = grouped(present, ["regiao", "faixa1", "sexo", "situacao"])
    q2 = present.loc[present.idade.ge(5) | present.ignorada].copy()
    q2["faixa2"] = pd.cut(q2.idade, (5, 7, 13, 20, 25, 30, 40, 50, 60, np.inf), right=False, labels=Q2_LABELS).astype(object).fillna(UNKNOWN)
    q2.loc[q2.ignorada, "faixa2"] = Q2_LABELS[-1]
    q2["dezmais"], q2["quinzemais"] = q2.idade.ge(10) | q2.ignorada, q2.idade.ge(15) | q2.ignorada
    q2["alf"] = q2.alf.str.replace(" ", "_", regex=False)
    frames["q2"] = grouped(q2, ["regiao", "faixa2", "sexo", "alf", "dezmais", "quinzemais"])
    q3 = present.loc[present.idade.ge(10)].copy()
    v = q3.V223B
    q3["ramo"] = np.select((v.isna(), q3.V223.isin((4, 5)), v.lt(200), v.lt(300), v.le(339), v.eq(351), v.isin(range(411, 430)), v.isin(range(611, 630)), v.isin(range(511, 520))),
        ("condicoes_inativas", "outras_atividades", "agricultura_pecuaria_silvicultura", "industrias_extrativas", "industrias_transformacao", "industrias_construcao", "comercio_mercadorias", "transportes_comunicacoes_armazenagem", "prestacao_servicos"), default="outras_atividades")
    q3["grupo"] = np.select((v.isna(), v.lt(300), v.lt(400)), ("inativas", "agro", "ind"), default="outras")
    q3["renda"] = q3.V219.map(dict(enumerate(("10001_20000", "20001_mais", "20001_mais", "sem_rendimento", "sem_declaracao", "ate_2100", "2101_3300", "3301_4500", "4501_6000", "6001_10000")))).fillna("sem_declaracao")
    frames["q3"] = grouped(q3, ["regiao", "ramo", "sexo"])
    frames["q4"] = grouped(q3, ["regiao", "renda", "grupo", "sexo"])
    q5 = resident.loc[resident.idade.ge(15)].copy()
    q5["conjugal"] = q5.V215.map(dict(enumerate(("solteiros", "separados", "outros", "outros", "viuvos", "outros", "casados_civil_religioso", "casados_somente_civil", "casados_somente_religioso", "casados_sem_vinculo")))).fillna("outros")
    frames["q5"] = grouped(q5, ["regiao", "conjugal"])
    dp, rp = housing(p, d)
    conditions = {
        "TOTAIS": pd.Series(True, index=dp.index), "proprios": dp.V103.eq(7), "alugados": dp.V103.eq(8), "outra_condicao": dp.V103.eq(9),
        "agua_rede_geral": dp.V105.isin((9, 0)), "agua_poco_nascente": dp.V105.isin((1, 2)), "agua_outra_sem_declaracao": dp.V105.eq(3) | dp.V105.isna(),
        "fogao_lenha": dp.V107.eq(9), "fogao_carvao": dp.V107.eq(0), "fogao_gas": dp.V107.eq(2), "fogao_oleo_querosene": dp.V107.eq(3),
        "instalacao_sanitaria": dp.V106.isin((4, 5, 6, 7)), "iluminacao_eletrica": dp.V108.eq(5), "radio": dp.V109.eq(7), "geladeira": dp.V110.eq(9),
    }
    for item, mask in conditions.items():
        frames[("q67", item, "dom")] = grouped(dp.loc[mask], ["regiao", "situacao"])
        frames[("q67", item, "pes")] = grouped(rp.loc[mask], ["regiao", "situacao"])
    frames[(32, "presente")] = grouped(present, ["UF", "sexo"])
    frames[(32, "residente")] = grouped(resident, ["UF", "sexo"])
    for table, field in ((33, "faixa"), (34, "situacao"), (37, "cor")):
        frames[table] = grouped(present, ["UF", field, "sexo"])
    frames[40] = grouped(present.loc[present.idade.ge(5)], ["UF", "alf", "sexo"])
    frames[(7, "domicilios")] = grouped(dp, ["UF", "situacao"])
    frames[(7, "pessoas")] = grouped(rp, ["UF", "situacao"])
    return frames


def select_preliminary(row: dict, frames: dict) -> pd.DataFrame | None:
    table, item, column = row["quadro"], row["linha"], row["coluna"]
    if table == 5 and column != "total":
        return None
    if table == 6 and item not in ("TOTAIS", "proprios", "alugados", "outra_condicao"):
        return None
    if table in (6, 7):
        measure_name, situation = column.split("_", 1)
        z = frames[("q67", item, measure_name)]
        z = z.loc[z.regiao.eq(row["regiao"])]
        return z if situation == "total" else z.loc[z.situacao.eq(situation)]
    z = frames[f"q{table}"]
    z = z.loc[z.regiao.eq(row["regiao"])]
    if table == 1:
        if item != "TOTAIS":
            z = z.loc[z.faixa1.eq(item)]
        if column in ("urbana", "rural"):
            return z.loc[z.situacao.eq(column)]
        if column.startswith(("urbana_", "rural_")):
            situation, sex = column.split("_", 1)
            return z.loc[z.situacao.eq(situation) & z.sexo.eq(sex)]
    elif table == 2:
        if item == "10 e mais":
            z = z.loc[z.dezmais]
        elif item == "15 e mais":
            z = z.loc[z.quinzemais]
        elif item != "5 e mais":
            z = z.loc[z.faixa2.eq(item)]
        if column.startswith(("sabem", "nao_sabem")):
            sex = next((s for s in ("homens", "mulheres") if column.endswith(f"_{s}")), None)
            literacy = column if sex is None else column[: -(len(sex) + 1)]
            z = z.loc[z.alf.eq(literacy)]
            return z if sex is None else z.loc[z.sexo.eq(sex)]
    elif table == 3:
        if item != "TOTAIS":
            z = z.loc[z.ramo.eq(item)]
    elif table == 4:
        if item != "TOTAIS":
            z = z.loc[z.renda.eq(item)]
        if column != "total":
            group, sex = column.split("_", 1)
            return z.loc[z.grupo.eq(group) & z.sexo.eq(sex)]
    elif table == 5:
        if item == "casados":
            z = z.loc[z.conjugal.str.startswith("casados_")]
        elif item != "TOTAIS":
            z = z.loc[z.conjugal.eq(item)]
    return z if column == "total" else z.loc[z.sexo.eq(column)]


def select_definitive(row: dict, frames: dict) -> pd.DataFrame:
    table, item = row["tabela"], row["item"]
    key = (table, item) if table == 32 else (table, row["medida"]) if table == 7 else table
    z = frames[key]
    z = z.loc[z.UF.eq(row["uf60"])]
    field = {7: "situacao", 33: "faixa", 34: "situacao", 37: "cor", 40: "alf"}.get(table)
    if field and item not in ("total", "5 e mais"):
        z = z.loc[z[field].eq(item)]
    if row["sexo"] not in ("total", ""):
        z = z.loc[z.sexo.eq(row["sexo"])]
    return z


def comparison_grid(source: pd.DataFrame, frames: dict, preliminary: bool) -> pd.DataFrame:
    out = []
    for row in source.to_dict("records"):
        z = select_preliminary(row, frames) if preliminary else select_definitive(row, frames)
        for weight in WEIGHTS:
            value, n, bad = (np.nan, np.nan, np.nan) if z is None else measure(z, weight)
            status = "nao_reconstruida" if z is None else "peso_ausente" if bad else "sem_observacoes" if not n else "observada"
            target = float(row["valor"])
            diff = value - target
            item = {k: v for k, v in row.items() if k != "valor"}
            item.update(peso=weight, publicado=target, nosso=value, n_amostra=n, n_pesos_ausentes=bad,
                status_celula=status, dif_abs=diff, dif_pct=np.nan if target == 0 else round(100 * diff / target, 2),
                referencia_estimada=preliminary or row["uf60"] not in UNIVERSE_STATES)
            out.append(item)
    return pd.DataFrame(out)


def diagnostics(p: pd.DataFrame, d: pd.DataFrame) -> pd.DataFrame:
    masks = {
        "presenca_sexo_desconhecidos": ~p.V202.isin(range(1, 7)),
        "situacao_desconhecida": ~p.V118.isin((1, 3, 5)),
        "idade_declarada_ignorada": p.ignorada,
        "idade_nao_classificavel": p.idade.isna() & ~p.ignorada,
        "cor_nao_classificavel": ~p.V206.isin(range(4, 10)),
        "cor_india_sem_coluna_publicada": p.V206.eq(8),
        "alfabetizacao_sem_classificacao": ~p.V211.isin(range(4)),
    }
    output = []
    for issue, mask in masks.items():
        z = grouped(p.loc[mask], ["UF"])
        for uf, group in z.groupby("UF", dropna=False):
            for weight in WEIGHTS:
                value, n, bad = measure(group, weight)
                output.append(dict(UF=uf, motivo=issue, unidade="pessoas", peso=weight, n_amostra=n, nosso=value, n_pesos_ausentes=bad))
    z = grouped(d.loc[~d.V101.isin(range(1, 6))], ["UF"])
    for uf, group in z.groupby("UF", dropna=False):
        for weight in WEIGHTS:
            value, n, bad = measure(group, weight)
            output.append(dict(UF=uf, motivo="tipo_domicilio_desconhecido", unidade="domicilios", peso=weight, n_amostra=n, nosso=value, n_pesos_ausentes=bad))
    return pd.DataFrame(output)


def self_test() -> None:
    z = metric_columns(pd.DataFrame({"UF": [0, 0], WEIGHTS[0]: [10, np.nan], WEIGHTS[1]: [20, 20]}))
    g = grouped(z, ["UF"])
    assert measure(g, WEIGHTS[0])[1:] == (2, 1)
    assert np.isnan(measure(g, WEIGHTS[0])[0])
    assert measure(g.iloc[:0], WEIGHTS[0]) == (0.0, 0, 0)
    # An official zero must retain an absolute discrepancy, without division by zero.
    source = pd.DataFrame([dict(tabela=32, uf60=0, item="presente", sexo="total", medida="", valor=0)])
    result = comparison_grid(source, {(32, "presente"): g.assign(sexo="homens")}, False)
    assert result.loc[result.peso.eq(WEIGHTS[1]), "dif_abs"].iloc[0] == 40
    assert result.dif_pct.isna().all()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--output-dir", type=Path, default=ROOT / "data_raw/microdata/1960/amostra_127/auditoria_validacao_20260921")
    args = parser.parse_args()
    self_test()
    if args.self_test:
        print("Regressoes Python em memoria: OK")
        return
    base = ROOT / "data_raw/microdata/1960/amostra_127"
    ppath, dpath = base / "pessoas_1960_amostra_127.parquet", base / "domicilios_1960_amostra_127.parquet"
    pcols = ["linha", "UF", "censobr_idhousehold", "V118", "V202", "V204", "V204B", "V206", "V211", "V215", "V219", "V223", "V223B", *WEIGHTS]
    dcols = ["UF", "censobr_idhousehold", "V118", "V101", "V103", "V105", "V106", "V107", "V108", "V109", "V110", *WEIGHTS]
    p, d = classified(pq.read_table(ppath, columns=pcols).to_pandas(), pq.read_table(dpath, columns=dcols).to_pandas())
    # Small existing-case smoke checks before constructing all comparison cells.
    assert len(p) == 897009 and len(d) == 174245
    assert p.loc[p.UF.eq(0), "situacao"].eq("urbana").all()
    assert p.loc[~p.V202.isin(range(1, 7)), "linha"].tolist() == [855822, 951432, 951433]
    print("Smoke checks dos parquets: RO urbano e tres registros V202 ausente confirmados.", flush=True)
    frames = build_frames(p, d)
    prepath = ROOT / "references/censo_1960_resultados_preliminares_1965.csv"
    defpath = ROOT / "references/censo_1960_resultados_definitivos_serie_nacional.csv"
    pre = pd.read_csv(prepath, keep_default_na=False)
    pre = pre.loc[pre.regiao.ne("Brasil")]
    definitive = pd.read_csv(defpath, keep_default_na=False)
    definitive = definitive.loc[definitive.nivel.eq("uf")].copy()
    definitive["uf60"] = definitive.uf60.astype(int)
    pregrid, defgrid = comparison_grid(pre, frames, True), comparison_grid(definitive, frames, False)
    assert len(pregrid) == 2 * len(pre) and len(defgrid) == 2 * len(definitive)
    assert not pregrid.duplicated(["peso", "quadro", "regiao", "linha", "coluna"]).any()
    assert not defgrid.duplicated(["peso", "tabela", "uf60", "item", "sexo", "medida"]).any()
    ro = defgrid.loc[defgrid.tabela.eq(34) & defgrid.uf60.eq(0) & defgrid.item.eq("rural")]
    assert len(ro) == 6 and ro.n_amostra.eq(0).all() and ro.dif_pct.eq(-100).all()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    pregrid.to_csv(args.output_dir / "preliminares_grade_completa.csv", index=False, encoding="utf-8-sig")
    defgrid.to_csv(args.output_dir / "definitivos_grade_completa.csv", index=False, encoding="utf-8-sig")
    diag = diagnostics(p, d)
    diag.to_csv(args.output_dir / "universos_nao_classificados.csv", index=False, encoding="utf-8-sig")
    rows = []
    for name, grid, number in (("1965", pregrid, "quadro"), ("definitivos", defgrid, "tabela")):
        for (weight, table, status), group in grid.groupby(["peso", number, "status_celula"]):
            rows.append(dict(referencia=name, peso=weight, tabela=int(table), status_celula=status,
                             celulas=len(group), publicado_positivo=int(group.publicado.gt(0).sum())))
    pd.DataFrame(rows).to_csv(args.output_dir / "resumo_grade.csv", index=False, encoding="utf-8-sig")
    # Compare the audit's original finding on exactly the legacy age grouping,
    # so a changed number of missing cells is not confused with new data loss.
    legacy_keys = ["tabela", "uf60", "item", "sexo", "medida"]
    legacy_source = definitive.copy()
    legacy_source.loc[legacy_source.tabela.eq(33) & legacy_source.item.isin(("70 e mais", "ignorada")), "item"] = "70 e mais e ignorada"
    legacy_source = legacy_source.groupby(legacy_keys, as_index=False).valor.sum()
    legacy = pd.read_csv(base / "calibracao_definitivos_validacao.csv", keep_default_na=False)
    legacy = legacy.loc[legacy.peso.eq(WEIGHTS[0]), legacy_keys]
    omitted = legacy_source.merge(legacy, on=legacy_keys, how="left", indicator=True, validate="one_to_one")
    omitted = omitted.loc[omitted._merge.eq("left_only")].drop(columns="_merge")
    omitted.to_csv(args.output_dir / "celulas_omitidas_validacao_anterior.csv", index=False, encoding="utf-8-sig")
    manifest = dict(escopo="Auditoria independente dos parquets existentes; nao executa R nem recalibra", pessoas=len(p), domicilios=len(d),
        grade_1965_por_peso=len(pre), grade_definitivos_por_peso=len(definitive),
        grade_definitivos_legado_por_peso=len(legacy_source), celulas_omitidas_legado=len(omitted),
        celulas_positivas_omitidas_legado=int(omitted.valor.gt(0).sum()),
        politica_idade="Q1/Q2 incluem V204=9 nas linhas explicitas e cumulativas; Q3-5 e tab40 exigem idade conhecida; tab33 separa 70+ e ignorada",
        fontes=[dict(path=str(path.relative_to(ROOT)), bytes=path.stat().st_size,
                     sha256=file_sha256(path)) for path in (ppath, dpath, prepath, defpath,
                         base / "calibracao_definitivos_validacao.csv")])
    (args.output_dir / "manifesto.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(pd.DataFrame(rows).to_string(index=False))
    print("Auditoria concluida:", args.output_dir)


def file_sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


if __name__ == "__main__":
    main()
