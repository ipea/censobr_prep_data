"""Busca adicional, somente leitura, de todos os vinculos residuais de 1960.

As correspondencias sao candidatos, nunca autorizacoes de mudanca. A assinatura
de 24 campos omite V216 apenas na geracao de candidatos. Nada e recodificado.
"""
import argparse
from collections import Counter, defaultdict
import gzip
import json
from pathlib import Path
import sqlite3
import time

import auditoria_recuperacao_cartoes_1960 as old

INDEX = "tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite"
INVENTORY = "references/fechamento_registros_1960_evidencias/inventario_final.json"


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")


def signatures(text, sample):
    if sample == "25":
        full = text[14:24] + text[25:51]
    else:
        full = text[18:54]
        # Only the five documented skips; an embedded dash is not a blank.
        for pos in (1, 2, 14, 17, 28):
            if full[pos:pos+1] == "-" and not full[pos+1:].strip():
                full = full[:pos] + " " * (len(full)-pos)
                break
    return full, full[:20] + full[22:]


def canonical(profile, guides):
    full = "".join(" " * (guides[("25", "pessoas")][name][1]-guides[("25", "pessoas")][name][0])
                   if value is None else str(value).zfill(guides[("25", "pessoas")][name][1]-guides[("25", "pessoas")][name][0])
                   for name, value in zip(old.PERSON_NAMES, profile))
    return full, full[:20] + full[22:]


def group_candidates(profiles, lookup):
    """All source cards containing every profile with sufficient multiplicity."""
    required = Counter(profiles)
    if not required:
        return set()
    sets = [{key for key, count in lookup.get(profile, {}).items() if count >= n}
            for profile, n in required.items()]
    return set.intersection(*sets)


def physical_card_context(text, card):
    """Physical order cannot suppress a candidate in a damaged/reordered source."""
    return card if card is not None and card[1][:8] == text[:8] else (None, None)


def run(root, out, pilot=False):
    started = time.monotonic()
    out.mkdir(parents=True, exist_ok=False)
    guides = old.load_guides(root)
    inventory = json.loads((root / INVENTORY).read_text(encoding="utf-8"))
    source_index = root / INDEX
    conn = sqlite3.connect(source_index.as_uri()+"?mode=ro", uri=True)
    conn.row_factory = sqlite3.Row
    groups = {}
    corrupt = {r["linha"] for r in inventory["corrompidas_sem_grupo_identificavel"]}
    for row in inventory["vinculos_pendentes"]:
        if row["linha"] in corrupt:
            continue
        uf = old.integer(row["UF"])
        if pilot and uf != 40:
            continue
        key = f"orfao:{uf}:{row['chave']}"
        groups.setdefault(key, {"tipo": "sem_cartao", "UF": uf, "chave": row["chave"], "alvos": [], "linhas": []})["alvos"].append(row["linha"])
    for row in inventory["conflitos_municipais"]+inventory["conflitos_situacao"]:
        uf = old.integer(row["UF"])
        if pilot and uf != 40:
            continue
        key = f"conflito:{row['linha_cartao']}"
        group = groups.setdefault(key, {"tipo": "conflito", "UF": uf, "cartao127": row["linha_cartao"], "alvos": [], "linhas": []})
        if row["linha"] not in group["alvos"]:
            group["alvos"].append(row["linha"])
    people = {}
    for key, group in groups.items():
        if group["tipo"] == "sem_cartao":
            found = old.fetch(conn, "SELECT * FROM pessoas WHERE uf=? AND chave=? AND excluida=0", (group["UF"], group["chave"]))
        else:
            found = old.fetch(conn, "SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0", (group["cartao127"],))
        for person in found:
            values, bad = old.parse_profile(person["corrigido"], guides[("127", "pessoas")], old.PERSON_NAMES)
            full, partial = canonical(values, guides)
            person.pop("perfil")
            person.update({"sig25": full, "sig24": partial, "invalidos": bad})
            people[person["linha"]] = person
        group["linhas"] = sorted(p["linha"] for p in found)
    targets24 = {p["sig24"] for p in people.values() if not p["invalidos"]}
    hits = sqlite3.connect(out / "ocorrencias25.sqlite")
    hits.executescript("""CREATE TABLE hits(uf INTEGER,linha INTEGER,pasta INTEGER,boletim INTEGER,
      cartao_linha INTEGER,cartao TEXT,texto TEXT,sig25 TEXT,sig24 TEXT);
      CREATE INDEX h24 ON hits(sig24); CREATE INDEX hg ON hits(uf,pasta,boletim);""")
    counts = {}; hashes = {}; batch = []; invalid_hits = 0; missing_card_context = 0
    # Search all supplied UFs, including UF different from the target's code.
    for uf, label in sorted(old.UF.items()):
        if pilot and uf != 40:
            continue
        path = root / f"data/release_legacy/Censo.1960.amostra.25porcento.{label}.gz"
        hashes[str(path.relative_to(root))] = old.sha256(path)
        card = None; n = 0; found = 0
        with gzip.open(path, "rt", encoding="latin1") as stream:
            for n, text in enumerate(stream, 1):
                text = text.rstrip("\r\n")
                if text[8:10] == "00":
                    card = (n, text)
                    continue
                full, partial = signatures(text, "25")
                if partial not in targets24:
                    continue
                parsed, bad = old.parse_profile(text, guides[("25", "pessoas")], old.PERSON_NAMES)
                if bad or canonical(parsed, guides) != (full, partial):
                    invalid_hits += 1
                    continue
                card_line, card_text = physical_card_context(text, card)
                if card_line is None:
                    missing_card_context += 1
                batch.append((uf, n, old.integer(text[:5]), old.integer(text[5:8]), card_line, card_text, text, full, partial))
                found += 1
                if len(batch) >= 4096:
                    hits.executemany("INSERT INTO hits VALUES(?,?,?,?,?,?,?,?,?)", batch); batch.clear()
        hits.executemany("INSERT INTO hits VALUES(?,?,?,?,?,?,?,?,?)", batch); batch.clear(); hits.commit()
        counts[str(uf)] = {"registros_lidos": n, "pessoas_candidatas": found}
        print(f"UF {label}: {n} registros, {found} candidatos", flush=True)
    lookup = defaultdict(dict)
    for sig, uf, pasta, boletim, count in hits.execute("SELECT sig24,uf,pasta,boletim,count(*) FROM hits GROUP BY sig24,uf,pasta,boletim"):
        lookup[sig][(uf,pasta,boletim)] = count
    all_candidates = set(); per_person = []
    for line, person in sorted(people.items()):
        matches = list(hits.execute("SELECT uf,count(*),sum(sig25=?) FROM hits WHERE sig24=? GROUP BY uf", (person["sig25"],person["sig24"]))) if not person["invalidos"] else []
        per_person.append({"linha": line, "UF": person["uf"], "invalidos": person["invalidos"],
            "contagens_por_uf": [{"UF": u,"n24": n,"n25": exact} for u,n,exact in matches]})
    for key, group in groups.items():
        candidates = group_candidates([people[n]["sig24"] for n in group["linhas"]], lookup)
        # Invalid fields must not become evidence of equality through NA.
        if any(people[n]["invalidos"] for n in group["linhas"]):
            candidates = set(); group["busca_completa_impedida_por_campo_invalido"] = True
        group["candidatos25_que_contem_todos24"] = sorted(candidates)
        group["fonte25_da_uf_disponivel"] = group["UF"] in old.UF
        all_candidates.update(candidates)
    # Reopen complete candidate groups, not just the people who matched.
    complete = {}
    for uf in sorted({k[0] for k in all_candidates}):
        f25,p25 = old.read_source(root, uf, {(p,b) for u,p,b in all_candidates if u == uf})
        for _,pasta,boletim in sorted(k for k in all_candidates if k[0] == uf):
            complete[(uf,pasta,boletim)] = (f25[pasta,boletim],p25[pasta,boletim])
    detailed = []
    for key, group in groups.items():
        aa = Counter(people[n]["sig25"] for n in group["linhas"])
        ab = Counter(people[n]["sig24"] for n in group["linhas"])
        group["comparacoes_completas"] = []
        for candidate in group["candidatos25_que_contem_todos24"]:
            families, persons = complete[tuple(candidate)]
            p25 = [old.parse_profile(p["texto"],guides[("25","pessoas")],old.PERSON_NAMES) for p in persons]
            bb = Counter(canonical(p,guides)[1] for p,bad in p25)
            ba = Counter(canonical(p,guides)[0] for p,bad in p25)
            check = {"chave25": candidate, "n25":len(persons), "n127":len(group["linhas"]),
              "composicao24_exata": ab==bb, "composicao25_exata": aa==ba,
              "invalidos25": [p["linha"] for p,(_,bad) in zip(persons,p25) if bad],
              "cartoes25": families, "mesma_uf":candidate[0]==group["UF"],
              "estrutura25":old.source_structure(families[0],persons) if len(families)==1 else ["cartao_nao_unico"]}
            group["comparacoes_completas"].append(check)
            if ab==bb:
                detailed.append({"grupo":key,"linhas127":group["linhas"],"chave25":candidate,"cartoes25":families,"pessoas25":persons,"comparacao":check})
    public_people = [{k:v for k,v in p.items() if k not in {"sig25","sig24"}} for p in people.values()]
    summary = {"grupos":len(groups),"pessoas_contexto":len(people),"pessoas_alvo_distintas":len({n for g in groups.values() for n in g["alvos"]}),
      "fragmentos_separados":sorted(corrupt) if not pilot else [],"fontes25":counts,"invalidos25_nao_admitidos":invalid_hits,
      "candidatos_sem_cartao_fisico_da_mesma_chave_preservados":missing_card_context,
      "grupos_com_algum_candidato24":sum(bool(g["comparacoes_completas"]) for g in groups.values()),
      "grupos_com_composicao24_exata":sum(any(c["composicao24_exata"] for c in g["comparacoes_completas"]) for g in groups.values()),
      "grupos_com_composicao25_exata":sum(any(c["composicao25_exata"] for c in g["comparacoes_completas"]) for g in groups.values()),
      "segundos":time.monotonic()-started,"nenhuma_decisao_aplicada":True,
      "limite":"Busca exaustiva por 24/25 respostas nas 17 fontes disponiveis; nao e busca de todas as combinacoes possiveis de erros de resposta."}
    dump(out/"resultado.json",{"resumo":summary,"grupos":groups,"pessoas":per_person,"fontes25_sha256":hashes})
    dump(out/"grupos_composicao24_exata.json",detailed)
    dump(out/"pessoas127_contexto.json",public_people)
    conn.close();hits.close()
    print(json.dumps(summary,ensure_ascii=False),flush=True)


if __name__ == "__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--out",required=True);parser.add_argument("--pilot",action="store_true")
    args=parser.parse_args();root=Path(__file__).resolve().parents[1];out=(root/args.out).resolve()
    if not out.is_relative_to(root/"tmp"):
        raise ValueError("Saida deve ser nova e sob tmp")
    run(root,out,args.pilot)
