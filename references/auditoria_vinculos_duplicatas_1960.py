"""Audita HHOLDA e intermediarios existentes, sem executar R ou escrever dados.

Uso: python references/auditoria_vinculos_duplicatas_1960.py [--uf pb]
     python references/auditoria_vinculos_duplicatas_1960.py --details

A comparacao usa os 25 campos comuns de pessoa e UF+pasta+boletim.
Os parquets de 25% sao intermediarios de leitura, nao populacoes externas.
Correspondencia de conteudo identifica multiplicidade, nao identidade civil.
"""

import argparse
from collections import Counter, defaultdict
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys

import pyarrow.parquet as pq


UF = {25: "al", 31: "ba", 14: "ce", 97: "df", 24: "fn", 94: "go",
      40: "mg", 91: "mt", 19: "pb", 21: "pe", 71: "pr", 52: "rj",
      17: "rn", 81: "rs", 50: "sa", 30: "se", 60: "sp"}


def csv_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        return list(csv.DictReader(source))


def integer(value):
    try:
        return int(value)
    except (ValueError, TypeError):
        return None


def metadata(path):
    stat = path.stat()
    return {"path": str(path), "bytes": stat.st_size,
            "mtime_utc": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat()}


def run(root, selected_uf=None):
    base = root / "data_raw/microdata/1960"
    guides = root / "read_guides"
    guide = csv_rows(guides / "readguide_1960_amostra_127_pessoas.csv")
    fields = [g for g in guide if g["variavel"] not in
              {"UF", "V116", "REC_TYPE", "V118", "BARRA", "ID"}]
    names = [g["variavel"] for g in fields]
    corrections = {int(d["linha"]): d for d in
                   csv_rows(guides / "1960_amostra_127_correcoes.csv")}
    exclusions = csv_rows(base / "amostra_127/duplicatas_removidas.csv")
    if selected_uf:
        exclusions = [r for r in exclusions if UF.get(int(r["UF"])) == selected_uf]
    removed = {int(r["linha"]): r for r in exclusions}

    person_path = base / "amostra_127/pessoas_1960_amostra_127.parquet"
    home_path = base / "amostra_127/domicilios_1960_amostra_127.parquet"
    columns = ["linha", "UF", "V116", "pasta", "distrito", "chave",
               "censobr_idfamily", "censobr_idhousehold", "censobr_upa",
               "code_muni_1960", "censobr_diagnostico"]
    attached = pq.read_table(person_path, columns=columns, filters=[
        ("censobr_familia_origem", "=", "anexada_anterior")]).to_pylist()
    if selected_uf:
        attached = [r for r in attached if UF.get(r["UF"]) == selected_uf]
    homes = pq.read_table(home_path, columns=["censobr_idhousehold", "linha", "UF",
                         "V116", "pasta", "distrito"]).to_pylist()
    homes = {r["censobr_idhousehold"]: r for r in homes}
    attached_by_line = {r["linha"]: r for r in attached}
    repair_lines = [387715, 387853] if selected_uf in (None, "ba") else []
    target_lines = set(attached_by_line) | set(removed) | set(repair_lines)

    raw_path = base / "amostra_127/HHOLDA.txt"
    with raw_path.open(encoding="latin1") as source:
        raw = source.read().splitlines()
    if len(raw) != 1074328 or any(len(s) != 62 for s in raw):
        raise ValueError("HHOLDA diverge da quantidade/comprimento esperados")
    for line, correction in corrections.items():
        if raw[line - 1] != correction["texto_original"]:
            raise ValueError(f"Correcao nao corresponde ao bruto na linha {line}")

    def corrected(line):
        text = raw[line - 1]
        decision = corrections.get(line, {})
        text = decision.get("texto_corrigido") or text
        if decision.get("decisao") == "corrompida":
            text = " " * 16 + text[16] + " " * 37 + "\\" + text[55:]
        uf = integer(text[:2])
        if uf == 3 and text[2:6] == "0011":
            uf = 0
        return text, (uf, integer(text[8:13]), integer(text[13:16]))

    def signature(text):
        values = []
        for field in fields:
            value = text[int(field["inicio"]) - 1:int(field["fim"])]
            valid = field["valores_validos"].split(";")
            values.append(integer(value) if value in valid else None)
        return tuple(values)

    raw_records = {}
    keys = set()
    for line in target_lines:
        text, key = corrected(line)
        raw_records[line] = (text, key, signature(text))
        keys.add(key)
    family127 = defaultdict(list)
    before = defaultdict(Counter)
    excluded_profiles = defaultdict(list)
    for line, source_text in enumerate(raw, 1):
        if corrections.get(line, {}).get("decisao") == "cartao_uf":
            continue
        text, key = corrected(line)
        if text[16] == "1":
            family127[key].append({"linha": line, "municipio": integer(text[2:6]),
                                   "distrito": integer(text[6:8]), "situacao": integer(text[17])})
        elif key in keys:
            person_signature = signature(text)
            before[key][person_signature] += 1
            if line in removed:
                excluded_profiles[(key, person_signature)].append(line)

    direct_conflicts = []
    for batch in pq.ParquetFile(person_path).iter_batches(batch_size=65536, columns=[
            "linha", "UF", "V116", "chave", "censobr_familia_origem"]):
        for row in batch.to_pylist():
            if row["censobr_familia_origem"] != "registro":
                continue
            if selected_uf and UF.get(row["UF"]) != selected_uf:
                continue
            key = (row["UF"], integer(row["chave"][2:7]), integer(row["chave"][7:10]))
            candidates = [f for f in family127[key] if f["distrito"] == integer(row["chave"][:2])]
            if len(candidates) == 1 and row["V116"] != candidates[0]["municipio"]:
                direct_conflicts.append({"linha": row["linha"], "UF": row["UF"],
                                         "municipio_pessoa_materializado": row["V116"],
                                         "cartao_familia": candidates[0]})

    people25 = defaultdict(list)
    family25 = defaultdict(list)
    sources = [metadata(raw_path), metadata(person_path), metadata(home_path)]
    sources[0]["sha256"] = hashlib.sha256(raw_path.read_bytes()).hexdigest()
    for path in [guides / "readguide_1960_amostra_127_pessoas.csv",
                 guides / "1960_amostra_127_correcoes.csv",
                 base / "amostra_127/duplicatas_removidas.csv"]:
        item = metadata(path)
        item["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
        sources.append(item)
    for uf, state in UF.items():
        folders = sorted({k[1] for k in keys if k[0] == uf and k[1] is not None})
        if not folders:
            continue
        directory = base / "amostra_25" / state
        for name, columns25 in [("familias", ["linha", "UF", "v001", "v002", "v100",
                                             "V101", "V116", "V117", "V118"]),
                                 ("pessoas", ["linha", "UF", "v001", "v002", "v003"] + names)]:
            path = directory / (name + ".parquet")
            sources.append(metadata(path))
            rows = pq.read_table(path, columns=columns25,
                                 filters=[("v001", "in", folders)], use_threads=False).to_pylist()
            for row in rows:
                key = (uf, row["v001"], row["v002"])
                if key not in keys:
                    continue
                if name == "familias":
                    family25[key].append(row)
                else:
                    people25[key].append(row)

    count_checks = [{"chave": key, "familias": len(rows),
                     "declarado_v100": sum(r["v100"] for r in rows),
                     "pessoas_lidas": len(people25[key])}
                    for key, rows in family25.items()
                    if len(rows) != 1 or rows[0]["v100"] != len(people25[key])]
    comparisons = []
    for row in attached:
        line = row["linha"]
        text, key, person_signature = raw_records[line]
        home = homes[row["censobr_idhousehold"]]
        differences = [v for v in ["UF", "V116", "pasta", "distrito"] if row[v] != home[v]]
        candidates = [r for r in people25[key] if tuple(r[n] for n in names) == person_signature]
        fam25 = family25[key]
        fam127 = family127[key]
        nearest = []
        if not candidates:
            for candidate in people25[key]:
                diff = {n: [person_signature[i], candidate[n]] for i, n in enumerate(names)
                        if person_signature[i] != candidate[n]}
                nearest.append({"linha_25": candidate["linha"], "diferencas": diff})
            nearest.sort(key=lambda x: len(x["diferencas"]))
            nearest = nearest[:3]
        status = "sem_fonte_25" if key[0] not in UF else "sem_correspondencia_exata"
        if candidates and len(fam25) == 1:
            status = "boletim_proprio_com_registro_25"
            if len(fam127) == 1:
                status = "registro_127_existente"
            elif len(fam127) > 1:
                status = "mais_de_um_registro_127"
        comparisons.append({"linha": line, "chave_original": key,
                            "distrito_original": text[6:8], "diferencas_domicilio": differences,
                            "domicilio_atual_linha": home["linha"], "upa_atual": row["censobr_upa"],
                            "status": status, "pessoas_25_exatas": [r["linha"] for r in candidates],
                            "familias_25": fam25, "familias_127": fam127,
                            "candidatos_nao_exatos_nao_decisivos": nearest})

    duplicate_comparisons = []
    for (key, person_signature), lines in excluded_profiles.items():
        n_before = before[key][person_signature]
        n_after = n_before - len(lines)
        matches = [r for r in people25[key] if tuple(r[n] for n in names) == person_signature]
        n25 = len(matches)
        status = "sem_fonte_25" if key[0] not in UF else "sem_correspondencia_exata"
        restore = None
        if n25:
            if n_after == n25:
                status = "exclusao_corrobora_multiplicidade_25"
                restore = 0
            elif n_after < n25 <= n_before:
                status = "exclusao_excessiva_contra_25"
                restore = n25 - n_after
            elif n_after > n25:
                status = "multiplicidade_127_ainda_excessiva"
                restore = 0
            else:
                status = "mais_pessoas_25_que_127"
        duplicate_comparisons.append({"chave_original": key, "linhas_excluidas": lines,
                                      "antes": n_before, "depois": n_after, "n25": n25,
                                      "status": status, "restauracoes_corrob_por_25": restore,
                                      "pessoas_25_exatas": [r["linha"] for r in matches],
                                      "perfil": dict(zip(names, person_signature))})

    conflict = [r for r in comparisons if r["diferencas_domicilio"]]
    group_statuses = defaultdict(set)
    for row in comparisons:
        group_statuses[(tuple(row["chave_original"]), row["distrito_original"])].add(row["status"])
    def statuses(rows):
        return dict(Counter(r["status"] for r in rows))
    summary = {"anexadas": len(comparisons), "conflitos_geograficos": len(conflict),
               "conflitos_por_campo": dict(Counter(v for r in conflict for v in r["diferencas_domicilio"])),
               "vinculos_diretos_v116_divergente": len(direct_conflicts),
               "vinculos_diretos_v116_divergente_ambos_numericos": sum(
                   r["municipio_pessoa_materializado"] is not None and r["cartao_familia"]["municipio"] is not None
                   for r in direct_conflicts),
               "anexadas_status": statuses(comparisons), "conflitos_status": statuses(conflict),
               "grupos_anexados_status": dict(Counter(next(iter(v)) if len(v) == 1 else "correspondencia_parcial"
                                                       for v in group_statuses.values())),
               "linhas_excluidas": len(exclusions), "perfis_excluidos_status": statuses(duplicate_comparisons),
               "linhas_excluidas_status": dict(Counter({status: sum(len(r["linhas_excluidas"]) for r in duplicate_comparisons if r["status"] == status)
                                                          for status in statuses(duplicate_comparisons)})),
               "restauracoes_corrob_por_25": sum(r["restauracoes_corrob_por_25"] or 0 for r in duplicate_comparisons),
               "restauracoes_por_uf": dict(Counter({state: sum((r["restauracoes_corrob_por_25"] or 0) for r in duplicate_comparisons
                                                                if r["chave_original"][0] == uf)
                                                      for uf, state in UF.items()})),
               "regra_pe_cauda_duas_repetidas_excluiria": sum(r["UF"] == "21" and r["na_cauda"] == "TRUE" and int(r["n_repetidas"]) >= 2 for r in exclusions),
               "boletins_25_com_contagem_ou_unicidade_inconsistente": count_checks,
               "quesitos_comuns": names}
    repairs = []
    early = [i for i, field in enumerate(fields) if int(field["fim"]) <= 37]
    for line in repair_lines:
        text, key, person_signature = raw_records[line]
        candidates = [r for r in people25[key] if all(person_signature[i] == r[names[i]] for i in early)]
        repairs.append({"linha": line, "chave_original": key,
                        "criterio": "campos V202 a V214 exatos; nao usa trecho deslocado",
                        "candidatos_25": [{"linha_25": r["linha"], "ordem_25": r["v003"],
                                            "diferencas_restantes": {n: [person_signature[i], r[n]] for i, n in enumerate(names)
                                                                       if person_signature[i] != r[n]}}
                                           for r in candidates]})
    examples = {"vinculos": [r for r in comparisons if r["linha"] in [491756, 302261, 302262]],
                "duplicatas": [r for r in duplicate_comparisons if set(r["linhas_excluidas"]) & {168805, 168806, 306831, 306841, 392256, 392259}]}
    return {"resumo": summary, "exemplos": examples, "reparos": repairs, "fontes": sources,
            "vinculos": comparisons, "vinculos_diretos": direct_conflicts, "duplicatas": duplicate_comparisons}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--uf", choices=sorted(UF.values()))
    parser.add_argument("--details", action="store_true", help="inclui cada vinculo e perfil excluido")
    args = parser.parse_args()
    result = run(Path(__file__).resolve().parents[1], args.uf)
    if not args.details:
        result.pop("vinculos")
        result.pop("vinculos_diretos")
        result.pop("duplicatas")
    sys.stdout.reconfigure(encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))
