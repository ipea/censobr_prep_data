"""Refaz fatos da prova PE após mudanças em manifestos, sem alterar a produção."""

import argparse
import copy
import gzip
import json
from pathlib import Path

import auditoria_recuperacao_cartoes_1960 as core
import conferir_distrito_pe_residual_1960 as prior
from preparar_reparos_residuais_texto_1960 import mascarar

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "references/fechamento_integral_1960_evidencias/distrito_pe_reauditoria.json"
OLD = "references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"
ARCHIVE = "references/fechamento_integral_1960_evidencias/distrito_pe_operacional_anterior.json"


def run(index, provenance):
    if OUTPUT.exists():
        raise FileExistsError(OUTPUT)
    before = {name: core.sha256(ROOT / name) for name in core.FIXED_SOURCES}
    index_proof = json.loads(provenance.read_text(encoding="utf-8"))
    files = index_proof.get("fontes_sha256") or {r["arquivo"]: r["sha256"] for r in index_proof["fontes"]}
    if any(files.get(name) != digest for name, digest in before.items()):
        raise ValueError("Índice sem procedência compatível com os manifestos atuais")
    index_hash = core.sha256(index)
    if index_proof.get("indice_atual_sha256", index_hash) != index_hash:
        raise ValueError("Hash do índice diverge da sua auditoria")
    prior.INDEX = index.relative_to(ROOT).as_posix()
    facts = prior.inspect()
    baseline = ARCHIVE if (ROOT / ARCHIVE).exists() else OLD
    old = json.loads((ROOT / baseline).read_text(encoding="utf-8"))
    expected = [238423, 239457, 239458, 239459, 239460, 239461]
    assert [r["linha"] for r in facts["pessoas127"]] == expected
    assert facts["vinculos_pendentes"] == []
    assert all(r["familia_atual"] == 238422 for r in facts["pessoas127"])
    assert facts["cartao127"]["original"] == old["cartao127"]["original"]
    assert facts["cartao127"]["corrigido"] == old["cartao127"]["corrigido"]
    assert [(r["linha"], r["original"], r["corrigido"]) for r in facts["pessoas127"]] == [
        (r["linha"], r["original"], r["corrigido"]) for r in old["pessoas127"]]
    assert facts["cartao25"] == old["cartao25"] and facts["pessoas25"] == old["pessoas25"]
    assert facts["cartao25"]["texto"][29:36] == "2166075"
    assert facts["testemunha_previa_sem_V208"] == old["testemunha_previa_sem_V208"]

    corrections = {int(r["linha"]): r for r in core.rows(ROOT / core.FIXED_SOURCES[1])}
    links = {int(r["linha"]): r for r in core.rows(ROOT / core.FIXED_SOURCES[3])}
    for line in expected[1:]:
        assert int(links[line]["linha_familia"]) == 238422
    target = facts["pessoas127"][0]
    mask = mascarar(target["original"], "127", ["V208"])
    assert mask == facts["testemunha_previa_sem_V208"]["mascara"]
    assert target["original"][27] == " " and target["corrigido"][27] == "9"
    assert target["original"][:27] + "9" + target["original"][28:] == target["corrigido"]
    assert target["original"][6:8] == target["corrigido"][6:8] == "X7"
    hits_raw = []
    hits_current = []
    literals = {}
    needed = {238422, *expected}
    with (ROOT / core.FIXED_SOURCES[0]).open(encoding="latin1") as stream:
        for line, raw in enumerate(stream, 1):
            raw = raw.rstrip("\r\n")
            if line in needed:
                literals[line] = raw
            current = corrections.get(line, {}).get("texto_corrigido") or raw
            if raw[:2] == "21" and raw[16] in "23" and mascarar(raw, "127", ["V208"]) == mask:
                hits_raw.append(line)
            if current[:2] == "21" and current[16] in "23" and mascarar(current, "127", ["V208"]) == mask:
                hits_current.append(line)
    for record in [facts["cartao127"], *facts["pessoas127"]]:
        assert record["original"] == literals[record["linha"]]
        assert record["corrigido"] == (corrections.get(record["linha"], {}).get("texto_corrigido") or literals[record["linha"]])
    hits25 = []
    pe_path = "data/release_legacy/Censo.1960.amostra.25porcento.pe.gz"
    with gzip.open(ROOT / pe_path, "rt", encoding="latin1") as stream:
        for line, text in enumerate(stream, 1):
            text = text.rstrip("\r\n")
            if text[8:10] != "00" and mascarar(text, "25", ["V208"]) == mask:
                hits25.append(line)
    assert hits_raw == hits_current == [238423] and hits25 == [902375]
    # As pistas amplas só permanecem alternativas se se permitir substituir
    # um boletim que é inteiramente legível no alvo e em seus seis integrantes.
    broad = [r for r in facts["conferencia_concorrentes"] if r["motivos_alternativa"]]
    assert [r["linha"] for r in broad] == facts["alternativas_restantes_busca_ampla"]
    for record in broad:
        assert record["texto_corrigido"][13:16].isdigit()
        assert record["texto_corrigido"][13:16] != "154"
    assert len(facts["cartoes127_mesma_chave_territorio"]) == 1
    assert facts["cartoes127_mesma_chave_territorio"][0]["linha"] == 238422
    assert all(core.sha256(ROOT / name) == digest for name, digest in before.items())
    assert core.sha256(index) == index_hash

    result = copy.deepcopy(facts)
    result.update({
        "versao_reauditoria": 1,
        "id": "PE-22366-154-distrito-reauditoria",
        "prova_anterior": {"arquivo": baseline, "arquivo_original": OLD, "sha256": core.sha256(ROOT / baseline)},
        "indice": {"arquivo": index.relative_to(ROOT).as_posix(), "sha256": index_hash,
                   "procedencia": provenance.relative_to(ROOT).as_posix(), "procedencia_sha256": core.sha256(provenance)},
        "testemunha_recontada": {"linhas127_brutas": hits_raw, "linhas127_corrigidas": hits_current,
                                 "linhas25": hits25, "campos_ignorados": ["V208"], "distrito_usado_no_pareamento": False},
        "alternativas_sob_toda_chave_legivel": 0,
        "vinculos_atualizados": expected[1:],
        "textos_geograficos_originais_preservados": True,
        "respostas_pessoais_adicionais_alteradas": False,
        "fontes_atuais_sha256": before,
        "script_sha256": core.sha256(Path(__file__)),
        "limite": "Confirma a mesma derivação operacional X7 para07; não autoriza mudar qualquer dígito legível nem corrige V21600/63."
    })
    OUTPUT.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"prova": OUTPUT.relative_to(ROOT).as_posix(), "cartoes_examinados": facts["cartoes_concorrentes_examinados"],
                      "alternativas_amplas": facts["alternativas_restantes_busca_ampla"], "vinculos_pendentes": facts["vinculos_pendentes"],
                      "testemunha": result["testemunha_recontada"]}, ensure_ascii=False))


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--index", required=True)
    parser.add_argument("--provenance", required=True)
    args = parser.parse_args()
    run((ROOT / args.index).resolve(), (ROOT / args.provenance).resolve())
