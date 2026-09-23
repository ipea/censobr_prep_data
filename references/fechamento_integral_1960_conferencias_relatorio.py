"""Regressao exata das colunas antigas apos acrescentar os limites T7."""
import argparse
import hashlib
import json
import pandas as pd

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--before",required=True)
parser.add_argument("--after",required=True)
parser.add_argument("--out",required=True)
args=parser.parse_args()
old=pd.read_csv(args.before)
new=pd.read_csv(args.after)
added=[c for c in new if c not in old]
assert added==["valor_minimo","valor_maximo"]
assert len(old)==len(new)==2040
assert new[old.columns].equals(old), "colunas preexistentes mudaram"
assert new.loc[new.tabela!=7,added].isna().all().all()
assert new.loc[new.tabela==7,added].notna().all().all()
assert (new.loc[new.tabela==7,"valor_maximo"]>=new.loc[new.tabela==7,"valor_minimo"]).all()
result={"aprovado":True,"linhas":len(new),"colunas_adicionadas":added,
        "colunas_preexistentes_identicas_inclusive_ordem":list(old.columns),
        "t7_com_limites":int(new.tabela.eq(7).sum()),
        "demais_celulas_limites_ausentes":int(new.tabela.ne(7).sum()),
        "status_t7":new.loc[new.tabela==7,"status_celula"].value_counts().to_dict(),
        "sha256_antes":hashlib.file_digest(open(args.before,"rb"),"sha256").hexdigest(),
        "sha256_depois":hashlib.file_digest(open(args.after,"rb"),"sha256").hexdigest(),
        "limites_sao_intervalos_confianca":False,"variancias_fechadas":False}
with open(args.out,"x",encoding="utf-8") as stream:
    json.dump(result,stream,ensure_ascii=False,indent=2)
print(json.dumps(result,ensure_ascii=False))
