"""Confere os microlotes R reabertos e registra o antes/depois sem mudar originais."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

import pyarrow.parquet as pq


def sha256(path):
    result = hashlib.sha256()
    with path.open("rb") as source:
        while block := source.read(4 * 1024 ** 2):
            result.update(block)
    return result.hexdigest()


def run(root, folder, log, output):
    root = root.resolve()
    folder, log, output = folder.resolve(), log.resolve(), output.resolve()
    if not all(p.is_relative_to(root / "tmp") for p in (folder, log, output)):
        raise ValueError("Entradas R e nova saida devem ficar no tmp do projeto")
    log_text = log.read_text(encoding="utf-8")
    if "Exit code: 0 hex: 0x0" not in log_text or "Piloto, manifesto completo e ataques aprovados" not in log_text:
        raise ValueError("Execucao R completa nao aprovada")
    manifest_path = root / "read_guides/1960_amostra_127_cartoes_recuperados.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    source_paths = [root / item["arquivo"] for item in manifest["fontes"]]
    before = {p: sha256(p) for p in source_paths}
    if any(before[root / item["arquivo"]] != item["sha256"] for item in manifest["fontes"]):
        raise ValueError("Fonte mudou desde a auditoria")
    original = root / "data_raw/microdata/1960/amostra_127/pessoas_1960_amostra_127.parquet"
    before[original] = sha256(original)
    people_path = folder / "pessoas_vinculadas.parquet"
    families_path = folder / "cartoes_recuperados.parquet"
    people = pq.read_table(people_path).to_pylist()
    families = pq.read_table(families_path).to_pylist()
    by_line = {p["linha"]: p for p in people}
    by_id = {f["censobr_cartao_recuperado_id"]: f for f in families}
    expected_lines = {p["linha"] for c in manifest["cartoes"] for p in c["pessoas"]}
    if len(by_line) != len(people) or set(by_line) != expected_lines or len(by_id) != len(families):
        raise ValueError("Pessoas ou cartoes repetidos, faltantes ou excedentes")
    if set(by_id) != {c["id_recuperacao"] for c in manifest["cartoes"]}:
        raise ValueError("Conjunto de cartoes divergente")
    old = pq.read_table(original, columns=["linha", "censobr_idfamily", "censobr_idhousehold",
        "censobr_upa", "censobr_familia_origem"], filters=[("linha", "in", sorted(expected_lines))]).to_pylist()
    old = {p["linha"]: p for p in old}
    comparisons = []
    for card in manifest["cartoes"]:
        family = by_id[card["id_recuperacao"]]
        if any(family[k] is not None for k in ("linha", "id_arquivo", "texto_original", "texto_corrigido")):
            raise ValueError("Cartao recuperado recebeu falso localizador HHOLDA")
        for key, value in card["familias"].items():
            if family[key] != value:
                raise ValueError(f"Resposta familiar alterada: {card['id_recuperacao']} {key}")
        if (family["censobr_cartao_arquivo"], family["censobr_cartao_linha"]) != (card["arquivo_25"], card["linha_25"]):
            raise ValueError("Procedencia do cartao divergente")
        for expected in card["pessoas"]:
            person = by_line[expected["linha"]]
            if any(person[k] != expected[k] for k in ("texto_original", "texto_corrigido")):
                raise ValueError("Texto pessoal alterado")
            for key in ("UF", "V116", "V118", "distrito", "pasta", "boletim"):
                if person[key] != card[key]:
                    raise ValueError("Geografia pessoal alterada")
            if (person["censobr_idfamily"], person["censobr_idhousehold"]) != (
                    family["censobr_idfamily"], family["censobr_idhousehold"]):
                raise ValueError("Vinculo nao aponta para o cartao aprovado")
            for key in (k for k in family if k.startswith("censobr_cartao_")):
                if person[key] != family[key]:
                    raise ValueError("Procedencia nao transmitida a pessoa")
            if person["censobr_familia_origem"] != "recuperada_25":
                raise ValueError("Origem familiar incorreta")
            comparisons.append({"linha_pessoa127": expected["linha"], "antes_no_parquet_atual": old.get(expected["linha"]),
                "depois": {"cartao_recuperado": card["id_recuperacao"], "arquivo25": card["arquivo_25"],
                    "linha_cartao25": card["linha_25"], "pasta": card["pasta"], "boletim": card["boletim"],
                    "unidade": card["unidade"], "respostas_pessoais_preservadas": True}})
    if any(sha256(p) != value for p, value in before.items()):
        raise ValueError("Entrada mudou durante conferencia")
    output.mkdir(parents=True, exist_ok=False)
    artifacts = [people_path, families_path, log, manifest_path,
        root / "R/microdata_1960_amostra_127.R", root / "R/microdata_1960.R", root / "_targets.R",
        root / "references/test_recuperacao_cartoes_1960.R", root / "references/auditoria_recuperacao_cartoes_1960.py",
        root / "references/conferir_recuperacao_cartoes_1960.py"]
    result = {"escopo": "Somente os cartoes e pessoas aprovados; nao e a amostra completa nem recalculo de pesos.",
        "cartoes_recuperados": len(families), "pessoas_preservadas": len(people), "pessoas_acrescentadas": 0,
        "por_uf_cartoes": dict(Counter(c["UF"] for c in manifest["cartoes"])),
        "por_uf_pessoas": dict(Counter(p["UF"] for p in people)), "originais_inalterados": True,
        "pessoas_ja_no_parquet_atual": len(old), "pessoas_brutas_nao_encontradas_no_parquet_atual": sorted(expected_lines - set(old)),
        "origem_vinculo_anterior": dict(Counter(p["censobr_familia_origem"] for p in old.values())),
        "pessoas_com_pasta_atribuida_diferente": sum(
            old[p["linha"]]["censobr_upa"] != f"{int(c['UF'])}-{c['pasta']}"
            for c in manifest["cartoes"] for p in c["pessoas"] if p["linha"] in old),
        "arquivos": [{"arquivo": p.relative_to(root).as_posix(), "sha256": sha256(p)} for p in artifacts],
        "entradas_conferidas": [{"arquivo": p.relative_to(root).as_posix(), "sha256": v} for p, v in before.items()],
        "antes_depois": comparisons}
    with (output / "indice_entrega.json").open("x", encoding="utf-8") as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2)
    print(json.dumps({k: v for k, v in result.items() if k not in ("antes_depois", "entradas_conferidas")}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--saidas-r", type=Path, required=True)
    parser.add_argument("--log", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    run(Path(__file__).resolve().parents[1], args.saidas_r, args.log, args.out)
