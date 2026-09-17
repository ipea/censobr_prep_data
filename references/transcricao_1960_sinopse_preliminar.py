# -*- coding: utf-8 -*-
"""Localiza e recorta os blocos do quadro II das Sinopses Preliminares de 1960
-- "Populacao urbana e rural e domicilios segundo as zonas fisiograficas, os
municipios e os distritos" -- para os municipios em que o Codigo de Zonas
Fisiograficas imprime a numeracao com buraco e o microdado nao a reproduz.

A camada de texto destes volumes e ruim (3% das linhas fecham a aritmetica na
pagina de Campos), entao o script nao transcreve: ele acha a pagina, imprime o
texto cru como primeira leitura e grava o recorte a 300 dpi para leitura
visual. A transcricao resultante fica em
references/censo_1960_sinopse_preliminar_distritos.csv.

Roda da raiz do projeto:  python references/transcricao_1960_sinopse_preliminar.py
"""
import fitz
import io
import os
import re
import sys
import unicodedata

PDFS = "references/fontes_1960/sinopse_preliminar_1960"
SAIDA = os.path.join(os.environ.get("SINOPSE_OUT", "."), "recortes_sinopse")

# municipio -> (uf do arquivo, codigo de 1960, como o nome aparece na pagina)
# A chave e por letras, e algumas precisam do que o OCR fez do nome: Pedro
# Osorio sai "FOdro"/"Podro", Dois Irmaos sai "Doia", Caico sai "Caioo" e
# "Caieo" -- neste ultimo nao sobra letra que identifique, e a ancora e a
# pagina e o y da linha, lidos uma vez.
ALVOS = [
    ("rj", 5210, "CARDOSOMOREIRA"),   # distrito de Campos, nome unico no volume
    ("rj", 5306, "RIOBONITO"),
    ("pb", 2012, "CAJAZEIRAS"),
    ("rn", 1741, (11, 357)),          # Caico, que o OCR escreve "Caioo"
    ("rn", 1725, "GOIANINHA"),
    ("sp", 6341, "ITAPORANGA"),
    ("rs", 8553, "DROOSORIO"),
    ("rs", 8405, "IRMAOS"),
    ("mt", 9162, "LIVRAM"),
    ("mg", 4096, "ITUTINGA"),
    ("es", 5150, "COLATINA"),
    ("sc", 7546, "TAIO"),
    ("sc", 7545, "RODEIO"),
]


def sa(x):
    return "".join(c for c in unicodedata.normalize("NFD", x)
                   if unicodedata.category(c) != "Mn").upper()


def linhas_com_y(pg):
    """As palavras da pagina agrupadas em linhas, com o y de cada uma."""
    d = {}
    for x0, y0, x1, y1, t, *_ in pg.get_text("words"):
        d.setdefault(round(y0 / 4), []).append((x0, y0, t))
    saida = []
    for k in sorted(d):
        it = sorted(d[k])
        saida.append((it[0][1], " ".join(t for _, _, t in it)))
    return saida


def so_letras(x):
    return re.sub(r"[^A-Z]", "", sa(x))


def paginas_quadro_ii(doc):
    """O volume tem varias tabelas; so o quadro II abre por distrito. Uma vez
    aberto, ele corre por paginas seguidas, e so a primeira repete o titulo --
    entao a faixa vai do primeiro ao ultimo titulo mais o que vier depois com
    linhas de cinco numeros."""
    tit = [i for i in range(doc.page_count)
           if "MUNICIPIOS" in so_letras(doc[i].get_text()[:1200])
           and "DISTRITOS" in so_letras(doc[i].get_text()[:1200])]
    if not tit:
        return set()
    ini, fim = min(tit), max(tit)
    while fim + 1 < doc.page_count:
        n5 = sum(1 for _, l in linhas_com_y(doc[fim + 1])
                 if len(re.findall(r"\d[\d ]*\d|\d", l)) >= 4)
        if n5 < 8:
            break
        fim += 1
    return set(range(ini, fim + 1))


def acha(doc, chave):
    """As linhas do quadro II em que a chave aparece. A comparacao e por letras
    apenas: o ruido destes volumes e de pontuacao e de algarismo, e o nome
    sobrevive."""
    q2 = paginas_quadro_ii(doc)
    out = []
    for i in sorted(q2):
        for y, l in linhas_com_y(doc[i]):
            if chave in so_letras(l):
                out.append((i, y, l))
    return out


def recorta(doc, pagina, y, destino, antes=40, depois=430):
    pg = doc[pagina]
    r = fitz.Rect(pg.rect.x0, max(pg.rect.y0, y - antes),
                  pg.rect.x1, min(pg.rect.y1, y + depois))
    pg.get_pixmap(matrix=fitz.Matrix(300 / 72, 300 / 72), clip=r).save(destino)


if __name__ == "__main__":
    os.makedirs(SAIDA, exist_ok=True)
    so = sys.argv[1] if len(sys.argv) > 1 else None
    for uf, cod, nome in ALVOS:
        if so and so != str(cod):
            continue
        doc = fitz.open(os.path.join(PDFS, "cd_1960_sinopse_preliminar_%s.pdf" % uf))
        hits = [(nome[0], nome[1], "(ancora de pagina)")] if isinstance(nome, tuple) else acha(doc, nome)
        print("\n===== %s %s (%s) -- %d ocorrencia(s) em linha de tabela" % (uf, cod, nome, len(hits)))
        for j, (p, y, l) in enumerate(hits):
            print("  p%d y=%.0f | %s" % (p + 1, y, l[:100]))
            dest = os.path.join(SAIDA, "%s_%d_%d.png" % (uf, cod, j))
            recorta(doc, p, y, dest)
            print("     recorte: %s" % dest)
        doc.close()
