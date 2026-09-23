"""Prova e proposta dos dois vinculos com um digito perdido na pasta.

Rele os registros brutos e a composicao inteira. Emite patch, nunca edita
manifestos por efeito incidental. Nao executa R nem reconstrucao completa.
"""
import argparse
from collections import Counter
import csv
import io
import json
from pathlib import Path
import auditoria_recuperacao_cartoes_1960 as core


def compatible_key(raw, candidate):
    return len(raw)==len(candidate) and all(a==b or a==" " for a,b in zip(raw,candidate))


def audit(root):
    guide=core.load_guides(root)
    fixture=json.loads((root/"references/investigacao_residual_1960_evidencias/vinculos_casos.json").read_text(encoding="utf-8"))
    cases=fixture["chaves_parcialmente_ilegiveis"]
    corrections={int(r["linha"]):r for r in core.rows(root/"read_guides/1960_amostra_127_correcoes.csv")}
    manifest=core.rows(root/"read_guides/1960_amostra_127_vinculos.csv")
    removed={int(r["linha"]) for r in core.rows(root/"read_guides/1960_amostra_127_duplicatas.csv") if r["acao"]=="remover"}
    source_text={}; candidate_cards={}; outputs=[]; proposed=[]
    wanted={r["pessoa127"]["linha"] for r in cases}
    for r in cases:
        wanted.update(p["linha"] for p in r["candidatos"][0]["pessoas127_ja_ligadas"])
        wanted.add(r["candidatos"][0]["cartao127"]["linha"])
        candidate_cards[r["pessoa127"]["linha"]]=[]
    for line,original,text in core.raw_records(root,corrections):
        if line in wanted:source_text[line]=(original,text)
        if text[16]!="1":continue
        for r in cases:
            person=r["pessoa127"];pt=source_text.get(person["linha"],(person["original"],person["corrigido"]))[1]
            if text[:2]==pt[:2] and compatible_key(pt[6:16],text[6:16]):
                candidate_cards[person["linha"]].append(line)
    for r in cases:
        person=r["pessoa127"];candidate=r["candidatos"][0];card=candidate["cartao127"]
        target=person["linha"];dest=card["linha"]
        if candidate_cards[target]!=[dest]:raise ValueError("Destino nao unico pelos caracteres legiveis")
        members=[person]+candidate["pessoas127_ja_ligadas"]
        allowed={p["linha"] for p in members}
        if removed&allowed:raise ValueError("Membro removido por decisao atual")
        if {int(x["linha"])for x in manifest if int(x["linha_familia"])==dest}-allowed:
            raise ValueError("Destino possui integrante adicional no manifesto atual")
        for row in members+[card]:
            if source_text[row["linha"]]!=(row["original"],row["corrigido"]):
                raise ValueError("Literal do caderno diverge da fonte ou das decisoes atuais")
        t=person["corrigido"];f=card["corrigido"]
        if any(t[a:b]!=f[a:b] for a,b in [(0,2),(2,6),(6,8),(13,16),(17,18)]):
            raise ValueError("Geografia ou boletim divergem")
        if t[8:13].count(" ")!=1:raise ValueError("Caso nao tem exatamente um digito perdido na pasta")
        uf=int(t[:2]);key=(int(f[8:13]),int(f[13:16]))
        fs,ps=core.read_source(root,uf,{key});families=fs[key];persons25=ps[key]
        if len(families)!=1 or core.source_structure(families[0],persons25):
            raise ValueError("Estrutura da fonte25 invalida")
        a=[core.parse_profile(p["corrigido"],guide[("127","pessoas")],core.PERSON_NAMES)for p in members]
        b=[core.parse_profile(p["texto"],guide[("25","pessoas")],core.PERSON_NAMES)for p in persons25]
        if any(bad for _,bad in a+b) or Counter(p for p,bad in a)!=Counter(p for p,bad in b):
            raise ValueError("Composicao pessoal integral nao confere")
        fa,ia=core.parse_profile(f,guide[("127","familias")],core.FAMILY_NAMES)
        fb,ib=core.parse_profile(families[0]["texto"],guide[("25","familias")],core.FAMILY_NAMES)
        if ia or ib or fa!=fb or f[6:8]!=families[0]["texto"][33:35]:
            raise ValueError("Cartao ou distrito nao conferem")
        profile=a[0][0]
        matches=[p for p,(value,bad)in zip(persons25,b)if value==profile]
        if len(matches)!=1:raise ValueError("Origem pessoal nao unica dentro do grupo")
        source=f"data/release_legacy/Censo.1960.amostra.25porcento.{core.UF[uf]}.gz"
        proposed.append({"linha":str(target),"linha_familia":str(dest),"texto_original":person["original"],
          "texto_corrigido":person["corrigido"],"texto_familia_original":card["original"],"texto_familia_corrigido":card["corrigido"],
          "fonte_25":source,"linha_pessoa_25":str(matches[0]["linha"]),"linha_familia_25":str(families[0]["linha"]),
          "justificativa":f"Chave pessoal com um digito perdido na pasta; unico cartao127 compativel com todos os caracteres legiveis, geografia concordante, cartao integral e grupo completo de {len(members)} pessoas exatos na fonte25. Original preservado; prova em references/resolucao_residuais_1960_evidencias/vinculos_chaves_incompletas.json."})
        outputs.append({"linha":target,"linha_familia":dest,"cartoes127_compativeis":candidate_cards[target],
          "pessoas127":members,"cartao127":card,"cartao25":families[0],"pessoas25":persons25,
          "linha_pessoa25":matches[0]["linha"],"n_pessoas":len(members),"composicao25_exata":True,
          "pasta_original_preservada":True,"fonte25":source,"fonte25_sha256":core.sha256(root/source)})
    return {"casos":outputs,"propostas_manifesto":proposed,"alteracao_respostas":False,
      "fontes":[{"arquivo":p,"sha256":core.sha256(root/p)} for p in core.FIXED_SOURCES]}


if __name__=="__main__":
    p=argparse.ArgumentParser();p.add_argument("--out");p.add_argument("--emit-patch",action="store_true");args=p.parse_args()
    root=Path(__file__).resolve().parents[1];result=audit(root)
    if args.out:
        target=(root/args.out).resolve()
        if not target.is_relative_to(root/"references/resolucao_residuais_1960_evidencias") and not target.is_relative_to(root/"tmp"):
            raise ValueError("Saida fora da rodada")
        if target.exists():raise FileExistsError(target)
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    if args.emit_patch:
        path=root/"read_guides/1960_amostra_127_vinculos.csv";existing=core.rows(path)
        ids={r["linha"]for r in existing};new=[r for r in result["propostas_manifesto"]if r["linha"]not in ids]
        if not new:raise ValueError("Decisoes ja presentes")
        buf=io.StringIO();writer=csv.DictWriter(buf,fieldnames=list(existing[0]),quoting=csv.QUOTE_ALL,lineterminator="\n")
        writer.writerows(new)
        print("*** Begin Patch\n*** Update File: read_guides/1960_amostra_127_vinculos.csv\n@@\n "+path.read_text(encoding="utf-8").splitlines()[-1]+"\n"+"".join("+"+line+"\n"for line in buf.getvalue().splitlines())+"*** End Patch")
    else:print(json.dumps({"casos":len(result["casos"]),"pessoas":sum(c["n_pessoas"]for c in result["casos"])}))
