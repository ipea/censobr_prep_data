"""Extrai fontes dos dois pares distritais pendentes, sem alterar documentos."""

from pathlib import Path
import hashlib
import json

import fitz
import xlrd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/geografia_rs"
AUX = Path(r"D:\Dropbox\Bancos_Dados\Censos\Censo 1960\2-Arquivos Auxiliares")
original = AUX / "Censo 1960 - Códigos dos municípios.pdf"
doc = fitz.open(original)
pages = []
for number in (278, 280):
    page = doc[number - 1]
    stem = f"codigo_original_p{number}"
    page.get_pixmap(matrix=fitz.Matrix(2, 2)).save(OUT / f"{stem}.png")
    pages.append({"pagina_pdf": number, "pagina_impressa": number - 1, "imagem": f"{stem}.png"})
sources = [{"arquivo": str(original), "sha256": hashlib.sha256(original.read_bytes()).hexdigest(), "paginas": pages}]
for name in ("horizontina", "tenenteportela"):
    path = OUT / f"{name}.pdf"
    pdf = fitz.open(path)
    text = "\n".join(page.get_text() for page in pdf)
    (OUT / f"{name}.txt").write_text(text, encoding="utf-8")
    sources.append({"arquivo": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                    "url": f"https://www.ibge.gov.br/biblioteca/visualizacao/dtb/riograndedosul/{name}.pdf", "texto": text})
path = Path(r"D:\Dropbox\Bancos_Dados\Censos\Censo 1970\Divisão Territorial do Brasil - Com erros na UF ES\Rio Grande do Sul.xls")
sheet = xlrd.open_workbook(path).sheet_by_name("Rio Grande do Sul")
keys = {(867, 708), (867, 717), (868, 810)}
rows = [{"linha_excel": i + 1, "valores_A_D": sheet.row_values(i)} for i in range(sheet.nrows)
        if (sheet.cell_value(i, 0), sheet.cell_value(i, 1)) in keys]
sources.append({"arquivo": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "aba": sheet.name, "cabecalho_A1_D1": sheet.row_values(0), "linhas": rows})
(OUT / "horizontina_tenenteportela_fontes.json").write_text(
    json.dumps(sources, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(sources[1:], ensure_ascii=True, indent=2))
