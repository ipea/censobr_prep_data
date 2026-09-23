"""Testes residuais e regressao, sempre com uma unica instancia R isolada."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import time

from verificar_fechamento_registros_1960 import SCRIPTS, checksum

NOVOS = [
    "test_dependencias_residuais_1960.R",
    "test_resolucao_duplicatas_1960.R",
    "test_vinculos_chaves_incompletas_1960.R",
    "test_distrito_pe_operacional_1960.R",
    "test_cartoes_chaves_fonte25_1960.R",
    "test_resolucao_familias_coincidentes_1960.R",
    "test_reparos_residuais_texto_1960.R",
    "test_idade_ignorada_q34_residuais_1960.R",
    "test_geografia_validacao_residuais_1960.R",
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--scripts", nargs="+", help="Recorte explicito de testes, sem omitir o seu registro.")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = (root / args.out).resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida deve ficar sob tmp do projeto")
    out.mkdir(parents=True, exist_ok=False)
    scripts = args.scripts or NOVOS + SCRIPTS
    if any(Path(name).name != name or not name.startswith("test_") or not name.endswith(".R") for name in scripts):
        raise ValueError("Somente scripts de teste .R em references")
    paths = [root / "references" / name for name in scripts]
    paths += list((root / "R").glob("microdata_1960*.R"))
    paths += list((root / "read_guides").glob("1960_amostra_127_*"))
    paths += [root / "_targets.R", root / "references/rodar_r_isolado_1960.py"]
    paths += [p for p in (root / "references/resolucao_residuais_1960_evidencias").rglob("*.json")]
    paths += list((root / "references").glob("resolucao_residuais_duplicatas*evidencias.json"))
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
                  "scripts_solicitados": scripts, "testes": results, "fontes_codigo_antes": before,
                  "arquivos_alterados": changed,
                  "limite": "Testes pequenos; nao reconstruiram os parquets nem homologam casos historicos indeterminados."}
        (out / "resultado.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
        print("RESULTADO", script, execution.returncode, results[-1]["segundos"], flush=True)
        if execution.returncode or changed:
            print(execution.stdout.decode("utf-8", errors="replace"), flush=True)
            print("Arquivos alterados durante os testes:", changed, flush=True)
            return 1
    print("TODOS_APROVADOS", len(results), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
