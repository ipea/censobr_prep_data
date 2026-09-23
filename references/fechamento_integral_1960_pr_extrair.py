"""Evidencia primaria para leitura integral dos 162 municipios do Parana."""
import hashlib
import json
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]
PDF = ROOT / "references/fontes_1960/sinopse_preliminar_1960/cd_1960_sinopse_preliminar_pr.pdf"
OUT = ROOT / "tmp/fechamento_integral_1960/parana"
OUT.mkdir(parents=True, exist_ok=True)
doc = fitz.open(PDF)
pages = []
for i in range(6, 27):
    page = doc[i]
    page.get_pixmap(matrix=fitz.Matrix(300/72, 300/72)).save(OUT/f"quadroII_pdf{i+1:02d}.png")
    words = page.get_text("words")
    lines = []
    for word in sorted(words, key=lambda w: w[1]):
        matching = [r for r in lines if abs(r["y"]-word[1]) < 3]
        if matching:
            matching[0]["words"].append(word)
        else:
            lines.append({"y": word[1], "words": [word]})
    for line in lines:
        line["words"].sort(key=lambda w: w[0])
        line["text"] = " ".join(w[4] for w in line["words"])
    pages.append({"pagina_pdf": i+1, "pagina_impressa": i-3, "dimensoes": list(page.rect), "lines": lines})
    print(i+1, flush=True)
(OUT/"extracao_paginas.json").write_text(json.dumps(pages,ensure_ascii=False,indent=2),encoding="utf-8")
(OUT/"extracao_paginas.txt").write_text("\n\n".join(f"PDF {p['pagina_pdf']} | impresso {p['pagina_impressa']}\n"+"\n".join(f"y={r['y']:.1f} {r['text']}" for r in p["lines"]) for p in pages),encoding="utf-8")
(OUT/"fonte.json").write_text(json.dumps({"arquivo":str(PDF.relative_to(ROOT)),"sha256":hashlib.sha256(PDF.read_bytes()).hexdigest(),"paginas_pdf":list(range(7,28)),"resolucao_render_dpi":300},indent=2),encoding="utf-8")
# Sete divergencias e linha estadual, para segunda leitura visual independente.
for name, number, y0, y1 in [
    ("estado",7,235,267),("7227_cianorte",16,287,336),
    ("7252_paranavai",19,633,785),("7266_terra_boa",21,519,574),
    ("7336_nova_fatima",25,590,647),("7348_sertaneja",26,725,803),
    ("7350_urai",27,236,333),("7120_bituruna",27,356,431),
]:
    doc[number-1].get_pixmap(matrix=fitz.Matrix(300/72,300/72),clip=fitz.Rect(40,y0,558,y1)).save(OUT/f"recorte_{name}_pdf{number}.png")
