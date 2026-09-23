"""Recortes locais das fontes geográficas de RS8405, sem modificar PDFs."""

from pathlib import Path
import hashlib
import json

import fitz
import xlrd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/geografia_rs"
OUT.mkdir(parents=True, exist_ok=True)
AUX = Path(r"D:\Dropbox\Bancos_Dados\Censos\Censo 1960\2-Arquivos Auxiliares")
sources = [
    ("codigo_original", AUX / "Censo 1960 - Códigos dos municípios.pdf", [285]),
    ("sinopse_rs", ROOT / "references/fontes_1960/sinopse_preliminar_1960/cd_1960_sinopse_preliminar_rs.pdf", [27, 75, 76, 79, 80]),
    ("divisao1960", OUT / "liv13611.pdf", [1, 2, 3, 4, 19, 130]),
]
records = []
for name, path, pages in sources:
    doc = fitz.open(path)
    pages_out = []
    for number in pages:
        page = doc[number - 1]
        stem = f"{name}_p{number}"
        page.get_pixmap(matrix=fitz.Matrix(2, 2)).save(OUT / f"{stem}.png")
        (OUT / f"{stem}.txt").write_text(page.get_text(), encoding="utf-8")
        pages_out.append({"pdf_page": number, "png": f"{stem}.png", "text": f"{stem}.txt"})
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    records.append({"path": str(path), "sha256": digest, "n_pages": len(doc), "inspected_pages": pages_out})
(OUT / "fontes_locais.json").write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")
territorial1970 = Path(r"D:\Dropbox\Bancos_Dados\Censos\Censo 1970\Divisão Territorial do Brasil - Com erros na UF ES\Rio Grande do Sul.xls")
book = xlrd.open_workbook(territorial1970)
sheet = book.sheet_by_name("Rio Grande do Sul")
selected = [{"excel_row": row + 1, "values": sheet.row_values(row)}
            for row in range(sheet.nrows) if sheet.cell_value(row, 0) == 852 and sheet.cell_value(row, 1) == 202]
(OUT / "cadastro1970_rs.json").write_text(json.dumps({
    "path": str(territorial1970), "sha256": hashlib.sha256(territorial1970.read_bytes()).hexdigest(),
    "sheet": sheet.name, "header_A1_D1": sheet.row_values(0), "rows": selected,
    "limite": "Código de 1970: não prova por si só continuidade do código censitário de 1960."
}, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(records, ensure_ascii=False))
