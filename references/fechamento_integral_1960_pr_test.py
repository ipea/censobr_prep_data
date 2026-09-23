"""Regressao dos 162 valores visuais e protecao de todas as outras linhas do guia."""
import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path

from fechamento_integral_1960_pr_conferencia import VISUAL

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/parana"
GUIDE = ROOT / "read_guides/1960_municipios.csv"
BASELINE = ROOT / "references/fechamento_integral_1960_evidencias/guia_municipal_anterior.json"
BASELINE_SHA256 = "5362895fd1fc4f2c721436008308438067fb18b9c2a904624fb9fe0a51afa0cb"
FIELDS = ["pop_total", "pop_urbana", "pop_rural"]
CHANGED = {7227:12,7252:15,7266:17,7336:21,7348:22,7350:23,7120:23}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--snapshot",action="store_true")
    parser.add_argument("--out",default=str(OUT/"teste_guia.json"))
    args=parser.parse_args()
    rows=list(csv.DictReader(GUIDE.open(encoding="utf-8-sig")))
    signature=hashlib.sha256(GUIDE.read_bytes()).hexdigest()
    if args.snapshot:
        raise RuntimeError("Baseline historica congelada; nao recriar com o guia atual")
    assert hashlib.sha256(BASELINE.read_bytes()).hexdigest()==BASELINE_SHA256, "Snapshot historico diverge da copia conferida"
    baseline=json.loads(BASELINE.read_text(encoding="utf-8"))
    key=lambda r:(r["uf60"],r["cod60"])
    old={key(r):r for r in baseline["linhas"]}
    current={key(r):r for r in rows}
    errors=[]
    if len(old)!=len(baseline["linhas"]) or len(current)!=len(rows):
        errors.append("chave_uf_codigo_repetida")
    if old.keys()!=current.keys():
        errors.append("conjunto_de_linhas_alterado")
    actual_changed=[]
    for k,before in old.items():
        after=current.get(k,{})
        is_pr="Paran" in before["nome_uf60"]
        code=int(before["cod60"])
        if before!=after:
            actual_changed.append({"uf60":k[0],"cod60":code,"campos":[f for f in before if before[f]!=after.get(f)]})
        if not is_pr or code not in CHANGED:
            if before!=after:
                errors.append(f"linha_fora_dos_sete_alterada:{k}")
        else:
            if before["fonte_pop"] != "AEB":
                errors.append(f"fonte_anterior_nao_AEB:{code}")
            for field in set(before)-set(FIELDS)-{"fonte_pop"}:
                if before[field]!=after.get(field):
                    errors.append(f"campo_nao_autorizado_alterado:{code}:{field}")
            expected_source=f"Sinopse1960_QuadroII_p{CHANGED[code]}"
            if after.get("fonte_pop")!=expected_source:
                errors.append(f"fonte_nova:{code}:{after.get('fonte_pop')}!={expected_source}")
    pr={int(r["cod60"]):r for r in rows if "Paran" in r["nome_uf60"]}
    visual={}
    for line in VISUAL.strip().splitlines():
        page,code,*values=map(int,line.split())
        visual[code]=values
        for field,value in zip(FIELDS,values):
            if code not in pr or int(pr[code][field])!=value:
                errors.append(f"valor_visual:{code}:{field}:esperado={value}")
    if len(pr)!=162 or set(pr)!=set(visual):
        errors.append("cobertura_diferente_de_162")
    sums={field:sum(int(r[field]) for r in pr.values()) for field in FIELDS}
    if sums!=dict(zip(FIELDS,[4277763,1327982,2949781])):
        errors.append("somas_estaduais_nao_fecham")
    if {r["cod60"] for r in actual_changed}!={*CHANGED} or len(actual_changed)!=7:
        errors.append("alteracoes_nao_sao_exatamente_sete_municipios")
    result={"aprovado":not errors,"erros":errors,"alteracoes":actual_changed,"somas":sums,
            "baseline_sha256":baseline["sha256"],"baseline_artefato_sha256":BASELINE_SHA256,"atual_sha256":signature,
            "fontes_anteriores":{str(code):next(r["fonte_pop"] for r in baseline["linhas"] if int(r["cod60"])==code) for code in CHANGED}}
    Path(args.out).parent.mkdir(parents=True,exist_ok=True)
    Path(args.out).write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps(result,ensure_ascii=False,indent=2))
    return 0 if not errors else 1


if __name__=="__main__":
    sys.exit(main())
