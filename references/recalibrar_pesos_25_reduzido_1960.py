"""Pesos25 auxiliares: SE-paridade primeiro, restantes serialmente, sem producao.

Executa somente o R filho criado via rodar_r_isolado_1960.py. Projecao em lotes,
hashes originais, limites de RAM e prazo; nao encerra processos preexistentes.
As saidas parciais NAO sao microdados completos e nao alimentam compile/targets.
"""
import argparse
import csv
import gc
import hashlib
import json
import math
import os
from pathlib import Path
import subprocess
import sys
import time
from datetime import datetime

import numpy as np
import psutil
import pyarrow as pa
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "data_raw/microdata/1960/amostra_25"
PILOTO = ROOT / "tmp/execucao_1960_20260922/pesos25_piloto_20260922_092755"
DOM = ["UF", "censobr_idhousehold", "V118", "v001", "code_muni_1960", "censobr_n_presentes", "V101", "V102"]
PES = ["UF", "censobr_idhousehold", "linha", "V118", "V202", "V204", "V204B", "V211", "code_muni_1960", "V206"]
PESOS = ["censobr_weight", "censobr_weight_ibge", "censobr_weight_desenho", "censobr_weight_fator"]
RESTANTES = ["df", "sa", "mt", "rn", "al", "go", "pb", "ce", "rj", "pe", "pr", "rs", "ba", "mg", "sp"]
FONTES = [ROOT / f for f in ["R/microdata_1960_amostra_127.R", "R/microdata_1960_amostra_25.R",
    "R/microdata_1960_validacao.R", "R/microdata_1960.R", "read_guides/1960_municipios.csv",
    "references/censo_1960_resultados_definitivos_serie_nacional.csv",
    "references/recalibrar_pesos_25_reduzido_1960.py", "references/recalibrar_pesos_25_reduzido_1960.R",
    "references/rodar_r_isolado_1960.py"]]
GIB = 2 ** 30


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2, allow_nan=False)


def md5(path):
    result = hashlib.md5()
    with path.open("rb") as stream:
        for part in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(part)
    return result.hexdigest()


def hashes(paths):
    return {p.relative_to(ROOT).as_posix(): md5(p) for p in paths}


def project(source, target, columns):
    """Preserva ordem, valores e tipos; remove apenas metadados globais obsoletos."""
    if target.exists():
        raise FileExistsError(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    original = pq.ParquetFile(source)
    schema = pa.schema([original.schema_arrow.field(c) for c in columns])
    count = 0
    with pq.ParquetWriter(target, schema, compression="zstd", compression_level=1) as writer:
        for batch in original.iter_batches(batch_size=65536, columns=columns, use_threads=False):
            if psutil.virtual_memory().available < 2 * GIB:
                raise MemoryError("RAM livre <2GiB durante projecao; nenhum R foi iniciado")
            table = pa.Table.from_arrays(list(batch.columns), schema=schema)
            writer.write_table(table)
            count += batch.num_rows
    check = pq.ParquetFile(target)
    if count != original.metadata.num_rows or check.metadata.num_rows != count or check.schema_arrow != schema:
        raise ValueError("projecao mudou linhas/schema: " + str(source))
    return {"origem": source.relative_to(ROOT).as_posix(), "destino": target.relative_to(ROOT).as_posix(),
        "linhas": count, "colunas": columns, "tipos": [str(schema.field(c).type) for c in columns],
        "md5_auxiliar": md5(target)}


def terminate_owned(process):
    # Somente descendentes do runner que ESTA execucao criou; nao busca nomes globais.
    try:
        try:
            children = psutil.Process(process.pid).children(recursive=True)
        except psutil.NoSuchProcess:
            children = []
        for child in reversed(children):
            try:
                child.kill()
            except psutil.NoSuchProcess:
                pass
    except psutil.AccessDenied:
        # Falha do proprio monitor nao pode deixar o R sem supervisao. /PID /T
        # limita a operacao a arvore do Popen criado aqui; nao usa busca por nome.
        if os.name != "nt":
            raise
        killed = subprocess.run(["taskkill.exe", "/PID", str(process.pid), "/T", "/F"],
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            timeout=15, creationflags=subprocess.CREATE_NO_WINDOW)
        if killed.returncode and process.poll() is None:
            raise RuntimeError("nao foi possivel encerrar arvore propria: " + killed.stdout.decode(errors="replace"))
        process.wait(timeout=15)
        return
    if process.poll() is None:
        process.kill()
    process.wait(timeout=15)
    _, alive = psutil.wait_procs(children, timeout=15)
    if alive:
        raise RuntimeError("descendentes proprios nao encerraram: " + str([p.pid for p in alive]))


def run_r(uf, root, timeout):
    log = root / "logs" / (uf + ".log")
    log.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env.update(CENSOBR_AUTORIZAR_PESOS25_REDUZIDO="SIM", CENSOBR_PESOS25_UF=uf,
               CENSOBR_PESOS25_RAIZ=str(root))
    cmd = [sys.executable, "references/rodar_r_isolado_1960.py",
        "references/recalibrar_pesos_25_reduzido_1960.R", str(log), "--timeout", str(timeout),
        "--locale-c", "--windows-arch"]
    started = time.monotonic()
    peak_rss = peak_windows = 0
    minimum_free = psutil.virtual_memory().available
    reason = ""
    with (root / "logs" / (uf + "_runner.log")).open("x", encoding="utf-8") as console, \
            (root / "logs" / (uf + "_memoria.csv")).open("x", newline="", encoding="utf-8") as mem:
        writer = csv.writer(mem)
        writer.writerow(["segundos", "livre_bytes", "rss_R_bytes", "peak_wset_R_bytes"])
        process = subprocess.Popen(cmd, cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
            stdout=console, stderr=subprocess.STDOUT,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        monitor_error = None
        try:
            while process.poll() is None:
                available = psutil.virtual_memory().available
                minimum_free = min(minimum_free, available)
                rss = peak = 0
                try:
                    for child in psutil.Process(process.pid).children(recursive=True):
                        try:
                            if child.name().lower() in {"rscript.exe", "rterm.exe", "rscript", "r"}:
                                memory = child.memory_info()
                                rss += memory.rss
                                peak += getattr(memory, "peak_wset", memory.rss)
                        except psutil.NoSuchProcess:
                            pass
                except psutil.NoSuchProcess:
                    pass
                peak_rss, peak_windows = max(peak_rss, rss), max(peak_windows, peak)
                elapsed = time.monotonic() - started
                writer.writerow([round(elapsed, 3), available, rss, peak])
                mem.flush()
                if available < 2 * GIB:
                    reason = "RAM livre abaixo de 2GiB; encerrado somente filho proprio"
                elif elapsed > timeout + 15:
                    reason = "prazo externo excedido; encerrado somente filho proprio"
                if reason:
                    terminate_owned(process)
                    break
                time.sleep(0.20)
        except BaseException as exc:
            monitor_error = exc
            console.write("\nFALHA_MONITOR: " + type(exc).__name__ + ": " + str(exc) + "\n")
            console.flush()
            raise
        finally:
            if monitor_error is not None or process.poll() is None:
                try:
                    terminate_owned(process)
                    console.write("\nLIMPEZA_MONITOR: filhos proprios encerrados e aguardados.\n")
                    console.flush()
                except BaseException as cleanup_error:
                    console.write("\nFALHA_LIMPEZA: " + repr(cleanup_error) + "\n")
                    console.flush()
                    if monitor_error is None:
                        raise
                    monitor_error.add_note("Falha adicional ao encerrar filho proprio: " + repr(cleanup_error))
    return {"exit_runner": process.returncode, "segundos_R_runner": round(time.monotonic() - started, 3),
        "pico_R_rss_observado_bytes": peak_rss, "pico_R_working_set_Windows_bytes": peak_windows,
        "minimo_RAM_livre_bytes": minimum_free, "interrupcao_recursos": reason,
        "log": log.relative_to(ROOT).as_posix()}


def compare_parquets(reference, current):
    """Compara TODAS as colunas da saida parcial, inclusive todos os pesos/desenho."""
    actual = pq.read_table(current, use_threads=False)
    expected = pq.read_table(reference, columns=actual.column_names, use_threads=False)
    if actual.num_rows != expected.num_rows:
        raise ValueError("paridade SE: quantidade de linhas diferente")
    result = []
    for name in actual.column_names:
        left, right = expected[name].combine_chunks(), actual[name].combine_chunks()
        exact = left.equals(right)
        maximum = None
        if not exact and pa.types.is_floating(left.type):
            a, b = left.to_numpy(zero_copy_only=False), right.to_numpy(zero_copy_only=False)
            equal = bool(np.allclose(a, b, rtol=1e-12, atol=1e-12, equal_nan=True))
            maximum = float(np.nanmax(np.abs(a - b)))
        else:
            equal = exact
        result.append({"coluna": name, "igual_exato": exact, "igual_tolerancia": equal,
                       "max_diferenca": maximum})
        if not equal:
            raise ValueError("paridade SE falhou na coluna " + name)
    return {"arquivo": current.name, "linhas": actual.num_rows, "colunas": result}


def compare_controls(reference, current):
    with reference.open(encoding="utf-8-sig", newline="") as stream:
        old = list(csv.DictReader(stream))
    with current.open(encoding="utf-8-sig", newline="") as stream:
        new = list(csv.DictReader(stream))
    if len(old) != len(new) or not old or set(old[0]) != set(new[0]):
        raise ValueError("paridade SE: grade de controles mudou")
    count = 0
    for a, b in zip(old, new):
        for key in a:
            if a[key] != b[key]:
                try:
                    equal = math.isclose(float(a[key]), float(b[key]), rel_tol=1e-12, abs_tol=1e-12)
                except ValueError:
                    equal = False
                if not equal:
                    raise ValueError("paridade SE: controle " + a["celula"] + "/" + key)
                count += 1
    return {"controles": len(old), "campos_por_controle": len(old[0]),
            "campos_distintos_texto_mas_iguais_tolerancia": count, "todos_iguais": True}


def run_uf(uf, root, source_hashes, timeout):
    if psutil.virtual_memory().available < 4 * GIB:
        raise MemoryError("RAM livre <4GiB antes de " + uf + "; nenhum filho iniciado")
    if hashes(FONTES) != source_hashes:
        raise RuntimeError("codigo/referencias mudaram desde inicio; nao executar")
    originals = [BASE / uf / name for name in ["domicilios.parquet", "pessoas_geo.parquet",
                                               "domicilios_pesos.parquet", "pessoas_pesos.parquet"]]
    if uf == "se":
        originals += [PILOTO / "pesos/se/domicilios_pesos.parquet",
                      PILOTO / "pesos/se/pessoas_pesos.parquet",
                      PILOTO / "diagnosticos/se/controles.csv"]
    before = hashes(FONTES + originals)
    write_json(root / "manifestos" / (uf + "_antes.json"), before)
    result = {"uf": uf, "status": "iniciado", "natureza": "AUXILIAR_PARCIAL_NAO_PUBLICAVEL"}
    started = time.monotonic()
    try:
        projected = [project(BASE / uf / name, root / "entradas_parciais" / uf / name, cols)
                     for name, cols in [("domicilios.parquet", DOM), ("pessoas_geo.parquet", PES)]]
        write_json(root / "manifestos" / (uf + "_projecao.json"), projected)
        gc.collect()
        if psutil.virtual_memory().available < 4 * GIB:
            raise MemoryError("RAM livre <4GiB depois da projecao; nenhum filho iniciado")
        print("INICIANDO_R", uf, flush=True)
        result.update(run_r(uf, root, timeout))
        if result["exit_runner"] != 0 or result["interrupcao_recursos"]:
            raise RuntimeError("R nao concluiu: " + (result["interrupcao_recursos"] or result["log"]))
        if uf == "se":
            parity = {"arquivos": [compare_parquets(PILOTO / "pesos" / uf / name,
                root / "saidas_parciais" / uf / name) for name in ["domicilios_pesos.parquet", "pessoas_pesos.parquet"]],
                "controles": compare_controls(PILOTO / "diagnosticos/se/controles.csv",
                    root / "diagnosticos/se/controles.csv"), "aprovado": True}
            write_json(root / "paridade_se.json", parity)
        extracted = [project(root / "saidas_parciais" / uf / name,
            root / "pesos_com_chaves" / uf / name, keys + PESOS)
            for name, keys in [("domicilios_pesos.parquet", ["UF", "censobr_idhousehold"]),
                ("pessoas_pesos.parquet", ["UF", "censobr_idhousehold", "linha"])]]
        write_json(root / "manifestos" / (uf + "_pesos_com_chaves.json"), extracted)
        result["status"] = "concluido_auxiliar_parcial"
    except Exception as exc:
        result.update(status="falha", erro=str(exc), tipo_erro=type(exc).__name__)
    finally:
        after = hashes(FONTES + originals)
        changed = [name for name in before if before[name] != after[name]]
        write_json(root / "manifestos" / (uf + "_depois.json"), after)
        result.update(hashes_conferidos=len(before), hashes_alterados=changed,
                      segundos_total=round(time.monotonic() - started, 3))
        if changed:
            result.update(status="falha", erro="insumo/codigo alterado durante a UF")
        write_json(root / "resultados" / (uf + ".json"), result)
    print(json.dumps(result, ensure_ascii=False), flush=True)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--autorizar-execucao", action="store_true", required=True)
    parser.add_argument("--restantes", action="store_true", help="Exige --raiz com SE reduzido aprovado")
    parser.add_argument("--raiz", type=Path)
    parser.add_argument("--timeout", type=int, default=600)
    args = parser.parse_args()
    os.chdir(ROOT)
    pa.set_cpu_count(1)
    pa.set_io_thread_count(2)
    if args.restantes:
        if not args.raiz:
            parser.error("--restantes exige --raiz")
        root = args.raiz.resolve()
        if not root.is_relative_to(ROOT / "tmp/execucao_1960_20260922"):
            raise ValueError("raiz fora do staging permitido")
        with (root / "paridade_se.json").open(encoding="utf-8") as stream:
            if not json.load(stream)["aprovado"]:
                raise ValueError("SE ainda sem paridade")
        with (root / "resultados/se.json").open(encoding="utf-8") as stream:
            if json.load(stream)["status"] != "concluido_auxiliar_parcial":
                raise ValueError("SE nao concluido")
        with (root / "fontes_inicio.json").open(encoding="utf-8") as stream:
            source_hashes = json.load(stream)
        units = RESTANTES
    else:
        if args.raiz:
            parser.error("primeiro SE sempre cria raiz nova")
        root = ROOT / "tmp/execucao_1960_20260922" / ("pesos25_reduzido_" + datetime.now().strftime("%Y%m%d_%H%M%S_%f"))
        root.mkdir(parents=True, exist_ok=False)
        source_hashes = hashes(FONTES)
        write_json(root / "fontes_inicio.json", source_hashes)
        with (root / "LEIA_ANTES.txt").open("x", encoding="utf-8") as stream:
            stream.write("ARTEFATOS AUXILIARES PARCIAIS. NAO SAO MICRODADOS COMPLETOS.\n"
                "Nao publicar, compilar, alimentar targets nem substituir originais com estes arquivos.\n"
                "entradas/saidas_parciais contem somente colunas de calculo/validacao.\n"
                "pesos_com_chaves permite futura reuniao comprovada com originais, ainda nao executada.\n")
        units = ["se"]
    print("RAIZ_REDUZIDA", root.relative_to(ROOT).as_posix(), flush=True)
    results = []
    for uf in units:
        try:
            result = run_uf(uf, root, source_hashes, args.timeout)
        except Exception as exc:
            result = {"uf": uf, "status": "nao_iniciado", "erro": str(exc),
                      "tipo_erro": type(exc).__name__}
            write_json(root / "resultados" / (uf + "_nao_iniciado.json"), result)
            print(json.dumps(result, ensure_ascii=False), flush=True)
        results.append(result)
        if result["status"] != "concluido_auxiliar_parcial":
            # Nao relaxar a matematica nem prosseguir apos falha sem revisar sua causa.
            break
    ok = len(results) == len(units) and all(x["status"] == "concluido_auxiliar_parcial" for x in results)
    write_json(root / ("resumo_restantes.json" if args.restantes else "resumo_se.json"),
               {"concluido": ok, "resultados": results, "ufs_previstas": units})
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
