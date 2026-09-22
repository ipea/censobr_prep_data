"""Executa suites pequenas, uma instancia R por vez, sem targets ou reconstrucao."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time

SCRIPTS = [
    "test_guardas_familias_situacao_1960.R", "test_nacionalidade_registros_1960.R",
    "test_integridade_amostra_127.R", "test_novas_duplicatas_1960.R",
    "test_novos_vinculos_1960.R", "test_reparos_fonte25_1960.R",
    "test_reparos_fonte25_guardas_1960.R", "test_geografia_registros_1960.R",
    "test_recuperacao_cartoes_1960.R", "test_contagens_registros_1960.R",
    "test_validacao_1960.R", "test_validacao_amostra_127.R", "test_pesos_1960.R",
]


def checksum(path):
    result = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(4 * 1024 ** 2):
            result.update(block)
    return result.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--start", choices=SCRIPTS)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = (root / args.out).resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida deve ficar sob tmp do projeto")
    out.mkdir(parents=True, exist_ok=False)
    scripts = SCRIPTS[SCRIPTS.index(args.start):] if args.start else SCRIPTS
    paths = [root / "references" / name for name in SCRIPTS]
    paths += list((root / "R").glob("microdata_1960*.R"))
    paths += list((root / "read_guides").glob("1960_amostra_127_*"))
    paths += [root / "_targets.R", root / "references/ler_fixtures_registros_1960.R",
              root / "references/fechamento_registros_1960_evidencias/fixtures_decisoes.json"]
    paths += [root / "data_raw/microdata/1960/amostra_127" / name for name in
              ["HHOLDA.txt", "pessoas_1960_amostra_127.parquet", "domicilios_1960_amostra_127.parquet"]]
    before = {p.relative_to(root).as_posix(): checksum(p) for p in paths}
    results = []
    for script in scripts:
        print("TESTE", script, flush=True)
        log = out / (Path(script).stem + ".log")
        command = [sys.executable, "references/rodar_r_isolado_1960.py", "references/" + script,
                   str(log.relative_to(root)), "--windows-arch", "--locale-c", "--timeout", "360"]
        started = time.monotonic()
        execution = subprocess.run(command, cwd=root, stdin=subprocess.DEVNULL,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        results.append({"script": script, "exit_code": execution.returncode,
                        "segundos": round(time.monotonic() - started, 3),
                        "log": log.relative_to(root).as_posix(), "log_sha256": checksum(log) if log.exists() else None})
        changed = [name for name, value in before.items() if checksum(root / name) != value]
        report = {"aprovado": execution.returncode == 0 and not changed and len(results) == len(scripts),
                  "testes": results, "fontes_codigo_antes": before, "arquivos_alterados": changed,
                  "limite": "Somente suites pequenas; nao e reconstrucao da base ou aprovacao dos registros indeterminados."}
        (out / "resultado.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print("RESULTADO", script, execution.returncode, results[-1]["segundos"], flush=True)
        if execution.returncode or changed:
            print(execution.stdout.decode("utf-8", errors="replace"), flush=True)
            if changed:
                print("Fontes/codigo mudaram durante testes:", changed, flush=True)
            return 1
    print("TODOS_APROVADOS", len(results), out.relative_to(root).as_posix(), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
