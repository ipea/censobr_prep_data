"""Amplia contextos: pasta RS inteira e adultos do cartao SP sem pessoas."""
import argparse
from collections import Counter,defaultdict
import json
from pathlib import Path
import sqlite3
import auditoria_recuperacao_cartoes_1960 as old
import investigacao_residual_vinculos_1960 as search
import investigacao_residual_vinculos_detalhes_1960 as detail


def main(root,out,caderno=None):
    out.mkdir(parents=True,exist_ok=False)
    guides=old.load_guides(root)
    c=sqlite3.connect((root/search.INDEX).as_uri()+"?mode=ro",uri=True);c.row_factory=sqlite3.Row
    cards=old.fetch(c,"SELECT * FROM familias WHERE uf=81 AND pasta=82588 ORDER BY boletim")
    needed={(pasta,f["boletim"]) for pasta in(82588,82586) for f in cards}
    fs,ps=old.read_source(root,81,needed)
    pattern=[]
    for f in cards:
        people=old.fetch(c,"SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0",(f["linha"],))
        checks=[]
        for pasta in(82588,82586):
            sf,sp=fs[pasta,f["boletim"]],ps[pasta,f["boletim"]]
            check=detail.compare(people,sp,guides)
            checks.append({"pasta25":pasta,"cartoes25":sf,"n25":len(sp),"n127":len(people),
              "composicao24":check["composicao24"],"composicao25":check["composicao25"],
              "n_ocorrencias_pessoais_exatas":check["n_ocorrencias_pessoais_exatas"]})
        pattern.append({"cartao127":detail.serial(f),"linhas_pessoas127":[p["linha"]for p in people],"comparacoes":checks})
    summary={str(pasta):{"composicao24":sum(any(x["pasta25"]==pasta and x["composicao24"] for x in g["comparacoes"])for g in pattern),
      "composicao25":sum(any(x["pasta25"]==pasta and x["composicao25"] for x in g["comparacoes"])for g in pattern)} for pasta in(82588,82586)}
    source=json.loads((root/"references/investigacao_residual_1960_evidencias/vinculos_casos.json").read_text(encoding="utf-8"))
    missing=source["cartoes_especiais"]["780535"]["pessoas25"][:2]
    names=[n for n in old.PERSON_NAMES if n!="V216"]
    spans=[];pos=0
    for name in names:
        start,end,_=guides[("25","pessoas")][name];spans.append((name,pos,pos+end-start));pos+=end-start
    masks=defaultdict(list)
    for p in missing:
        full,sig=search.signatures(p["texto"],"25")
        for name,start,end in spans:masks[(name,sig[:start]+sig[end:])].append(p)
    found=defaultdict(dict)
    for row in c.execute("SELECT * FROM pessoas"):
        if row["invalidos"]:continue
        full,sig=search.signatures(row["corrigido"],"127")
        for name,start,end in spans:
            for target in masks.get((name,sig[:start]+sig[end:]),[]):
                key=target["linha"]
                if row["linha"]not in found[key]:
                    x=detail.serial(dict(row));x["campos_omitidos_na_busca"]=["V216",name]
                    x["comparacao"]=detail.compare([x],[target],guides)
                    found[key][row["linha"]]=x
    missing_result=[]
    for target in missing:
        matches=list(found[target["linha"]].values())
        for p in matches:
            if p["familia_atual"]:
                p["cartao127"]=detail.serial(old.fetch(c,"SELECT * FROM familias WHERE linha=?",(p["familia_atual"],))[0])
        missing_result.append({"pessoa25":target,"candidatos_ate_um_campo_alem_V216":matches})
    result={"pasta82588":{"cartoes":len(cards),"resumo":summary,"grupos":pattern},
      "adultos_cartao780535":missing_result,"ressalva":"V216 e outro campo omitidos somente para procurar candidatos; nao houve recodificacao nem aprovacao."}
    search.dump(out/"resultado.json",result)
    if caderno is not None:
        if caderno.exists():raise FileExistsError(caderno)
        caderno.parent.mkdir(parents=True,exist_ok=True)
        search.dump(caderno,result)
    print(json.dumps({"cartoes_pasta":len(cards),"resumo":summary,"adultos":[(g["pessoa25"]["linha"],len(g["candidatos_ate_um_campo_alem_V216"]))for g in missing_result]}),flush=True)


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--out",required=True);p.add_argument("--caderno");a=p.parse_args();root=Path(__file__).resolve().parents[1];out=(root/a.out).resolve()
    if not out.is_relative_to(root/"tmp"):raise ValueError("Saida deve ser nova e sob tmp")
    caderno=(root/a.caderno).resolve() if a.caderno else None
    if caderno is not None and not caderno.is_relative_to(root/"references/investigacao_residual_1960_evidencias"):
        raise ValueError("Caderno fora do diretorio desta investigacao")
    main(root,out,caderno)
