# Recorta as paginas das publicacoes de 1960 e 1965 a que os pesos sao calibrados, para que o guia do
# desenho amostral mostre a fonte ao lado da descricao das celulas.
#
# Sao duas publicacoes, com mapeamentos diferentes entre a pagina impressa e a pagina do PDF:
#
#   Serie Nacional, vol. I (resultados definitivos)  -- a pagina impressa p esta no indice p+40 do PDF (o volume
#                                                       tem 41 paginas de rosto e indice antes da pagina 1
#                                                       impressa); a mesma correspondencia que
#                                                       transcricao_1960_serie_nacional.py usa em PAGES
#   Resultados Preliminares, Serie Especial vol. II  -- sem numeracao util no OCR; os quadros foram localizados
#                                                       pelo texto e entram pelo indice do PDF
#
# Uso, da raiz do projeto:  python references/figuras/facsimiles_1960.py
# Precisa de Python 3 com PyMuPDF (fitz).
import os
import fitz

DIR = "references/figuras/desenho_amostral_1960"
DPI = 150

# (arquivo de saida, pdf, indice da pagina no PDF, o que e)
PAGINAS = [
    ("facsimile_definitivos_tab33.png", "references/fontes_1960/1960_serie_nacional_vol1_brasil.pdf", 82 + 40,
     "tabela 33, p. 82: populacao presente por sexo e grupos de idade, por UF -- as margens (a) e (b)"),
    ("facsimile_definitivos_tab34.png", "references/fontes_1960/1960_serie_nacional_vol1_brasil.pdf", 85 + 40,
     "tabela 34, p. 85: populacao presente por situacao do domicilio, por UF -- a margem (c)"),
    ("facsimile_definitivos_tab40.png", "references/fontes_1960/1960_serie_nacional_vol1_brasil.pdf", 98 + 40,
     "tabela 40, p. 98: alfabetizacao de 5 anos e mais por sexo, por UF -- a margem (d)"),
    ("facsimile_1965_quadro1.png", "references/fontes_1960/1965_resultados_preliminares_vol2.pdf", 27,
     "quadro 1, Nordeste: populacao urbana e rural por sexo e grupos de idade -- 176 celulas nas 4 regioes"),
    ("facsimile_1965_quadro2.png", "references/fontes_1960/1965_resultados_preliminares_vol2.pdf", 28,
     "quadro 2, Nordeste: alfabetizacao por sexo e grupos de idade -- as 8 celulas de quem sabe ler"),
]

os.makedirs(DIR, exist_ok=True)
for nome, pdf, i, oque in PAGINAS:
    doc = fitz.open(pdf)
    saida = os.path.join(DIR, nome)
    doc[i].get_pixmap(dpi=DPI).save(saida)
    kb = os.path.getsize(saida) // 1024
    print("%-36s %4d KB  %s" % (nome, kb, oque))
    doc.close()
