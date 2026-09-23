"""Registra assinaturas da entrega residual concluida, sem substituir indice existente."""
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "references/resolucao_residuais_1960_evidencias"


def main():
    output = EVIDENCE / "indice.json"
    notes = [ROOT / "references/resolucao_residuais_registros_1960_20260922.md",
             ROOT / "references/resolucao_residuais_duplicatas_1960.md",
             ROOT / "references/resolucao_residual_texto_1960.md",
             ROOT / "references/resolucao_residual_vinculos_1960.md", EVIDENCE / "LEIAME.md"]
    paths = set(notes) | set(EVIDENCE.iterdir())
    paths.update((ROOT / "references").glob("resolucao_residuais_duplicatas*.json"))
    paths.update((ROOT / "read_guides").glob("1960_amostra_127_*.csv"))
    paths.update((ROOT / "read_guides").glob("1960_amostra_127_*.json"))
    paths.update([ROOT / "R/microdata_1960_amostra_127.R", ROOT / "_targets.R",
                  ROOT / ".gitattributes", ROOT / ".claude/plans/2026-09-22_resolver_residuais_registros.md",
                  ROOT / "references/fechamento_registros_1960_evidencias/fixtures_decisoes.json"])
    scripts = [
        "verificar_resolucao_residuais_1960.py", "consolidar_resolucao_residuais_1960.py",
        "verificar_testes_python_residuais_1960.py",
        "verificar_fechamento_registros_1960.py", "rodar_r_isolado_1960.py",
        "ler_fixtures_registros_1960.R", "inventario_final_registros_1960.py",
        "investigacao_familias_repetidas_1960.py", "conferir_coincidencias_operacionais_residuais_1960.py",
        "conferir_integracao_residuais_1960.py", "conferir_fontes_residuais_adicionais_1960.py",
        "indexar_resolucao_residuais_1960.py", "resolver_cartoes_chaves_fonte25_1960.py",
        "resolver_vinculos_chaves_incompletas_1960.py", "conferir_distrito_pe_residual_1960.py",
        "preparar_distrito_pe_operacional_1960.py", "preparar_reparos_residuais_texto_1960.py",
        "conferir_disposicao_sp_gb_texto_1960.py", "conferir_limite_unipessoal_residual_1960.py",
        "conferir_segunda_testemunha_rs_1960.py", "conferir_preservacao_ce_1960.py",
        "aprofundar_preservacao_duplicatas_1960.py", "aplicar_residuais_duplicatas_1960.py",
        "consolidar_preservacoes_duplicatas_1960.py", "preparar_disposicoes_familias_1960.py",
    ]
    paths.update(ROOT / "references" / name for name in scripts)
    for report in EVIDENCE.glob("bateria_*.json"):
        if report.name == "bateria_python.json":
            continue
        data = json.loads(report.read_text(encoding="utf-8"))
        paths.update(ROOT / "references" / t["script"] for t in data["testes"])
    tested_python = ["test_aplicar_residuais_duplicatas_1960.py", "test_preservacao_alternativos_1960.py",
        "test_preservacao_composta_ce_1960.py", "test_disposicoes_familias_1960.py",
        "test_preparar_reparos_residuais_texto_1960.py", "test_resolver_cartoes_chaves_fonte25_1960.py",
        "test_resolver_vinculos_chaves_incompletas_1960.py"]
    paths.update(ROOT / "references" / name for name in tested_python)
    checked_links = []
    for note in notes:
        for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", note.read_text(encoding="utf-8")):
            if target.startswith(("https://", "http://", "#")):
                continue
            local = (note.parent / target.split("#")[0]).resolve()
            assert local.exists() or local == output, (note, target)
            checked_links.append({"nota": note.relative_to(ROOT).as_posix(), "alvo": target})
    paths.discard(output)
    entries = []
    for path in sorted(paths):
        assert path.is_file(), path
        entries.append({"arquivo": path.relative_to(ROOT).as_posix(), "bytes": path.stat().st_size,
                        "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    with output.open("x", encoding="utf-8") as f:
        json.dump({"arquivos": entries, "links_locais_conferidos": checked_links,
                   "nota": "Assinaturas da entrega; nao sao prova autonoma da verdade historica dos registros."},
                  f, ensure_ascii=False, indent=2)
    print(json.dumps({"arquivos_indexados": len(entries), "links_locais_conferidos": len(checked_links)}))


if __name__ == "__main__":
    main()
