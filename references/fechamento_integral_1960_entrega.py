"""Confere integridade e produz o índice da entrega, sem certificar dados bloqueados."""
import argparse
import csv
from datetime import datetime
import hashlib
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--testes", type=Path, action="append", required=True)
parser.add_argument("--log-aprovado", type=Path, action="append", default=[])
parser.add_argument("--reconstrucao", type=Path, required=True)
parser.add_argument("--log-reconstrucao", type=Path, required=True)
parser.add_argument("--validacao25", type=Path, required=True)
parser.add_argument("--t7", type=Path, required=True)
args = parser.parse_args()

def sha(path):
    h = hashlib.sha256()
    with (root / path).open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()

protegidos = {
    "censobr_prep_data.Rproj": "aa1bb6b4e0ed0325d1e781f5b6eacf7549b809566866accf8ca605331d136816",
    "renv.lock": "cebd5e98542910cc17236a8c9ff3de2e87c66eb4b9a000eabd681a26bc5e3fff",
    "schemas/censobr_types.csv": "9bb56074c5d6b00cb8bc435bba4390c99d9543e431d572c1ea65f368f50790c2",
    "data_raw/microdata/1960/amostra_127/HHOLDA.txt": "6449ca06c9086bbb0474481827f0efff98a0d9489838f322b4a69e489a42c44c",
    "data_raw/microdata/1960/amostra_127/pessoas_1960_amostra_127.parquet": "f757fddae54edddd6742ad800149a3086acc9f581a8197ec0a123d7f4efca404",
    "data_raw/microdata/1960/amostra_127/domicilios_1960_amostra_127.parquet": "f526ab6090d0be7dd9325a0f6b5143dab46186734f8760be8f44513924f93938",
}
# O projeto já tinha alterações do usuário; comparar com o início, não com HEAD.
for path, expected in protegidos.items():
    assert sha(path) == expected, (path, sha(path), expected)

tests = []
for path in args.testes:
    entries = json.loads((root / path).read_text(encoding="utf-8"))
    tests.extend(entries)
ultimos = {x["script"]: x for x in tests}
assert all(x["codigo"] == 0 for x in ultimos.values()), [x for x in ultimos.values() if x["codigo"] != 0]
for path in args.log_aprovado:
    text = (root / path).read_text(encoding="utf-8")
    assert text.rstrip().endswith("Exit code: 0 hex: 0x0"), path

indice = Path("tmp/fechamento_integral_1960/pesos_municipais_20260923_021933_338649_completo/indice_34_parquets_completos.json")
completo = json.loads((root / indice).read_text(encoding="utf-8"))
assert len(completo["arquivos"]) == 34
for entry in completo["arquivos"]:
    assert sha(entry["caminho"]) == entry["sha256"], entry["caminho"]
estado25 = json.loads((root / args.validacao25 / "estado.json").read_text(encoding="utf-8"))
assert estado25["linhas"] == 2040 and estado25["arquivos_conferidos"] == 34
for path, expected in estado25["fontes"].items():
    assert sha(path) == expected, ("fonte da validacao alterada", path)
t7 = json.loads((root / args.t7 / "t7_resultado.json").read_text(encoding="utf-8"))
assert t7["status"] == "CONFERIDO_SEM_ALTERAR_DADOS"
estado127 = json.loads((root / args.reconstrucao / "estado.json").read_text(encoding="utf-8"))
assert estado127["reconstruida"] is False
log127 = (root / args.log_reconstrucao).read_text(encoding="utf-8")
assert "Deduplicacao suspensa" in log127 and "nenhuma pessoa foi excluida" in log127

inventario = json.loads((root / "references/fechamento_integral_1960_evidencias/inventario_final.json").read_text(encoding="utf-8"))
with (root / args.reconstrucao / "duplicatas_a_revisar.csv").open(encoding="utf-8-sig", newline="") as stream:
    repeticoes_r = list(csv.DictReader(stream))
assert len(repeticoes_r) == inventario["resumo"]["ocorrencias_apos_primeira_pendentes"] == 459
tracked = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=all"], cwd=root, text=True, encoding="utf-8")
artifacts = [indice, args.validacao25 / "estado.json", args.validacao25 / "validacao_definitivos.csv",
    args.t7 / "t7_resultado.json", args.t7 / "t7_celulas_17ufs.csv", args.reconstrucao / "estado.json",
    args.reconstrucao / "entradas.csv", args.reconstrucao / "duplicatas_a_revisar.csv",
    args.reconstrucao / "duplicatas_decisoes_conferidas.csv",
    args.log_reconstrucao, *args.testes, *args.log_aprovado,
    Path("references/fechamento_integral_1960_pr_entrega.json"),
    Path("references/fechamento_integral_1960_conferencias_entrega.json"),
    Path("references/fechamento_integral_1960_cem_entrega.json"),
    Path("references/fechamento_integral_1960_evidencias/inventario_final.json"),
    Path("references/fechamento_integral_1960_evidencias/pendencias_nominais.json"),
    Path("references/fechamento_integral_1960_evidencias/pastas_desenho.json"),
    Path("references/fechamento_integral_1960_evidencias/guia_municipal_anterior.json"),
    Path("tmp/fechamento_integral_1960/parana/outras_ufs/teste_integrativo_portatil.json"),
    Path("read_guides/1960_amostra_127_cartoes_recuperados.json"),
    Path("read_guides/1960_amostra_127_reparos_fonte25.json"),
    Path("read_guides/1960_amostra_127_duplicatas.csv"),
    Path("read_guides/1960_amostra_127_correcoes.csv"),
    Path("read_guides/1960_municipios.csv"),
    Path("R/microdata_1960_amostra_127.R"), Path("R/microdata_1960_amostra_25.R"),
    Path("R/microdata_1960_validacao.R")]
preliminar = Path("tmp/fechamento_integral_1960/relatorios/preliminar_base_antiga_c1641f26838")
artifacts.extend(preliminar / name for name in ["estado.json", "entradas.csv",
    "calibracao_1965_validacao.csv", "q5_cenarios_idade_ignorada.csv", "q5_conferencia_com_validador.csv"])
resultado = dict(
    data=datetime.now().isoformat(), status="ENTREGA_TECNICA_COM_BLOQUEIO_FACTUAL_NA_BASE_NACIONAL",
    nacional_corrigida_publicada=False, novos_pesos127=False,
    pesos25_recalculados=["mt", "pr", "mg"], arquivos25_completos=34,
    relatorio_preliminar=dict(arquivo=str(preliminar).replace("\\", "/"),
        estado="RELATORIO_NOVO_SOBRE_BASE_E_PESOS_ANTIGOS_NAO_RECONSTRUIDOS"),
    validacao25_comparacoes=2040, etapas={
        "registros": "correcoes comprovadas integradas; residuos nominalmente nao identificados",
        "conferencias": "correcoes e limites implementados; convencoes historicas nao presumidas",
        "reconstrucao": "25 completa e conferida; 127 interrompida antes de excluir repeticoes incertas",
        "entrega": "provas, testes, relatorios e limites documentados; sem release nacional"},
    inventario=inventario["resumo"], testes_aprovados=len(ultimos),
    execucoes_testes=len(tests), tentativas_anteriores_falhas=[x for x in tests if x["codigo"] != 0],
    logs_adicionais_aprovados=[str(p).replace("\\", "/") for p in args.log_aprovado],
    protegidos_sha256=protegidos,
    artefatos=[dict(arquivo=str(p).replace("\\", "/"), sha256=sha(p)) for p in artifacts],
    rejeitados_ou_superados=[
        dict(arquivo="tmp/fechamento_integral_1960/logs/validacao25_integral01.log", motivo="leitura parou com Arrow I/O=1; filho encerrado; repeticao com I/O=2 aprovada"),
        dict(arquivo="tmp/fechamento_integral_1960/relatorios/preliminar_base_antiga_3fc6c4b4b5e", motivo="cenario auxiliar Q5 inicial tinha leitura incorreta de idade; substituido pela segunda execucao"),
        dict(arquivo="tmp/fechamento_integral_1960/fonte_cem/auditoria_integral/registros_pendentes_cem.json", motivo="hipotese posicional rejeitada; usar residuos_pareados.json"),
        dict(arquivo="tmp/fechamento_integral_1960/conferencias/pesos_corrigidos_20260923_01", motivo="conferencia parcial rejeitou caso vazio FN por erro no auditor; refeita sem alterar dados")],
    limite="Investigar todas as listas conhecidas nao prova inexistencia de outra fonte historica. Variancias calibradas adiadas; esquema nacional exige dados completos.",
    git_status=tracked)
out = root / "references/fechamento_integral_1960_entrega.json"
out.write_text(json.dumps(resultado, ensure_ascii=False, indent=2), encoding="utf-8")
print("ENTREGA CONFERIDA:", out.relative_to(root), "testes:", len(ultimos), flush=True)
