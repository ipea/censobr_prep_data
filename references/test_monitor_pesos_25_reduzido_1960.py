"""Teste do monitor com dois processos Python inofensivos; nunca executa R."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from types import SimpleNamespace
import unittest
from unittest import mock
import uuid

import psutil

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("executor_pesos25",
    ROOT / "references/recalibrar_pesos_25_reduzido_1960.py")
EXECUTOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EXECUTOR)
REAL_POPEN = subprocess.Popen
REAL_CHILDREN = psutil.Process.children
TEST_ROOT = ROOT / "tmp/execucao_1960_20260922" / ("teste_monitor_python_" + uuid.uuid4().hex)
TEST_ROOT.mkdir(parents=True, exist_ok=False)
RESULTS = []


class MonitorTest(unittest.TestCase):
    def check_failure(self, label, denied=False):
        folder = TEST_ROOT / label
        folder.mkdir()
        owned = []
        descendants = []
        error = psutil.AccessDenied(pid=0, name="monitor_simulado") if denied else RuntimeError("monitor_simulado")

        def harmless_runner(cmd, **kwargs):
            if len(cmd) > 1 and cmd[1] == "references/rodar_r_isolado_1960.py":
                harmless = "import subprocess,sys,time; subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)']); time.sleep(60)"
                process = REAL_POPEN([sys.executable, "-c", harmless], **kwargs)
                owned.append(process)
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    found = REAL_CHILDREN(psutil.Process(process.pid), recursive=True)
                    if found:
                        descendants.extend(found)
                        break
                    time.sleep(0.02)
                self.assertTrue(descendants, "filho Python de teste nao iniciou")
                return process
            # Permite apenas a limpeza nativa da arvore propria no fallback Windows.
            self.assertEqual(cmd[0], "taskkill.exe")
            self.assertEqual(cmd[1:3], ["/PID", str(owned[0].pid)])
            self.assertEqual(cmd[3:], ["/T", "/F"])
            return REAL_POPEN(cmd, **kwargs)

        try:
            with mock.patch.object(EXECUTOR.subprocess, "Popen", side_effect=harmless_runner):
                if denied:
                    with mock.patch.object(EXECUTOR.psutil, "virtual_memory", return_value=SimpleNamespace(available=8 * 2**30)), \
                            mock.patch.object(psutil.Process, "children", side_effect=error):
                        with self.assertRaises(psutil.AccessDenied) as caught:
                            EXECUTOR.run_r(label, folder, timeout=600)
                else:
                    with mock.patch.object(EXECUTOR.psutil, "virtual_memory",
                            side_effect=[SimpleNamespace(available=8 * 2**30), error]):
                        with self.assertRaises(RuntimeError) as caught:
                            EXECUTOR.run_r(label, folder, timeout=600)
            self.assertIs(caught.exception, error, "a causa original deve ser preservada")
            self.assertEqual(len(owned), 1)
            self.assertIsNotNone(owned[0].poll(), "runner Python permaneceu ativo")
            gone, alive = psutil.wait_procs(descendants, timeout=5)
            self.assertFalse(alive, "descendente Python permaneceu ativo")
            log = (folder / "logs" / (label + "_runner.log")).read_text(encoding="utf-8")
            self.assertIn("FALHA_MONITOR", log)
            self.assertIn("monitor_simulado", log)
            self.assertIn("LIMPEZA_MONITOR", log)
            RESULTS.append({"teste": label, "aprovado": True, "runner_pid": owned[0].pid,
                "descendentes_pids": [p.pid for p in descendants], "todos_encerrados": True,
                "causa_original_preservada": True, "nenhum_R_executado": True})
        finally:
            # Salvaguarda do proprio teste, restrita aos handles/PIDs que ele criou.
            for child in descendants:
                try:
                    if child.is_running():
                        child.kill()
                except psutil.NoSuchProcess:
                    pass
            for process in owned:
                if process.poll() is None:
                    process.kill()
                process.wait(timeout=5)

    def test_unexpected_monitor_error(self):
        self.check_failure("erro_inesperado")

    @unittest.skipUnless(os.name == "nt", "fallback de arvore especifico do Windows")
    def test_access_denied_monitor_and_cleanup(self):
        self.check_failure("access_denied", denied=True)


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(MonitorTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    with (TEST_ROOT / "resultado.json").open("x", encoding="utf-8") as stream:
        json.dump({"aprovado": result.wasSuccessful(), "testes": RESULTS,
                   "escopo": "Somente Python inofensivo; nenhum R/microdado"}, stream, ensure_ascii=False, indent=2)
    print("EVIDENCIA_MONITOR", TEST_ROOT.relative_to(ROOT).as_posix(), flush=True)
    sys.exit(0 if result.wasSuccessful() else 1)
