"""Compara suplemento T7 anterior e atualizado sem alterar nenhum deles."""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
import pandas as pd

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--before",required=True,type=Path)
parser.add_argument("--after",required=True,type=Path)
parser.add_argument("--out",required=True,type=Path)
args=parser.parse_args()
key=["uf","item","medida","peso"]
old=pd.read_csv(args.before)
new=pd.read_csv(args.after)
assert len(old)==len(new)==204
assert not old.duplicated(key).any() and not new.duplicated(key).any()
joined=old.merge(new,on=key,suffixes=("_antes","_depois"),validate="1:1",how="outer",indicator=True)
assert joined._merge.eq("both").all()
for field in ["n_amostra","n_sem_classificacao","status","publicado"]:
    assert joined[field+"_antes"].equals(joined[field+"_depois"]),field
change=np.zeros(len(joined),dtype=bool)
for field in ["valor_minimo","valor_maximo","peso_sem_classificacao"]:
    change|=~np.isclose(joined[field+"_antes"],joined[field+"_depois"],rtol=0,atol=1e-6)
assert set(joined.loc[change,"uf"])=={"mg","mt","pr"}
result={"status":"COMPARACAO_CONFERIDA", "sha256_antes":hashlib.sha256(args.before.read_bytes()).hexdigest(),
        "sha256_depois":hashlib.sha256(args.after.read_bytes()).hexdigest(),"celulas":len(new),
        "uf_com_mudanca_ponderada":sorted(joined.loc[change,"uf"].unique()),
        "contagens_status_referencias_inalterados":True,
        "celulas_com_mudanca":joined.loc[change,key].to_dict("records"), "referencia_no_intervalo":{}}
for weight in new.peso.unique():
    sub=new[(new.peso==weight)&(new.n_sem_classificacao>0)]
    inside=(sub.publicado>=sub.valor_minimo)&(sub.publicado<=sub.valor_maximo)
    width=(sub.valor_maximo-sub.valor_minimo)/sub.publicado*100
    result["referencia_no_intervalo"][weight]={"dentro":int(inside.sum()),"fora":int((~inside).sum()),
        "maior_largura_percentual":float(width.max()),"celula_maior_largura":sub.loc[width.idxmax(),key].to_dict()}
with args.out.open("x",encoding="utf-8") as stream:
    json.dump(result,stream,ensure_ascii=False,indent=2)
print(json.dumps({k:v for k,v in result.items() if k!="celulas_com_mudanca"},ensure_ascii=False))
