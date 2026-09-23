"""Autoriza nominalmente 7 correcoes PR + 5 outras; preserva os 2.758 demais registros."""
import argparse
import copy
import csv
import hashlib
import json
import sys
from pathlib import Path
from fechamento_integral_1960_pr_conferencia import VISUAL
from fechamento_integral_1960_pr_test import CHANGED as PR_CHANGED, BASELINE, BASELINE_SHA256

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"tmp/fechamento_integral_1960/parana"
GUIDE=ROOT/"read_guides/1960_municipios.csv"
FIELDS=["pop_total","pop_urbana","pop_rural"]
EXTRA=[
    ("mg",4032,41,37,[19740,4445,15295],"Alpinopolis: distritos 9225/3869/5356 + 10515/576/9939; 6298 e rural de Alterosa"),
    ("mg",4095,47,43,[7395,2043,5352],"Itumirim: sede 4257/1525/2732 + Ingai 3138/518/2620"),
    ("sp",6378,30,26,[16625,7533,9092],"Jardinopolis: sede 14380/6965/7415 + Juruce 2245/568/1677; somente pop_total muda"),
    ("sc",7457,16,11,[12814,6470,6344],"Sao Bento do Sul: mesmo total e componentes na linha do unico distrito"),
    ("mt",9204,13,8,[12997,2798,10199],"Coxim: sede 9893/1371/8522 + Pedro Gomes 3104/1427/1677"),
]


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out",required=True,type=Path)
    parser.add_argument("--proposal",type=Path)
    args=parser.parse_args()
    assert hashlib.sha256(BASELINE.read_bytes()).hexdigest()==BASELINE_SHA256, "Snapshot historico diverge da copia conferida"
    baseline=json.loads(BASELINE.read_text(encoding="utf-8"))
    before=baseline["linhas"]
    current=list(csv.DictReader(GUIDE.open(encoding="utf-8-sig")))
    expected=copy.deepcopy(before)
    codes={int(r["cod60"]):r for r in expected}
    assert len(expected)==2770
    assert len({(r["uf60"],r["cod60"]) for r in expected})==2770
    # cod60 nao e chave nacional: 541 ocorre em UFs distintas, fora desta lista.
    assert all(sum(int(r["cod60"])==code for r in expected)==1 for code in [*PR_CHANGED]+[r[1] for r in EXTRA])
    proposals=[]
    for line in VISUAL.strip().splitlines():
        pdf,code,*values=map(int,line.split())
        if code in PR_CHANGED:
            codes[code].update(dict(zip(FIELDS,map(str,values))),fonte_pop=f"Sinopse1960_QuadroII_p{PR_CHANGED[code]}")
    for uf,code,pdf,page,values,note in EXTRA:
        original=copy.deepcopy(codes[code])
        assert original["fonte_pop"]=="AEB"
        assert values[0]==sum(values[1:])
        codes[code].update(dict(zip(FIELDS,map(str,values))),fonte_pop=f"Sinopse1960_QuadroII_p{page}")
        proposals.append({"uf":uf,"cod60":code,"nome":original["nome"],"pagina_pdf":pdf,"pagina_impressa":page,
                          "url":f"https://biblioteca.ibge.gov.br/visualizacao/periodicos/312/cd_1960_sinopse_preliminar_{uf}.pdf",
                          "antes":original,"depois":codes[code],"evidencia":note,
                          "altera_alvos_urbana_rural":any(original[f]!=codes[code][f] for f in FIELDS[1:])})
    errors=[]
    if len(current)!=len(expected):
        errors.append("numero_linhas_diferente")
    for i,(a,b) in enumerate(zip(current,expected)):
        if a!=b:
            errors.append({"linha_dados":i+1,"cod60":b["cod60"],"campos":{f:{"atual":a.get(f),"esperado":b[f]} for f in b if a.get(f)!=b[f]}})
    changed=[int(a["cod60"]) for a,b in zip(before,current) if a!=b]
    authorized=sorted([*PR_CHANGED]+[r[1] for r in EXTRA])
    if sorted(changed)!=authorized:
        errors.append({"alteracoes_exatamente_doze":False,"observadas":changed,"autorizadas":authorized})
    nulls=[r for r in current if any(not r[f] for f in FIELDS)]
    arithmetic=[r["cod60"] for r in current if all(r[f] for f in FIELDS) and int(r["pop_total"])!=int(r["pop_urbana"])+int(r["pop_rural"])]
    if arithmetic:
        errors.append({"municipios_com_soma_divergente":arithmetic})
    result={"aprovado":not errors,"erros":errors,"n_municipios":len(current),"mudancas_autorizadas":authorized,
            "mudancas_observadas":changed,"baseline_sha256":baseline["sha256"],
            "atual_sha256":hashlib.sha256(GUIDE.read_bytes()).hexdigest(),"baseline_artefato_sha256":BASELINE_SHA256,
            "regra":"Igualdade integral e ordenada das 2770 linhas contra baseline +12 atualizacoes nominais; nao afrouxa teste do marco PR.",
            "n_linhas_inalteradas_esperado":2758,"proposta_outras_ufs":proposals,"linhas_com_componente_ausente_preservadas":nulls}
    args.out.parent.mkdir(parents=True,exist_ok=True)
    with args.out.open("x",encoding="utf-8") as stream:
        json.dump(result,stream,ensure_ascii=False,indent=2)
    if args.proposal:
        with args.proposal.open("x",encoding="utf-8") as stream:
            json.dump(proposals,stream,ensure_ascii=False,indent=2)
    print(json.dumps({k:v for k,v in result.items() if k!="proposta_outras_ufs"},ensure_ascii=False,indent=2))
    return 0 if result["aprovado"] else 1


if __name__=="__main__":
    sys.exit(main())
