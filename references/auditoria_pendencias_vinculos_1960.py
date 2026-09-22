"""Confere todo o inventario de vinculos, sem aplicar decisoes ou executar R."""
import argparse
from collections import Counter, defaultdict
import csv
import json
from pathlib import Path
import sqlite3
import time

import auditoria_recuperacao_cartoes_1960 as recovery


INDEX = "tmp/recuperacao_cartoes_1960_20260922/auditoria_completa_02"
PENDING = "tmp/execucao_1960_20260922/integridade_127_pendencias_final.json"
GUARDS = "tmp/execucao_1960_20260922/integridade_127_guardas_vinculos.json"
RECOVERED = "read_guides/1960_amostra_127_cartoes_recuperados.json"


def public(row):
    return {k: v.hex() if isinstance(v, bytes) else v for k, v in row.items()}


def profile(row, sample, kind, guides):
    names = recovery.PERSON_NAMES if kind == "pessoas" else recovery.FAMILY_NAMES
    return recovery.parse_profile(row["corrigido"] if sample == "127" else row["texto"],
                                  guides[(sample, kind)], names)


def compare_group(families127, people127, families25, people25, guides):
    reasons = []
    if len(families127) != 1:
        reasons.append("cartao127_ausente" if not families127 else "cartao127_multiplo")
    if len(families25) != 1:
        reasons.append("cartao25_ausente" if not families25 else "cartao25_multiplo")
    a = [profile(p, "127", "pessoas", guides) for p in people127]
    b = [profile(p, "25", "pessoas", guides) for p in people25]
    invalid_a = [p["linha"] for p, (_, bad) in zip(people127, a) if bad]
    invalid_b = [p["linha"] for p, (_, bad) in zip(people25, b) if bad]
    if invalid_a or invalid_b:
        reasons.append("quesitos_pessoais_invalidos")
    count_a = Counter(p for p, _ in a)
    count_b = Counter(p for p, _ in b)
    if not count_a or count_a != count_b:
        reasons.append("composicao_integral_diverge")
    differences = {}
    if len(families25) == 1:
        reasons.extend(recovery.source_structure(families25[0], people25))
        family25, invalid = profile(families25[0], "25", "familias", guides)
        if invalid:
            reasons.append("cartao25_quesitos_invalidos")
        if len(families127) == 1:
            family127, invalid = profile(families127[0], "127", "familias", guides)
            if invalid:
                reasons.append("cartao127_quesitos_invalidos")
            differences = {name: [x, y] for name, x, y in zip(recovery.FAMILY_NAMES, family127, family25) if x != y}
            if differences:
                reasons.append("respostas_cartoes_divergem")
            if families127[0]["distrito"] != recovery.integer(families25[0]["texto"][33:35]):
                reasons.append("distritos_cartoes_divergem")
    target = families127[0]["linha"] if len(families127) == 1 else None
    other = [p["linha"] for p in people127 if p["familia_atual"] is not None and p["familia_atual"] != target]
    if other:
        reasons.append("pessoa_ja_atribuida_a_outro_cartao")
    paired = []
    for person, (values, invalid) in zip(people127, a):
        matches = [p["linha"] for p, (v, bad) in zip(people25, b) if v == values and not bad and not invalid]
        nearest = []
        if not matches and people25 and not invalid:
            distances = []
            for candidate, (values25, bad) in zip(people25, b):
                if bad:
                    continue
                delta = {name: [x, y] for name, x, y in zip(recovery.PERSON_NAMES, values, values25) if x != y}
                distances.append((len(delta), candidate["linha"], delta))
            if distances:
                best = min(n for n, _, _ in distances)
                nearest = [{"linha25": line, "diferencas": delta} for n, line, delta in distances if n == best]
        paired.append({"linha127": person["linha"], "linhas25_quesitos_exatos": matches,
                       "candidatos_mais_proximos_nao_aprovados": nearest})
    return {"motivos": sorted(set(reasons)), "composicao_exata": bool(count_a) and count_a == count_b,
            "n127": len(people127), "n25": len(people25), "diferencas_cartoes": differences,
            "invalidas127": invalid_a, "invalidas25": invalid_b, "outro_destino": other,
            "correspondencias_pessoais": paired}


def classify(check, has_source):
    if not has_source:
        return "fonte25_nao_disponivel"
    if not check["motivos"]:
        return "vinculo_existente_comprovavel"
    if check["motivos"] == ["cartao127_ausente"]:
        return "cartao_ausente_com_composicao_exata"
    if "cartao25_ausente" in check["motivos"]:
        return "boletim_nao_encontrado_na25_por_chave"
    if "composicao_integral_diverge" in check["motivos"]:
        return "respostas_ou_numero_de_pessoas_divergentes"
    return "conflito_documentado_de_cartao_ou_chave"


def extra_linked_lines(group_lines, linked_lines):
    return sorted(set(linked_lines) - set(group_lines))


def bijection_without_v216(profiles127, profiles25):
    """Identifica grupo sem converter ou preencher nenhuma resposta."""
    position = recovery.PERSON_NAMES.index("V216")
    keys127 = [p[:position] + p[position+1:] for p in profiles127]
    keys25 = [p[:position] + p[position+1:] for p in profiles25]
    reasons = []
    if not profiles127 or len(profiles127) != len(profiles25):
        reasons.append("contagens_divergentes")
    if any(n != 1 for n in Counter(keys127).values()) or any(n != 1 for n in Counter(keys25).values()):
        reasons.append("pareamento24_nao_unico")
    if Counter(keys127) != Counter(keys25):
        reasons.append("diferenca_alem_de_V216")
    pairs = []; exact = 0
    if not reasons:
        indexes = {key: i for i, key in enumerate(keys25)}
        for i, key in enumerate(keys127):
            j = indexes[key]
            a, b = profiles127[i][position], profiles25[j][position]
            if a == b:
                exact += 1
            elif (a, b) != (0, 63):
                reasons.append("diferenca_V216_fora_do_par_00_63")
            pairs.append({"indice127": i, "indice25": j, "V216": [a, b], "exato25campos": a == b})
        if exact < 2:
            reasons.append("menos_de_duas_testemunhas_exatas")
    return {"aprovavel": not reasons, "motivos": sorted(set(reasons)), "pares": pairs,
            "n_testemunhas_exatas": exact, "respostas_modificadas": False}


def duplicate_rows(paths):
    if isinstance(paths, Path):
        paths = [paths]
    result = [row for path in paths for row in recovery.rows(path)]
    if len({int(r["linha"]) for r in result}) != len(result):
        raise ValueError("Manifestos candidatos de duplicatas se sobrepoem")
    return result


def group_identity_preserving_v216(profiles127, profiles25):
    position = recovery.PERSON_NAMES.index("V216")
    a = defaultdict(list); b = defaultdict(list)
    for i, profile127 in enumerate(profiles127):
        a[profile127[:position] + profile127[position+1:]].append(i)
    for j, profile25 in enumerate(profiles25):
        b[profile25[:position] + profile25[position+1:]].append(j)
    reasons = []
    if not a or Counter({key: len(v) for key, v in a.items()}) != Counter({key: len(v) for key, v in b.items()}):
        reasons.append("composicao24_ou_multiplicidade_diverge")
    pairs = []; exact_witnesses = []
    if not reasons:
        for key, indexes in a.items():
            source_indexes = b[key]
            ac = Counter(profiles127[i][position] for i in indexes)
            bc = Counter(profiles25[j][position] for j in source_indexes)
            left_a = list((ac-bc).elements()); left_b = list((bc-ac).elements())
            if any(x not in {0, 63} for x in left_a + left_b):
                reasons.append("V216_diverge_fora_00_63")
            if len(indexes) == 1 and profiles127[indexes[0]] == profiles25[source_indexes[0]]:
                exact_witnesses.append(indexes[0])
            pairs.append({"indices127": indexes, "indices25": source_indexes,
                          "V216_127": dict(ac), "V216_25": dict(bc)})
        if len(exact_witnesses) < 2:
            reasons.append("menos_de_duas_testemunhas_exatas_distintas")
    return {"aprovavel": not reasons, "motivos": sorted(set(reasons)), "classes_pareadas": pairs,
            "indices_testemunhas_exatas": exact_witnesses, "respostas_modificadas": False}


def existing_proposals(root, out, base, duplicate_files, selected_uf=None):
    root = root.resolve(); out = out.resolve(); base = base.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    sources = {r["arquivo"]: r["sha256"] for r in json.loads((root / INDEX / "manifesto.json").read_text(encoding="utf-8"))["fontes"]}
    for path, expected in sources.items():
        if recovery.sha256(root / path) != expected:
            raise ValueError("Fonte anterior mudou: " + path)
    guides = recovery.load_guides(root)
    duplicates = duplicate_rows(duplicate_files)
    removed = {int(r["linha"]) for r in duplicates if r["acao"] == "remover"}
    decided = {int(r["linha"]) for r in duplicates} | {int(r["linha"]) for r in recovery.rows(root / recovery.FIXED_SOURCES[2])}
    previous = json.loads((base / "resultado.json").read_text(encoding="utf-8"))
    new_links = {r["linha"]: r["linha_familia"] for r in json.loads((base / "candidatos_vinculos.json").read_text(encoding="utf-8"))["candidatos"]}
    scope = {tuple(g["chave"]): g for g in previous["grupos"]
        if g["classe"] not in {"vinculo_existente_comprovavel", "fonte25_nao_disponivel", "cartao_ausente_com_composicao_exata"}
        and (selected_uf is None or g["chave"][0] == selected_uf)}
    connection = sqlite3.connect((root / INDEX / "indice127.sqlite").as_uri()+"?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    pending, _ = recovery.pending_duplicate_lines(connection, decided)
    results = []; proposals = []
    with (base / "evidencias_literais.jsonl").open(encoding="utf-8") as f:
        for text in f:
            witness = json.loads(text); key = tuple(witness["chave"])
            if key not in scope:
                continue
            people = [r for r in witness["pessoas127"] if r["linha"] not in removed]
            families = witness["cartoes127"]; f25 = witness["cartoes25"]; p25 = witness["pessoas25"]
            reasons = []
            if len(families) != 1 or len(f25) != 1:
                reasons.append("cartao_ausente_ou_multiplo")
            base_check = compare_group(families, people, f25, p25, guides)
            reasons.extend(r for r in base_check["motivos"] if r not in {"respostas_cartoes_divergem", "composicao_integral_diverge"})
            if set(base_check["diferencas_cartoes"]) & {"V101", "V116", "V118"}:
                reasons.append("identidade_especie_municipio_situacao_do_cartao_diverge")
            if any(p["linha"] in pending for p in people):
                reasons.append("multiplicidade127_ainda_sem_decisao")
            if len(families) == 1:
                family = families[0]
                linked = recovery.fetch(connection, "SELECT linha FROM pessoas WHERE familia_atual=? AND excluida=0", (family["linha"],))
                all_linked = {p["linha"] for p in linked if p["linha"] not in removed and new_links.get(p["linha"], family["linha"]) == family["linha"]}
                all_linked.update(line for line, target in new_links.items() if target == family["linha"] and line not in removed)
                outside = extra_linked_lines([p["linha"] for p in people], all_linked)
                if outside:
                    reasons.append("outras_pessoas_ja_vinculadas_ao_destino")
            else:
                outside = []
            identity = group_identity_preserving_v216([profile(p, "127", "pessoas", guides)[0] for p in people],
                                                       [profile(p, "25", "pessoas", guides)[0] for p in p25])
            reasons.extend(identity["motivos"])
            unique = []
            if not reasons:
                for i in identity["indices_testemunhas_exatas"]:
                    p = people[i]
                    matching = recovery.fetch(connection, "SELECT linha FROM pessoas WHERE uf=? AND perfil=? AND excluida=0", (key[0], bytes.fromhex(p["perfil"])))
                    if len([r for r in matching if r["linha"] not in removed]) == 1:
                        unique.append(p["linha"])
                if len(unique) < 2:
                    reasons.append("menos_de_duas_testemunhas_exatas_unicas_na127_UF")
            target_lines = [line for line in scope[key]["linhas_escopo"] if line not in removed]
            item = {"chave": key, "linhas_escopo": target_lines, "motivos": sorted(set(reasons)),
                "diferencas_habitacionais_preservadas": base_check["diferencas_cartoes"], "identificacao_grupo": identity,
                "testemunhas_exatas_unicas127": unique, "outras_pessoas_ja_vinculadas": outside,
                "linhas_removidas_por_candidatos_duplicatas": [p["linha"] for p in witness["pessoas127"] if p["linha"] in removed]}
            results.append(item)
            if not reasons:
                item["evidencias_literais"] = witness
                item["linha_familia"] = families[0]["linha"]
                proposals.append(item)
    connection.close()
    for path, before in sources.items():
        if recovery.sha256(root / path) != before:
            raise ValueError("Fonte alterada durante auditoria: " + path)
    result = {"resumo": {"grupos_examinados": len(results), "pessoas_examinadas": sum(len(r["linhas_escopo"]) for r in results),
                         "grupos_propostos": len(proposals), "pessoas_propostas": sum(len(r["linhas_escopo"]) for r in proposals),
                         "fontes_inalteradas": True, "nota": "Propostas de identidade de grupo; preservar respostas V216 e atributos habitacionais divergentes. Nao aplicadas."},
              "grupos": results, "propostas_condicionais": proposals}
    with (out / "resultado.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(json.dumps(result["resumo"], ensure_ascii=False, indent=2), flush=True)
    return result


def export_proposals(root, out, base, proposed, duplicate_files):
    root = root.resolve(); out = out.resolve(); base = base.resolve(); proposed = proposed.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    fields = ["linha", "linha_familia", "texto_original", "texto_corrigido", "texto_familia_original",
              "texto_familia_corrigido", "fonte_25", "linha_pessoa_25", "linha_familia_25", "justificativa"]
    strict_input = json.loads((base / "candidatos_vinculos.json").read_text(encoding="utf-8"))
    candidates = []; ambiguous = []
    for row in strict_input["candidatos"]:
        if len(row["pessoas25_compativeis"]) != 1:
            raise ValueError("Estrito sem correspondencia pessoal unica")
        candidates.append({**{field: row[field] for field in fields if field != "linha_pessoa_25"},
                           "linha_pessoa_25": row["pessoas25_compativeis"][0]["linha"]})
    proposals = json.loads((proposed / "resultado.json").read_text(encoding="utf-8"))["propostas_condicionais"]
    conditional = []
    for group in proposals:
        witness = group["evidencias_literais"]
        people = [p for p in witness["pessoas127"] if p["linha"] not in group["linhas_removidas_por_candidatos_duplicatas"]]
        family = witness["cartoes127"][0]
        for pair in group["identificacao_grupo"]["classes_pareadas"]:
            for index in pair["indices127"]:
                person = people[index]
                if person["linha"] not in group["linhas_escopo"]:
                    continue
                matches = [witness["pessoas25"][i] for i in pair["indices25"]]
                if len(matches) != 1:
                    ambiguous.append({"linha": person["linha"], "linha_familia": family["linha"],
                                      "origens25_possiveis": matches, "grupo": group,
                                      "todos_no_mesmo_cartao25": len(witness["cartoes25"]) == 1 and all(
                                          p["texto"][:8] == witness["cartoes25"][0]["texto"][:8] for p in matches)})
                    if not ambiguous[-1]["todos_no_mesmo_cartao25"]:
                        raise ValueError("Origens individuais em mais de um cartao25")
                conditional.append({"linha": person["linha"], "linha_familia": family["linha"],
                    "texto_original": person["original"], "texto_corrigido": person["corrigido"],
                    "texto_familia_original": family["original"], "texto_familia_corrigido": family["corrigido"],
                    "fonte_25": witness["fonte25"], "linha_pessoa_25": ";".join(str(p["linha"]) for p in matches),
                    "linha_familia_25": witness["cartoes25"][0]["linha"],
                    "justificativa": "Identidade do grupo confirmavel por chave, especie, municipio, situacao e distrito do cartao, composicao de24campos e multiplicidades, com duas testemunhas pessoais exatas unicas naUF127. V21600/63 e atributos habitacionais divergentes permanecem como na127; nao copiar respostas25. Proposta sujeita a revisao do criterio." + (
                        " Mais de uma pessoa25 compativel, todas no mesmo cartao; lista integral de origens preservada, sem afirmar identidade civil individual." if len(matches) > 1 else "")})
    for filename, data in [("vinculos_estritos_33.csv", candidates), ("vinculos_condicionais_133.csv", conditional)]:
        with (out / filename).open("x", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=fields, quoting=csv.QUOTE_ALL)
            writer.writeheader(); writer.writerows(sorted(data, key=lambda r: r["linha"]))
    with (out / "origens_individuais_nao_unicas.json").open("x", encoding="utf-8") as f:
        json.dump(ambiguous, f, ensure_ascii=False, indent=2)
    snapshot = out / "fontes_decisoes_antes"; snapshot.mkdir()
    inventory = []
    paths = [root / r for r in recovery.FIXED_SOURCES[1:]] + [root / RECOVERED] + list(duplicate_files)
    for i, path in enumerate(paths):
        digest = recovery.sha256(path)
        filename = f"{i:02d}_{path.name}"
        with (snapshot / filename).open("xb") as f:
            f.write(path.read_bytes())
        inventory.append({"arquivo": str(path.resolve().relative_to(root)).replace("\\", "/"),
                          "snapshot": filename, "sha256": digest})
    result = {"vinculos_estritos": len(candidates), "vinculos_condicionais": len(conditional),
              "vinculos_condicionais_com_origem_individual_unica": len(conditional)-len(ambiguous),
              "linhas_com_origem_individual_nao_unica": [r["linha"] for r in ambiguous],
              "intersecao_estritos_condicionais": sorted({r["linha"] for r in candidates} & {r["linha"] for r in conditional}),
              "fontes_preservadas_antes_de_novas_decisoes": inventory,
              "nota": "A linha425558 tem duas possiveis pessoas25 explicitamente listadas, ambas no mesmo grupo; o vinculo familiar nao exige escolher uma identidade civil individual. Nenhuma decisao aplicada por esta exportacao."}
    with (out / "indice.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(json.dumps({k:v for k,v in result.items() if k != "fontes_preservadas_antes_de_novas_decisoes"}, ensure_ascii=False, indent=2), flush=True)
    return result


def fixture_links(root, out, delivery):
    root = root.resolve(); out = out.resolve(); delivery = delivery.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    decisions = recovery.rows(delivery / "vinculos_estritos_33.csv") + recovery.rows(delivery / "vinculos_condicionais_133.csv")
    destinations = {int(r["linha_familia"]) for r in decisions}
    people = {int(r["linha"]) for r in decisions}
    connection = sqlite3.connect((root / INDEX / "indice127.sqlite").as_uri()+"?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    families = {}; notes = []
    for line in destinations:
        family = recovery.fetch(connection, "SELECT * FROM familias WHERE linha=?", (line,))[0]
        families[line] = family
    for line in sorted(destinations):
        family = families[line]
        if family["corrigido"][18] in {"4", "5"}:
            current = family
            while current["corrigido"][18] in {"4", "5"}:
                previous = recovery.fetch(connection, "SELECT * FROM familias WHERE linha<? ORDER BY linha DESC LIMIT 1", (current["linha"],))
                if not previous:
                    notes.append({"linha": current["linha"], "motivo": "convivente_sem_cartao_anterior"}); break
                previous = previous[0]
                if any(previous[k] != current[k] or previous[k] is None for k in ("uf", "municipio", "distrito", "pasta")) or previous["corrigido"][18] not in {"2", "4", "5"}:
                    notes.append({"linha": current["linha"], "motivo": "principal_anterior_nao_compativel", "linha_anterior": previous["linha"]}); break
                families[previous["linha"]] = previous
                current = previous
    # Conservar todo o conjunto de familias de cada principal real trazido ao teste.
    for line, family in list(families.items()):
        if family["corrigido"][18] != "2":
            continue
        current = family
        while True:
            following = recovery.fetch(connection, "SELECT * FROM familias WHERE linha>? ORDER BY linha LIMIT 1", (current["linha"],))
            if not following or following[0]["corrigido"][18] not in {"4", "5"}:
                break
            following = following[0]
            if any(following[k] != family[k] or following[k] is None for k in ("uf", "municipio", "distrito", "pasta")):
                notes.append({"linha": following["linha"], "motivo": "convivente_seguinte_com_geografia_divergente"}); break
            families[following["linha"]] = following
            current = following
    all_people = {}
    for line, family in families.items():
        members = recovery.fetch(connection, "SELECT * FROM pessoas WHERE familia_atual=? OR (uf=? AND pasta=? AND boletim=?) ORDER BY linha",
                                 (line, family["uf"], family["pasta"], family["boletim"]))
        for person in members:
            all_people[person["linha"]] = person
    for line in people - set(all_people):
        all_people[line] = recovery.fetch(connection, "SELECT * FROM pessoas WHERE linha=?", (line,))[0]
    updated = {int(r["linha"]): int(r["linha_familia"]) for r in decisions}
    for line, person in all_people.items():
        current = updated.get(line, person["familia_atual"])
        if current is None and not person["excluida"]:
            notes.append({"linha": line, "motivo": "pessoa_contexto_sem_destino_confirmado"})
        elif current is not None and current not in families and not person["excluida"]:
            notes.append({"linha": line, "motivo": "pessoa_contexto_ligada_a_cartao_fora_do_fixture", "destino": current})
    connection.close()
    lines = sorted(set(families) | set(all_people))
    with (out / "linhas127.json").open("x", encoding="utf-8") as f:
        json.dump(lines, f, indent=2)
    result = {"pessoas_alvo": len(people), "cartoes_destino": len(destinations), "cartoes_com_contexto": len(families),
              "pessoas_com_contexto_antes_dedup": len(all_people), "linhas_fixture": len(lines),
              "cartoes_conviventes": [line for line, f in families.items() if f["corrigido"][18] in {"4", "5"}],
              "contexto_adicional": sorted(set(families)-destinations), "alertas": notes,
              "nota": "Inclui todas as pessoas por chave/destino e familias secundarias/principais fisicas compativeis, inclusive ocorrencias a remover por manifesto. Nao executa R nem remove alertas para fazer teste passar."}
    with (out / "conferencia.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(json.dumps(result, ensure_ascii=False, indent=2), flush=True)
    return result


def deep_audit(root, out, base, duplicate_file, selected_uf=None):
    root = root.resolve(); out = out.resolve(); base = base.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    metadata = json.loads((root / INDEX / "manifesto.json").read_text(encoding="utf-8"))
    sources = {r["arquivo"]: r["sha256"] for r in metadata["fontes"]}
    for path, expected in sources.items():
        if recovery.sha256(root / path) != expected:
            raise ValueError("Indice desatualizado: " + path)
    base_result = json.loads((base / "resultado.json").read_text(encoding="utf-8"))
    new_links = json.loads((base / "candidatos_vinculos.json").read_text(encoding="utf-8"))["candidatos"]
    duplicates = duplicate_rows(duplicate_file)
    guides = recovery.load_guides(root)
    connection = sqlite3.connect((root / INDEX / "indice127.sqlite").as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    # Somente a visao TEMP recebe as decisoes candidatas; SQLite fonte permanece readonly.
    connection.execute("CREATE TEMP TABLE novas_duplicatas(linha INTEGER PRIMARY KEY,excluida INTEGER)")
    connection.executemany("INSERT INTO novas_duplicatas VALUES(?,?)", [(int(r["linha"]), int(r["acao"] == "remover")) for r in duplicates])
    connection.execute("CREATE TEMP TABLE novos_vinculos(linha INTEGER PRIMARY KEY,familia INTEGER)")
    connection.executemany("INSERT INTO novos_vinculos VALUES(?,?)", [(r["linha"], r["linha_familia"]) for r in new_links])
    connection.execute("""CREATE TEMP VIEW pessoas AS SELECT p.linha,p.uf,p.pasta,p.boletim,p.distrito,
        p.municipio,p.situacao,p.chave,p.original,p.corrigido,p.perfil,p.invalidos,
        coalesce(d.excluida,p.excluida) AS excluida,p.familia_atual,p.familia_fisica
        FROM main.pessoas p LEFT JOIN novas_duplicatas d ON p.linha=d.linha
        WHERE NOT EXISTS(SELECT 1 FROM novos_vinculos v WHERE v.linha=p.linha)
        UNION ALL SELECT p.linha,p.uf,p.pasta,p.boletim,p.distrito,
        p.municipio,p.situacao,p.chave,p.original,p.corrigido,p.perfil,p.invalidos,
        coalesce(d.excluida,p.excluida),v.familia,p.familia_fisica
        FROM novos_vinculos v JOIN main.pessoas p ON p.linha=v.linha
        LEFT JOIN novas_duplicatas d ON p.linha=d.linha""")
    approved = {int(r["linha"]) for r in recovery.rows(root / recovery.FIXED_SOURCES[2])} | {int(r["linha"]) for r in duplicates}
    pending_duplicates, _ = recovery.pending_duplicate_lines(connection, approved)
    scope = [g for g in base_result["grupos"] if g["classe"] == "cartao_ausente_com_composicao_exata"
             and (selected_uf is None or g["chave"][0] == selected_uf)]
    strict_cards = []; proposed_cards = []; summaries = []; alternatives = []; own_proofs = {}
    for uf in sorted({g["chave"][0] for g in scope}):
        print("Alternativas UF", uf, flush=True)
        groups = [g for g in scope if g["chave"][0] == uf]
        f25, p25 = recovery.read_source(root, uf, {tuple(g["chave"][1:]) for g in groups})
        prepared = []; extra_keys = set()
        for group in groups:
            key = tuple(group["chave"])
            persons = recovery.fetch(connection, "SELECT * FROM pessoas WHERE uf=? AND pasta=? AND boletim=? AND excluida=0 ORDER BY linha", key)
            reasons, card = recovery.evaluate_group(key, f25[key[1:]], p25[key[1:]], persons, guides, pending_duplicates)
            candidates = {}; evidence = {}
            if card is not None:
                candidates, evidence = recovery.candidate_families(connection, key, f25[key[1:]][0], persons, guides)
                extra_keys.update((r["pasta"], r["boletim"]) for r in candidates.values())
            prepared.append((key, persons, reasons, card, candidates, evidence))
        own_f25, own_p25 = recovery.read_source(root, uf, extra_keys)
        for key, persons, reasons, card, candidates, evidence in prepared:
            unresolved_strict = []; unresolved_proposed = []; used_proposed = []
            if card is not None:
                target = Counter(r["perfil"] for r in persons)
                fprofile, _ = recovery.parse_profile(card["texto_25"], guides[("25", "familias")], recovery.FAMILY_NAMES)
                for line, family in sorted(candidates.items()):
                    if line not in own_proofs:
                        proof, direct = recovery.own_group_proof(connection, family, own_f25, own_p25, guides, pending_duplicates)
                        linked = recovery.fetch(connection, "SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (line,))
                        sp = own_p25.get((family["pasta"], family["boletim"]), [])
                        a = [profile(p, "127", "pessoas", guides)[0] for p in linked]
                        b = [profile(p, "25", "pessoas", guides)[0] for p in sp]
                        relaxed = bijection_without_v216(a, b)
                        remaining = set(proof["motivos"]) - {"composicao_propria_diverge"}
                        if remaining:
                            relaxed["motivos"].extend(sorted(remaining)); relaxed["aprovavel"] = False
                        anchors = []
                        if relaxed["aprovavel"]:
                            for pair in relaxed["pares"]:
                                if pair["exato25campos"]:
                                    person = linked[pair["indice127"]]
                                    other = recovery.fetch(connection, "SELECT linha FROM pessoas WHERE uf=? AND perfil=? AND excluida=0", (uf, person["perfil"]))
                                    if len(other) == 1:
                                        anchors.append(person["linha"])
                            if len(anchors) < 2:
                                relaxed["motivos"].append("menos_de_duas_testemunhas_unicas_na127_UF")
                                relaxed["aprovavel"] = False
                        relaxed["testemunhas_exatas_unicas127"] = anchors
                        for pair in relaxed["pares"]:
                            pair["linha127"] = linked[pair["indice127"]]["linha"]
                            pair["linha25"] = sp[pair["indice25"]]["linha"]
                        own_proofs[line] = {"prova_estrita": proof, "proposta_identificacao_grupo": relaxed,
                            "cartao127": public(family), "pessoas127": [public(p) for p in linked],
                            "cartoes25": own_f25.get((family["pasta"], family["boletim"]), []), "pessoas25": sp}
                    own = own_proofs[line]
                    direct = Counter(bytes.fromhex(r["perfil"]) for r in own["pessoas127"])
                    physical = Counter(r["perfil"] for r in recovery.fetch(connection, "SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0", (line,)))
                    same_geo = (family["uf"], family["municipio"], family["situacao"]) == (uf, recovery.integer(card["V116"]), recovery.integer(card["V118"]))
                    same_body = family["perfil"] == recovery.profile_hash(fprofile) and not family["invalidos"]
                    strong = bool(evidence[line] & {"mesmo_municipio_distrito_boletim", "chave_ate_um_caractere"})
                    same_species = family["corrigido"][18] == card["familias"]["V101"]
                    strict_alt = recovery.alternative_reasons(same_geo, same_body, strong, direct, physical, target, own["prova_estrita"]["confirmado"], same_species)
                    proposed_alt = recovery.alternative_reasons(same_geo, same_body, strong, direct, physical, target,
                        own["prova_estrita"]["confirmado"] or own["proposta_identificacao_grupo"]["aprovavel"], same_species)
                    if strict_alt:
                        unresolved_strict.append(line)
                    if proposed_alt:
                        unresolved_proposed.append(line)
                    if strict_alt and not proposed_alt:
                        used_proposed.append(line)
                    alternatives.append({"chave_alvo": key, "linha_cartao127": line, "pistas": sorted(evidence[line]),
                        "motivos_estritos": strict_alt, "motivos_apos_proposta": proposed_alt})
                # Igualdade integral em outra chave continua impedindo a recuperacao.
                others = set()
                for person in persons:
                    for row in recovery.fetch(connection, "SELECT DISTINCT uf,pasta,boletim FROM pessoas WHERE uf=? AND perfil=? AND excluida=0 AND NOT(pasta=? AND boletim=?)", (uf, person["perfil"], key[1], key[2])):
                        others.add((row["uf"], row["pasta"], row["boletim"]))
                for other_key in others:
                    other = recovery.fetch(connection, "SELECT perfil FROM pessoas WHERE uf=? AND pasta=? AND boletim=? AND excluida=0", other_key)
                    if Counter(r["perfil"] for r in other) == target:
                        reasons.append("composicao_integral_tambem_em_outra_chave127")
                if not reasons and not unresolved_strict:
                    strict_cards.append(card)
                elif not reasons and not unresolved_proposed:
                    card["cartoes_afastados_por_proposta"] = used_proposed
                    proposed_cards.append(card)
            summaries.append({"chave": key, "linhas127": [p["linha"] for p in persons], "motivos": reasons,
                              "alternativas_estritas": unresolved_strict, "alternativas_apos_proposta": unresolved_proposed,
                              "cartoes_afastados_por_proposta": used_proposed})
    connection.close()
    for path, before in sources.items():
        if recovery.sha256(root / path) != before:
            raise ValueError("Fonte alterada: " + path)
    result = {"resumo": {"grupos": len(scope), "pessoas": sum(len(g["linhas_escopo"]) for g in scope),
        "novos_cartoes_criterio_estrito": len(strict_cards), "pessoas_criterio_estrito": sum(c["n_pessoas"] for c in strict_cards),
        "novos_cartoes_sob_proposta": len(proposed_cards), "pessoas_sob_proposta": sum(c["n_pessoas"] for c in proposed_cards),
        "grupos_ainda_nao_liberados": len(scope)-len(strict_cards)-len(proposed_cards), "fontes_inalteradas": True,
        "nota": "Proposta de identificacao do grupo proprio em cartao alternativo, nao equivalencia de codigos nem modificacao de respostas. Candidatos nao aplicados."},
        "grupos": summaries, "criterio_estrito": strict_cards, "sob_proposta_para_revisao": proposed_cards}
    with (out / "resultado.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    with (out / "grupos_proprios.jsonl").open("x", encoding="utf-8") as f:
        for line, proof in own_proofs.items():
            f.write(json.dumps({"linha": line, **proof}, ensure_ascii=False) + "\n")
    with (out / "alternativas.jsonl").open("x", encoding="utf-8") as f:
        for value in alternatives:
            f.write(json.dumps(value, ensure_ascii=False) + "\n")
    print(json.dumps(result["resumo"], ensure_ascii=False, indent=2), flush=True)
    return result


def audit(root, out, selected_uf=None):
    started = time.monotonic()
    root = root.resolve(); out = out.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida fora de tmp")
    out.mkdir(parents=True, exist_ok=False)
    metadata = json.loads((root / INDEX / "manifesto.json").read_text(encoding="utf-8"))
    source_hashes = {r["arquivo"]: r["sha256"] for r in metadata["fontes"]}
    for path, expected in source_hashes.items():
        if recovery.sha256(root / path) != expected:
            raise ValueError("Indice anterior desatualizado: " + path)
    guides = recovery.load_guides(root)
    pending = json.loads((root / PENDING).read_text(encoding="utf-8"))
    guards = json.loads((root / GUARDS).read_text(encoding="utf-8"))
    recovered = json.loads((root / RECOVERED).read_text(encoding="utf-8"))
    recovered_lines = {p["linha"] for card in recovered["cartoes"] for p in card["pessoas"]}
    remaining = [p for p in pending["vinculos_pendentes"] if p["linha"] not in recovered_lines]
    if len(remaining) != 1339 or len({(p["UF"], p["chave"]) for p in remaining}) != 526:
        raise ValueError("Inventario inicial nao reconcilia 1339/526")
    connection = sqlite3.connect((root / INDEX / "indice127.sqlite").as_uri() + "?mode=ro", uri=True)
    connection.row_factory = sqlite3.Row
    records = {}; scope = defaultdict(set); line_class = defaultdict(set)
    for p in remaining:
        line_class[p["linha"]].add("sem_cartao_confirmado")
    for conflict in guards["conflitos_diretos"]:
        line_class[conflict["pessoa"]["linha"]].add("conflito_municipal_direto")
    situation_conflicts = recovery.fetch(connection, """SELECT p.linha FROM pessoas p
        JOIN familias f ON p.familia_atual=f.linha
        WHERE p.excluida=0 AND p.situacao<>f.situacao""")
    for person in situation_conflicts:
        line_class[person["linha"]].add("conflito_situacao_direto")
    corrupt = []
    for line, classes in sorted(line_class.items()):
        found = recovery.fetch(connection, "SELECT * FROM pessoas WHERE linha=?", (line,))
        if not found:
            corrupt.append({"linha": line, "classes": sorted(classes), "classe": "registro_corrompido_sem_chave_utilizavel"})
            continue
        p = found[0]
        if selected_uf is not None and p["uf"] != selected_uf:
            continue
        key = (p["uf"], p["pasta"], p["boletim"])
        records[line] = p; scope[key].add(line)
    # A convivente exige conferir a relacao entre boletins, nao apenas pessoa-cartao.
    cohabit = guards["conviventes_sem_principal"][0]
    cohabit_lines = [cohabit[k]["linha"] for k in ("familia", "anterior")]
    cohabit_families = recovery.fetch(connection, "SELECT * FROM familias WHERE linha IN (?,?) ORDER BY linha", cohabit_lines)
    cohabit_keys = {(f["pasta"], f["boletim"]) for f in cohabit_families}
    empty_cards = recovery.fetch(connection, """SELECT f.* FROM familias f WHERE NOT EXISTS
        (SELECT 1 FROM pessoas p WHERE p.familia_atual=f.linha AND p.excluida=0)""")
    for family in empty_cards:
        key = (family["uf"], family["pasta"], family["boletim"])
        if selected_uf is None or key[0] == selected_uf:
            scope[key]
    recovery_previous = json.loads((root / INDEX / "resultado.json").read_text(encoding="utf-8"))
    previous = {tuple(r["chave"]): r for r in recovery_previous["grupos"]}
    summaries = []; candidates = []; witnesses = []; cohabit_result = None
    for uf in sorted({key[0] for key in scope if key[0] is not None}):
        print("UF", uf, flush=True)
        keys = {key[1:] for key in scope if key[0] == uf}
        has_source = uf in recovery.UF
        source_path = f"data/release_legacy/Censo.1960.amostra.25porcento.{recovery.UF[uf]}.gz" if has_source else None
        has_source = has_source and (root / source_path).is_file()
        if has_source:
            source_hashes[source_path] = recovery.sha256(root / source_path)
            f25, p25 = recovery.read_source(root, uf, keys | (cohabit_keys if uf == 60 else set()))
        else:
            f25, p25 = {}, {}
        for key in sorted((key for key in scope if key[0] == uf), key=str):
            k25 = key[1:]
            persons = recovery.fetch(connection, "SELECT * FROM pessoas WHERE uf IS ? AND pasta IS ? AND boletim IS ? AND excluida=0 ORDER BY linha", key)
            families = recovery.fetch(connection, "SELECT * FROM familias WHERE uf IS ? AND pasta IS ? AND boletim IS ? ORDER BY linha", key)
            families25 = f25.get(k25, []); persons25 = p25.get(k25, [])
            check = compare_group(families, persons, families25, persons25, guides)
            outside = []
            if len(families) == 1:
                linked = recovery.fetch(connection, "SELECT linha FROM pessoas WHERE familia_atual=? AND excluida=0", (families[0]["linha"],))
                outside = extra_linked_lines([p["linha"] for p in persons], [p["linha"] for p in linked])
                if outside:
                    check["motivos"].append("pessoas_de_outras_chaves_ja_vinculadas_ao_destino")
            check["outras_linhas_atribuidas_ao_destino"] = outside
            category = classify(check, has_source)
            missing_geo = []
            if len(families) == 1:
                family = families[0]
                for person in persons:
                    geo = {name: [person[name], family[name]] for name in ("uf", "municipio", "distrito", "situacao") if person[name] != family[name] or person[name] is None}
                    if geo:
                        missing_geo.append({"linha": person["linha"], "diferencas_pessoa_cartao": geo})
            item = {"chave": key, "linhas_escopo": sorted(scope[key]), "classe": category,
                    "classes_origem": sorted({c for line in scope[key] for c in line_class[line]}),
                    "linhas_cartoes127": [f["linha"] for f in families],
                    "linhas_cartoes25": [f["linha"] for f in families25],
                    "conferencia": check, "divergencias_geograficas_pessoais_preservadas": missing_geo,
                    "recuperacao_anterior": previous.get(key)}
            summaries.append(item)
            witnesses.append({"chave": key, "fonte25": source_path,
                "cartoes127": [public(f) for f in families], "pessoas127": [public(p) for p in persons],
                "cartoes25": families25, "pessoas25": persons25})
            if category == "vinculo_existente_comprovavel":
                family = families[0]
                byline25 = {p["linha"]: p for p in persons25}
                for match in check["correspondencias_pessoais"]:
                    line = match["linha127"]
                    if line not in scope[key]:
                        continue
                    person = records[line]
                    candidates.append({"linha": line, "linha_familia": family["linha"],
                        "texto_original": person["original"], "texto_corrigido": person["corrigido"],
                        "texto_familia_original": family["original"], "texto_familia_corrigido": family["corrigido"],
                        "fonte_25": source_path, "linha_familia_25": families25[0]["linha"],
                        "texto_familia_25": families25[0]["texto"],
                        "pessoas25_compativeis": [byline25[n] for n in match["linhas25_quesitos_exatos"]],
                        "classes_origem": sorted(line_class[line]),
                        "geografia_preservada": next((g for g in missing_geo if g["linha"] == line), None),
                        "justificativa": "Cartao127 unico, 15 campos e distrito iguais ao cartao25; composicao integral e multiplicidades pessoais exatas, estrutura25 conferida. Preservar respostas e geografia pessoal; nao afirmar identidade civil."})
        if uf == 60:
            parts = []
            for family in cohabit_families:
                key = (family["uf"], family["pasta"], family["boletim"])
                people = recovery.fetch(connection, "SELECT * FROM pessoas WHERE uf=? AND pasta=? AND boletim=? AND excluida=0 ORDER BY linha", key)
                check = compare_group([family], people, f25.get(key[1:], []), p25.get(key[1:], []), guides)
                parts.append({"cartao127": public(family), "pessoas127": [public(p) for p in people],
                              "cartoes25": f25.get(key[1:], []), "pessoas25": p25.get(key[1:], []), "conferencia": check})
            cohabit_result = {"grupos": parts, "aprovado": False,
                "motivo": "Cartao V101=5 sem familia principal comprovada. A proximidade, mesmo na fonte25, nao demonstra qual domicilio deve recebe-lo; comparar especie e composicao antes de qualquer reparo."}
    connection.close()
    if selected_uf is not None:
        corrupt = []
    covered = {line for r in summaries for line in r["linhas_escopo"]} | {r["linha"] for r in corrupt}
    expected = set(line_class) if selected_uf is None else set(records)
    if covered != expected:
        raise ValueError("Linhas perdidas na classificacao")
    for path, before in source_hashes.items():
        if recovery.sha256(root / path) != before:
            raise ValueError("Fonte alterada durante a auditoria: " + path)
    summary = {"pessoas_sem_cartao_inventario": 1339, "grupos_sem_cartao_inventario": 526,
               "conflitos_diretos_inventario": len(guards["conflitos_diretos"]),
               "conflitos_situacao_inventario": len(situation_conflicts),
               "cartoes_sem_pessoa_atual": [public(f) for f in empty_cards],
               "pessoas_auditadas": len(covered), "grupos_por_chave_sem_distrito": len(summaries),
               "corrompidas_com_registro_explicito": len(corrupt), "candidatos_vinculo": len(candidates),
               "candidatos_por_classe_origem": dict(Counter(c for p in candidates for c in p["classes_origem"])),
               "grupos_por_classe": dict(Counter(p["classe"] for p in summaries)),
               "pessoas_por_classe": dict(sum((Counter({p["classe"]: len(p["linhas_escopo"])}) for p in summaries), Counter())),
               "fontes_inalteradas": True, "segundos": round(time.monotonic()-started, 1),
               "nota": "Auditoria de evidencias; candidatos nao aplicados. Grupos por UF/pasta/boletim diferem de UF/chave completa. Nao soma listas sobrepostas e nao fecha incerteza apenas atribuindo uma categoria."}
    for filename, value in [("resultado.json", {"resumo": summary, "grupos": summaries, "corrompidas": corrupt, "convivente": cohabit_result}),
                            ("candidatos_vinculos.json", {"fontes": [{"arquivo": path, "sha256": value} for path, value in sorted(source_hashes.items())], "candidatos": candidates})]:
        with (out / filename).open("x", encoding="utf-8") as f:
            json.dump(value, f, ensure_ascii=False, indent=2)
    with (out / "evidencias_literais.jsonl").open("x", encoding="utf-8") as f:
        for value in witnesses:
            f.write(json.dumps(value, ensure_ascii=False) + "\n")
    print(json.dumps(summary, ensure_ascii=False, indent=2), flush=True)
    return summary


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--uf", type=int)
    parser.add_argument("--deep-base", type=Path)
    parser.add_argument("--existing-base", type=Path)
    parser.add_argument("--export-base", type=Path)
    parser.add_argument("--proposed", type=Path)
    parser.add_argument("--fixture-delivery", type=Path)
    parser.add_argument("--duplicate-decisions", type=Path, nargs="+")
    args = parser.parse_args()
    if args.fixture_delivery:
        fixture_links(Path(__file__).resolve().parents[1], args.out, args.fixture_delivery)
    elif args.export_base:
        if args.proposed is None or args.duplicate_decisions is None:
            parser.error("export-base exige proposed e duplicate-decisions")
        export_proposals(Path(__file__).resolve().parents[1], args.out, args.export_base, args.proposed, args.duplicate_decisions)
    elif args.existing_base:
        if args.duplicate_decisions is None:
            parser.error("existing-base exige duplicate-decisions")
        existing_proposals(Path(__file__).resolve().parents[1], args.out, args.existing_base, args.duplicate_decisions, args.uf)
    elif args.deep_base:
        if args.duplicate_decisions is None:
            parser.error("deep-base exige duplicate-decisions")
        deep_audit(Path(__file__).resolve().parents[1], args.out, args.deep_base, args.duplicate_decisions, args.uf)
    else:
        audit(Path(__file__).resolve().parents[1], args.out, args.uf)
