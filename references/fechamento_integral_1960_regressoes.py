"""Executa as regressões de 1960, em série e com logs novos, sem targets."""
from datetime import datetime
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--script", nargs="+")
parser.add_argument("--timeout", type=int, default=1200)
args = parser.parse_args()
out = root / "tmp/fechamento_integral_1960/regressoes" / datetime.now().strftime("%Y%m%d_%H%M%S_%f")
out.mkdir(parents=True, exist_ok=False)
scripts = [
    "fechamento_integral_1960_vinculos_mg_teste.R",
    "fechamento_integral_1960_vinculos_teste.R",
    "test_reparos_fonte25_1960.R",
    "test_reparos_fonte25_guardas_1960.R",
    "test_recuperacao_cartoes_1960.R",
    "fechamento_integral_1960_duplicatas_teste_sp.R",
    "test_resolucao_duplicatas_1960.R",
    "test_novas_duplicatas_1960.R",
    "test_distrito_pe_operacional_1960.R",
    "test_cartoes_chaves_fonte25_1960.R",
    "test_dependencias_residuais_1960.R",
    "test_integridade_amostra_127.R",
    "test_guardas_familias_situacao_1960.R",
    "test_vinculos_chaves_incompletas_1960.R",
    "test_reparos_residuais_texto_1960.R",
    "test_geografia_registros_1960.R",
    "test_geografia_validacao_residuais_1960.R",
    "test_validacao_1960.R",
    "test_validacao_amostra_127.R",
    "test_aluguel_ignorado_1960.R",
    "test_deteccao_isolada_1960.R",
    "test_pesos_1960.R",
    "test_procedencia_compilacao_1960.R",
    "test_exportacao_sem_conferencia_1960.R",
    "test_publicacao_1960.R",
]
if args.script:
    scripts = args.script
env = os.environ.copy()
env["CENSOBR_TEST_PESOS_ARROW"] = "1"
results = []
print("Saída:", out.relative_to(root), flush=True)
for script in scripts:
    path = root / "references" / script
    sha = hashlib.sha256(path.read_bytes()).hexdigest()
    log = out / (path.stem + ".log")
    result = subprocess.run([
        sys.executable, "-X", "utf8", "references/rodar_r_isolado_1960.py",
        str(path), str(log), "--windows-arch", "--locale-c", "--timeout", str(args.timeout),
    ], cwd=root, env=env, capture_output=True, text=True, encoding="utf-8")
    text = log.read_text(encoding="utf-8") if log.exists() else result.stderr
    entry = dict(script=script, sha256=sha, codigo=result.returncode,
                 log=str(log.relative_to(root)), ultimas_linhas=text.splitlines()[-12:])
    results.append(entry)
    (out / "resultados.json").write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    print(script, "PASS" if result.returncode == 0 else "FALHOU", flush=True)
    if result.returncode:
        print("\n".join(entry["ultimas_linhas"]), flush=True)
print("Aprovados:", sum(r["codigo"] == 0 for r in results), "/", len(results), flush=True)
sys.exit(0 if all(r["codigo"] == 0 for r in results) else 1)
