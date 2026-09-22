"""Executa um arquivo R de teste com log, prazo e sem dialogos nativos de falha.

Nao altera configuracoes do Windows nem escolhe/encerra processos existentes.
O destino do log deve ser novo e ficar dentro deste projeto.
"""
import argparse
import ctypes
import os
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("script", type=Path)
parser.add_argument("log", type=Path)
parser.add_argument("--r", default="C:/Program Files/R/R-4.5.0/bin/x64/Rscript.exe")
parser.add_argument("--timeout", type=int, default=60)
parser.add_argument("--rterm", action="store_true")
parser.add_argument("--locale-c", action="store_true")
parser.add_argument("--windows-arch", action="store_true")
args = parser.parse_args()
script = args.script.resolve()
log = args.log.resolve()
if not script.is_relative_to(root) or not log.is_relative_to(root):
    raise ValueError("Script e log devem ficar no projeto")
if os.name == "nt":
    # Heranca documentada: flags afetam somente este processo e o filho.
    ctypes.windll.kernel32.SetErrorMode(0x0001 | 0x0002)
env = os.environ.copy()
env["OMP_NUM_THREADS"] = "1"
env["ARROW_NUM_THREADS"] = "1"
env["RENV_CONFIG_AUTOLOADER_ENABLED"] = "FALSE"
if args.locale_c:
    env["LANG"] = "C"
    env["LC_ALL"] = "C"
if args.windows_arch and os.name == "nt":
    # cli/src/thread.c compara getenv() sem testar NULL no encerramento.
    # GetNativeSystemInfo informa a arquitetura real, sem alterar o Windows.
    system_info = ctypes.create_string_buffer(64)
    ctypes.windll.kernel32.GetNativeSystemInfo(ctypes.byref(system_info))
    architecture = ctypes.c_ushort.from_buffer(system_info).value
    names = {0: "x86", 5: "ARM", 9: "AMD64", 12: "ARM64"}
    env["PROCESSOR_ARCHITECTURE"] = names[architecture]
    print("PROCESSOR_ARCHITECTURE do filho:", env["PROCESSOR_ARCHITECTURE"], flush=True)
cmd = [args.r, "--vanilla"]
cmd += ["--slave", "--file=" + str(script)] if args.rterm else [str(script)]
log.parent.mkdir(parents=True, exist_ok=True)
temporary = log.parent / (log.stem + "_temp")
temporary.mkdir(exist_ok=False)
env["TMPDIR"] = str(temporary)
env["TMP"] = str(temporary)
env["TEMP"] = str(temporary)
print("Executando:", Path(args.r).name, script.name, "| log:", log.relative_to(root), flush=True)
with log.open("x", encoding="utf-8") as stream:
    stream.write("R: " + args.r + "\nScript: " + str(script.relative_to(root)) + "\n")
    stream.write("PROCESSOR_ARCHITECTURE: " + env.get("PROCESSOR_ARCHITECTURE", "ausente") + "\n")
    stream.flush()
    process = subprocess.Popen(cmd, cwd=root, env=env, stdin=subprocess.DEVNULL,
        stdout=stream, stderr=subprocess.STDOUT,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
    try:
        code = process.wait(timeout=args.timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        stream.write("\nRunner: prazo excedido; encerrado somente este processo.\n")
        print("Prazo excedido; encerrado somente o processo iniciado por este teste.")
        sys.exit(124)
    stream.write("\nExit code: " + str(code) + " hex: " + hex(code & 0xffffffff) + "\n")
print(log.read_text(encoding="utf-8", errors="replace"))
print("Exit code:", code, "hex:", hex(code & 0xffffffff))
sys.exit(0 if code == 0 else 1)
