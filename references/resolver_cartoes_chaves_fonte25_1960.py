"""Aprova casos localizados BA/CE sem renumerar os campos preservados da127.

Reconstroi indice forense com os manifestos atuais, rele todas17 fontes para
testemunhas e reavalia cartoes concorrentes. Nenhum dado/R e executado ou escrito.
"""
import argparse
from collections import Counter,defaultdict
import gzip
import json
from pathlib import Path
import auditoria_recuperacao_cartoes_1960 as core
import investigacao_residual_vinculos_1960 as prior

PROOF="references/resolucao_residuais_1960_evidencias/cartoes_fora_chave.json"
CASES=[((14,14990,116),[132193,132194,132195,132196]),((31,32426,6),[333756,333757])]


def pair_group(a,b):
    project=lambda p:p[:16]+p[17:]
    aa={project(p):p for p in a};bb={project(p):p for p in b}
    if len(aa)!=len(a) or len(bb)!=len(b) or set(aa)!=set(bb):
        raise ValueError("Composicao24 ou multiplicidade ambigua")
    pairs=[]
    for p in a:
        q=bb[project(p)]
        if p[16]!=q[16] and {p[16],q[16]}!={0,63}:
            raise ValueError("Diferenca pessoal fora V21600/63")
        pairs.append(b.index(q))
    return pairs


def run(root,out,proof_path):
    out.mkdir(parents=True,exist_ok=False)
    sources={p:core.sha256(root/p)for p in core.FIXED_SOURCES}
    guides=core.load_guides(root)
    conn=core.build_index(root,out/"indice127.sqlite",guides)
    approved={int(r["linha"])for r in core.rows(root/"read_guides/1960_amostra_127_duplicatas.csv")}
    pending,_=core.pending_duplicate_lines(conn,approved)
    contexts=[];signatures=set();counts25=Counter();hits25=defaultdict(list)
    for key,lines in CASES:
        people=[core.fetch(conn,"SELECT * FROM pessoas WHERE linha=?",(n,))[0]for n in lines]
        profiles=[core.parse_profile(p["corrigido"],guides[("127","pessoas")],core.PERSON_NAMES)for p in people]
        if any(bad for _,bad in profiles) or any(p["excluida"]or p["familia_atual"]is not None or p["linha"]in pending for p in people):
            raise ValueError("Alvo nao esta integral e livre de conflito de vinculo/duplicacao")
        sigs=[prior.canonical(p,guides)[0]for p,bad in profiles]
        signatures.update(sigs);contexts.append((key,people,[p for p,b in profiles],sigs))
    for uf,label in sorted(core.UF.items()):
        path=f"data/release_legacy/Censo.1960.amostra.25porcento.{label}.gz"
        sources[path]=core.sha256(root/path)
        n=0
        with gzip.open(root/path,"rt",encoding="latin1")as stream:
            for n,text in enumerate(stream,1):
                text=text.rstrip("\r\n")
                if text[8:10]=="00":continue
                full,_=prior.signatures(text,"25")
                if full in signatures:
                    parsed,bad=core.parse_profile(text,guides[("25","pessoas")],core.PERSON_NAMES)
                    if bad:continue
                    counts25[uf,full]+=1;hits25[full].append({"UF":uf,"linha":n,"texto":text})
        print(f"Testemunhas: {label}, {n} registros lidos",flush=True)
    cards=[];analyses=[]
    for key,people,p127,sigs in contexts:
        uf,pasta25,boletim25=key
        fs,ps=core.read_source(root,uf,{key[1:]});sf=fs[key[1:]];sp=ps[key[1:]]
        if len(sf)!=1 or core.source_structure(sf[0],sp):raise ValueError("Fonte25 incompleta")
        source=sf[0];text=source["texto"]
        p25=[core.parse_profile(r["texto"],guides[("25","pessoas")],core.PERSON_NAMES)for r in sp]
        if any(b for p,b in p25):raise ValueError("Pessoa25 invalida")
        pairs=pair_group(p127,[p for p,b in p25])
        first=people[0]
        ownkey=(uf,first["pasta"],first["boletim"])
        if any((p["uf"],p["pasta"],p["boletim"],p["distrito"],p["municipio"],p["situacao"])!=(
          *ownkey,core.integer(text[33:35]),core.integer(text[29:33]),core.integer(text[35:36]))for p in people):
            raise ValueError("Territorio ou numeracao127 divergente dentro do grupo")
        if core.fetch(conn,"SELECT linha FROM familias WHERE uf=? AND ((pasta=? AND boletim=?) OR (pasta=? AND boletim=?))",(*ownkey,pasta25,boletim25)):
            raise ValueError("Cartao127 ja existente numa das duas chaves")
        witnesses=[];witness_details=[]
        for p,values,sig,j in zip(people,p127,sigs,pairs):
            copies=core.fetch(conn,"SELECT linha FROM pessoas WHERE uf=? AND perfil=? AND excluida=0",(uf,p["perfil"]))
            exact=values==p25[j][0]
            if exact and len(copies)==1 and counts25[uf,sig]==1:witnesses.append(p["linha"])
            witness_details.append({"linha127":p["linha"],"linha25":sp[j]["linha"],"exato25":exact,
              "ocorrencias127UF":len(copies),"ocorrencias25UF":counts25[uf,sig],"ocorrencias25_todasUF":hits25[sig]})
        if len(witnesses)<2:raise ValueError("Menos de duas testemunhas completas unicas nas duas fontes")
        candidates,evidence=core.candidate_families(conn,key,source,people,guides)
        own_f,own_p=core.read_source(root,uf,{(f["pasta"],f["boletim"])for f in candidates.values()})
        target=Counter(p["perfil"]for p in people);fprofile,bad=core.parse_profile(text,guides[("25","familias")],core.FAMILY_NAMES)
        if bad or text[13]not in"13":raise ValueError("Cartao25 invalido ou fora do escopo")
        alternatives=[];evaluated=[]
        for line,f in sorted(candidates.items()):
            own,direct=core.own_group_proof(conn,f,own_f,own_p,guides,pending,permitir_contexto=True)
            physical=Counter(r["perfil"]for r in core.fetch(conn,"SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0",(line,)))
            samegeo=(f["uf"],f["municipio"],f["situacao"])==(uf,core.integer(text[29:33]),core.integer(text[35:36]))
            samebody=f["perfil"]==core.profile_hash(fprofile)and not f["invalidos"]
            strong=bool(evidence[line]&{"mesmo_municipio_distrito_boletim","chave_ate_um_caractere"})
            alt=core.alternative_reasons(samegeo,samebody,strong,direct,physical,target,own["confirmado"],f["corrigido"][18]==text[13])
            evaluated.append({"linha_cartao127":line,"pistas":sorted(evidence[line]),"motivos_alternativa":alt,"prova_grupo_proprio":own})
            if alt:alternatives.append(line)
        if alternatives:raise ValueError(f"Cartoes concorrentes ainda nao excluidos: {alternatives}")
        raw=first["corrigido"]
        mode="25_campos"if all(p127[i]==p25[j][0]for i,j in enumerate(pairs))else"24_campos_V216_preservado"
        card={"id_recuperacao":f"{uf:02d}-{first['pasta']:05d}-{first['boletim']:03d}","UF":f"{uf:02d}",
          "distrito":raw[6:8],"pasta":raw[8:13],"boletim":raw[13:16],"V116":raw[2:6],"V118":raw[17],
          "linha_25":source["linha"],"arquivo_25":f"data/release_legacy/Censo.1960.amostra.25porcento.{core.UF[uf]}.gz",
          "texto_25":text,"n_pessoas":len(people),"familias":core.normalized_family(text,guides),
          "pessoas":[{"linha":p["linha"],"texto_original":p["original"],"texto_corrigido":p["corrigido"],"linha_25":sp[j]["linha"],"texto_25":sp[j]["texto"]}for p,j in zip(people,pairs)],
          "unidade":"boletim_coletivo"if text[13]=="3"else"boletim_particular",
          "ressalvas":["Numeracao127 e UPA127 preservadas; fonte25 tem chave explicitamente diferente.","Respostas pessoais divergentes nao sao recodificadas.","Correspondencia de registros nao e identificacao civil."],
          "reconciliacao_chave":{"modalidade":"numeracao127_preservada","pasta_25":text[:5],"boletim_25":text[5:8],
            "comparacao_pessoal":mode,"testemunhas_exatas":witnesses,"prova_arquivo":proof_path,
            "alternativas_restantes":0,"geografia_territorial_alterada":False,"respostas_pessoais_alteradas":False},
          "verificacoes":{"composicao_integral25":mode=="25_campos","composicao24_V216_preservado":mode!="25_campos",
            "ordens_redundancias_v100":True,"geografia_integral":True,"pessoas_nao_acrescentadas_nem_corrigidas":True,
            "cartao127_ausente_chaves127_e25":True,"cartoes127_examinados":len(candidates),"alternativas_plausiveis":0}}
        cards.append(card);analyses.append({"id_recuperacao":card["id_recuperacao"],"testemunhas":witness_details,"cartoes_examinados":evaluated})
    changed=[p for p,h in sources.items()if core.sha256(root/p)!=h]
    if changed:raise ValueError(f"Fontes mudaram durante auditoria: {changed}")
    result={"versao":1,"cartoes":cards,"analises":analyses,"fontes":[{"arquivo":p,"sha256":h}for p,h in sources.items()],
      "indice_atual_sha256":core.sha256(out/"indice127.sqlite"),"pessoas_novas":0,"respostas_alteradas":0}
    (out/"resultado.json").write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    target=root/proof_path
    if target.exists():raise FileExistsError(target)
    target.parent.mkdir(parents=True,exist_ok=True);target.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({"cartoes":len(cards),"pessoas":sum(x["n_pessoas"]for x in cards),"chaves127":[x["id_recuperacao"]for x in cards]}),flush=True)


def emit_patch(root,proof_path):
    new=json.loads((root/proof_path).read_text(encoding="utf-8"))["cartoes"]
    path=root/"read_guides/1960_amostra_127_cartoes_recuperados.json"
    old=json.loads(path.read_text(encoding="utf-8"));ids={x["id_recuperacao"]for x in old["cartoes"]}
    if any(x["id_recuperacao"]in ids for x in new):raise ValueError("Cartao ja promovido")
    last=json.dumps(old["cartoes"][-1],ensure_ascii=False,indent=2)
    # Anchor is the exact final verification block, not an arbitrary closing brace.
    old_tail=path.read_text(encoding="utf-8").splitlines()[-8:]
    additions=",\n".join("\n".join("    "+line for line in json.dumps(x,ensure_ascii=False,indent=2).splitlines())for x in new)
    new_tail=old_tail[:-3]+["    },"]+additions.splitlines()+["  ]","}"]
    print("*** Begin Patch\n*** Update File: read_guides/1960_amostra_127_cartoes_recuperados.json\n@@\n"+
      "".join("-"+x+"\n"for x in old_tail)+"".join("+"+x+"\n"for x in new_tail)+"*** End Patch")


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--out");p.add_argument("--prova",default=PROOF);p.add_argument("--emit-patch",action="store_true");a=p.parse_args();root=Path(__file__).resolve().parents[1]
    if a.emit_patch:emit_patch(root,a.prova)
    else:
        if not a.out:raise ValueError("--out obrigatorio")
        out=(root/a.out).resolve()
        if not out.is_relative_to(root/"tmp"):raise ValueError("Saida deve ficar em tmp")
        if not (root/a.prova).resolve().is_relative_to(root/"references/resolucao_residuais_1960_evidencias"):raise ValueError("Prova fora da rodada")
        run(root,out,a.prova)
