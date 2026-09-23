"""Segunda leitura dos grupos, ancoras exatas e casos especiais. Nao decide vinculos."""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import sqlite3
import auditoria_recuperacao_cartoes_1960 as old
import investigacao_residual_vinculos_1960 as search


def profile(person,sample,guides):
    return old.parse_profile(person["corrigido"] if sample=="127" else person["texto"],guides[(sample,"pessoas")],old.PERSON_NAMES)


def compare(people,source,guides):
    a=[profile(p,"127",guides) for p in people];b=[profile(p,"25",guides) for p in source]
    nearest=[]
    for row,(values,bad) in zip(people,a):
        distances=[]
        for row25,(values25,bad25) in zip(source,b):
            delta={n:[x,y] for n,x,y in zip(old.PERSON_NAMES,values,values25) if x!=y}
            distances.append((len(delta),row25["linha"],delta,bad25))
        best=min((d[0] for d in distances),default=None)
        nearest.append({"linha127":row["linha"],"invalidos127":bad,"minimo_campos_divergentes":best,
          "mais_proximos_sem_pareamento_automatico":[{"linha25":l,"diferencas":d,"invalidos25":bad25} for n,l,d,bad25 in distances if n==best]})
    ca=Counter(p for p,bad in a);cb=Counter(p for p,bad in b)
    pa=Counter(p[:16]+p[17:] for p,bad in a);pb=Counter(p[:16]+p[17:] for p,bad in b)
    return {"n127":len(people),"n25":len(source),"composicao25":bool(ca) and ca==cb,
      "composicao24":bool(pa) and pa==pb,"n_ocorrencias_pessoais_exatas":sum((ca&cb).values()),"mais_proximos":nearest}


def serial(row):
    return {k:v for k,v in row.items() if k!="perfil"}


def main(root,base,out):
    out.mkdir(parents=True,exist_ok=False)
    original=json.loads((base/"resultado.json").read_text(encoding="utf-8"))
    people={p["linha"]:p for p in json.loads((base/"pessoas127_contexto.json").read_text(encoding="utf-8"))}
    conn=sqlite3.connect((root/search.INDEX).as_uri()+"?mode=ro",uri=True);conn.row_factory=sqlite3.Row
    hits=sqlite3.connect((base/"ocorrencias25.sqlite").as_uri()+"?mode=ro",uri=True);hits.row_factory=sqlite3.Row
    guides=old.load_guides(root)
    needed=defaultdict(set); witnesses={}; groups=original["grupos"]
    for line,person in people.items():
        values,bad=profile(person,"127",guides)
        if bad:
            witnesses[line]=[];continue
        full,partial=search.canonical(values,guides)
        count=conn.execute("SELECT count(*) FROM pessoas WHERE uf=? AND perfil=? AND excluida=0",(person["uf"],old.profile_hash(values))).fetchone()[0]
        # Exact witness in one UF, unique on both sides, not just a common child profile.
        matches=[dict(r) for r in hits.execute("SELECT uf,linha,pasta,boletim FROM hits WHERE sig24=? AND sig25=? AND uf=?",(partial,full,person["uf"]))]
        witnesses[line]=matches if count==1 and len(matches)==1 else []
    for key,g in groups.items():
        if g["tipo"]=="sem_cartao":
            rawkey=(old.integer(g["chave"][2:7]),old.integer(g["chave"][7:]))
        else:
            f=old.fetch(conn,"SELECT * FROM familias WHERE linha=?",(g["cartao127"],))[0]
            rawkey=(f["pasta"],f["boletim"])
        if g["UF"] in old.UF and None not in rawkey:
            needed[g["UF"]].add(rawkey)
        g["chave_raw"]=rawkey
        bykey=defaultdict(list)
        for line in g["linhas"]:
            for witness in witnesses[line]:
                bykey[(witness["uf"],witness["pasta"],witness["boletim"])].append({"linha127":line,"linha25":witness["linha"]})
        g["testemunhas_unicas_exatas"]=[{"chave25":k,"pessoas":v} for k,v in sorted(bykey.items())]
        for k,v in bykey.items():
            if len(v)>=2:needed[k[0]].add(k[1:])
        for c in g["comparacoes_completas"]:
            if c["composicao24_exata"]:needed[c["chave25"][0]].add(tuple(c["chave25"][1:]))
    bhcards=[491772,492068,492653,492671,492685,492689,492706]
    special={}
    for line in bhcards+[780535,743892,743894]:
        f=old.fetch(conn,"SELECT * FROM familias WHERE linha=?",(line,))[0]
        ps=old.fetch(conn,"SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha",(line,))
        needed[f["uf"]].add((f["pasta"],f["boletim"]))
        special[line]={"cartao127":serial(f),"pessoas127":[serial(p) for p in ps]}
    cache={}
    for uf,keys in sorted(needed.items()):
        fs,ps=old.read_source(root,uf,keys)
        for key in keys:cache[(uf,*key)]=(fs[key],ps[key])
    fullgroups=[]; classifications=Counter(); per_case=[]
    for key,g in groups.items():
        uf=g["UF"]; target=[people[n] for n in g["linhas"]]
        fs,ps=cache.get((uf,*g["chave_raw"]),([],[]))
        check=compare(target,ps,guides)
        candidates=[]
        for anchor in g["testemunhas_unicas_exatas"]:
            if len(anchor["pessoas"])<2:continue
            f25,p25=cache[tuple(anchor["chave25"])]
            candidates.append({**anchor,"comparacao":compare(target,p25,guides),"cartoes25":f25})
        outside=[c for c in g["comparacoes_completas"] if c["composicao24_exata"] and tuple(c["chave25"])!=(uf,*g["chave_raw"])]
        if uf not in old.UF:label="fonte_da_uf_ausente"
        elif any(people[n]["invalidos"] for n in g["linhas"]):label="campo_invalido_impede_comparacao_integral"
        elif outside:label="composicao_encontrada_tambem_ou_somente_fora_chave"
        elif check["composicao25"]:label="composicao25_exata_na_chave_cartao_ainda_pendente"
        elif check["composicao24"]:label="composicao24_na_chave_diferencas_preservadas"
        elif not fs:label="cartao25_ausente_na_chave_sem_composicao_fora"
        elif candidates:label="composicao_diverge_mas_ha_duas_testemunhas_unicas"
        else:label="composicao_diverge_sem_duas_testemunhas_unicas"
        classifications[label]+=len(g["alvos"])
        item={"grupo":key,"UF":uf,"linhas_alvo":g["alvos"],"linhas_contexto":g["linhas"],"classe":label,
          "chave127":g["chave_raw"],"cartoes25_da_chave":fs,"comparacao_na_chave":check,
          "candidatos_duas_testemunhas":candidates,"testemunhas_unicas_por_chave":g["testemunhas_unicas_exatas"],
          "composicoes24_fora_chave":outside}
        fullgroups.append(item)
        per_case.extend({"linha":line,"grupo":key,"classe":label} for line in g["alvos"])
    for line,s in special.items():
        f=s["cartao127"];fs,ps=cache[(f["uf"],f["pasta"],f["boletim"])]
        s["cartoes25"]=fs;s["pessoas25"]=ps;s["comparacao"]=compare(s["pessoas127"],ps,guides)
        if len(fs)==1:
            a,b=old.parse_profile(f["corrigido"],guides[("127","familias")],old.FAMILY_NAMES)[0],old.parse_profile(fs[0]["texto"],guides[("25","familias")],old.FAMILY_NAMES)[0]
            s["diferencas_cartao"]={n:[x,y] for n,x,y in zip(old.FAMILY_NAMES,a,b) if x!=y}
        for p in s["pessoas127"]:
            v,bad=profile(p,"127",guides)
            p["ocorrencias25campos_na_uf127"]=conn.execute("SELECT count(*) FROM pessoas WHERE uf=? AND perfil=? AND excluida=0",(f["uf"],old.profile_hash(v))).fetchone()[0]
    # Reverse search for the five missing SP people, across every row/UF of127.
    missing=special[780535]["pessoas25"]
    reverse={p["linha"]:{"pessoa25":p,"ocorrencias24_na127":[]} for p in missing}
    target_sigs=defaultdict(list)
    for p in missing:target_sigs[search.signatures(p["texto"],"25")[1]].append(p)
    for row in conn.execute("SELECT linha,uf,pasta,boletim,familia_atual,corrigido,excluida,invalidos FROM pessoas"):
        full,part=search.signatures(row["corrigido"],"127")
        if part not in target_sigs or row["invalidos"]:continue
        for p in target_sigs[part]:reverse[p["linha"]]["ocorrencias24_na127"].append({**dict(row),"25campos_exatos":full==search.signatures(p["texto"],"25")[0]})
    special[780535]["busca_reversa25_em_toda127"]=list(reverse.values())
    summary={"por_classe_pessoas":dict(classifications),"casos":len(per_case),"grupos":len(fullgroups),
      "registros_corrompidos_fora_de_busca_por_igualdade":[855822,951432,951433],"decisoes_aplicadas":0,
      "testemunha":"Perfil completo unico na UF tanto na127 como na25; nao e identificacao civil nem decide sozinho o cartao."}
    search.dump(out/"detalhes.json",{"resumo":summary,"grupos":fullgroups,"casos":per_case,"especiais":special})
    search.dump(out/"evidencia_fora_chave.json",[g for g in fullgroups if g["composicoes24_fora_chave"]])
    search.dump(out/"especiais.json",special)
    hashes={path:old.sha256(root/path) for path in old.FIXED_SOURCES+[search.INDEX,search.INVENTORY]}
    search.dump(out/"fontes_sha256.json",hashes)
    print(json.dumps(summary,ensure_ascii=False),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--base",required=True);p.add_argument("--out",required=True);a=p.parse_args()
    root=Path(__file__).resolve().parents[1];out=(root/a.out).resolve()
    if not out.is_relative_to(root/"tmp"):raise ValueError("Saida deve ser nova e sob tmp")
    main(root,(root/a.base).resolve(),out)
