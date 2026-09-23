"""Examina alternativas de cartao para novas pistas, inclusive reparo conjunto MG.

O texto proposto para405458 existe apenas em memoria nesta investigacao.
Nao produz manifesto aprovado e nao edita dados, guias ou pipeline.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
import sqlite3
import auditoria_recuperacao_cartoes_1960 as old
import investigacao_residual_vinculos_1960 as search


def main(root,out,caderno=None):
    out.mkdir(parents=True,exist_ok=False)
    conn=sqlite3.connect((root/search.INDEX).as_uri()+"?mode=ro",uri=True);conn.row_factory=sqlite3.Row
    guides=old.load_guides(root)
    inv=json.loads((root/search.INVENTORY).read_text(encoding="utf-8"))
    pending={n for g in inv["duplicatas_pendentes"]for n in g["linhas"]}
    cases=[((14,14990,116),[132193,132194,132195,132196]),((31,32426,6),[333756,333757]),
      ((81,82892,201),[1009631,1009632]),((40,40880,1),[405457,405458,405459])]
    results=[]
    for key,lines in cases:
        uf,pasta,boletim=key
        people=[old.fetch(conn,"SELECT * FROM pessoas WHERE linha=?",(line,))[0]for line in lines]
        proposal=None
        if uf==40:
            p=next(p for p in people if p["linha"]==405458)
            before=p["corrigido"]
            assert before[19]==" " and before[21:23]==" 9"
            p["corrigido"]=before[:19]+"7"+before[20:21]+"79"+before[23:]
            values,bad=old.parse_profile(p["corrigido"],guides[("127","pessoas")],old.PERSON_NAMES)
            p["perfil"]=old.profile_hash(values);p["invalidos"]=";".join(bad)
            proposal={"linha":405458,"antes":before,"proposta_somente_em_memoria":p["corrigido"],"campos":{"V203":[" ","7"],"AGE":[" 9","79"]}}
        fs,ps=old.read_source(root,uf,{(pasta,boletim)})
        assert len(fs[pasta,boletim])==1
        sf=fs[pasta,boletim][0]
        candidates,evidence=old.candidate_families(conn,key,sf,people,guides)
        own_f,own_p=old.read_source(root,uf,{(f["pasta"],f["boletim"])for f in candidates.values()})
        target=Counter(p["perfil"]for p in people)
        source_profile,bad=old.parse_profile(sf["texto"],guides[("25","familias")],old.FAMILY_NAMES)
        alternatives=[]
        for line,f in sorted(candidates.items()):
            own,direct=old.own_group_proof(conn,f,own_f,own_p,guides,pending,permitir_contexto=True)
            physical=Counter(r["perfil"]for r in old.fetch(conn,"SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0",(line,)))
            samegeo=(f["uf"],f["municipio"],f["situacao"])==(uf,old.integer(sf["texto"][29:33]),old.integer(sf["texto"][35:36]))
            samebody=f["perfil"]==old.profile_hash(source_profile) and not f["invalidos"]
            strong=bool(evidence[line]&{"mesmo_municipio_distrito_boletim","chave_ate_um_caractere"})
            same_species=f["corrigido"][18]==sf["texto"][13]
            reasons=old.alternative_reasons(samegeo,samebody,strong,direct,physical,target,own["confirmado"],same_species)
            if reasons:
                alternatives.append({"linha_cartao127":line,"texto_original":f["original"],"texto_corrigido":f["corrigido"],
                  "pistas":sorted(evidence[line]),"motivos":reasons,"prova_grupo_proprio":own,
                  "linhas25_proprio":own_f[f["pasta"],f["boletim"]]+own_p[f["pasta"],f["boletim"]]})
        profiles127=[old.parse_profile(p["corrigido"],guides[("127","pessoas")],old.PERSON_NAMES)for p in people]
        profiles25=[old.parse_profile(p["texto"],guides[("25","pessoas")],old.PERSON_NAMES)for p in ps[pasta,boletim]]
        literal_people=[]
        for person in people:
            literal={k:v for k,v in person.items()if k!="perfil"}
            if proposal and person["linha"]==proposal["linha"]:
                literal["texto_proposto_apenas_para_comparacao"]=literal["corrigido"]
                literal["corrigido"]=proposal["antes"]
                literal["invalidos"]=old.fetch(conn,"SELECT invalidos FROM pessoas WHERE linha=?",(person["linha"],))[0]["invalidos"]
            literal_people.append(literal)
        result={"chave25":key,"linhas127":lines,"cartoes127_examinados":len(candidates),"alternativas_restantes":alternatives,
          "composicao25_exata_apos_proposta":Counter(p for p,b in profiles127)==Counter(p for p,b in profiles25),
          "composicao24_exata_apos_proposta":Counter(p[:16]+p[17:]for p,b in profiles127)==Counter(p[:16]+p[17:]for p,b in profiles25),
          "estrutura25":old.source_structure(sf,ps[pasta,boletim]),"proposta_textual_nao_aplicada":proposal,
          "pessoas127":literal_people,"cartoes25":fs[pasta,boletim],"pessoas25":ps[pasta,boletim],
          "aprovacao":False,"nota":"Ausencia de alternativas sob busca definida nao autoriza por si so corrigir chave ou respostas."}
        results.append(result)
    document={"casos":results,"decisoes_aplicadas":0}
    search.dump(out/"resultado.json",document)
    if caderno:
        if caderno.exists():raise FileExistsError(caderno)
        search.dump(caderno,document)
    print(json.dumps([(r["chave25"],r["cartoes127_examinados"],len(r["alternativas_restantes"]))for r in results]),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--out",required=True);p.add_argument("--caderno");a=p.parse_args()
    root=Path(__file__).resolve().parents[1];out=(root/a.out).resolve()
    if not out.is_relative_to(root/"tmp"):raise ValueError("Saida deve ser nova e sob tmp")
    caderno=(root/a.caderno).resolve()if a.caderno else None
    if caderno and not caderno.is_relative_to(root/"references/investigacao_residual_1960_evidencias"):raise ValueError("Caderno fora do diretorio da investigacao")
    main(root,out,caderno)
