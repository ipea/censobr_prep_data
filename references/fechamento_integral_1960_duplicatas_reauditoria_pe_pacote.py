"""Emite patches PE após reauditoria; não edita a prova vigente."""

import argparse
import difflib
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import sha256

ROOT = Path(__file__).resolve().parents[1]
OLD = "references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"
ARCHIVE = "references/fechamento_integral_1960_evidencias/distrito_pe_operacional_anterior.json"
REAUDIT = "references/fechamento_integral_1960_evidencias/distrito_pe_reauditoria.json"


def main(archive_only):
    old_text = (ROOT / OLD).read_text(encoding="utf-8")
    baseline = OLD if archive_only else ARCHIVE
    old = json.loads((ROOT / baseline).read_text(encoding="utf-8"))
    proof = json.loads((ROOT / REAUDIT).read_text(encoding="utf-8"))
    assert proof["prova_anterior"]["sha256"] == sha256(ROOT / baseline)
    assert proof["alternativas_sob_toda_chave_legivel"] == 0
    assert not proof["vinculos_pendentes"]
    assert proof["testemunha_previa_sem_V208"] == old["testemunha_previa_sem_V208"]
    assert proof["testemunha_recontada"]["linhas127_brutas"] == [238423]
    assert proof["testemunha_recontada"]["linhas25"] == [902375]
    if archive_only:
        assert not (ROOT / ARCHIVE).exists()
        print("*** Begin Patch\n*** Add File: " + ARCHIVE)
        print("\n".join("+" + line for line in old_text.splitlines()))
        print("*** End Patch")
        return
    assert json.loads((ROOT / ARCHIVE).read_text(encoding="utf-8")) == old
    old["prova_alternativas"] = REAUDIT
    old["pistas_amplas_examinadas"] = proof["cartoes_concorrentes_examinados"]
    old["pistas_amplas_que_exigiriam_trocar_boletim_legivel"] = proof["alternativas_restantes_busca_ampla"]
    old["fontes"] = [{"arquivo": r["arquivo"], "sha256": sha256(ROOT / r["arquivo"])}
                     for r in old["fontes"] if r["arquivo"] != "references/resolucao_residuais_1960_evidencias/distrito_pe_proposta.json"]
    old["fontes"].append({"arquivo": REAUDIT, "sha256": sha256(ROOT / REAUDIT)})
    new_text = json.dumps(old, ensure_ascii=False, indent=2) + "\n"
    diff = list(difflib.unified_diff(old_text.splitlines(True), new_text.splitlines(True), n=3))
    print("*** Begin Patch\n*** Update File: " + OLD)
    for line in diff[2:]:
        print("@@" if line.startswith("@@") else line.rstrip("\n"))
    print("*** End Patch")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive-only", action="store_true")
    main(parser.parse_args().archive_only)
