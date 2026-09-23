"""Encerra a hipotese de uma segunda testemunha rara RS82894/021.

Reusa o cache integral anterior, relendo somente os literais candidatos daRS25.
Nao faz outra busca nacional nem altera qualquer registro.
"""
import gzip
import json
from pathlib import Path
import sqlite3
import auditoria_recuperacao_cartoes_1960 as core
from investigacao_residual_vinculos_1960 import canonical

ROOT=Path(__file__).resolve().parents[1]
INDEX="tmp/resolucao_residuais_registros_1960_20260922/cartoes_chave01/indice127.sqlite"
CACHE="tmp/investigacao_residual_1960_20260922/vinculos/integral02/ocorrencias25.sqlite"
SOURCE="data/release_legacy/Censo.1960.amostra.25porcento.rs.gz"
TARGET="references/resolucao_residuais_1960_evidencias/segunda_testemunha_rs.json"


def run():
    current=sqlite3.connect((ROOT/INDEX).as_uri()+"?mode=ro",uri=True);current.row_factory=sqlite3.Row
    cache=sqlite3.connect((ROOT/CACHE).as_uri()+"?mode=ro",uri=True);cache.row_factory=sqlite3.Row
    guides=core.load_guides(ROOT);results=[];wanted={}
    for n in[1009631,1009632]:
        person=core.fetch(current,"SELECT * FROM pessoas WHERE linha=?",(n,))[0]
        values,bad=core.parse_profile(person["corrigido"],guides["127","pessoas"],core.PERSON_NAMES)
        assert not bad
        full,partial=canonical(values,guides)
        copies=core.fetch(current,"SELECT linha,original,corrigido FROM pessoas WHERE uf=81 AND perfil=? AND excluida=0",(person["perfil"],))
        candidates=core.fetch(cache,"SELECT uf,linha,pasta,boletim,texto,sig25 FROM hits WHERE uf=81 AND sig24=? ORDER BY linha",(partial,))
        for c in candidates:wanted[c["linha"]]=c["texto"]
        results.append({"linha127":n,"texto127_original":person["original"],"texto127_corrigido":person["corrigido"],
          "copias25campos_na127_UF":copies,"n_copias25campos_na127_UF":len(copies),
          "n_copias24campos_na25_UF":len(candidates),"n_copias25campos_na25_UF":sum(c["sig25"]==full for c in candidates),
          "candidatos25":[{k:v for k,v in c.items()if k!="sig25"}for c in candidates]})
    seen={}
    with gzip.open(ROOT/SOURCE,"rt",encoding="latin1")as stream:
        for n,text in enumerate(stream,1):
            if n in wanted:seen[n]=text.rstrip("\r\n")
    assert seen==wanted
    assert results[1]["n_copias25campos_na127_UF"]==2 and results[1]["n_copias24campos_na25_UF"]==8
    out=ROOT/TARGET
    if out.exists():raise FileExistsError(out)
    result={"casos":results,"criterio_alternativo_testado":"Uma testemunha25unica mais segunda24unica, conservandoV216.",
      "resultado":"Falha: a segunda pessoa nao e unica nem na127(ao menos2) nem na25(8).",
      "acao":"Nao recuperar cartao sob criterio da segunda testemunha rara; manter registros.",
      "limite":"Isto refuta essa via especifica; nao prova que o candidato82892/201 seja falso.",
      "fontes_sha256":{p:core.sha256(ROOT/p)for p in[INDEX,CACHE,SOURCE]},"nova_varredura_nacional":False}
    out.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps([{k:c[k]for k in["linha127","n_copias25campos_na127_UF","n_copias24campos_na25_UF","n_copias25campos_na25_UF"]}for c in results]))


if __name__=="__main__":run()
