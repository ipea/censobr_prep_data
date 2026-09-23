"""Procura grupos inteiros coincidentes sob chaves distintas; nao deduplica."""
import argparse
from collections import Counter, defaultdict
import gzip
import hashlib
import json
from pathlib import Path
import sqlite3

from conferir_investigacao_residual_1960 import UF, PNAMES, guide, profile

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INDEX = "tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite"


def composition_key(uf, district, card_profile, personal_profiles):
    return uf, district, card_profile, tuple(sorted(Counter(personal_profiles).items()))


def run(index, out, uf=None, minimum=2):
    con = sqlite3.connect(index.resolve().as_uri() + "?mode=ro", uri=True)
    con.row_factory = sqlite3.Row
    families = defaultdict(list)
    considered = 0
    params = [] if uf is None else [uf]
    selected = "" if uf is None else " AND f.uf=?"
    sql = """SELECT f.linha,f.uf,f.distrito,f.municipio,f.situacao,f.pasta,f.boletim,
             f.corrigido,hex(f.perfil) AS perfil_cartao,
             group_concat(hex(p.perfil)) AS perfis_pessoais,group_concat(p.linha) AS pessoas,
             count(*) AS n,sum(p.invalidos!='') AS n_invalidos
             FROM familias f JOIN pessoas p ON p.familia_atual=f.linha
             WHERE p.excluida=0 AND f.invalidos=''""" + selected + """
             GROUP BY f.linha HAVING count(*)>=? AND sum(p.invalidos!='')=0"""
    params.append(minimum)
    for row in con.execute(sql, params):
        r = dict(row); considered += 1
        profiles = r.pop("perfis_pessoais").split(",")
        key = composition_key(r["uf"], r["distrito"], r.pop("perfil_cartao"), profiles)
        r["pessoas"] = [int(n) for n in r["pessoas"].split(",")]
        families[key].append(r)
    result = []
    for key, matches in families.items():
        if len(matches) < 2:
            continue
        result.append({"UF": key[0], "distrito": key[1], "n_pessoas_por_grupo": matches[0]["n"],
                       "n_cartoes": len(matches), "cartoes": sorted(matches, key=lambda r: r["linha"]),
                       "linhas_exclusivas": len({n for r in matches for n in r["pessoas"]})})
    result.sort(key=lambda r: (-r["n_pessoas_por_grupo"], r["UF"], r["cartoes"][0]["linha"]))
    keys = defaultdict(set)
    for group in result:
        for card in group["cartoes"]:
            card["pessoas_literais"] = [dict(p) for p in con.execute(
                "SELECT linha,original,corrigido FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha", (card["linha"],))]
            if group["UF"] in UF:
                keys[group["UF"]].add((card["pasta"], card["boletim"]))
    sources = defaultdict(list)
    for state, wanted in keys.items():
        with gzip.open(ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{UF[state]}.gz", "rt", encoding="latin1") as f:
            for n, line in enumerate(f, 1):
                text = line.rstrip("\r\n")
                key = (int(text[:5]), int(text[5:8]))
                if key in wanted:
                    sources[(state,) + key].append({"linha": n, "texto": text})
    pg127 = guide("127", "pessoas"); pg25 = guide("25", "pessoas")
    for group in result:
        for card in group["cartoes"]:
            source = sources.get((group["UF"], card["pasta"], card["boletim"]))
            card["registros25_da_chave"] = source
            if source:
                pp25 = [p for p in source if p["texto"][8:10] != "00"]
                a = Counter(profile(p["corrigido"], pg127, PNAMES) for p in card["pessoas_literais"])
                b = Counter(profile(p["texto"], pg25, PNAMES) for p in pp25)
                card["composicao25_exata_na_chave"] = a == b
                card["n_pessoas25_na_chave"] = len(pp25)
    summary = {"minimo_pessoas_por_cartao": minimum, "cartoes_avaliados_sem_campos_invalidos": considered,
               "conjuntos_coincidentes": len(result), "cartoes_nesses_conjuntos": sum(r["n_cartoes"] for r in result),
               "pessoas_nesses_conjuntos": sum(r["linhas_exclusivas"] for r in result),
               "por_tamanho_grupo": dict(sorted(Counter(r["n_pessoas_por_grupo"] for r in result).items())),
               "decisoes_aplicadas": 0}
    payload = {"resumo": summary, "conjuntos": result,
               "criterio": "Mesma UF,distrito,15 campos do cartao e multiconjunto dos25quesitos de todas as pessoas ja ligadas. Chave/pasta/boletim/id_arquivo nao entram. Minimo de pessoas explicitado no resumo, sem campos invalidos.",
               "limite": "Coincidencia nao prova duplicacao. Nao inclui grupos orfaos, cartoes recuperados sinteticos ou alteracoes de respostas. Repeticoes pessoais ainda pendentes permanecem. Indice e perfis devem corresponder aos manifestos atuais.",
               "indice_sha256": hashlib.sha256(index.read_bytes()).hexdigest()}
    out.mkdir(parents=True, exist_ok=False)
    (out / "familias_repetidas.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    con.close()
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", required=True, type=Path)
    p.add_argument("--index", default=DEFAULT_INDEX, type=Path)
    p.add_argument("--uf", type=int)
    p.add_argument("--min-people", type=int, default=2)
    args = p.parse_args()
    output = (ROOT / args.out).resolve()
    if not output.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida deve ficar em tmp")
    if args.min_people < 1:
        raise ValueError("Minimo deve ser pelo menos1")
    run(ROOT / args.index, output, args.uf, args.min_people)
