"""Renderiza cinco divergencias aritmeticas adicionais do guia municipal."""
import hashlib
import json
from pathlib import Path
import fitz

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/"tmp/fechamento_integral_1960/parana/outras_ufs"
OUT.mkdir(parents=True,exist_ok=True)
evidence=[]
for uf,page in [("mg",41),("mg",47),("sp",30),("sc",16),("mt",13)]:
    source=ROOT/f"references/fontes_1960/sinopse_preliminar_1960/cd_1960_sinopse_preliminar_{uf}.pdf"
    doc=fitz.open(source)
    doc[page-1].get_pixmap(matrix=fitz.Matrix(300/72,300/72)).save(OUT/f"{uf}_pdf{page}.png")
    evidence.append({"uf":uf,"pagina_pdf":page,"sha256":hashlib.sha256(source.read_bytes()).hexdigest(),"arquivo":str(source.relative_to(ROOT))})
(OUT/"fontes.json").write_text(json.dumps(evidence,ensure_ascii=False,indent=2),encoding="utf-8")

for uf,page,name,rect in [
    ("mg",41,"4032_alpinopolis",(20,405,565,560)),
    ("mg",47,"4095_itumirim_4096_itutinga",(20,575,565,735)),
    ("sp",30,"6378_jardinopolis",(20,680,565,775)),
    ("sc",16,"7457_sao_bento_do_sul",(20,225,565,300)),
    ("mt",13,"9204_coxim",(20,580,565,685)),
]:
    source=ROOT/f"references/fontes_1960/sinopse_preliminar_1960/cd_1960_sinopse_preliminar_{uf}.pdf"
    doc=fitz.open(source)
    doc[page-1].get_pixmap(matrix=fitz.Matrix(300/72,300/72),clip=fitz.Rect(*rect)).save(OUT/f"recorte_{name}_pdf{page}.png")
