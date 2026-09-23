"""Concilia antes/depois e preserva provas pequenas, sem sobrescrever o caderno anterior."""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path

from verificar_resolucao_residuais_1960 import NOVOS, SCRIPTS

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "references/resolucao_residuais_1960_evidencias"
PENDING = {}


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        while chunk := f.read(4 * 1024 ** 2):
            h.update(chunk)
    return h.hexdigest()


def write_new(name, value):
    assert name not in PENDING
    PENDING[name] = json.dumps(value, ensure_ascii=False, indent=2).encode("utf-8")


def copy_new(source, name):
    assert name not in PENDING
    PENDING[name] = source.read_bytes()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--inventory", type=Path, required=True)
    parser.add_argument("--integration", type=Path, required=True)
    parser.add_argument("--sources", type=Path, required=True)
    parser.add_argument("--families", type=Path, required=True)
    parser.add_argument("--operational", type=Path, required=True)
    parser.add_argument("--tests", type=Path, nargs="+", required=True)
    parser.add_argument("--before", type=Path, nargs="*", default=[])
    parser.add_argument("--python", type=Path, required=True)
    args = parser.parse_args()
    DEST.mkdir(exist_ok=True)
    old = read(ROOT / "references/fechamento_registros_1960_evidencias/inventario_final.json")
    current = read(ROOT / args.inventory)
    integrated = read(ROOT / args.integration)
    historical = read(ROOT / "references/investigacao_residual_1960_evidencias/cobertura_integrada.json")
    links = read(ROOT / "references/investigacao_residual_1960_evidencias/vinculos_casos.json")
    families = read(ROOT / "read_guides/1960_amostra_127_familias_coincidentes.json")
    searched_families = read(ROOT / args.families)
    operational = read(ROOT / args.operational)
    assert operational["resumo"]["cartoes_recuperados"] == 32
    assert operational["resumo"]["pessoas_recuperadas"] == 80
    assert operational["resumo"]["coincidencias_recuperado_real"] == 0
    assert operational["resumo"]["coincidencias_entre_recuperados"] == 0
    assert operational["resumo"]["PE_cartoes_reais_mesmos15campos_ignorando_distrito"] == [238422]
    assert not operational["resumo"]["PE_coincidencias_com_recuperados"]
    for name, value in operational["fontes_sha256"].items():
        assert digest(ROOT / name) == value, name
    assert {tuple(sorted(c["linha"] for c in g["cartoes"])) for g in searched_families["conjuntos"]} == {
        tuple(sorted(g["linhas_cartoes"])) for g in families["conjuntos"]}
    recovery = read(ROOT / "read_guides/1960_amostra_127_cartoes_recuperados.json")
    with (ROOT / "read_guides/1960_amostra_127_duplicatas.csv").open(encoding="utf-8-sig", newline="") as f:
        duplicates = {int(r["linha"]): r for r in csv.DictReader(f)}

    old_groups = {tuple(g["linhas"]) for g in old["duplicatas_pendentes"]}
    new_groups = {tuple(g["linhas"]) for g in current["duplicatas_pendentes"]}
    assert new_groups <= old_groups
    resolved_groups = sorted(old_groups - new_groups)
    assert len(resolved_groups) == 5
    for group in resolved_groups:
        assert all(duplicates[n]["acao"] == "manter" for n in group)
    before_links = {r["linha"] for r in old["vinculos_pendentes"]}
    after_links = {r["linha"] for r in current["vinculos_pendentes"]}
    assert after_links <= before_links
    resolved_links = before_links - after_links
    recovered = {p["linha"] for c in recovery["cartoes"]
                 if c["id_recuperacao"] in integrated["novos_cartoes"] for p in c["pessoas"]}
    assert {142402, 259248} | recovered <= resolved_links
    assert all(not h["mudou"] for h in integrated["assinaturas_para_revalidar"])
    coverage_by_line = {r["linha"]: r for r in links["cobertura_cada_pessoa"]}
    old_pending = before_links | {r["linha"] for name in ["conflitos_municipais", "conflitos_situacao"] for r in old[name]}
    assert set(coverage_by_line) | {855822, 951432, 951433} == old_pending
    current_pending = after_links | {r["linha"] for name in ["conflitos_municipais", "conflitos_situacao"] for r in current[name]}
    classes = Counter(coverage_by_line[n]["classe"] if n in coverage_by_line else "fragmento_sem_grupo_identificavel"
                      for n in current_pending)
    by_line = {r["linha"]: {"linha": r["linha"], "marcacoes_historicas": r["marcacoes"],
               "disposicoes_nesta_rodada": []} for r in historical["registros"]}
    for group in resolved_groups:
        for n in group:
            by_line[n]["disposicoes_nesta_rodada"].append("manter_pessoa_com_prova_localizada")
    for n in resolved_links:
        by_line[n]["disposicoes_nesta_rodada"].append("cartao_familiar_recuperado" if n in recovered else "vinculo_confirmado")
    for n in [238423, 540394, 540399, 540461]:
        by_line[n]["disposicoes_nesta_rodada"].append("somente_nacionalidade_recuperada")
    for n in [238422, 238423]:
        by_line.setdefault(n, {"linha": n, "marcacoes_historicas": [], "disposicoes_nesta_rodada": []})
        by_line[n]["disposicoes_nesta_rodada"].append("distrito_operacional_recuperado_texto_preservado")
    for n in [760807, 760919, 760923, 760925, 761056, 761057, 761058, 806791, 806800, 806801]:
        by_line[n]["disposicoes_nesta_rodada"].append("dano_explicitado_sem_recuperacao_da_resposta")
    for group in families["conjuntos"]:
        for n in group["linhas_cartoes"] + group["linhas_pessoas"]:
            by_line[n]["disposicoes_nesta_rodada"].append("familias_coincidentes:" + group["acao"])
    for n in current_pending:
        by_line[n]["impedimento_vinculo_ou_geografia_permanece"] = True
        by_line[n]["classe_da_investigacao_anterior"] = coverage_by_line.get(n, {}).get("classe", "fragmento_sem_grupo_identificavel")
    for group in new_groups:
        for n in group:
            by_line[n]["repeticao_pessoal_permanece_pendente"] = True
    result = {
        "nota": "Cobertura nao e exclusao nem homologacao. As marcacoes se sobrepoem e nao devem ser somadas.",
        "antes": old["resumo"], "depois": current["resumo"],
        "grupos_pessoais_resolvidos_preservando": resolved_groups,
        "linhas_com_vinculo_resolvido": sorted(resolved_links),
        "pessoas_dos_novos_cartoes": sorted(recovered),
        "pendencias_vinculo_geografia_por_classe_anterior": dict(sorted(classes.items())),
        "limite_das_classes": "Classificacoes do caderno anterior, conciliadas com a lista atual; nao constituem nova busca global nem prova de inexistencia de fonte.",
        "registros": [by_line[n] for n in sorted(by_line)],
    }
    preserved = {}
    expected = {
        "data_raw/microdata/1960/amostra_127/HHOLDA.txt": "6449ca06c9086bbb0474481827f0efff98a0d9489838f322b4a69e489a42c44c",
        "data_raw/microdata/1960/amostra_127/pessoas_1960_amostra_127.parquet": "f757fddae54edddd6742ad800149a3086acc9f581a8197ec0a123d7f4efca404",
        "data_raw/microdata/1960/amostra_127/domicilios_1960_amostra_127.parquet": "f526ab6090d0be7dd9325a0f6b5143dab46186734f8760be8f44513924f93938",
    }
    for filename, value in expected.items():
        assert digest(ROOT / filename) == value, filename
        preserved[filename] = value
    # As rodadas interrompidas ficam preservadas. Para cada script vale a
    # ultima execucao documentada, que deve ter passado na versao entregue.
    last_results = {}
    for i, source in enumerate(args.tests, 1):
        report = read(ROOT / source)
        assert not report["arquivos_alterados"]
        copy_new(ROOT / source, f"bateria_{i:02d}.json")
        for test in report["testes"]:
            log = ROOT / test["log"]
            assert digest(log) == test["log_sha256"]
            name = f"teste_{i:02d}_{Path(test['log']).name}"
            copy_new(log, name)
            last_results[test["script"]] = ({**test, "log_portatil": name}, report)
    assert set(last_results) == set(NOVOS + SCRIPTS), "A entrega exige os 22 scripts distintos"
    test_results = []
    for script in NOVOS + SCRIPTS:
        test, report = last_results[script]
        assert test["exit_code"] == 0, script
        tested_path = "references/" + script
        assert digest(ROOT / tested_path) == report["fontes_codigo_antes"][tested_path], script
        for name, value in report["fontes_codigo_antes"].items():
            if Path(name).name.startswith("test_") and name.endswith(".R"):
                continue
            assert digest(ROOT / name) == value, name
        test_results.append(test)
    before_results = []
    for source in args.before:
        name = "antes_" + source.name
        copy_new(ROOT / source, name)
        before_results.append({"origem": source.as_posix(), "log_portatil": name,
                               "sha256": digest(ROOT / source),
                               "nota": "Registro da demonstracao anterior; nao e uma suite final aprovada."})
    write_new("cobertura_antes_depois.json", result)
    python_report = read(ROOT / args.python)
    assert python_report["aprovado"] and python_report["erros"] == python_report["falhas"] == 0
    assert python_report["testes"] == 32
    for name, value in python_report["scripts_sha256"].items():
        assert digest(ROOT / "references" / name) == value, name
    python_log = (ROOT / args.python).parent / "testes_python.log"
    assert digest(python_log) == python_report["log_sha256"]
    copy_new(ROOT / args.python, "bateria_python.json")
    copy_new(python_log, "testes_python.log")
    write_new("conferencia_entrega.json", {"brutos_e_parquets_preservados": preserved,
        "testes": test_results, "demonstracoes_antes": before_results,
        "scripts_R_distintos_aprovados": len(test_results),
        "criterio": "Ultima execucao de cada um dos 22 scripts aprovada; codigo, manifestos, provas e dados conferidos. Rodadas interrompidas preservadas, nao reclassificadas como integralmente aprovadas.",
        "nenhum_peso_recalculado": True, "nenhuma_pessoa_importada": True})
    copy_new(ROOT / args.inventory, "inventario_atual.json")
    copy_new(ROOT / args.integration, "integracao_cartoes.json")
    copy_new(ROOT / args.sources, "fontes_adicionais.json")
    copy_new(ROOT / args.families, "familias_reconferidas.json")
    copy_new(ROOT / args.operational, "coincidencias_operacionais.json")
    # Nenhuma copia e gravada antes de concluir todas as conferencias.
    assert all(not (DEST / name).exists() for name in PENDING), "Nao sobrescrever o caderno"
    for name, content in PENDING.items():
        with (DEST / name).open("xb") as stream:
            stream.write(content)
    print(json.dumps({"grupos_preservados": len(resolved_groups), "vinculos_resolvidos": len(resolved_links),
                      "registros_cobertura": len(by_line), "testes_R": len(test_results)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
