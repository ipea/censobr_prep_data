"""Executa os testes Python localizados e conserva resultado e assinaturas."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import unittest

FILES = ["test_aplicar_residuais_duplicatas_1960.py", "test_preservacao_alternativos_1960.py",
         "test_preservacao_composta_ce_1960.py", "test_disposicoes_familias_1960.py",
         "test_preparar_reparos_residuais_texto_1960.py", "test_resolver_cartoes_chaves_fonte25_1960.py",
         "test_resolver_vinculos_chaves_incompletas_1960.py"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = (root / args.out).resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida deve ficar em tmp do projeto")
    out.mkdir(parents=True, exist_ok=False)
    suite = unittest.TestSuite()
    paths = [root / "references" / name for name in FILES]
    before = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    for name in FILES:
        suite.addTests(unittest.defaultTestLoader.discover(str(root / "references"), pattern=name))
    stream = io.StringIO()
    result = unittest.TextTestRunner(stream=stream, verbosity=2).run(suite)
    assert before == {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
    log = stream.getvalue()
    (out / "testes_python.log").write_text(log, encoding="utf-8")
    report = {"aprovado": result.wasSuccessful(), "testes": result.testsRun,
              "falhas": len(result.failures), "erros": len(result.errors), "scripts_sha256": before,
              "log_sha256": hashlib.sha256((out / "testes_python.log").read_bytes()).hexdigest()}
    (out / "resultado.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(log)
    print(json.dumps(report, ensure_ascii=False))
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
