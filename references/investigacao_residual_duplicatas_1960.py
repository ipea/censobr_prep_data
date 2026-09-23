"""Busca residual ampla, sem decidir exclusoes nem alterar a base de 1960."""
import argparse
from collections import Counter, defaultdict
import gzip
import json
from pathlib import Path
import sqlite3
import time

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, UF, integer, load_guides, parse_profile,
    sha256, source_structure,
    profile_hash,
)

INVENTORY = "references/fechamento_registros_1960_evidencias/duplicatas_residuais463.json"
INDEX = "tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite"
V216 = PERSON_NAMES.index("V216")


def signature(profile, guides):
    values = []
    for name, value in zip(PERSON_NAMES, profile):
        if name == "V216":
            continue
        start, end, _ = guides[("25", "pessoas")][name]
        values.append(" " * (end - start) if value is None else str(value).zfill(end - start))
    return "".join(values)


def raw_signature(text):
    return text[14:24] + text[25:35] + text[37:51]


def differences(a, b):
    return [{"campo": name, "valor127": x, "valor25": y}
            for name, x, y in zip(PERSON_NAMES, a, b) if x != y]


def substantive_distance(a, b):
    return sum(x != y and not (name == "V216" and {x, y} == {0, 63})
               for name, x, y in zip(PERSON_NAMES, a, b))


def assignment_ranges(profiles127, profiles25, pending):
    """Quantidades possiveis sob hipotese explicita: ate1outro campo divergente."""
    import numpy as np
    from scipy.optimize import linear_sum_assignment
    n = len(profiles127); m = len(profiles25)
    if not m or m > n:
        return {"viavel": False, "motivo": "fonte25_vazia_ou_mais_numerosa_que127"}
    optional = set()
    for profile in pending:
        indices = [i for i, p in enumerate(profiles127) if p == profile]
        optional.update(indices[1:])
    feasible = np.zeros((n, n), dtype=bool)
    for i, a in enumerate(profiles127):
        for j, b in enumerate(profiles25):
            feasible[i, j] = substantive_distance(a, b) <= 1
        feasible[i, m:] = i in optional
    costs = np.where(feasible, 0, 100000)
    rr, cc = linear_sum_assignment(costs)
    if not feasible[rr, cc].all():
        return {"viavel": False, "motivo": "nao_existe_correspondencia_bijetiva_ate1campo"}
    ranges = []
    for profile in pending:
        selected = np.array([p == profile for p in profiles127])
        count_cost = np.zeros((n, n), dtype=int); count_cost[selected, :m] = 1
        extrema = []
        for sign in (1, -1):
            r, c = linear_sum_assignment(costs + sign * count_cost)
            extrema.append(int(count_cost[r, c].sum()))
        ranges.append({"perfil127": list(profile), "minimo": extrema[0], "maximo": extrema[1]})
    best_cost = np.full((n, n), 100000, dtype=int)
    for i, a in enumerate(profiles127):
        for j, b in enumerate(profiles25):
            if feasible[i, j]:
                best_cost[i, j] = substantive_distance(a, b)
        if i in optional:
            best_cost[i, m:] = 0
    r, c = linear_sum_assignment(best_cost)
    return {"viavel": True, "intervalos": ranges, "campos_adicionais_minimos": int(best_cost[r, c].sum()),
        "uma_atribuicao_minima_nao_identidade": [{"indice127": int(i), "indice25": int(j),
            "diferencas": differences(profiles127[i], profiles25[j])} for i, j in zip(r, c) if j < m]}


def multiplicities(a, b, pending):
    if set(a) != set(b):
        return False
    return all(1 <= b[p] <= n if p in pending else b[p] == n for p, n in a.items())


def nearest_people(people, source, guides):
    result = []
    source_profiles = [(row, parse_profile(row["texto"], guides[("25", "pessoas")], PERSON_NAMES))
                       for row in source]
    for row in people:
        profile, invalid = parse_profile(row["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)
        distances = [(len(differences(profile, p)), other, p, bad)
                     for other, (p, bad) in source_profiles]
        distance = min((d[0] for d in distances), default=None)
        result.append({"linha127": row["linha"], "invalidos127": invalid,
            "distancia_minima25": distance,
            "candidatos_minimos": [{"linha25": other["linha"], "invalidos25": bad,
                "diferencas": differences(profile, p)} for d, other, p, bad in distances if d == distance]})
    return result


def deepen(root, folder, portable=None):
    """Confronta os candidatos globais com cartoes, geografias e outras familias127."""
    root = root.resolve(); folder = folder.resolve(); guides = load_guides(root)
    data = json.loads((folder / "resultado.json").read_text(encoding="utf-8"))
    contexts = {tuple(c["chave"]): c for c in data["contextos"]}
    connection = sqlite3.connect((root / INDEX).as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    result = []; exact_cache = {}; portable_rows = []
    with (folder / "alternativas_composicao24.jsonl").open(encoding="utf-8") as stream:
        for line in stream:
            candidate = json.loads(line); key = tuple(candidate["chave127"]); context = contexts[key]
            f25 = candidate["cartao25"]; pp25 = candidate["pessoas25"]
            fprofile25, invalidf = parse_profile(f25["texto"], guides[("25", "familias")], FAMILY_NAMES)
            p25 = [parse_profile(p["texto"], guides[("25", "pessoas")], PERSON_NAMES)[0] for p in pp25]
            p127 = [parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0] for p in context["pessoas127"]]
            by24a = defaultdict(set); by24b = defaultdict(set)
            for p in p127:
                by24a[signature(p, guides)].add(p)
            for p in p25:
                by24b[signature(p, guides)].add(p)
            v216_differences = []; merges = []
            for s in by24a:
                if len(by24a[s]) != 1 or len(by24b[s]) != 1:
                    merges.append(s); continue
                a = next(iter(by24a[s])); b = next(iter(by24b[s]))
                if a[V216] != b[V216]:
                    v216_differences.append([a[V216], b[V216]])
            geo25 = [integer(f25["texto"][29:33]), integer(f25["texto"][33:35]), integer(f25["texto"][35:36])]
            geo127 = sorted({(integer(p["corrigido"][2:6]), integer(p["corrigido"][6:8]), integer(p["corrigido"][17]))
                             for p in context["pessoas127"]})
            f_differences = []; district_same = False
            if len(context["cartoes127"]) == 1:
                f127 = context["cartoes127"][0]
                fprofile127, invalid127 = parse_profile(f127["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
                f_differences = [{"campo": n, "valor127": a, "valor25": b}
                    for n, a, b in zip(FAMILY_NAMES, fprofile127, fprofile25) if a != b]
                district_same = integer(f127["corrigido"][6:8]) == geo25[1]
            witnesses = []; candidate_families = set()
            for p in set(p127) & set(p25):
                cache_key = (key[0], p)
                if cache_key not in exact_cache:
                    exact_cache[cache_key] = [dict(r) for r in connection.execute(
                        "SELECT linha,familia_atual,familia_fisica FROM pessoas WHERE uf=? AND perfil=? AND excluida=0",
                        (key[0], profile_hash(p)))]
                hits = exact_cache[cache_key]
                if len(hits) == 1:
                    witnesses.append(hits[0]["linha"])
                for r in hits:
                    for field in ("familia_atual", "familia_fisica"):
                        if r[field] is not None:
                            candidate_families.add(r[field])
            target_cards = {f["linha"] for f in context["cartoes127"]}
            others = []
            for family in sorted(candidate_families - target_cards):
                related = [dict(r) for r in connection.execute(
                    "SELECT linha,corrigido FROM pessoas WHERE familia_atual=? AND excluida=0", (family,))]
                pc = Counter(signature(parse_profile(r["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0], guides)
                             for r in related)
                source_counts = Counter(signature(p, guides) for p in p25)
                if pc == source_counts:
                    others.append({"cartao127": family, "linhas127": [r["linha"] for r in related]})
            key_cards = [dict(r) for r in connection.execute(
                "SELECT linha,corrigido FROM familias WHERE uf=? AND pasta=? AND boletim=?", candidate["chave25"])]
            problems = []
            if invalidf or (len(context["cartoes127"]) == 1 and invalid127):
                problems.append("cartao_com_campos_invalidos")
            if not candidate["mesma_UF"]:
                problems.append("UF_diferente")
            if geo127 != [tuple(geo25)] or not district_same:
                problems.append("geografia_ou_distrito_diferente")
            if len(context["cartoes127"]) != 1 or f_differences:
                problems.append("cartao_diferente_ou_nao_unico")
            if merges:
                problems.append("projecao_funde_perfis")
            if any(set(pair) != {0, 63} for pair in v216_differences):
                problems.append("V216_fora00_63")
            if len(witnesses) < 2:
                problems.append("menos_de_duas_testemunhas_exatas_unicas_UF")
            if others:
                problems.append("outra_familia127_mesma_composicao")
            if any(f["linha"] not in target_cards for f in key_cards):
                problems.append("outra_familia127_na_chave25")
            problems.extend(candidate["problemas_estrutura25"])
            decisions = []
            for group in data["grupos"]:
                if group["chave"] != list(key):
                    continue
                target_person = next(p for p in context["pessoas127"] if p["linha"] == group["linhas127"][0])
                profile = parse_profile(target_person["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0]
                ss = signature(profile, guides)
                source_lines = [p["linha"] for p in pp25 if raw_signature(p["texto"]) == ss]
                decisions.append({"grupo": group["id"], "linhas127": group["linhas127"],
                    "linhas25": source_lines, "quantidade127": len(group["linhas127"]), "quantidade25": len(source_lines),
                    "exclusoes_antigas": group["exclusoes_antigas_sem_prova"]})
            result.append({"chave127": list(key), "chave25": candidate["chave25"], "cartao25": f25["linha"],
                "mesma_chave": candidate["mesma_chave"], "geografia127": geo127, "geografia25": geo25,
                "diferencas_cartao": f_differences, "diferencasV216": v216_differences,
                "testemunhas_exatas_unicas_UF": witnesses, "outras_familias127_composicao24": others,
                "cartoes127_na_chave25": key_cards, "problemas": sorted(set(problems)),
                "grupos": decisions, "candidato_forte_nao_aplicado": not problems})
            if not candidate["mesma_chave"]:
                portable_rows.append({"avaliacao": result[-1], "cartoes127": context["cartoes127"],
                    "pessoas127": context["pessoas127"], "cartao25": f25, "pessoas25": pp25,
                    "comparacao_pessoas": candidate["comparacao_pessoas"]})
    (folder / "aprofundamento.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"candidatos": len(result), "fora_chave": sum(not r["mesma_chave"] for r in result),
        "fortes_sem_aplicacao": sum(r["candidato_forte_nao_aplicado"] for r in result)}, indent=2))
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(root / "references") or portable.exists():
            raise ValueError("Caderno portatil deve ser novo e ficar em references")
        portable.parent.mkdir(parents=True, exist_ok=True)
        portable.write_text(json.dumps({"fontes": data["fontes"], "resumo_busca": data["resumo"],
            "limite": "Candidatos de investigacao, nao decisoes implementadas. Iguais24campos nao equivalem a identidade civil.",
            "casos": portable_rows}, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    return result


def neighborhood(root, folder, portable=None):
    root = root.resolve(); folder = folder.resolve(); guides = load_guides(root)
    candidates = json.loads((folder / "aprofundamento.json").read_text(encoding="utf-8"))
    selected = [c for c in candidates if not c["mesma_chave"] and c["chave127"][0] == c["chave25"][0]]
    pastas = {(c["chave127"][0], c["chave127"][1]) for c in selected} | {(c["chave25"][0], c["chave25"][1]) for c in selected}
    connection = sqlite3.connect((root / INDEX).as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    families = {}; signature_families = defaultdict(set)
    for uf, pasta in sorted(pastas):
        for record in connection.execute("SELECT linha,uf,pasta,boletim,distrito,municipio,situacao,corrigido FROM familias WHERE uf=? AND pasta=?", (uf, pasta)):
            card = dict(record)
            pp = [dict(r) for r in connection.execute("SELECT linha,corrigido FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (card["linha"],))]
            parsed = [parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES) for p in pp]
            if not pp or any(bad for _, bad in parsed):
                continue
            counter = Counter(signature(p, guides) for p, _ in parsed)
            families[card["linha"]] = {"cartao127": card, "pessoas127": pp, "counter": counter}
            for s in counter:
                signature_families[(uf, s)].add(card["linha"])
    matches = []; scanned = 0
    for uf in sorted({uf for uf, _ in pastas}):
        path = root / f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz"
        family = None; people = []

        def examine():
            if not family:
                return
            counter = Counter(raw_signature(p["texto"]) for p in people)
            possible = set()
            for s in counter:
                possible.update(signature_families.get((uf, s), ()))
            for line in possible:
                target = families[line]; card = target["cartao127"]
                if not multiplicities(target["counter"], counter, {p for p, n in target["counter"].items() if n > 1}):
                    continue
                fp, _ = parse_profile(card["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
                fq, invalid = parse_profile(family["texto"], guides[("25", "familias")], FAMILY_NAMES)
                geo25 = [integer(family["texto"][29:33]), integer(family["texto"][33:35]), integer(family["texto"][35:36])]
                matches.append({"cartao127": line, "chave127": [uf, card["pasta"], card["boletim"]],
                    "cartao25": family["linha"], "chave25": [uf, integer(family["texto"][:5]), integer(family["texto"][5:8])],
                    "mesma_contagem24": target["counter"] == counter, "n127": len(target["pessoas127"]), "n25": len(people),
                    "corpo_cartao_exato": fp == fq and not invalid,
                    "geografia_exata": [card["municipio"], card["distrito"], card["situacao"]] == geo25,
                    "linhas127": [p["linha"] for p in target["pessoas127"]], "linhas25": [p["linha"] for p in people]})

        with gzip.open(path, "rt", encoding="latin1") as stream:
            for line, text in enumerate(stream, 1):
                scanned += 1; text = text.rstrip("\r\n"); row = {"linha": line, "texto": text}
                if text[8:10] == "00":
                    examine(); family = row; people = []
                else:
                    people.append(row)
            examine()
    result = {"pastas127": sorted(pastas), "cartoes127_com_pessoas": len(families), "linhas25_pesquisadas": scanned,
        "coincidencias": matches, "limite": "Busca de contexto, nao homologacao: V216 ignorado apenas na assinatura; repeticoes permitidas1..n. Exige revisao do caso antes de decidir."}
    (folder / "vizinhancas.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"cartoes127": len(families), "coincidencias": len(matches), "linhas25": scanned}))
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(root / "references") or portable.exists():
            raise ValueError("Caderno portatil deve ser novo e ficar em references")
        portable.parent.mkdir(parents=True, exist_ok=True)
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    return result


def summarize(root, folder, portable=None):
    root = root.resolve(); folder = folder.resolve()
    data = json.loads((folder / "resultado.json").read_text(encoding="utf-8"))
    contexts = {tuple(c["chave"]): c for c in data["contextos"]}
    diagnostics = []; field_counts = Counter(); minimum_counts = Counter()
    for g in data["grupos"]:
        row = dict(g)
        row["pessoas_comparadas_na_chave"] = []
        if g["chave"]:
            context = contexts[tuple(g["chave"])]
            for source in context["mesma_chave25"]:
                target = next(p for p in source["comparacao_pessoas"] if p["linha127"] == g["linhas127"][0])
                row["pessoas_comparadas_na_chave"].append(target)
                minimum_counts[target["distancia_minima25"]] += 1
                for name in {d["campo"] for c in target["candidatos_minimos"] for d in c["diferencas"]}:
                    field_counts[name] += 1
            row["n_pessoas127_na_chave"] = len(context["pessoas127"])
            row["n_pessoas25_na_chave"] = [len(s["pessoas25"]) for s in context["mesma_chave25"]]
        diagnostics.append(row)
    result = {"resumo": data["resumo"], "razoes_originais": dict(Counter(g["razao_principal"] for g in data["grupos"])),
        "campos_nos_vizinhos_minimos_sobrepostos": dict(field_counts),
        "distancias_minimas_perfil_repetido": dict(sorted(minimum_counts.items(), key=lambda item: str(item[0]))),
        "grupos": diagnostics, "limites": data["criterios"], "fontes": data["fontes"],
        "script_sha256": sha256(Path(__file__)), "indice127_sha256": data["indice127_sha256"],
        "inventario_sha256": data["inventario_sha256"]}
    (folder / "cobertura463.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(root / "references") or portable.exists():
            raise ValueError("Caderno portatil deve ser novo e ficar em references")
        portable.parent.mkdir(parents=True, exist_ok=True)
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps({"minimos": result["distancias_minimas_perfil_repetido"], "campos": dict(field_counts)}))
    return result


def relaxed(root, folder, portable=None):
    root = root.resolve(); folder = folder.resolve(); guides = load_guides(root)
    data = json.loads((folder / "resultado.json").read_text(encoding="utf-8"))
    result = []; groups_by_key = defaultdict(list)
    for g in data["grupos"]:
        if g["chave"]:
            groups_by_key[tuple(g["chave"])].append(g)
    for context in data["contextos"]:
        key = tuple(context["chave"]); groups = groups_by_key[key]
        parsed127 = [parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES) for p in context["pessoas127"]]
        if any(bad for _, bad in parsed127):
            result.append({"chave": list(key), "motivo": "perfil127_invalido", "viavel": False}); continue
        profiles127 = [p for p, _ in parsed127]
        pending = {profiles127[i] for i, p in enumerate(context["pessoas127"]) if any(p["linha"] in g["linhas127"] for g in groups)}
        if len(context["mesma_chave25"]) != 1:
            result.append({"chave": list(key), "motivo": "cartao25_ausente_ou_nao_unico", "viavel": False}); continue
        source = context["mesma_chave25"][0]
        parsed25 = [parse_profile(p["texto"], guides[("25", "pessoas")], PERSON_NAMES) for p in source["pessoas25"]]
        if any(bad for _, bad in parsed25):
            result.append({"chave": list(key), "motivo": "perfil25_invalido", "viavel": False}); continue
        info = assignment_ranges(profiles127, [p for p, _ in parsed25], pending)
        info["chave"] = list(key); info["cartao25"] = source["cartao25"]["linha"]
        info["grupos"] = []
        if info["viavel"]:
            for assignment in info["uma_atribuicao_minima_nao_identidade"]:
                assignment["linha127"] = context["pessoas127"][assignment.pop("indice127")]["linha"]
                assignment["linha25"] = source["pessoas25"][assignment.pop("indice25")]["linha"]
            for g in groups:
                i = next(i for i, p in enumerate(context["pessoas127"]) if p["linha"] == g["linhas127"][0])
                interval = next(r for r in info["intervalos"] if r["perfil127"] == list(profiles127[i]))
                info["grupos"].append({"id": g["id"], "linhas127": g["linhas127"],
                    "minimo_sob_hipotese": interval["minimo"], "maximo_sob_hipotese": interval["maximo"]})
            del info["intervalos"]
        result.append(info)
    output = {"hipotese_nao_aprovada": "Cada correspondencia pode diferir em V21600/63 e em no maximo um outro campo; so repeticoes pendentes podem perder copias. Quantidades respeitam correspondencia bijetiva, nao apenas vizinho mais proximo.",
        "nao_e_prova_de_identidade": True, "contextos": result,
        "resumo": {"contextos": len(result), "viaveis_sob_hipotese": sum(r["viavel"] for r in result),
            "exigem_outras_divergencias": sum(r.get("campos_adicionais_minimos", 0) > 0 for r in result),
            "grupos_com_intervalo_ambiguo": sum(g["minimo_sob_hipotese"] != g["maximo_sob_hipotese"] for r in result for g in r.get("grupos", []))}}
    (folder / "hipotese_um_campo.json").write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(root / "references") or portable.exists():
            raise ValueError("Caderno portatil deve ser novo e ficar em references")
        portable.parent.mkdir(parents=True, exist_ok=True)
        portable.write_text(json.dumps(output, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps(output["resumo"]))
    return output


def household_collisions(root, folder, portable=None):
    root = root.resolve(); folder = folder.resolve(); guides = load_guides(root)
    data = json.loads((folder / "resultado.json").read_text(encoding="utf-8"))
    neighborhoods = json.loads((folder / "vizinhancas.json").read_text(encoding="utf-8"))
    by_source = defaultdict(list); strict_by_source = defaultdict(list)
    for row in neighborhoods["coincidencias"]:
        key = (row["chave25"][0], row["cartao25"])
        by_source[key].append(row)
        if row["mesma_contagem24"] and row["corpo_cartao_exato"] and row["geografia_exata"]:
            strict_by_source[key].append(row)
    connection = sqlite3.connect((root / INDEX).as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    ce = next(c for c in data["contextos"] if c["chave"] == [14, 15004, 34])
    collisions = []; counts = []
    ce_counter = Counter(signature(parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0], guides)
                         for p in ce["pessoas127"])
    for person in ce["pessoas127"]:
        profile, bad = parse_profile(person["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)
        count = connection.execute("SELECT count(*) FROM pessoas WHERE uf=14 AND perfil=? AND excluida=0", (profile_hash(profile),)).fetchone()[0]
        counts.append({"linha127": person["linha"], "ocorrencias_exatas_UF127": count})
    anchor = next(p for p in ce["pessoas127"] if p["linha"] == 131522)
    anchor_signature = signature(parse_profile(anchor["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0], guides)
    anchor_matches = []
    # Varre toda a UF, sem depender da pasta nem de um indice parcial de campos.
    for record in connection.execute("SELECT linha,corrigido,familia_atual,familia_fisica FROM pessoas WHERE uf=14 AND excluida=0"):
        profile, bad = parse_profile(record["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)
        if not bad and signature(profile, guides) == anchor_signature:
            anchor_matches.append(dict(record))
    target_cards = {f["linha"] for f in ce["cartoes127"]}
    possible_cards = {r[field] for r in anchor_matches for field in ("familia_atual", "familia_fisica") if r[field] is not None}
    for family in sorted(possible_cards):
        for field in ("familia_atual", "familia_fisica"):
            rows127 = [dict(r) for r in connection.execute(f"SELECT linha,corrigido FROM pessoas WHERE {field}=? AND excluida=0", (family,))]
            counter = Counter(signature(parse_profile(p["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0], guides) for p in rows127)
            collisions.append({"cartao127": family, "agrupamento": field, "alvo": family in target_cards,
                "mesma_composicao24_e_quantidades": counter == ce_counter, "linhas127": [r["linha"] for r in rows127]})
    result = {"coincidencias_vizinhanca": len(neighborhoods["coincidencias"]),
        "muitos127_para_um25": [v for v in by_source.values() if len(v) > 1],
        "muitos127_para_um25_com_cartao_geografia_quantidades_exatos": [v for v in strict_by_source.values() if len(v) > 1],
        "CE15004_034": {"frequencias_perfis_UF127": counts, "adulto_ancora24": anchor_matches,
            "grupos_inteiros_testados": collisions,
            "outras_familias_completas_compativeis": sum(not r["alvo"] and r["mesma_composicao24_e_quantidades"] for r in collisions),
            "escopo": "Toda a UF14 no indice127; campoV216 omitido somente na busca. Grupos atuais e fisicos examinados; exige adulto com mesmo restante24."},
        "limite": "Nao e auditoria nacional de todas as duplicacoes de familia inteira; examina1531coincidencias das1702familias das pastas selecionadas e CE15004/034 em todaUF."}
    (folder / "colisoes_familias.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(root / "references") or portable.exists():
            raise ValueError("Caderno portatil deve ser novo e ficar em references")
        portable.parent.mkdir(parents=True, exist_ok=True)
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps({"colisoes_amplas": len(result["muitos127_para_um25"]),
        "colisoes_estritas": len(result["muitos127_para_um25_com_cartao_geografia_quantidades_exatos"]),
        "CE_outros_grupos": result["CE15004_034"]["outras_familias_completas_compativeis"]}))
    return result


def independent_blocks(root, folder, portable=None):
    root = root.resolve(); folder = folder.resolve(); guides = load_guides(root)
    wanted = set(range(8380, 8520)) | set(range(69943, 69952)) | set(range(70359, 70368))
    raw = {}; path = root / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    with path.open("rb") as stream:
        for line in sorted(wanted):
            stream.seek((line - 1) * 64)
            text = stream.read(64).decode("latin1").rstrip("\r\n")
            if len(text) != 62:
                raise ValueError("Posicao de registro HHOLDA divergente")
            raw[line] = text
    comparisons = []
    for a, b in [(line, line + 17) for line in range(8443, 8460)] + [(69946 + i, 70362 + i) for i in range(3)]:
        x = raw[a]; y = raw[b]
        names = FAMILY_NAMES if x[16] == "1" else PERSON_NAMES
        kind = "familias" if x[16] == "1" else "pessoas"
        px, bx = parse_profile(x, guides[("127", kind)], names)
        py, by = parse_profile(y, guides[("127", kind)], names)
        positions = [i + 1 for i, (u, v) in enumerate(zip(x, y)) if u != v]
        comparisons.append({"linhaA": a, "linhaB": b, "textoA": x, "textoB": y,
            "tipo": kind, "posicoes_diferentes": positions, "perfis_exatos": px == py,
            "geografia_exata": x[:8] == y[:8], "restante_fora_boletim_e_id_exato": x[:13] + x[16:55] == y[:13] + y[16:55],
            "campos": dict(zip(names, px)), "invalidos": [bx, by]})
    repeat_runs = []; run = []
    for line in range(8380, 8503):
        a = raw[line]; b = raw[line + 17]
        if a[:13] + a[16:55] == b[:13] + b[16:55]:
            run.append(line)
        else:
            if run:
                repeat_runs.append({"inicioA": run[0], "fimA": run[-1], "inicioB": run[0] + 17,
                    "fimB": run[-1] + 17, "quantidade": len(run)})
            run = []
    if run:
        repeat_runs.append({"inicioA": run[0], "fimA": run[-1], "inicioB": run[0] + 17,
            "fimB": run[-1] + 17, "quantidade": len(run)})
    permutations = []
    for aa, bb in [(range(8443, 8448), range(8460, 8465)), (range(8448, 8460), range(8465, 8477)),
                   (range(69946, 69949), range(70362, 70365))]:
        left = Counter(raw[i][:13] + raw[i][16:55] for i in aa)
        right = Counter(raw[i][:13] + raw[i][16:55] for i in bb)
        permutations.append({"linhasA": list(aa), "linhasB": list(bb),
            "mesmo_multiconjunto_literal_fora_boletim_ID": left == right,
            "mapeamento": [{"linhaA": a, "linhasB_compativeis": [b for b in bb if raw[a][:13] + raw[a][16:55] == raw[b][:13] + raw[b][16:55]]} for a in aa]})
    result = {"fonte": str(path.relative_to(root)), "sha256": sha256(path), "comparacoes_mesma_posicao": comparisons,
        "comparacao_sem_exigir_mesma_ordem": permutations,
        "corridas_textuais_deslocamento17_na_janela8380_8519": repeat_runs,
        "conclusaoAM": "Dois pares de grupos4e11pessoas com cartoes,perfis e geografia iguais. Nao e repeticao literal sequencial: pessoas reordenadas. Comparacao de multiconjunto literal fora boletim/ID registrada separadamente. Sem fonte25AM para estabelecer multiplicidade historica.",
        "conclusaoMA": "Cartoes e2pessoas coincidem. Avaliar genericidade dos campos; nao concluir exclusao pela igualdade de grupo pequeno.",
        "decisoes_aplicadas": 0}
    (folder / "qc_blocos_am_ma.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    if portable:
        portable = portable.resolve()
        if not portable.is_relative_to(root / "references") or portable.exists():
            raise ValueError("Caderno portatil deve ser novo e ficar em references")
        portable.parent.mkdir(parents=True, exist_ok=True)
        portable.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps({"pares": len(comparisons), "exatos_fora_boletim_ID": sum(r["restante_fora_boletim_e_id_exato"] for r in comparisons),
        "runs": repeat_runs, "MA": [r["campos"] for r in comparisons if r["linhaA"] in {69947, 69948}]}, ensure_ascii=False))
    return result


def audit(root, out, uf_filter=None):
    root = root.resolve(); out = out.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    started = time.monotonic(); guides = load_guides(root)
    inventory = json.loads((root / INVENTORY).read_text(encoding="utf-8"))
    groups = [g for g in inventory["grupos"] if uf_filter is None or (g["chave"] and g["chave"][0] == uf_filter)]
    keys_by_id = {g["id"]: tuple(g["chave"]) for g in groups if g["chave"]}
    connection = sqlite3.connect((root / INDEX).as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    groups_by_context = defaultdict(list)
    for g in groups:
        if g["chave"]:
            groups_by_context[tuple(g["chave"])].append(g)
    contexts = {}; profile_contexts = defaultdict(set); targets = defaultdict(list)
    for key, pending in groups_by_context.items():
        people = [dict(r) for r in connection.execute(
            "SELECT linha,original,corrigido,invalidos,familia_atual,familia_fisica FROM pessoas "
            "WHERE uf=? AND pasta=? AND boletim=? AND excluida=0 ORDER BY linha", key)]
        families = [dict(r) for r in connection.execute(
            "SELECT linha,original,corrigido FROM familias WHERE uf=? AND pasta=? AND boletim=? ORDER BY linha", key)]
        signatures = Counter(); bad = []
        for r in people:
            p, invalid = parse_profile(r["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)
            s = signature(p, guides); signatures[s] += 1
            if invalid:
                bad.append({"linha": r["linha"], "campos": invalid})
            else:
                profile_contexts[s].add(key)
        pending_signatures = set()
        for g in pending:
            row = g["registros127"][0]
            p, invalid = parse_profile(row["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)
            s = signature(p, guides); pending_signatures.add(s)
            if not invalid:
                targets[s].append(g["id"])
        contexts[key] = {"chave": list(key), "pessoas127": people, "cartoes127": families,
            "invalidos": bad, "assinaturas": signatures, "pendentes": pending_signatures,
            "mesma_chave25": [], "alternativas_composicao24": []}
    sightings = {g["id"]: Counter() for g in groups}; sight_examples = defaultdict(list)
    sources = []; counts = {}; alternative_count = 0
    candidate_file = out / "alternativas_composicao24.jsonl"
    with candidate_file.open("x", encoding="utf-8") as alternatives:
        for uf, abbrev in sorted(UF.items()):
            if uf_filter is not None and uf != uf_filter:
                continue
            path = root / f"data/release_legacy/Censo.1960.amostra.25porcento.{abbrev}.gz"
            fingerprint = sha256(path)
            source_groups = 0; source_people = 0; line_count = 0
            family = None; people = []

            def examine():
                nonlocal source_groups, source_people, alternative_count
                if not family:
                    return
                source_groups += 1; source_people += len(people)
                key = (uf, integer(family["texto"][:5]), integer(family["texto"][5:8]))
                counter = Counter(raw_signature(p["texto"]) for p in people)
                candidates = set()
                for s, n in counter.items():
                    candidates.update(profile_contexts.get(s, ()))
                    for group_id in targets.get(s, ()):
                        own = keys_by_id[group_id]
                        scope = "mesma_chave" if key == own else "outra_chave_mesma_UF" if uf == own[0] else "outra_UF"
                        sightings[group_id][scope] += n
                        if len(sight_examples[group_id]) < 12:
                            sight_examples[group_id].append({"UF25": uf, "cartao25": family["linha"],
                                "chave25": list(key), "quantidade": n, "ambito": scope})
                payload = {"UF25": uf, "cartao25": family, "pessoas25": people}
                if key in contexts:
                    contexts[key]["mesma_chave25"].append(payload)
                for candidate in candidates:
                    context = contexts[candidate]
                    if context["invalidos"] or not multiplicities(context["assinaturas"], counter, context["pendentes"]):
                        continue
                    detail = dict(payload, chave127=list(candidate), chave25=list(key),
                        mesma_chave=key == candidate, mesma_UF=uf == candidate[0],
                        problemas_estrutura25=source_structure(family, people))
                    detail["comparacao_pessoas"] = nearest_people(context["pessoas127"], people, guides)
                    detail["aprovado"] = False
                    alternatives.write(json.dumps(detail, ensure_ascii=False) + "\n")
                    context["alternativas_composicao24"].append({"UF25": uf,
                        "cartao25": family["linha"], "chave25": list(key), "mesma_chave": key == candidate,
                        "mesma_UF": uf == candidate[0]})
                    alternative_count += 1

            with gzip.open(path, "rt", encoding="latin1") as stream:
                for line_count, text in enumerate(stream, 1):
                    text = text.rstrip("\r\n")
                    row = {"linha": line_count, "texto": text}
                    if text[8:10] == "00":
                        examine(); family = row; people = []
                    else:
                        people.append(row)
                examine()
            if sha256(path) != fingerprint:
                raise ValueError("Fonte25 mudou durante leitura")
            sources.append({"arquivo": str(path.relative_to(root)), "sha256": fingerprint})
            counts[abbrev] = {"linhas": line_count, "cartoes": source_groups, "pessoas": source_people}
            print(json.dumps({"UF": abbrev, **counts[abbrev], "segundos": round(time.monotonic() - started, 1)}), flush=True)
    output_contexts = []
    for context in contexts.values():
        del context["assinaturas"]; del context["pendentes"]
        for source in context["mesma_chave25"]:
            source["comparacao_pessoas"] = nearest_people(context["pessoas127"], source["pessoas25"], guides)
            source["estrutura25"] = source_structure(source["cartao25"], source["pessoas25"])
            if len(context["cartoes127"]) == 1:
                f127, bad127 = parse_profile(context["cartoes127"][0]["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
                f25, bad25 = parse_profile(source["cartao25"]["texto"], guides[("25", "familias")], FAMILY_NAMES)
                source["diferencas_cartao"] = [{"campo": n, "valor127": a, "valor25": b}
                    for n, a, b in zip(FAMILY_NAMES, f127, f25) if a != b]
                source["invalidos_cartao"] = [bad127, bad25]
        output_contexts.append(context)
    output_groups = []
    for g in groups:
        row = {k: g[k] for k in ("id", "chave", "linhas127", "razao_principal", "exclusoes_antigas_sem_prova")}
        row["ocorrencias24_nacionais"] = dict(sightings[g["id"]])
        row["primeiros_exemplos24"] = sight_examples[g["id"]]
        row["investigado_fora_chave"] = bool(g["chave"])
        row["decisao_nova"] = None
        if g["chave"]:
            row["alternativas_composicao24"] = contexts[tuple(g["chave"])]["alternativas_composicao24"]
        output_groups.append(row)
    summary = {"grupos": len(groups), "linhas127": sum(len(g["linhas127"]) for g in groups),
        "contextos": len(contexts), "fontes25_lidas": len(sources),
        "linhas25_lidas": sum(v["linhas"] for v in counts.values()),
        "alternativas_grupo_completo24": alternative_count,
        "grupos_com_ocorrencia_mesma_chave": sum(s["mesma_chave"] > 0 for s in sightings.values()),
        "grupos_com_ocorrencia_outra_chave_UF": sum(s["outra_chave_mesma_UF"] > 0 for s in sightings.values()),
        "grupos_com_ocorrencia_outra_UF": sum(s["outra_UF"] > 0 for s in sightings.values()),
        "novas_decisoes_aplicadas": 0, "segundos": round(time.monotonic() - started, 1)}
    result = {"resumo": summary, "contagem_fontes": counts, "fontes": sources,
        "inventario_sha256": sha256(root / INVENTORY), "indice127_sha256": sha256(root / INDEX),
        "grupos": output_groups, "contextos": output_contexts,
        "criterios": ["Todas as 17 fontes e todas as chaves pesquisadas, inclusive outras UFs.",
            "Busca individual por24campos e composicao integral/multiplicidades; V216 nao e recodificado.",
            "Demais divergencias pessoais examinadas sem limite de distancia na propria chave; candidatos minimos podem compartilhar destino e NA nao identifica pessoa.",
            "Nao e busca global por qualquer distancia, nomes inexistentes ou todas as possiveis particoes familiares.",
            "Exemplos individuais limitados aos12primeiros; totais e alternativas de composicao integral nao truncados."]}
    (out / "resultado.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path)
    parser.add_argument("--uf", type=int)
    parser.add_argument("--deepen", type=Path)
    parser.add_argument("--portable", type=Path)
    parser.add_argument("--neighborhood", type=Path)
    parser.add_argument("--summarize", type=Path)
    parser.add_argument("--relaxed", type=Path)
    parser.add_argument("--household-collisions", type=Path)
    parser.add_argument("--independent-blocks", type=Path)
    args = parser.parse_args()
    if args.deepen:
        deepen(Path(__file__).resolve().parents[1], args.deepen, args.portable)
    elif args.neighborhood:
        neighborhood(Path(__file__).resolve().parents[1], args.neighborhood, args.portable)
    elif args.summarize:
        summarize(Path(__file__).resolve().parents[1], args.summarize, args.portable)
    elif args.relaxed:
        relaxed(Path(__file__).resolve().parents[1], args.relaxed, args.portable)
    elif args.household_collisions:
        household_collisions(Path(__file__).resolve().parents[1], args.household_collisions, args.portable)
    elif args.independent_blocks:
        independent_blocks(Path(__file__).resolve().parents[1], args.independent_blocks, args.portable)
    else:
        audit(Path(__file__).resolve().parents[1], args.out, args.uf)
