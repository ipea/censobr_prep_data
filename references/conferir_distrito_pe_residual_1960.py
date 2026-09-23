"""Conferencia delimitada PE22366/154: proposta geografica, nao implementacao.

Usa indice ja atualizado; so rele a fontePE. Nao escreve microdados/manifestos.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import sqlite3
import auditoria_recuperacao_cartoes_1960 as core
from resolver_cartoes_chaves_fonte25_1960 import pair_group

ROOT=Path(__file__).resolve().parents[1]
INDEX="tmp/resolucao_residuais_registros_1960_20260922/cartoes_chave01/indice127.sqlite"
TEXT="references/resolucao_residuais_1960_evidencias/texto_propostas.json"


def inspect():
    guides=core.load_guides(ROOT)
    conn=sqlite3.connect((ROOT/INDEX).as_uri()+"?mode=ro",uri=True);conn.row_factory=sqlite3.Row
    card=core.fetch(conn,"SELECT * FROM familias WHERE linha=238422")[0]
    people=core.fetch(conn,"SELECT * FROM pessoas WHERE uf=21 AND pasta=22366 AND boletim=154 AND excluida=0 ORDER BY linha")
    lines=[p["linha"]for p in people]
    assert lines==[238423,239457,239458,239459,239460,239461]
    fs,ps=core.read_source(ROOT,21,{(22366,154)})
    assert len(fs[22366,154])==1
    sf=fs[22366,154][0];sp=ps[22366,154]
    assert not core.source_structure(sf,sp)
    a,b=[core.parse_profile(x["corrigido"],guides["127","pessoas"],core.PERSON_NAMES)for x in people],[core.parse_profile(x["texto"],guides["25","pessoas"],core.PERSON_NAMES)for x in sp]
    assert not any(bad for _,bad in a+b)
    pairs=pair_group([p for p,bad in a],[p for p,bad in b])
    f127,bad127=core.parse_profile(card["corrigido"],guides["127","familias"],core.FAMILY_NAMES)
    f25,bad25=core.parse_profile(sf["texto"],guides["25","familias"],core.FAMILY_NAMES)
    assert not bad127 and not bad25 and f127==f25
    proof=json.loads((ROOT/TEXT).read_text(encoding="utf-8"))
    anchor=next(x for x in proof["testemunhas_verificadas"]if x["linha127"]==238423)
    assert anchor["campos_ignorados"]==["V208"]and anchor["n127"]==anchor["n25"]==1
    mask=next(x for x in proof["reparos"]if x["linha127"]==238423)
    assert mask["texto_antes"][27]==" "and mask["texto_antes"][6:8]=="X7"
    assert mask["texto_corrigido_proposto"]==people[0]["corrigido"]
    matching_cards=core.fetch(conn,"SELECT linha,distrito,chave,corrigido FROM familias WHERE uf=21 AND pasta=22366 AND boletim=154 AND municipio=2166 AND situacao=5")
    assert len(matching_cards)==1 and matching_cards[0]["linha"]==238422
    candidates,evidence=core.candidate_families(conn,(21,22366,154),sf,people,guides)
    other={k:v for k,v in candidates.items()if k!=238422}
    ownf,ownp=core.read_source(ROOT,21,{(f["pasta"],f["boletim"])for f in other.values()})
    approved={int(r["linha"])for r in core.rows(ROOT/"read_guides/1960_amostra_127_duplicatas.csv")}
    pending,_=core.pending_duplicate_lines(conn,approved)
    alternatives=[];evaluated=[];target=Counter(p["perfil"]for p in people)
    for line,f in sorted(other.items()):
        own,direct=core.own_group_proof(conn,f,ownf,ownp,guides,pending,permitir_contexto=True)
        physical=Counter(r["perfil"]for r in core.fetch(conn,"SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0",(line,)))
        strong=bool(evidence[line]&{"mesmo_municipio_distrito_boletim","chave_ate_um_caractere"})
        reasons=core.alternative_reasons((f["uf"],f["municipio"],f["situacao"])==(21,2166,5),
          f["perfil"]==core.profile_hash(f25)and not f["invalidos"],strong,direct,physical,target,own["confirmado"],f["corrigido"][18]==sf["texto"][13])
        evaluated.append({"linha":line,"texto_original":f["original"],"texto_corrigido":f["corrigido"],
          "pistas":sorted(evidence[line]),"motivos_alternativa":reasons,"grupo_proprio":own})
        if reasons:alternatives.append(line)
    personal=[]
    for i,j in enumerate(pairs):
        differences={name:[x,y]for name,x,y in zip(core.PERSON_NAMES,a[i][0],b[j][0])if x!=y}
        personal.append({"linha127":people[i]["linha"],"linha25":sp[j]["linha"],"diferencas_preservadas":differences,
          "vinculo_atual":people[i]["familia_atual"],"distrito127":people[i]["corrigido"][6:8]})
    portable=lambda x:{k:v for k,v in x.items()if k!="perfil"}
    return {"cartao127":portable(card),"pessoas127":[portable(p)for p in people],"cartao25":sf,"pessoas25":sp,
      "comparacao_pessoas":personal,"testemunha_previa_sem_V208":anchor,
      "circularidade":"A unicidade foi contada ignorando V208 antes da correcao, sem exigir o distrito X7/07. O V208 recuperado nao e a prova original.",
      "cartoes127_mesma_chave_territorio":matching_cards,"cartoes_concorrentes_examinados":len(other),
      "alternativas_restantes_busca_ampla":alternatives,"conferencia_concorrentes":evaluated,
      "proposta_nao_aplicada":[{"linha":n,"campo":"distrito","original":"X7","operacional":"07"}for n in [238422,238423]],
      "vinculos_pendentes":[p["linha"]for p in people if p["familia_atual"]is None],
      "respostas_a_preservar":[{"linha":239457,"campo":"V216","127":"00","25":"63"}],
      "fontes_sha256":{p:core.sha256(ROOT/p)for p in core.FIXED_SOURCES+[TEXT,"data/release_legacy/Censo.1960.amostra.25porcento.pe.gz"]}}


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--out",required=True);a=p.parse_args();out=(ROOT/a.out).resolve()
    if not out.is_relative_to(ROOT/"references/resolucao_residuais_1960_evidencias") or out.exists():raise ValueError("Nova evidencia somente")
    result=inspect();out.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({k:result[k]for k in["cartoes_concorrentes_examinados","alternativas_restantes_busca_ampla","vinculos_pendentes"]}))
