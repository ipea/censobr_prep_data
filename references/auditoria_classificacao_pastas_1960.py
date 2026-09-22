"""Compara classificacao de pastas no legado25 e na amostra127 materializada.

Somente leitura: nao executa R, modifica dados, calcula pesos ou estima variancias.
Compara a regra historica das figuras anterior a revisao de 21/09/2026 com
a regra sem o duplo ajuste de Alagoas, ja corrigido no codigo R (nao executado).
Uso: python references/auditoria_classificacao_pastas_1960.py
"""

from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
import sys

import pyarrow.parquet as pq


def run(root):
    guide_path = root / "read_guides/1960_municipios.csv"
    with guide_path.open(encoding="utf-8-sig", newline="") as source:
        guide = {(int(r["uf60"]), int(r["cod60"])): {
            "nome": r["nome"], "pop_urbana": float(r["pop_urbana"])
            if r["pop_urbana"] not in ("", "NA") else None}
            for r in csv.DictReader(source)}

    legacy_path = root / "data/release_legacy/Censo.1960.brasil.domicilios.amostraCompilada.censobr.parquet"
    current_path = root / "data_raw/microdata/1960/amostra_127/domicilios_1960_amostra_127.parquet"

    def empty():
        return {"urbanos": 0, "rurais": 0, "municipios": Counter()}

    legacy = defaultdict(empty)
    for batch in pq.ParquetFile(legacy_path).iter_batches(batch_size=65536, columns=[
            "uf", "v001", "v116", "v118", "censobr_source"]):
        for row in batch.to_pylist():
            if row["censobr_source"] != 2:
                continue
            uf = int(row["uf"])
            municipality = int(row["v116"]) if row["v116"] is not None else None
            if uf == 25 and municipality is not None:
                # Reproduz a regra HISTORICA das figuras, anterior a revisao. O legado
                # ja usa 23xx: este -200 e auditado separadamente abaixo.
                municipality -= 200
            if uf == 24:
                municipality = 2401
            folder = legacy[(uf, int(row["v001"]))]
            folder["municipios"][municipality] += 1
            folder["urbanos"] += row["v118"] in (1, 3)
            folder["rurais"] += row["v118"] == 5

    current = defaultdict(empty)
    for batch in pq.ParquetFile(current_path).iter_batches(batch_size=65536, columns=[
            "UF", "censobr_upa", "code_muni_1960", "V118"]):
        for row in batch.to_pylist():
            # Usa a UPA reconciliada atual, incluindo os dois reparos de pasta.
            folder = current[(row["UF"], int(row["censobr_upa"].split("-")[1]))]
            folder["municipios"][row["code_muni_1960"]] += 1
            folder["urbanos"] += row["V118"] in (1, 3)
            folder["rurais"] += row["V118"] == 5

    def classification(folder, uf):
        mode = folder["municipios"].most_common(1)[0][0]
        modal_pop = guide.get((uf, mode), {}).get("pop_urbana")
        modal_large = modal_pop is not None and modal_pop >= 100000
        any_large = any((guide.get((uf, m), {}).get("pop_urbana") or 0) >= 100000
                        for m in folder["municipios"])

        def group(large):
            if folder["urbanos"] and folder["rurais"]:
                return "mista"
            if not folder["urbanos"]:
                return "rural"
            return "cidade grande" if large else "urbana menor"

        return {"grupo_moda": group(modal_large), "grupo_any": group(any_large),
                "grande_moda": modal_large, "grande_any": any_large,
                "municipio_modal": mode, "urbanos": folder["urbanos"],
                "rurais": folder["rurais"], "linhas": sum(folder["municipios"].values()),
                "municipios": [{"codigo": m, "linhas": n, **guide.get((uf, m), {})}
                               for m, n in folder["municipios"].most_common()]}

    canonical_al = {}
    for key, value in legacy.items():
        adjusted = value
        if key[0] == 25:
            municipalities = Counter()
            for code, count in value["municipios"].items():
                # Reverte somente o deslocamento que tirou um codigo do guia.
                if code is not None and (25, code) not in guide and (25, code + 200) in guide:
                    code += 200
                municipalities[code] += count
            adjusted = {**value, "municipios": municipalities}
        canonical_al[key] = classification(adjusted, key[0])

    legacy = {key: classification(value, key[0]) for key, value in legacy.items()}
    current = {key: classification(value, key[0]) for key, value in current.items()}
    shared = sorted(legacy.keys() & current.keys())
    legacy_ufs = {key[0] for key in legacy}
    absent = sorted(key for key in current if key[0] in legacy_ufs and key not in legacy)
    differences = [{"UF": key[0], "pasta": key[1], "legado25": legacy[key], "atual127": current[key]}
                   for key in shared if legacy[key]["grupo_any"] != current[key]["grupo_any"]]
    canonical_differences = [{"UF": key[0], "pasta": key[1],
                              "legado25": canonical_al[key]["grupo_any"],
                              "atual127": current[key]["grupo_any"]}
                             for key in shared if canonical_al[key]["grupo_any"] != current[key]["grupo_any"]]

    def summary(folders):
        return {"pastas": len(folders),
                "marca_grande_moda_vs_any_diverge": sum(x["grande_moda"] != x["grande_any"] for x in folders.values()),
                "grupo_moda_vs_any_diverge": sum(x["grupo_moda"] != x["grupo_any"] for x in folders.values()),
                "composicao_any": dict(Counter(x["grupo_any"] for x in folders.values()))}

    transitions = Counter((legacy[key]["grupo_any"], current[key]["grupo_any"]) for key in shared)
    return {"legado25": summary(legacy), "legado25_sem_duplo_deslocamento_al": summary(canonical_al),
            "atual127": summary(current),
            "pastas_127_em_ufs_com_legado25": sum(key[0] in legacy_ufs for key in current),
            "pastas_comuns": len(shared), "pastas_127_ausentes_no_legado25": absent,
            "grupos_divergentes_mesma_regra": len(differences),
            "nota_geografia_al": "A regra historica das figuras, anterior a revisao de 21/09/2026, subtraia 200 de codigos ja em 23xx; 2306 tornava-se 2106, sem par no guia. A segunda comparacao preserva o codigo do legado. O codigo R foi corrigido, mas nao executado nesta revisao.",
            "grupos_divergentes_sem_duplo_deslocamento_al": len(canonical_differences),
            "divergencias_sem_duplo_deslocamento_al": canonical_differences,
            "transicoes": [{"legado25": a, "atual127": b, "pastas": n}
                           for (a, b), n in sorted(transitions.items())],
            "divergencias": differences,
            "limite": "Compara classificacoes do legado25 e da127 atual; nao refaz ranks, prova estratos historicos ou estima variancias.",
            "fontes": [{"path": str(path), "bytes": path.stat().st_size,
                         "mtime_ns": path.stat().st_mtime_ns}
                        for path in [legacy_path, current_path, guide_path]],
            "guia_sha256": hashlib.sha256(guide_path.read_bytes()).hexdigest()}


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    print(json.dumps(run(Path(__file__).resolve().parents[1]), ensure_ascii=False, indent=2))
