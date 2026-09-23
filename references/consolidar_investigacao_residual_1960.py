"""Concilia cobertura e preserva resultados pequenos da investigacao, sem alterar dados."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "references/investigacao_residual_1960_evidencias"


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_new(path, value):
    with path.open("x", encoding="utf-8") as f:
        json.dump(value, f, ensure_ascii=False, indent=2)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--families", required=True, type=Path)
    parser.add_argument("--sources", required=True, type=Path)
    args = parser.parse_args()
    old = read(ROOT / "references/fechamento_registros_1960_evidencias/inventario_final.json")
    dup = read(EVIDENCE / "duplicatas_cobertura463.json")
    link = read(EVIDENCE / "vinculos_casos.json")
    text = read(ROOT / "references/investigacao_residual_texto_1960_evidencias.json")
    families = read(ROOT / args.families)
    sources = read(ROOT / args.sources)
    expected_dups = {tuple(g["linhas"]) for g in old["duplicatas_pendentes"]}
    assert {tuple(g["linhas127"]) for g in dup["grupos"]} == expected_dups
    assert len(dup["grupos"]) == 463
    covered = {r["linha"] for r in link["cobertura_cada_pessoa"]}
    expected_link = {r["linha"] for r in old["vinculos_pendentes"] + old["conflitos_municipais"] + old["conflitos_situacao"]}
    corrupt = set(link["resumo"]["registros_corrompidos_fora_de_busca_por_igualdade"])
    assert covered | corrupt == expected_link
    cases = defaultdict(set)
    for group in old["duplicatas_pendentes"]:
        for n in group["linhas"]:
            cases[n].add("repeticao_pessoal_pendente_anterior")
    for name in ["vinculos_pendentes", "conflitos_municipais", "conflitos_situacao", "cartoes_sem_pessoas", "conviventes_sem_principal"]:
        for row in old[name]:
            cases[row["linha"]].add(name)
    for row in text["inventario124"]:
        cases[row["linha"]].add("texto_revisitado_124_nao_equivale_pendente")
    for n in text["cobertura"]["dez_falsas_igualdades_nos22_antigos"]:
        cases[n].add("dano_textual_igualdade_artificial_NA")
    for group in families["conjuntos"]:
        for card in group["cartoes"]:
            cases[card["linha"]].add("cartao_de_composicao_coincidente_entre_chaves")
            for n in card["pessoas"]:
                cases[n].add("pessoa_de_composicao_coincidente_entre_chaves")
    counts = Counter(tag for tags in cases.values() for tag in tags)
    result = {"nota": "Livro de cobertura, nao lista de exclusoes. Categorias sobrepostas; texto_revisitado inclui casos ja resolvidos.",
              "cobertura_conferida": {"grupos_repetidos": len(expected_dups), "linhas_vinculos_e_conflitos": len(expected_link),
                                      "registros_textuais_revisitados": len(text["inventario124"])},
              "contagem_por_marcacao_nao_somar": dict(counts),
              "registros": [{"linha": n, "marcacoes": sorted(tags)} for n, tags in sorted(cases.items())],
              "decisoes_aplicadas": 0}
    write_new(EVIDENCE / "cobertura_integrada.json", result)
    write_new(EVIDENCE / "familias_coincidentes.json", families)
    write_new(EVIDENCE / "fontes_documentais.json", sources)
    paths = list(EVIDENCE.glob("*.json")) + list((ROOT / "references").glob("*investigacao*1960*.py")) + list((ROOT / "references").glob("investigacao_residual*1960*.md"))
    paths += list((ROOT / "references").glob("investigacao_residual_texto_1960*.json"))
    paths += [EVIDENCE / "LEIAME.md", ROOT / "references/conferir_complementos_residuais_texto_1960.py",
              ROOT / ".claude/plans/2026-09-22_investigacao_residual_registros.md"]
    index = {"arquivos": [{"arquivo": str(p.relative_to(ROOT)).replace("\\", "/"), "bytes": p.stat().st_size,
                             "sha256": hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(set(paths))],
             "nota": "Assinaturas dos arquivos desta investigacao; nao certificado de verdade historica das correspondencias."}
    write_new(EVIDENCE / "indice.json", index)
    print(json.dumps(result["cobertura_conferida"]))


if __name__ == "__main__":
    main()
