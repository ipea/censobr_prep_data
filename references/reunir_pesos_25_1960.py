"""Reune bruto completo + nove colunas calibradas, somente em staging novo.

Exemplo: python references/reunir_pesos_25_1960.py --uf se --partial-run tmp/RUN
  --out tmp/NOVO --compare-root tmp/PILOTO/pesos
Nao executa R/targets, recalibra, publica, ordena ou corrige dados. A pasta UF
e fixa; somente APROVADO.json completo identifica uma recomposicao conferida.
"""
import argparse
import gc
import hashlib
import json
import os
from pathlib import Path
import sqlite3
import time
from datetime import datetime, timezone

import psutil
import pyarrow as pa
import pyarrow.compute as pc
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
GIB = 2**30
UF = {"al": 25, "ba": 31, "ce": 14, "df": 97, "fn": 24, "go": 94,
      "mg": 40, "mt": 91, "pb": 19, "pe": 21, "pr": 71, "rj": 52,
      "rn": 17, "rs": 81, "sa": 50, "se": 30, "sp": 60}
NINE = {"situacao", "censobr_upa", "censobr_estrato", "censobr_fpc",
        "censobr_weight_desenho", "censobr_weight", "censobr_weight_fator",
        "censobr_weight_nivel", "censobr_weight_ibge"}
FILES = [("domicilios.parquet", "domicilios_pesos.parquet", "censobr_idhousehold"),
         ("pessoas_geo.parquet", "pessoas_pesos.parquet", "linha")]


class MemoryGuard:
    def __init__(self, available=None):
        self.available = available or (lambda: psutil.virtual_memory().available)
        self.minimum = None
        self.peak_rss = 0
        self.process = psutil.Process()

    def check(self, phase, start=False):
        free = self.available()
        self.minimum = free if self.minimum is None else min(self.minimum, free)
        self.peak_rss = max(self.peak_rss, self.process.memory_info().rss)
        threshold = (4 if start else 2) * GIB
        if free < threshold:
            raise MemoryError(f"RAM insuficiente em {phase}: {free / GIB:.3f} GiB; requer {threshold / GIB:g}")


def safe_path(path):
    path = Path(path).resolve()
    if not path.is_relative_to(ROOT):
        raise ValueError(f"Caminho fora deste projeto: {path}")
    return path


def label(path):
    return Path(path).resolve().relative_to(ROOT).as_posix()


def write_json(path, value):
    with Path(path).open("x", encoding="utf-8") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2, allow_nan=False)


def hashes(path, guard):
    md5 = hashlib.md5(); sha = hashlib.sha256()
    with Path(path).open("rb") as stream:
        while True:
            guard.check("hash")
            chunk = stream.read(4 * 1024**2)
            if not chunk:
                break
            md5.update(chunk); sha.update(chunk)
    return {"bytes": Path(path).stat().st_size, "md5": md5.hexdigest(), "sha256": sha.hexdigest()}


def paired_batches(left, right, batch_size, guard, columns=None):
    """Alinha apenas limites de batch, nunca reordena registros."""
    a = iter(left.iter_batches(batch_size=batch_size, columns=columns, use_threads=False))
    b = iter(right.iter_batches(batch_size=batch_size, columns=columns, use_threads=False))
    x = y = None
    while True:
        guard.check("leitura_batch")
        if x is None or not x.num_rows:
            x = next(a, None)
        if y is None or not y.num_rows:
            y = next(b, None)
        if x is None or y is None:
            if x is not None or y is not None:
                raise ValueError("Quantidades diferentes ao percorrer batches")
            break
        count = min(x.num_rows, y.num_rows)
        yield x.slice(0, count), y.slice(0, count)
        x = x.slice(count); y = y.slice(count)


def compare_columns(a, b, names, offset):
    for name in names:
        if not a.column(name).equals(b.column(name)):
            raise ValueError(f"Conteudo divergente na coluna {name}, batch iniciado na linha {offset + 1}")


def compare_files(left_path, right_path, guard, batch_size, columns=None):
    with pq.ParquetFile(left_path) as left, pq.ParquetFile(right_path) as right:
        if left.metadata.num_rows != right.metadata.num_rows:
            raise ValueError("Contagens divergentes na verificacao da saida")
        names = columns or left.schema_arrow.names
        if columns is None and left.schema_arrow.names != right.schema_arrow.names:
            raise ValueError("Ordem ou conjunto de colunas diverge do piloto")
        for name in names:
            if not left.schema_arrow.field(name).equals(right.schema_arrow.field(name), check_metadata=False):
                raise ValueError(f"Tipo/nullable divergente: {name}")
        count = 0
        for a, b in paired_batches(left, right, batch_size, guard, names):
            compare_columns(a, b, names, count)
            count += a.num_rows
        if count != left.metadata.num_rows:
            raise ValueError("Verificacao incompleta")
    return {"linhas": count, "colunas": names, "igualdade_exata": True}


def assemble_pair(raw_path, partial_path, output_path, uf, unique_key, guard, batch_size=32768):
    """Recusa permutacoes, mesmo com mesmo comprimento; verifica chaves em disco."""
    if output_path.exists():
        raise FileExistsError(output_path)
    database = output_path.with_suffix(".chaves.sqlite")
    if database.exists():
        raise FileExistsError(database)
    with pq.ParquetFile(raw_path) as raw, pq.ParquetFile(partial_path) as partial:
        raw_names = raw.schema_arrow.names; partial_names = partial.schema_arrow.names
        if len(raw_names) != len(set(raw_names)) or len(partial_names) != len(set(partial_names)):
            raise ValueError("Colunas duplicadas no esquema")
        if set(raw_names) & NINE:
            raise ValueError("Bruto ja contem colunas de peso/desenho")
        extras = [name for name in partial_names if name not in raw_names]
        if set(extras) != NINE or len(extras) != 9:
            raise ValueError("Saida parcial nao contem exatamente as nove colunas novas")
        common = [name for name in partial_names if name in raw_names]
        required = {"UF", "censobr_idhousehold", unique_key}
        if not required.issubset(common):
            raise ValueError("Chaves de identificacao ausentes da intersecao")
        for name in common:
            if not raw.schema_arrow.field(name).equals(partial.schema_arrow.field(name), check_metadata=False):
                raise ValueError(f"Tipo/nullable divergente na coluna comum {name}")
        if not raw.metadata.num_rows or raw.metadata.num_rows != partial.metadata.num_rows:
            raise ValueError("Arquivo vazio ou quantidade bruto/parcial divergente")
        fields = list(raw.schema_arrow) + [partial.schema_arrow.field(name) for name in extras]
        # O atributo R serializado descreve o dataframe de origem, nao a nova
        # tabela. Campos/tipos sao preservados; metadados R obsoletos nao sao copiados.
        schema = pa.schema(fields, metadata={b"censobr_stage": b"completo_recomposto_nao_promovido"})
        db = sqlite3.connect(database)
        try:
            db.execute("PRAGMA cache_size=-16384")
            db.execute("PRAGMA temp_store=FILE")
            db.execute("CREATE TABLE chaves (id INTEGER PRIMARY KEY) WITHOUT ROWID")
            count = 0
            with pq.ParquetWriter(output_path, schema, compression="zstd", compression_level=1) as writer:
                for a, b in paired_batches(raw, partial, batch_size, guard):
                    compare_columns(a, b, common, count)
                    for key in required:
                        if a.column(key).null_count:
                            raise ValueError(f"Chave ausente: {key}")
                    if not pa.types.is_integer(a.column(unique_key).type):
                        raise ValueError("Chave nao inteira")
                    if not pc.all(pc.equal(a.column("UF"), UF[uf])).as_py():
                        raise ValueError("UF incorreta na entrada")
                    try:
                        db.executemany("INSERT INTO chaves VALUES (?)", ((v,) for v in a.column(unique_key).to_pylist()))
                    except sqlite3.IntegrityError as exc:
                        raise ValueError(f"Chave global duplicada: {unique_key}") from exc
                    db.commit()
                    batch = pa.RecordBatch.from_arrays(list(a.columns) + [b.column(name) for name in extras], schema=schema)
                    writer.write_batch(batch)
                    count += a.num_rows
                    guard.check("escrita_batch")
                    del batch
            if count != raw.metadata.num_rows or db.execute("SELECT COUNT(*) FROM chaves").fetchone()[0] != count:
                raise ValueError("Contagem final/chaves divergente")
        finally:
            db.close()
    preserved = compare_files(raw_path, output_path, guard, batch_size, raw_names)
    appended = compare_files(partial_path, output_path, guard, batch_size, extras)
    return {"linhas": count, "colunas_brutas": raw_names, "colunas_acrescidas": extras,
            "colunas_comuns_conferidas": common, "chave_unica": ["UF", unique_key],
            "bruto_preservado_exato": preserved["igualdade_exata"],
            "pesos_preservados_exatos": appended["igualdade_exata"],
            "ordem_preservada": True, "metadados_R_serializados": "nao_copiados"}


def run_uf(uf, raw_root, partial_run, out_root, compare_root, guard, batch_size):
    started = time.monotonic()
    guard.check(f"inicio_{uf}", start=True)
    working = out_root / uf
    working.mkdir(exist_ok=False)
    result = {"uf": uf, "status": "falhou_nao_promover", "arquivos": [], "entradas": {}}
    try:
        source_status_path = partial_run / "resultados" / f"{uf}.json"
        source_status = json.loads(source_status_path.read_text(encoding="utf-8"))
        if source_status.get("status") != "concluido_auxiliar_parcial" or source_status.get("hashes_alterados") != []:
            raise ValueError("Calibracao parcial nao concluida com originais preservados")
        previous_path = partial_run / "manifestos" / f"{uf}_antes.json"
        previous = json.loads(previous_path.read_text(encoding="utf-8"))
        paths = [source_status_path, previous_path]
        for raw_name, weighted_name, key in FILES:
            raw = raw_root / uf / raw_name
            partial = partial_run / "saidas_parciais" / uf / weighted_name
            paths.extend([raw, partial])
            old_weighted = raw_root / uf / weighted_name
            if old_weighted.exists():
                paths.append(old_weighted)  # somente hash: nenhum campo antigo e copiado
            if compare_root is not None:
                paths.append(compare_root / uf / weighted_name)
        for path in paths:
            result["entradas"][label(path)] = hashes(path, guard)
        for raw_name, weighted_name, key in FILES:
            path = raw_root / uf / raw_name
            if previous.get(label(path)) != result["entradas"][label(path)]["md5"]:
                raise ValueError(f"Bruto atual diverge do hash usado na calibracao: {path.name}")
        write_json(working / "inicio.json", {"utc": datetime.now(timezone.utc).isoformat(), **result})
        for raw_name, weighted_name, key in FILES:
            output = working / weighted_name
            record = assemble_pair(raw_root / uf / raw_name,
                partial_run / "saidas_parciais" / uf / weighted_name,
                output, uf, key, guard, batch_size)
            record["arquivo"] = weighted_name
            if compare_root is not None:
                record["paridade_piloto_todas_colunas"] = compare_files(
                    compare_root / uf / weighted_name, output, guard, batch_size)
            record["hash_saida"] = hashes(output, guard)
            result["arquivos"].append(record)
            gc.collect()
        after = {label(path): hashes(path, guard) for path in paths}
        result["hashes_entradas_depois"] = after
        if result["entradas"] != after:
            raise ValueError("Uma entrada mudou durante a recomposicao")
        result["status"] = "concluido_staging_nao_promovido"
        result["pasta"] = label(working)
    except Exception as exc:
        result["erro"] = f"{type(exc).__name__}: {exc}"
        result["artefatos_incompletos_preservados"] = label(working)
        # A falha nao apaga arquivos. A prova de hashes pode ficar indisponivel
        # se justamente faltou RAM ou a entrada deixou de existir.
        try:
            result["hashes_entradas_depois"] = {path: hashes(ROOT / path, guard) for path in result["entradas"]}
            result["entradas_inalteradas_na_falha"] = result["entradas"] == result["hashes_entradas_depois"]
        except Exception as check_error:
            result["erro_conferencia_pos_falha"] = str(check_error)
    result["segundos"] = round(time.monotonic() - started, 3)
    result["minimo_RAM_disponivel_observado_bytes"] = guard.minimum
    result["pico_RSS_Python_observado_bytes"] = guard.peak_rss
    filename = "APROVADO.json" if result["status"] == "concluido_staging_nao_promovido" else "FALHA.json"
    write_json(working / filename, result)
    print(json.dumps({k: result[k] for k in ["uf", "status", "segundos"]}, ensure_ascii=False), flush=True)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--uf", nargs="+", choices=sorted(UF), required=True)
    parser.add_argument("--partial-run", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--raw-root", type=Path, default=ROOT / "data_raw/microdata/1960/amostra_25")
    parser.add_argument("--compare-root", type=Path)
    parser.add_argument("--batch-size", type=int, default=32768)
    args = parser.parse_args()
    if len(args.uf) != len(set(args.uf)) or not 1 <= args.batch_size <= 65536:
        parser.error("UF repetida ou batch fora de 1..65536")
    raw_root = safe_path(args.raw_root); partial_run = safe_path(args.partial_run)
    out_root = safe_path(args.out)
    comparison = safe_path(args.compare_root) if args.compare_root is not None else None
    if not out_root.is_relative_to(ROOT / "tmp") or out_root == ROOT / "tmp":
        parser.error("Saida deve ser uma pasta NOVA dentro de tmp")
    if any(out_root.is_relative_to(p) for p in [raw_root, partial_run] + ([comparison] if comparison else [])):
        parser.error("Staging deve ficar separado das pastas de entrada")
    guard = MemoryGuard()
    guard.check("inicio", start=True)
    out_root.mkdir(parents=True, exist_ok=False)
    pa.set_cpu_count(1); pa.set_io_thread_count(1)
    write_json(out_root / "execucao.json", {"utc": datetime.now(timezone.utc).isoformat(),
        "ufs": args.uf, "script_sha256": hashes(Path(__file__), guard)["sha256"],
        "raw_root": label(raw_root), "partial_run": label(partial_run),
        "compare_root": label(comparison) if comparison else None,
        "batch_size": args.batch_size, "pyarrow": pa.__version__,
        "natureza": "STAGING_COMPLETO_NAO_PROMOVIDO"})
    results = []
    for uf in args.uf:
        try:
            result = run_uf(uf, raw_root, partial_run, out_root, comparison, guard, args.batch_size)
        except Exception as exc:
            result = {"uf": uf, "status": "falhou_nao_promover", "erro": f"{type(exc).__name__}: {exc}"}
        results.append(result)
        if result["status"] != "concluido_staging_nao_promovido":
            break
    success = len(results) == len(args.uf) and all(r["status"] == "concluido_staging_nao_promovido" for r in results)
    write_json(out_root / "resultado.json", {"concluido": success, "ufs_previstas": args.uf, "resultados": results})
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
