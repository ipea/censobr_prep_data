"""Recuperacao candidata de cartoes25: evidencia literal, sem R ou novos microdados.

Primeiro: --uf mg --pasta 40090 --boletim 4 --out tmp/.../auditoria_piloto_01
Sem filtros: examina todas as pessoas ainda sem cartao apos decisoes aprovadas.
Saidas exclusivas; SQLite local limita RAM. O manifesto nunca fabrica linha127.
"""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path
import sqlite3
import time

import psutil

UF = {25: "al", 31: "ba", 14: "ce", 97: "df", 24: "fn", 94: "go", 40: "mg", 91: "mt",
      19: "pb", 21: "pe", 71: "pr", 52: "rj", 17: "rn", 81: "rs", 50: "sa", 30: "se", 60: "sp"}
PERSON_NAMES = ["V202", "V203", "V204", "AGE", "V205", "V206", "V207", "V208", "V209", "V299",
                "V210", "V211", "V212", "V213", "V214", "V215", "V216", "V217", "V218", "V219",
                "V220", "V221", "V223", "V223B", "V224"]
FAMILY_NAMES = [f"V{n}" for n in range(101, 114)] + ["V116", "V118"]
FIXED_SOURCES = ["data_raw/microdata/1960/amostra_127/HHOLDA.txt",
                 "read_guides/1960_amostra_127_correcoes.csv",
                 "read_guides/1960_amostra_127_duplicatas.csv", "read_guides/1960_amostra_127_vinculos.csv"]
FIXED_SOURCES += [f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv"
                  for sample in ("127", "25") for kind in ("familias", "pessoas")]


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def integer(text):
    return int(text) if text is not None and str(text).strip().isdigit() else None


def memory_guard(minimum=2):
    available = psutil.virtual_memory().available
    if available < minimum * 1024 ** 3:
        raise MemoryError(f"RAM disponivel inferior a {minimum} GiB: {available}")
    return available


def sha256(path):
    result = hashlib.sha256()
    with path.open("rb") as f:
        while block := f.read(4 * 1024 ** 2):
            memory_guard()
            result.update(block)
    return result.hexdigest()


def load_guides(root):
    return {(sample, kind): {r["variavel"]: (int(r["inicio"]) - 1, int(r["fim"]),
                set(r["valores_validos"].split(";")) - {"", "NA"})
                for r in rows(root / f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv")}
            for sample in ("127", "25") for kind in ("familias", "pessoas")}


def parse_profile(text, guide, names):
    values = []; invalid = []
    for name in names:
        start, end, valid = guide[name]
        raw = text[start:end]
        # HHOLDA documenta salto nas posicoes20/21/33/36/47, com toda a cauda em branco.
        skip = len(text) == 62 and start in {19, 20, 32, 35, 46} and raw.startswith("-") and not text[start + 1:54].strip()
        missing = not raw.strip() or skip
        ok = raw in valid if valid else integer(raw) is not None
        if len(raw) != end - start or (not missing and not ok):
            invalid.append(name)
        values.append(None if missing or not ok else integer(raw))
    return tuple(values), invalid


def profile_hash(profile):
    return hashlib.sha256(json.dumps(profile, separators=(",", ":")).encode()).digest()


def normalized_family(text, guides):
    values, invalid = parse_profile(text, guides[("25", "familias")], FAMILY_NAMES)
    if invalid:
        raise ValueError(f"Campos familiares invalidos: {invalid}")
    result = {}
    for name, value in zip(FAMILY_NAMES, values):
        start, end, _ = guides[("127", "familias")][name]
        converted = None if value is None else str(value).zfill(end - start)
        if converted is not None and len(converted) != end - start:
            raise ValueError(f"Campo nao cabe no layout127: {name}")
        result[name] = converted
    return result


def source_structure(family, people):
    reasons = []
    if len(family["texto"]) != 54 or any(len(r["texto"]) != 54 for r in people):
        reasons.append("comprimento25_invalido")
    if integer(family["texto"][11:13]) != len(people):
        reasons.append("v100_diverge_contagem25")
    if sorted(integer(r["texto"][8:10]) or -1 for r in people) != list(range(1, len(people) + 1)):
        reasons.append("ordens25_incompletas_ou_repetidas")
    if [r["linha"] for r in people] != list(range(family["linha"] + 1, family["linha"] + len(people) + 1)):
        reasons.append("pessoas25_nao_contiguas_ao_cartao")
    if any(t[8:11] != t[11:14] or t[23] != t[24] or t[51:54] != "000"
           for t in (r["texto"] for r in people)):
        reasons.append("redundancias25_divergentes")
    if family["texto"][8:10] != "00" or family["texto"][36:54] != "0" * 18:
        reasons.append("estrutura_cartao25_invalida")
    return reasons


def evaluate_group(key, families25, people25, people127, guides, pending_duplicates=frozenset()):
    reasons = []
    if any(value is None for value in key):
        return ["chave127_invalida"], None
    if not families25:
        return ["cartao25_ausente"], None
    if len(families25) != 1:
        return ["cartao25_nao_unico"], None
    family = families25[0]; text = family["texto"]
    reasons.extend(source_structure(family, people25))
    if text[13:14] not in {"1", "3"}:
        reasons.append("especie_fora_escopo_1_3")
    fprofile, invalid = parse_profile(text, guides[("25", "familias")], FAMILY_NAMES)
    if invalid:
        reasons.append("cartao25_codigo_invalido")
    p127 = [parse_profile(r["corrigido"], guides[("127", "pessoas")], PERSON_NAMES) for r in people127]
    p25 = [parse_profile(r["texto"], guides[("25", "pessoas")], PERSON_NAMES) for r in people25]
    if any(bad for _, bad in p127):
        reasons.append("pessoa127_codigo_invalido")
    if any(bad for _, bad in p25):
        reasons.append("pessoa25_codigo_invalido")
    a = Counter(p for p, _ in p127); b = Counter(p for p, _ in p25)
    if not people127 or a != b:
        reasons.append("composicao_integral_diverge")
    if any(n != 1 for n in a.values()):
        reasons.append("perfil127_nao_unico")
    if any(n != 1 for n in b.values()):
        reasons.append("perfil25_nao_unico")
    if any(r.get("familia_atual") is not None for r in people127):
        reasons.append("pessoa_ja_vinculada")
    if any(r["linha"] in pending_duplicates for r in people127):
        reasons.append("duplicata_sem_decisao")
    for row in people127:
        t = row["corrigido"]
        if len(t) != 62 or t[16] not in "23" or t[54] != "\\" or not t[55:62].isdigit():
            reasons.append("estrutura127_invalida")
        if (integer(t[:2]), integer(t[8:13]), integer(t[13:16])) != key:
            reasons.append("chave_pessoal127_diverge")
        if (integer(t[2:6]), integer(t[6:8]), integer(t[17:18])) != (
                integer(text[29:33]), integer(text[33:35]), integer(text[35:36])) or any(
                integer(x) is None for x in (t[2:6], t[6:8], t[17:18])):
            reasons.append("geografia_pessoal_diverge_ou_ausente")
    if any((integer(r["texto"][:5]), integer(r["texto"][5:8])) != key[1:] for r in people25):
        reasons.append("chave_pessoal25_diverge")
    if (integer(text[:5]), integer(text[5:8])) != key[1:]:
        reasons.append("chave_cartao25_diverge")
    if any(integer(x) is None for x in (text[29:33], text[33:35], text[35:36])):
        reasons.append("geografia_cartao25_ausente")
    if reasons:
        return sorted(set(reasons)), None
    matching = {p: row for (p, _), row in zip(p25, people25)}
    persons = []
    for (profile, _), row in zip(p127, people127):
        source = matching[profile]
        persons.append({"linha": row["linha"], "texto_original": row["original"],
                        "texto_corrigido": row["corrigido"], "linha_25": source["linha"],
                        "texto_25": source["texto"]})
    return [], {"id_recuperacao": f"{key[0]:02d}-{key[1]:05d}-{key[2]:03d}",
        "UF": f"{key[0]:02d}", "distrito": text[33:35], "pasta": text[:5], "boletim": text[5:8],
        "V116": text[29:33], "V118": text[35:36], "linha_25": family["linha"],
        "arquivo_25": f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[key[0]]}.gz",
        "texto_25": text, "n_pessoas": len(persons), "familias": normalized_family(text, guides),
        "pessoas": persons,
        "unidade": "boletim_coletivo" if text[13] == "3" else "boletim_particular",
        "ressalvas": ["Correspondencia de registros nao e identificacao civil.",
                      "Cartao nao encontrado pelas chaves e buscas documentadas; nao e prova de inexistencia absoluta."] +
                     (["Boletim coletivo nao demonstra edificio fisicamente distinto."] if text[13] == "3" else [])}


def alternative_reasons(same_geo, same_body, strong_key, direct, physical, target, own_confirmed=False,
                        same_species=True):
    reasons = []
    if direct == target and target:
        reasons.append("composicao_ligada_integral")
    if physical == target and target:
        reasons.append("composicao_fisica_integral")
    if same_geo and (same_body or (strong_key and same_species)) and not own_confirmed:
        reasons.append("cartao_compativel_sem_grupo_proprio")
    return reasons


def raw_records(root, corrections):
    with (root / FIXED_SOURCES[0]).open(encoding="latin1") as f:
        for line, original in enumerate(f, 1):
            original = original.rstrip("\r\n")
            if len(original) != 62:
                raise ValueError(f"HHOLDA comprimento inesperado: {line}")
            correction = corrections.get(line, {})
            if correction and correction["texto_original"] != original:
                raise ValueError(f"Correcao nao confere: {line}")
            if correction.get("decisao") in {"cartao_uf", "corrompida"}:
                continue
            yield line, original, correction.get("texto_corrigido") or original


def build_index(root, path, guides):
    connection = sqlite3.connect(path)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA cache_size=-16384")
    connection.execute("PRAGMA temp_store=FILE")
    connection.executescript("""
      CREATE TABLE familias(linha INTEGER PRIMARY KEY,uf INTEGER,pasta INTEGER,boletim INTEGER,
        distrito INTEGER,municipio INTEGER,situacao INTEGER,chave TEXT,original TEXT,corrigido TEXT,
        perfil BLOB,invalidos TEXT);
      CREATE TABLE pessoas(linha INTEGER PRIMARY KEY,uf INTEGER,pasta INTEGER,boletim INTEGER,
        distrito INTEGER,municipio INTEGER,situacao INTEGER,chave TEXT,original TEXT,corrigido TEXT,
        perfil BLOB,invalidos TEXT,excluida INTEGER,familia_atual INTEGER,familia_fisica INTEGER);
    """)
    corrections = {int(r["linha"]): r for r in rows(root / FIXED_SOURCES[1])}
    duplicate = {int(r["linha"]): r for r in rows(root / FIXED_SOURCES[2])}
    links = {int(r["linha"]): r for r in rows(root / FIXED_SOURCES[3])}
    families = {}; original_families = {}; batch = []
    for line, original, text in raw_records(root, corrections):
        if text[16] != "1":
            continue
        uf = integer(text[:2]); uf = 0 if uf == 3 and text[2:6] == "0011" else uf
        key = (uf, text[6:16])
        if key in families:
            raise ValueError(f"Chave127 de cartao duplicada: {key}")
        families[key] = line
        original_families[line] = (original, text)
        profile, invalid = parse_profile(text, guides[("127", "familias")], FAMILY_NAMES)
        batch.append((line, uf, integer(text[8:13]), integer(text[13:16]), integer(text[6:8]),
                      integer(text[2:6]), integer(text[17]), text[6:16], original, text,
                      profile_hash(profile), ";".join(invalid)))
        if len(batch) == 4096:
            memory_guard(); connection.executemany("INSERT INTO familias VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", batch); batch.clear()
    connection.executemany("INSERT INTO familias VALUES(?,?,?,?,?,?,?,?,?,?,?,?)", batch)
    connection.commit(); batch.clear(); physical = None
    seen_decisions = set(); seen_links = set()
    for line, original, text in raw_records(root, corrections):
        if text[16] == "1":
            physical = line
            continue
        uf = integer(text[:2]); uf = 0 if uf == 3 and text[2:6] == "0011" else uf
        family = families.get((uf, text[6:16]))
        if line in duplicate:
            decision = duplicate[line]; seen_decisions.add(line)
            if (original, text) != (decision["texto_original"], decision["texto_corrigido"]):
                raise ValueError(f"Decisao duplicata nao confere: {line}")
        if line in links:
            decision = links[line]; seen_links.add(line); destination = int(decision["linha_familia"])
            if (original, text) != (decision["texto_original"], decision["texto_corrigido"]) or original_families.get(destination) != (
                    decision["texto_familia_original"], decision["texto_familia_corrigido"]):
                raise ValueError(f"Decisao vinculo nao confere: {line}")
            if family is not None and family != destination:
                raise ValueError(f"Vinculo conflita com chave: {line}")
            family = destination
        profile, invalid = parse_profile(text, guides[("127", "pessoas")], PERSON_NAMES)
        batch.append((line, uf, integer(text[8:13]), integer(text[13:16]), integer(text[6:8]),
                      integer(text[2:6]), integer(text[17]), text[6:16], original, text,
                      profile_hash(profile), ";".join(invalid), int(duplicate.get(line, {}).get("acao") == "remover"), family, physical))
        if len(batch) == 4096:
            memory_guard(); connection.executemany("INSERT INTO pessoas VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", batch); batch.clear()
    connection.executemany("INSERT INTO pessoas VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", batch)
    if seen_decisions != set(duplicate) or seen_links != set(links):
        raise ValueError("Manifesto contem linha nao encontrada")
    connection.commit()
    del families, original_families, batch
    connection.executescript("""
      CREATE INDEX fk ON familias(uf,pasta,boletim);
      CREATE INDEX fb ON familias(uf,perfil);
      CREATE INDEX fg ON familias(uf,municipio,distrito,boletim);
      CREATE INDEX fd ON familias(uf,distrito,boletim);
      CREATE INDEX pk ON pessoas(uf,pasta,boletim);
      CREATE INDEX pp ON pessoas(uf,perfil);
      CREATE INDEX pc ON pessoas(familia_atual);
      CREATE INDEX pf ON pessoas(familia_fisica);
    """)
    return connection


def fetch(connection, sql, args=()):
    return [dict(r) for r in connection.execute(sql, args)]


def pending_duplicate_lines(connection, approved):
    groups = fetch(connection, """SELECT group_concat(linha) AS linhas FROM pessoas
      GROUP BY uf,chave,municipio,situacao,perfil,substr(corrigido,17,1),substr(corrigido,56,7)
      HAVING count(*)>1""")
    pending = set()
    for group in groups:
        lines = {int(n) for n in group["linhas"].split(",")}
        decided = lines & approved
        if decided and decided != lines:
            raise ValueError("Grupo repetido com decisao parcial")
        if not decided:
            pending.update(lines)
    return pending, len(groups)


def read_source(root, uf, keys):
    families = defaultdict(list); people = defaultdict(list)
    path = root / f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz"
    with gzip.open(path, "rt", encoding="latin1") as f:
        for line, text in enumerate(f, 1):
            if line % 65536 == 0:
                memory_guard()
            text = text.rstrip("\r\n")
            key = (integer(text[:5]), integer(text[5:8]))
            if key not in keys:
                continue
            (families if text[8:10] == "00" else people)[key].append({"linha": line, "texto": text})
    return families, people


def candidate_families(connection, key, source_family, persons, guides):
    uf, pasta, boletim = key; text = source_family["texto"]
    profile, _ = parse_profile(text, guides[("25", "familias")], FAMILY_NAMES)
    candidates = {}; evidence = defaultdict(set)
    searches = [("mesma_pasta", "uf=? AND pasta=?", (uf, pasta)),
                ("mesmo_municipio_distrito_boletim", "uf=? AND municipio=? AND distrito=? AND boletim=?",
                 (uf, integer(text[29:33]), integer(text[33:35]), boletim)),
                ("corpo_familiar_igual", "uf=? AND perfil=?", (uf, profile_hash(profile))),
                ("mesmo_distrito_boletim", "uf=? AND distrito=? AND boletim=?", (uf, integer(text[33:35]), boletim))]
    for label, where, params in searches:
        for row in fetch(connection, "SELECT * FROM familias WHERE " + where, params):
            candidates[row["linha"]] = row; evidence[row["linha"]].add(label)
    for person in persons:
        for op, order in (("<", "DESC"), (">", "ASC")):
            for row in fetch(connection, f"SELECT * FROM familias WHERE linha {op} ? ORDER BY linha {order} LIMIT 1", (person["linha"],)):
                if row["uf"] == uf:
                    candidates[row["linha"]] = row; evidence[row["linha"]].add("adjacente_no_arquivo")
        for similar in fetch(connection, "SELECT familia_atual,familia_fisica FROM pessoas WHERE uf=? AND perfil=? AND excluida=0",
                             (uf, person["perfil"])):
            for name in ("familia_atual", "familia_fisica"):
                if similar[name] is not None:
                    row = fetch(connection, "SELECT * FROM familias WHERE linha=?", (similar[name],))[0]
                    candidates[row["linha"]] = row; evidence[row["linha"]].add("perfil_pessoal_em_outro_contexto")
    target_key = text[33:35] + text[:8]
    for line, row in candidates.items():
        if len(row["chave"]) == len(target_key) and sum(a != b for a, b in zip(row["chave"], target_key)) <= 1:
            evidence[line].add("chave_ate_um_caractere")
    return candidates, evidence


def own_group_proof(connection, family, families25, people25, guides, pending_duplicates,
                    permitir_contexto=False):
    key = (family["pasta"], family["boletim"])
    sources = families25.get(key, []); source_people = people25.get(key, [])
    linked = fetch(connection, "SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (family["linha"],))
    reasons = []
    if len(sources) != 1 or not linked:
        reasons.append("cartao25_ou_grupo_proprio_ausente")
    else:
        source = sources[0]
        reasons.extend(source_structure(source, source_people))
        profile, invalid = parse_profile(source["texto"], guides[("25", "familias")], FAMILY_NAMES)
        if invalid or family["invalidos"] or profile_hash(profile) != family["perfil"]:
            reasons.append("corpo_cartao_proprio_diverge")
        if integer(source["texto"][33:35]) != family["distrito"]:
            reasons.append("distrito_cartao_proprio_diverge")
        source_profiles = [parse_profile(r["texto"], guides[("25", "pessoas")], PERSON_NAMES) for r in source_people]
        if any(bad for _, bad in source_profiles) or any(r["invalidos"] for r in linked):
            reasons.append("perfil_proprio_invalido")
        if Counter(r["perfil"] for r in linked) != Counter(profile_hash(p) for p, _ in source_profiles):
            reasons.append("composicao_propria_diverge")
        if any((r["uf"], r["municipio"], r["distrito"], r["situacao"]) != (
                family["uf"], family["municipio"], family["distrito"], family["situacao"]) for r in linked):
            reasons.append("geografia_propria_diverge")
        if any(r["linha"] in pending_duplicates for r in linked):
            reasons.append("duplicata_propria_pendente")
    strict_reasons = sorted(set(reasons)); pairs = []; anchors = []
    criterion = "composicao_integral25" if not reasons else None
    # Identificar o grupo ja ligado nao autoriza corrigir suas respostas divergentes.
    if permitir_contexto and strict_reasons == ["composicao_propria_diverge"]:
        fallback_reasons = []
        profiles127 = [parse_profile(r["corrigido"], guides[("127", "pessoas")], PERSON_NAMES)[0] for r in linked]
        profiles25 = [p for p, _ in source_profiles]
        position = PERSON_NAMES.index("V216")
        keys127 = [p[:position] + p[position+1:] for p in profiles127]
        keys25 = [p[:position] + p[position+1:] for p in profiles25]
        if any(n != 1 for n in Counter(keys127).values()) or any(n != 1 for n in Counter(keys25).values()):
            fallback_reasons.append("pareamento24_nao_unico")
        if Counter(keys127) != Counter(keys25):
            fallback_reasons.append("diferenca_alem_de_V216")
        if any((integer(r["corrigido"][:2]), integer(r["corrigido"][8:13]), integer(r["corrigido"][13:16])) !=
               (family["uf"], *key) for r in linked) or any(
               (integer(r["texto"][:5]), integer(r["texto"][5:8])) != key for r in source_people):
            fallback_reasons.append("chave_do_grupo_proprio_diverge")
        if not fallback_reasons:
            indexes25 = {k: i for i, k in enumerate(keys25)}
            for i, profile_key in enumerate(keys127):
                j = indexes25[profile_key]; a = profiles127[i][position]; b = profiles25[j][position]
                if a != b and (a, b) != (0, 63):
                    fallback_reasons.append("diferenca_V216_fora_do_par_00_63")
                if a == b:
                    copies = fetch(connection, "SELECT linha FROM pessoas WHERE uf=? AND perfil=? AND excluida=0",
                                   (family["uf"], linked[i]["perfil"]))
                    if len(copies) == 1:
                        anchors.append(linked[i]["linha"])
                pairs.append({"linha127": linked[i]["linha"], "linha25": source_people[j]["linha"],
                              "V216": [a, b], "exato25campos": a == b,
                              "texto127": linked[i]["corrigido"], "texto25": source_people[j]["texto"]})
            if len(anchors) < 2:
                fallback_reasons.append("menos_de_duas_testemunhas_unicas_na127_UF")
        if fallback_reasons:
            reasons.extend(fallback_reasons)
        else:
            reasons = []; criterion = "grupo_proprio24_V216_preservado"
    return {"confirmado": not reasons, "criterio": criterion, "motivos": sorted(set(reasons)),
            "motivos_estritos": strict_reasons, "pares": pairs,
            "testemunhas_exatas_unicas127": anchors, "respostas_modificadas": False,
            "linhas_pessoas127": [r["linha"] for r in linked],
            "linhas_cartao25": [r["linha"] for r in sources],
            "linhas_pessoas25": [r["linha"] for r in source_people]}, Counter(r["perfil"] for r in linked)


def audit(root, out, selected_uf=None, pasta=None, boletim=None):
    memory_guard(4)
    root = root.resolve(); out = out.resolve()
    if not out.is_relative_to(root / "tmp"):
        raise ValueError("Saida deve ser nova pasta sob tmp do workspace")
    out.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    sources = {path: sha256(root / path) for path in FIXED_SOURCES}
    guides = load_guides(root)
    connection = None
    try:
        connection = build_index(root, out / "indice127.sqlite", guides)
        approved_duplicate_lines = {int(r["linha"]) for r in rows(root / FIXED_SOURCES[2])}
        pending_duplicates, duplicate_groups = pending_duplicate_lines(connection, approved_duplicate_lines)
        groups = fetch(connection, """SELECT p.uf,p.pasta,p.boletim,count(*) AS n FROM pessoas p
          WHERE p.excluida=0 AND p.familia_atual IS NULL AND NOT EXISTS
            (SELECT 1 FROM familias f WHERE f.uf=p.uf AND f.pasta=p.pasta AND f.boletim=p.boletim)
          GROUP BY p.uf,p.pasta,p.boletim ORDER BY p.uf,p.pasta,p.boletim""")
        scope = [g for g in groups if g["uf"] in UF and (selected_uf is None or UF[g["uf"]] == selected_uf)
                 and (pasta is None or g["pasta"] == pasta) and (boletim is None or g["boletim"] == boletim)]
        manifest = []; summaries = []; alternatives_file = out / "alternativas.jsonl"
        with alternatives_file.open("x", encoding="utf-8") as alternatives_output:
            for uf in sorted({g["uf"] for g in scope}):
                print("UF", UF[uf], "iniciada", flush=True)
                relevant = [g for g in scope if g["uf"] == uf]
                gzip_path = f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz"
                sources[gzip_path] = sha256(root / gzip_path)
                f25, p25 = read_source(root, uf, {(g["pasta"], g["boletim"]) for g in relevant
                                                 if g["pasta"] is not None and g["boletim"] is not None})
                prepared = []; extra_keys = set()
                for group in relevant:
                    key = (uf, group["pasta"], group["boletim"]); k25 = key[1:]
                    persons = fetch(connection, "SELECT * FROM pessoas WHERE uf IS ? AND pasta IS ? AND boletim IS ? AND excluida=0 ORDER BY linha", key)
                    reasons, card = evaluate_group(key, f25[k25], p25[k25], persons, guides, pending_duplicates)
                    candidates = {}; evidence = {}
                    if card is not None:
                        candidates, evidence = candidate_families(connection, key, f25[k25][0], persons, guides)
                        extra_keys.update((f["pasta"], f["boletim"]) for f in candidates.values())
                    prepared.append((key, persons, reasons, card, candidates, evidence))
                own_f25, own_p25 = read_source(root, uf, extra_keys) if extra_keys else ({}, {})
                proof_cache = {}
                for key, persons, reasons, card, candidates, evidence in prepared:
                    detail = {"chave": key, "linhas127": [r["linha"] for r in persons], "motivos": reasons,
                              "cartoes127_examinados": len(candidates), "alternativas_plausiveis": [], "perfis_fora_chave": []}
                    if card is not None:
                        target = Counter(r["perfil"] for r in persons)
                        other_groups = {}
                        for person in persons:
                            others = fetch(connection, """SELECT linha,uf,pasta,boletim,familia_atual,familia_fisica
                                FROM pessoas WHERE uf=? AND perfil=? AND excluida=0 AND NOT(pasta=? AND boletim=?)""",
                                (uf, person["perfil"], key[1], key[2]))
                            if others:
                                detail["perfis_fora_chave"].append({"linha127": person["linha"], "outros": others})
                                for other in others:
                                    other_key = (other["uf"], other["pasta"], other["boletim"])
                                    if other_key not in other_groups:
                                        members = fetch(connection, "SELECT linha,perfil,municipio,distrito,situacao FROM pessoas WHERE uf=? AND pasta=? AND boletim=? AND excluida=0", other_key)
                                        other_groups[other_key] = {"chave": other_key, "linhas": [r["linha"] for r in members],
                                            "composicao_integral_igual": Counter(r["perfil"] for r in members) == target,
                                            "geografia": sorted({(r["municipio"],r["distrito"],r["situacao"]) for r in members}, key=str)}
                        detail["outros_grupos_com_perfil_parcial_igual"] = list(other_groups.values())
                        if any(r["composicao_integral_igual"] for r in other_groups.values()):
                            reasons.append("composicao_integral_tambem_em_outra_chave127")
                        family_profile, _ = parse_profile(card["texto_25"], guides[("25", "familias")], FAMILY_NAMES)
                        for line, family in sorted(candidates.items()):
                            if line not in proof_cache:
                                proof_cache[line] = own_group_proof(connection, family, own_f25, own_p25, guides,
                                                                   pending_duplicates, permitir_contexto=True)
                            own, direct = proof_cache[line]
                            physical = Counter(r["perfil"] for r in fetch(connection,
                                "SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0", (line,)))
                            # Distrito divergente pode ser justamente a chave deslocada; nao elimina alternativa.
                            same_geo = (family["uf"], family["municipio"], family["situacao"]) == (
                                uf, integer(card["V116"]), integer(card["V118"]))
                            same_body = family["perfil"] == profile_hash(family_profile) and not family["invalidos"]
                            strong = bool(evidence[line] & {"mesmo_municipio_distrito_boletim", "chave_ate_um_caractere"})
                            same_species = family["corrigido"][18] == card["familias"]["V101"]
                            alt = alternative_reasons(same_geo, same_body, strong, direct, physical, target, own["confirmado"], same_species)
                            result = {"chave_alvo": key, "linha_cartao127": line, "pistas": sorted(evidence[line]),
                                      "texto_original": family["original"], "texto_corrigido": family["corrigido"],
                                      "uf_municipio_situacao_iguais": same_geo,
                                      "distrito_igual": family["distrito"] == integer(card["distrito"]),
                                      "corpo_igual": same_body, "especie_igual": same_species, "prova_grupo_proprio": own,
                                      "n_vinculadas": sum(direct.values()), "n_bloco_fisico": sum(physical.values()),
                                      "motivos_alternativa": alt}
                            alternatives_output.write(json.dumps(result, ensure_ascii=False) + "\n")
                            if alt:
                                detail["alternativas_plausiveis"].append({"linha_cartao127": line, "motivos": alt})
                        if detail["alternativas_plausiveis"]:
                            reasons.append("cartao127_alternativo_nao_descartado")
                        if not reasons:
                            card["verificacoes"] = {"perfil_pessoal_campos": PERSON_NAMES, "composicao_integral": True,
                                "ordens_redundancias_v100": True, "geografia_integral": True,
                                "pessoas_nao_acrescentadas_nem_corrigidas": True, "cartao127_ausente_chave_sem_distrito": True,
                                "cartoes127_examinados": len(candidates), "alternativas_plausiveis": 0,
                                "busca": "Todos os cartoes da UF por chaves parciais/corpo e todos os perfis pessoais da UF; contexto fisico separado do vinculo.",
                                "evidencia_alternativas": str(alternatives_file.relative_to(root)).replace("\\", "/")}
                            manifest.append(card)
                    detail["motivos"] = sorted(set(reasons)); detail["aprovavel"] = not reasons
                    summaries.append(detail)
                print("UF", UF[uf], "concluida", "cartoes aprovaveis acumulados", len(manifest), flush=True)
        connection.close(); connection = None
        changed = [path for path, before in sources.items() if sha256(root / path) != before]
        if changed:
            raise ValueError(f"Fontes alteradas durante auditoria: {changed}")
        result = {"versao": 1, "fontes": [{"arquivo": path, "sha256": value} for path, value in sorted(sources.items())],
                  "auditoria": {"script": "references/auditoria_recuperacao_cartoes_1960.py",
                      "script_sha256": sha256(Path(__file__)),
                      "alternativas_sha256": sha256(alternatives_file),
                      "alternativas_arquivo": str(alternatives_file.relative_to(root)).replace("\\", "/"),
                      "comando_reproducao": "python references/auditoria_recuperacao_cartoes_1960.py --out tmp/recuperacao_cartoes_1960_20260922/auditoria_NOVA" +
                          (f" --uf {selected_uf}" if selected_uf else "") + (f" --pasta {pasta}" if pasta is not None else "") +
                          (f" --boletim {boletim}" if boletim is not None else "")},
                  "cartoes": manifest}
        with (out / "manifesto.json").open("x", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        summary = {"cartoes_examinados": len(scope), "pessoas_examinadas": sum(g["n"] for g in scope),
            "cartoes_aprovaveis": len(manifest), "pessoas_aprovaveis": sum(r["n_pessoas"] for r in manifest),
            "por_especie": dict(Counter(r["familias"]["V101"] for r in manifest)),
            "por_uf": dict(Counter(r["UF"] for r in manifest)),
            "motivos_pendencia": dict(Counter(m for r in summaries for m in r["motivos"])),
            "fontes_inalteradas": True, "segundos": time.monotonic() - started,
            "grupos_repetidos127": duplicate_groups, "linhas_em_duplicatas_pendentes": len(pending_duplicates),
            "corrompidas_excluidas_somente_da_busca": [int(r["linha"]) for r in rows(root / FIXED_SOURCES[1]) if r["decisao"] == "corrompida"],
            "rss_final_mib": psutil.Process().memory_info().rss / 1024 ** 2,
            "nota": "Manifesto de candidatos aprovaveis; nao e execucao R nem microdado reconstruido. Demais casos preservados."}
        with (out / "resultado.json").open("x", encoding="utf-8") as f:
            json.dump({"resumo": summary, "grupos": summaries, "universo_sem_cartao": groups}, f, ensure_ascii=False, indent=2)
        print(json.dumps(summary, ensure_ascii=False, indent=2), flush=True)
        return result
    except BaseException as error:
        if connection is not None:
            connection.close()
        with (out / "FALHA.json").open("x", encoding="utf-8") as f:
            json.dump({"tipo": type(error).__name__, "motivo": str(error)}, f, ensure_ascii=False, indent=2)
        raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--uf", choices=sorted(UF.values()))
    parser.add_argument("--pasta", type=int)
    parser.add_argument("--boletim", type=int)
    args = parser.parse_args()
    if (args.pasta is not None or args.boletim is not None) and args.uf is None:
        parser.error("pasta/boletim exigem UF")
    audit(Path(__file__).resolve().parents[1], args.out, args.uf, args.pasta, args.boletim)
