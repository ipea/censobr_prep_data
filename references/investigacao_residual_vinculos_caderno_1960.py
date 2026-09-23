"""Exporta evidencias geradas para um caderno portatil; nao muda decisoes."""
import json
from pathlib import Path
import sqlite3
import auditoria_recuperacao_cartoes_1960 as old
import investigacao_residual_vinculos_1960 as search


def main():
    root=Path(__file__).resolve().parents[1]
    base=root/"tmp/investigacao_residual_1960_20260922/vinculos"
    details=json.loads((base/"detalhes01/detalhes.json").read_text(encoding="utf-8"))
    people={p["linha"]:p for p in json.loads((base/"integral01/pessoas127_contexto.json").read_text(encoding="utf-8"))}
    full=json.loads((base/"integral01/grupos_composicao24_exata.json").read_text(encoding="utf-8"))
    selected=[g for g in details["grupos"] if g["composicoes24_fora_chave"] or g["grupo"] in {"conflito:695175","orfao:40:0140090004"}]
    conn=sqlite3.connect((root/search.INDEX).as_uri()+"?mode=ro",uri=True);conn.row_factory=sqlite3.Row
    for group in selected:
        group["pessoas127"]=[people[n] for n in group["linhas_contexto"]]
        group["composicoes_localizadas25"]=[g for g in full if g["grupo"]==group["grupo"]]
        if group["grupo"].startswith("conflito:"):
            row=dict(conn.execute("SELECT * FROM familias WHERE linha=?",(int(group["grupo"].split(":")[1]),)).fetchone());row.pop("perfil")
            group["cartao127"]=row
    partial=[]
    for line in (142402,259248):
        person=dict(conn.execute("SELECT * FROM pessoas WHERE linha=?",(line,)).fetchone());person.pop("perfil")
        pattern="".join("_" if c==" " else c for c in person["corrigido"][6:16])
        cards=old.fetch(conn,"SELECT * FROM familias WHERE uf=? AND chave LIKE ?",(person["uf"],pattern))
        cases=[]
        for card in cards:
            card.pop("perfil")
            group=old.fetch(conn,"SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0",(card["linha"],))
            for p in group:p.pop("perfil")
            fs,ps=old.read_source(root,person["uf"],{(card["pasta"],card["boletim"])})
            cases.append({"cartao127":card,"pessoas127_ja_ligadas":group,
              "cartoes25":fs[card["pasta"],card["boletim"]],"pessoas25":ps[card["pasta"],card["boletim"]]})
        partial.append({"pessoa127":person,"mascara_so_caracteres_legiveis":pattern,"candidatos":cases})
    result={"escopo":"Investigacao: nenhum vinculo, registro ou peso foi alterado.","resumo":details["resumo"],
      "cobertura_cada_pessoa":details["casos"],"casos_escolhidos_para_revisao":selected,
      "cartoes_especiais":details["especiais"],"chaves_parcialmente_ilegiveis":partial,
      "fontes_sha256":json.loads((base/"detalhes01/fontes_sha256.json").read_text(encoding="utf-8"))}
    target=root/"references/investigacao_residual_1960_evidencias/vinculos_casos.json"
    target.parent.mkdir(parents=True,exist_ok=True)
    if target.exists():raise FileExistsError(target)
    search.dump(target,result)
    print(target)


if __name__=="__main__":main()
