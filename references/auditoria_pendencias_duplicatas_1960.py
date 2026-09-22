"""Confronta todos os perfis repetidos pendentes com grupos integrais da fonte25.

Nao altera manifestos ou microdados. Igualdade de respostas nao prova identidade.
Uso inicial: --uf pb --limit 3 --out tmp/.../piloto_01; depois sem filtros.
"""
import argparse
from collections import Counter, defaultdict
import csv
import json
from pathlib import Path
import time

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, UF, integer, load_guides, memory_guard,
    parse_profile, raw_records, read_source, rows, sha256, source_structure,
)


INVENTORY = "tmp/execucao_1960_20260922/integridade_127_pendencias_final.json"


def reconcile_counts(observed, source, pending_counts):
    reasons = []
    if set(observed) != set(source):
        reasons.append("perfis_integrantes_do_grupo_divergem")
    for profile, count in observed.items():
        expected = source[profile]
        if profile in pending_counts:
            if count != pending_counts[profile]:
                reasons.append("mesmo_perfil_fora_do_conjunto_repetido")
            if not 1 <= expected <= count:
                reasons.append("multiplicidade25_fora_dos_limites127")
        elif count != expected:
            reasons.append("quantidade_de_outro_perfil_diverge")
    return sorted(set(reasons))


def evaluate_context(key, families127, people127, families25, people25, pending, guides,
                     match_without_v216=False, allow_family_attribute_differences=False):
    reasons = []
    if len(families127) != 1:
        reasons.append("cartao127_ausente_ou_nao_unico")
    if len(families25) != 1:
        return sorted(set(reasons + ["cartao25_ausente_ou_nao_unico"])), {}
    family25 = families25[0]
    if (integer(family25["texto"][:5]), integer(family25["texto"][5:8])) != key[1:]:
        reasons.append("chave_cartao25_diverge")
    reasons.extend(source_structure(family25, people25))
    family_profile25, invalid = parse_profile(family25["texto"], guides[("25", "familias")], FAMILY_NAMES)
    if invalid:
        reasons.append("cartao25_codigo_invalido")
    geo25 = (integer(family25["texto"][29:33]), integer(family25["texto"][33:35]), integer(family25["texto"][35:36]))
    if None in geo25:
        reasons.append("geografia25_ausente")
    if len(families127) == 1:
        family127 = families127[0]
        text127 = family127["corrigido"]
        if (integer(text127[:2]), integer(text127[8:13]), integer(text127[13:16])) != key:
            reasons.append("chave_cartao127_diverge")
        profile, invalid = parse_profile(family127["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
        same_family = profile == family_profile25
        if allow_family_attribute_differences:
            same_family = all(a == b for name, a, b in zip(FAMILY_NAMES, profile, family_profile25)
                              if name in {"V101", "V116", "V118"})
        if not same_family or invalid:
            reasons.append("corpo_cartao127_25_diverge_ou_invalido")
        if integer(family127["corrigido"][6:8]) != geo25[1]:
            reasons.append("distrito_cartao127_25_diverge")
    profiles127 = {}; profiles25 = {}
    for row in people127:
        text = row["corrigido"]
        profile, invalid = parse_profile(text, guides[("127", "pessoas")], PERSON_NAMES)
        profiles127[row["linha"]] = profile
        if invalid:
            reasons.append("pessoa127_codigo_invalido")
        if (integer(text[:2]), integer(text[8:13]), integer(text[13:16])) != key:
            reasons.append("pessoa127_de_outra_chave")
        if (integer(text[2:6]), integer(text[6:8]), integer(text[17])) != geo25:
            reasons.append("geografia_pessoal127_diverge")
    for row in people25:
        if (integer(row["texto"][:5]), integer(row["texto"][5:8])) != key[1:]:
            reasons.append("chave_pessoa25_diverge")
        profile, invalid = parse_profile(row["texto"], guides[("25", "pessoas")], PERSON_NAMES)
        profiles25[row["linha"]] = profile
        if invalid:
            reasons.append("pessoa25_codigo_invalido")
    full_profiles127 = dict(profiles127)
    if match_without_v216:
        position = PERSON_NAMES.index("V216")
        projected = [{}, {}]
        members = [defaultdict(set), defaultdict(set)]
        for index, profiles in enumerate((profiles127, profiles25)):
            for line, profile in profiles.items():
                key24 = profile[:position] + (None,) + profile[position + 1:]
                projected[index][line] = key24
                members[index][key24].add(profile)
        if any(len(variants) > 1 for group in members for variants in group.values()):
            reasons.append("projecao24_funde_perfis_distintos")
        for key24 in members[0].keys() & members[1].keys():
            a = members[0][key24]; b = members[1][key24]
            if len(a) == len(b) == 1:
                value127 = next(iter(a))[position]; value25 = next(iter(b))[position]
                if value127 != value25 and {value127, value25} != {0, 63}:
                    reasons.append("divergencia_V216_fora_par_00_63")
        profiles127, profiles25 = projected
    pending_counts = {}
    for group in pending:
        group_rows = [r for r in people127 if r["linha"] in group["linhas"]]
        if len(group_rows) != len(group["linhas"]):
            reasons.append("linha_do_conjunto_ausente_no_contexto")
            continue
        if len({r["corrigido"] for r in group_rows}) != 1:
            reasons.append("conjunto127_difere_no_texto_integral")
        profile = profiles127[group["linhas"][0]]
        if profile in pending_counts:
            reasons.append("perfil_compartilhado_por_conjuntos_distintos")
        pending_counts[profile] = len(group_rows)
    a = Counter(profiles127.values()); b = Counter(profiles25.values())
    reasons.extend(reconcile_counts(a, b, pending_counts))
    counts = {min(group["linhas"]): {
        "n25": b[profiles127[group["linhas"][0]]],
        "linhas25": [line for line, profile in profiles25.items() if profile == profiles127[group["linhas"][0]]],
        "perfil": dict(zip(PERSON_NAMES, full_profiles127[group["linhas"][0]])),
    } for group in pending if group["linhas"][0] in profiles127}
    return sorted(set(reasons)), counts


def projected_audit(root, out, previous, family_attributes=False):
    """Correspondencia de 24 campos nao declara 00 e63 semanticamente iguais."""
    root = root.resolve(); out = out.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida deve ficar em tmp do projeto")
    out.mkdir(parents=True, exist_ok=False)
    data = json.loads(previous.read_text(encoding="utf-8")); guides = load_guides(root)
    for source in data["fontes"]:
        if sha256(root / source["arquivo"]) != source["sha256"]:
            raise ValueError("Fonte alterada depois da auditoria integral")
    groups_by_context = defaultdict(list)
    for group in data["grupos"]:
        if group.get("contexto"):
            groups_by_context[group["contexto"]].append(group)
    results = []; proposals = []; matching = []
    for context in data["contextos"]:
        groups = groups_by_context[context["id"]]
        pending = [{"linhas": g["linhas127"]} for g in groups]
        key = tuple(context["chave"])
        if not context["fonte25"]:
            reasons = ["fonte25_nao_disponivel"]; counts = {}
        else:
            reasons, counts = evaluate_context(key, context["familias127"],
                context["pessoas127_apos_decisoes_anteriores"], context["familias25"],
                context["pessoas25"], pending, guides, match_without_v216=True)
            if family_attributes:
                if not reasons:
                    continue
                reasons, counts = evaluate_context(key, context["familias127"],
                    context["pessoas127_apos_decisoes_anteriores"], context["familias25"],
                    context["pessoas25"], pending, guides, match_without_v216=True,
                    allow_family_attribute_differences=True)
        family_differences = []
        counter127 = Counter(parse_profile(r["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0]
                             for r in context["pessoas127_apos_decisoes_anteriores"])
        counter25 = Counter(parse_profile(r["texto"], guides[("25", "pessoas")], PERSON_NAMES)[0]
                            for r in context["pessoas25"])
        exact_people = sum((counter127 & counter25).values())
        if len(context["familias127"]) == len(context["familias25"]) == 1:
            f127, _ = parse_profile(context["familias127"][0]["corrigido"], guides[("127", "familias")], FAMILY_NAMES)
            f25, _ = parse_profile(context["familias25"][0]["texto"], guides[("25", "familias")], FAMILY_NAMES)
            family_differences = [{"campo": name, "valor127": a, "valor25": b}
                                  for name, a, b in zip(FAMILY_NAMES, f127, f25) if a != b]
        for group in groups:
            if group["aprovavel"]:
                continue
            lines = group["linhas127"]; info = counts.get(min(lines), {})
            result = {"id": group["id"], "chave": group["chave"], "linhas127": lines,
                "n_apos_regra_antiga": group["n_apos_regra_antiga"], "n127": len(lines),
                "n25_por_24_campos": info.get("n25"), "linhas25": info.get("linhas25", []),
                "linhas_excluidas_antigamente": group["linhas_excluidas_antigamente"],
                "motivos": reasons, "proposta_condicional": not reasons,
                "divergencias_cartao_preservadas": family_differences,
                "testemunhas_pessoais_exatas_25campos": exact_people,
                "pessoas25_que_exigem_projecao24": len(context["pessoas25"]) - exact_people,
                "total_pessoas25_no_grupo": len(context["pessoas25"]),
                "nota": "Correspondencia de grupo com24campos; preserva divergencia V21600/63. Nao aprova equivalencia de codigos nem altera respostas."}
            results.append(result)
            if reasons:
                continue
            source_people = context["pessoas25"]
            group_people = context["pessoas127_apos_decisoes_anteriores"]
            mapping = []
            for person in group_people:
                profile, _ = parse_profile(person["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)
                candidates = []
                for source in source_people:
                    source_profile, _ = parse_profile(source["texto"], guides[("25", "pessoas")], PERSON_NAMES)
                    if all(a == b for name, a, b in zip(PERSON_NAMES, profile, source_profile) if name != "V216"):
                        candidates.append({"linha": source["linha"], "V216": source_profile[PERSON_NAMES.index("V216")],
                                           "igual_em_todos_25_campos": source_profile == profile})
                mapping.append({"linha127": person["linha"], "V216_127": profile[PERSON_NAMES.index("V216")], "candidatos25": candidates})
            matching.append({"grupo": group["id"], "contexto": context["id"], "mapeamento_integral": mapping})
            for index, line in enumerate(sorted(lines)):
                record = next(r for r in group_people if r["linha"] == line)
                proposals.append({"grupo": group["id"], "linha": line,
                    "acao": "manter" if index < info["n25"] else "remover", "n_antes": len(lines), "n_manter": info["n25"],
                    "texto_original": record["original"], "texto_corrigido": record["corrigido"],
                    "fonte_25": context["fonte25"], "linhas_25": ";".join(map(str, info["linhas25"])),
                    "justificativa": "PROPOSTA SOB REVISAO: grupo integral conciliado por24campos, chaves/especie/geografia/contagens/ordens exatos. Diferenca V21600/63 preservada, nao recodificada. Perfis projetados sem fusao de variantes; quantidade25 documentada. " +
                        ("Divergencias de atributos domiciliares preservadas no relatorio." if family_attributes else "Corpo do cartao tambem identico.")})
    approved = [r for r in results if r["proposta_condicional"]]
    old = {line for g in data["grupos"] for line in g["linhas_excluidas_antigamente"]}
    summary = {"grupos_reexaminados": len(results), "propostas_condicionais": len(approved),
        "linhas_propostas": len(proposals), "remocoes_propostas": sum(r["acao"] == "remover" for r in proposals),
        "restauracoes_propostas": sum(r["acao"] == "manter" and r["linha"] in old for r in proposals),
        "exclusoes_antigas_no_escopo_proposto": sum(len(g["linhas_excluidas_antigamente"]) for g in approved),
        "motivos_sobrepostos": dict(Counter(reason for r in results for reason in r["motivos"])),
        "nao_e_equivalencia_00_63": True, "nao_e_aprovacao_automatica": True,
        "atributos_domiciliares_divergentes_preservados": family_attributes}
    for source in data["fontes"]:
        if sha256(root / source["arquivo"]) != source["sha256"]:
            raise ValueError("Fonte alterada durante segunda auditoria")
    result = {"resumo": summary, "auditoria_base": str(previous.relative_to(root)),
        "auditoria_base_sha256": sha256(previous), "fontes": data["fontes"], "grupos": results, "mapeamentos": matching}
    result["script_sha256"] = sha256(Path(__file__))
    with (out / "projecao24.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    if proposals:
        with (out / "propostas_condicionais.csv").open("x", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=list(proposals[0]), quoting=csv.QUOTE_ALL)
            writer.writeheader(); writer.writerows(proposals)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return result


def residual_inventory(root, out, base_folder):
    root = root.resolve(); out = out.resolve(); base_folder = base_folder.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida deve ficar em tmp do projeto")
    out.mkdir(parents=True, exist_ok=False)
    inputs = [base_folder / "completa_01/resultado.json", base_folder / "projecao_completa_03/projecao24.json",
              base_folder / "atributos_completa_02/projecao24.json"]
    strict, projected, attributes = [json.loads(path.read_text(encoding="utf-8")) for path in inputs]
    decided = {g["id"] for g in strict["grupos"] if g["aprovavel"]}
    decided.update(g["id"] for data in (projected, attributes) for g in data["grupos"] if g["proposta_condicional"])
    final = {g["id"]: g for g in attributes["grupos"]}
    contexts = {c["id"]: c for c in strict["contextos"]}
    records = []; totals = defaultdict(lambda: {"grupos": 0, "linhas": 0, "exclusoes_antigas_sem_prova": 0})
    for group in strict["grupos"]:
        if group["id"] in decided:
            continue
        evidence = final.get(group["id"], group)
        reasons = evidence["motivos"]
        if "linhas_corrompidas_sem_perfil_legivel" in reasons:
            category = "texto_corrompido"
        elif "fonte25_nao_disponivel" in reasons:
            category = "fonte25_indisponivel"
        elif "cartao25_ausente_ou_nao_unico" in reasons:
            category = "cartao25_ausente_ou_nao_unico"
        elif any(r in reasons for r in ("distrito_cartao127_25_diverge", "geografia_pessoal127_diverge")):
            category = "geografia_ou_distrito_divergente"
        elif "corpo_cartao127_25_diverge_ou_invalido" in reasons:
            category = "especie_ou_geografia_do_cartao_diverge"
        elif "divergencia_V216_fora_par_00_63" in reasons:
            category = "ano_casamento_divergencia_adicional"
        elif evidence.get("n25_por_24_campos") == 0:
            category = "perfil_repetido_sem_correspondencia24_no_boletim25"
        elif evidence.get("n25_por_24_campos", 0) > group["n127"]:
            category = "mais_ocorrencias25_que_linhas127"
        else:
            category = "composicao_de_outros_integrantes_diverge"
        context = contexts.get(group.get("contexto"))
        literal = [r for r in context["pessoas127_apos_decisoes_anteriores"] if r["linha"] in group["linhas127"]] if context else group["registros"]
        item = {"id": group["id"], "chave": group.get("chave"), "linhas127": group["linhas127"],
            "n127": group["n127"], "exclusoes_antigas_sem_prova": group["linhas_excluidas_antigamente"],
            "razao_principal": category, "motivos_completos": reasons,
            "n25_por24campos": evidence.get("n25_por_24_campos"),
            "linhas25_por24campos": evidence.get("linhas25", []), "registros127": literal,
            "prova_interna_deterministica_identificada": False,
            "limite": "HHOLDA nao fornece ordinal pessoal nem total declarado de pessoas no cartao; IDarquivo e compartilhado. Igualdade, posicao na cauda e papel familiar nao demonstram quantas pessoas reais existiam."}
        records.append(item)
        totals[category]["grupos"] += 1; totals[category]["linhas"] += group["n127"]
        totals[category]["exclusoes_antigas_sem_prova"] += len(group["linhas_excluidas_antigamente"])
    assert (len(records), sum(r["n127"] for r in records), sum(len(r["exclusoes_antigas_sem_prova"]) for r in records)) == (463, 928, 127)
    result = {"resumo": {"grupos": 463, "linhas": 928, "exclusoes_antigas_sem_prova": 127,
              "razoes_mutuamente_exclusivas": dict(totals)}, "grupos": records,
              "hierarquia_razao_principal": "texto;fonte;cartao25;geografia;especie;V216;perfil_ausente;fonte_mais_numerosa;outros_integrantes",
              "limites": ["Os motivos completos podem se sobrepor; razao principal conta cada grupo uma unica vez.",
                           "Nenhuma prova interna deterministica encontrada. Nao e afirmacao de impossibilidade de pesquisa futura.",
                           "Uma correspondencia fora da chave ou fonte adicional poderia esclarecer certos casos; nao foi imposta nenhuma mudanca.",
                           "Inventario residual apos tres classes propostas, ainda sujeito a homologacao pela integracao."],
              "fontes": [{"arquivo": str(p.relative_to(root)), "sha256": sha256(p)} for p in inputs]}
    with (out / "residuais463.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    print(json.dumps(result["resumo"], ensure_ascii=False, indent=2))
    return result


def audit(root, out, selected_uf=None, limit=None):
    start = time.perf_counter(); memory_guard(3)
    root = root.resolve(); out = out.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida deve ficar em tmp do projeto")
    out.mkdir(parents=True, exist_ok=False)
    inventory_path = root / INVENTORY
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    tracked = {r["arquivo"].replace("\\", "/"): r["sha256"] for r in inventory["fontes"]}
    for path, digest in tracked.items():
        if sha256(root / path) != digest:
            raise ValueError(f"Inventario de pendencias desatualizado: {path}")
    guides = load_guides(root)
    for sample in ("127", "25"):
        for kind in ("familias", "pessoas"):
            name = f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv"
            tracked[name] = sha256(root / name)
    tracked[INVENTORY] = sha256(inventory_path)
    raw_path = root / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    corrections = {int(r["linha"]): r for r in rows(root / "read_guides/1960_amostra_127_correcoes.csv")}
    decisions = {int(r["linha"]): r for r in rows(root / "read_guides/1960_amostra_127_duplicatas.csv")}
    links = {int(r["linha"]): r for r in rows(root / "read_guides/1960_amostra_127_vinculos.csv")}
    historical_path = "data_raw/microdata/1960/amostra_127/duplicatas_removidas.csv"
    old_removed = {int(r["linha"]) for r in rows(root / historical_path)}
    tracked[historical_path] = sha256(root / historical_path)
    pending = inventory["duplicatas_pendentes"]
    target_lines = {line for group in pending for line in group["linhas"]}
    literals = {}
    with raw_path.open(encoding="latin1") as source:
        for line, text in enumerate(source, 1):
            if line in target_lines:
                original = text.rstrip("\r\n"); correction = corrections.get(line, {})
                literals[line] = {"linha": line, "original": original,
                    "corrigido": correction.get("texto_corrigido") or original,
                    "corrompida": correction.get("decisao") == "corrompida"}
    if set(literals) != target_lines:
        raise ValueError("Inventario contem linha ausente")
    by_key = defaultdict(list)
    corrupt = []
    for group in pending:
        first = literals[group["linhas"][0]]["corrigido"]
        key = (integer(first[:2]), integer(first[8:13]), integer(first[13:16]))
        if selected_uf and UF.get(key[0]) != selected_uf:
            continue
        if any(literals[n]["corrompida"] for n in group["linhas"]):
            corrupt.append(group)
        else:
            by_key[key].append(group)
    if limit:
        selected = []
        for key, groups in by_key.items():
            if len(selected) >= limit:
                break
            selected.extend(groups)
        selected_ids = {min(g["linhas"]) for g in selected}
        by_key = {key: [g for g in groups if min(g["linhas"]) in selected_ids]
                  for key, groups in by_key.items() if any(min(g["linhas"]) in selected_ids for g in groups)}
        corrupt = []
    families127 = defaultdict(list); people127 = defaultdict(list)
    relevant_lines = set()
    for line, original, text in raw_records(root, corrections):
        key = (integer(text[:2]), integer(text[8:13]), integer(text[13:16]))
        if key in by_key and text[16] == "1":
            families127[key].append({"linha": line, "original": original, "corrigido": text})
            relevant_lines.add(line)
    incoming_links = {line: int(r["linha_familia"]) for line, r in links.items()
                      if int(r["linha_familia"]) in relevant_lines}
    family_key_by_line = {r["linha"]: key for key, records in families127.items() for r in records}
    for line, original, text in raw_records(root, corrections):
        if text[16] == "1" or decisions.get(line, {}).get("acao") == "remover":
            continue
        key = (integer(text[:2]), integer(text[8:13]), integer(text[13:16]))
        if key in by_key:
            people127[key].append({"linha": line, "original": original, "corrigido": text})
        if line in incoming_links:
            resolved_key = family_key_by_line[incoming_links[line]]
            if resolved_key != key:
                people127[resolved_key].append({"linha": line, "original": original, "corrigido": text})
    results = []; candidates = []; contexts = []
    for uf in sorted({key[0] for key in by_key}):
        keys = [key for key in by_key if key[0] == uf]
        if uf in UF:
            source_path = f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz"
            tracked[source_path] = sha256(root / source_path)
            f25, p25 = read_source(root, uf, {key[1:] for key in keys})
        else:
            source_path = None; f25 = {}; p25 = {}
        print("UF", uf, "grupos", sum(len(by_key[k]) for k in keys), flush=True)
        for key in keys:
            fs = f25.get(key[1:], []); ps = p25.get(key[1:], [])
            reasons, counts = evaluate_context(key, families127[key], people127[key], fs, ps, by_key[key], guides)
            if source_path is None:
                reasons = ["fonte25_nao_disponivel"]
            context_id = "-".join(str(x) for x in key)
            contexts.append({"id": context_id, "chave": key, "motivos": reasons,
                "familias127": families127[key], "pessoas127_apos_decisoes_anteriores": people127[key],
                "familias25": fs, "pessoas25": ps, "fonte25": source_path})
            for group in by_key[key]:
                lines = group["linhas"]; n25 = counts.get(min(lines), {}).get("n25")
                detail = {"id": f"{context_id}-linha{min(lines)}", "contexto": context_id,
                    "chave": key, "linhas127": lines, "n127": len(lines),
                    "linhas_excluidas_antigamente": sorted(set(lines) & old_removed),
                    "n_apos_regra_antiga": len(set(lines) - old_removed),
                    "n25": n25, "motivos": reasons,
                    "aprovavel": not reasons, "linhas25": counts.get(min(lines), {}).get("linhas25", []),
                    "perfil": counts.get(min(lines), {}).get("perfil")}
                detail["status"] = ("manter_multiplicidade_comprovada" if n25 == len(lines) else "reduzir_multiplicidade_comprovada") if not reasons else "indeterminado"
                results.append(detail)
                if reasons:
                    continue
                for i, line in enumerate(sorted(lines)):
                    candidates.append({"grupo": detail["id"], "linha": line,
                        "acao": "manter" if i < n25 else "remover", "n_antes": len(lines), "n_manter": n25,
                        "texto_original": literals[line]["original"], "texto_corrigido": literals[line]["corrigido"],
                        "fonte_25": source_path, "linhas_25": ";".join(map(str, detail["linhas25"])),
                        "justificativa": "Composicao familiar integral conciliada com gzip25; cartao/geografia/campos/ordens/contagens conferidos. Mesmos textos integrais127; multiplicidade25 preservada, sem identidade civil individual."})
    for group in corrupt:
        results.append({"id": f"corrompida-linha{min(group['linhas'])}", "linhas127": group["linhas"],
            "n127": len(group["linhas"]), "n25": None, "status": "indeterminado", "aprovavel": False,
            "motivos": ["linhas_corrompidas_sem_perfil_legivel"],
            "linhas_excluidas_antigamente": sorted(set(group["linhas"]) & old_removed),
            "registros": [literals[n] for n in group["linhas"]]})
    for name, digest in tracked.items():
        if sha256(root / name) != digest:
            raise ValueError(f"Fonte mudou durante auditoria: {name}")
    approved = [r for r in results if r["aprovavel"]]
    summary = {"grupos_examinados": len(results), "linhas_examinadas": sum(r["n127"] for r in results),
        "grupos_aprovaveis": len(approved), "linhas_aprovaveis": sum(r["n127"] for r in approved),
        "grupos_indeterminados": len(results) - len(approved), "status": dict(Counter(r["status"] for r in results)),
        "remocoes_candidatas": sum(r["acao"] == "remover" for r in candidates),
        "restauracoes_contra_regra_antiga": sum(r["acao"] == "manter" and r["linha"] in old_removed for r in candidates),
        "linhas_excluidas_antigamente_ainda_indeterminadas": sum(len(r["linhas_excluidas_antigamente"]) for r in results if not r["aprovavel"]),
        "motivos_sobrepostos": dict(Counter(reason for r in results for reason in r["motivos"])),
        "fontes_inalteradas": True, "segundos": round(time.perf_counter() - start, 2),
        "nota": "Auditoria e candidatos apenas; nao altera manifestos, microdados ou pesos. Indeterminacao nao equivale a duplicacao comprovada nem a multiplicidade confirmada."}
    if not selected_uf and not limit and (len(results), sum(r["n127"] for r in results)) != (1417, 2836):
        raise ValueError("Cobertura diverge do inventario integral")
    result = {"resumo": summary, "fontes": [{"arquivo": n, "sha256": h} for n, h in tracked.items()],
        "grupos": results, "contextos": contexts}
    result["script_sha256"] = sha256(Path(__file__))
    with (out / "resultado.json").open("x", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)
    if candidates:
        with (out / "decisoes_candidatas.csv").open("x", encoding="utf-8", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=list(candidates[0]), quoting=csv.QUOTE_ALL)
            writer.writeheader(); writer.writerows(candidates)
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--uf", choices=sorted(UF.values()))
    parser.add_argument("--limit", type=int)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--projection-from", type=Path)
    parser.add_argument("--household-attributes", action="store_true")
    parser.add_argument("--residual-from", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    if args.residual_from:
        residual_inventory(root, args.out, args.residual_from)
    elif args.projection_from:
        projected_audit(root, args.out, args.projection_from.resolve(), args.household_attributes)
    else:
        audit(root, args.out, args.uf, args.limit)
