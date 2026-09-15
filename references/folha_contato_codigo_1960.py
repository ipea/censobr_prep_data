# Folha de contato do Codigo de Zonas Fisiograficas, Municipios e Distritos.
#
# A pagina do livro e quase toda espaco em branco e pontilhado: o que interessa
# e o nome, a esquerda, e dois numeros curtos, a direita. Recortando cada linha
# ao nome e colando os codigos logo ao lado, uma pagina inteira cabe numa
# coluna estreita, e varias paginas cabem numa imagem so. Nenhum OCR entra
# aqui: a folha e para ler.
import fitz, numpy as np, sys, os, json
from PIL import Image, ImageDraw

LIVRO = r"D:/Dropbox/Bancos_Dados/Censos/Censo 1960/2-Arquivos Auxiliares/Censo 1960 - Códigos dos municípios.pdf"
Z = 3.2

def linhas_da_pagina(a, W, H):
    bw = a < 150
    col = bw[:, int(0.14*W):int(0.50*W)]
    dens = col.sum(axis=1) > 2
    out, dentro, ini = [], False, 0
    for i in range(int(0.16*H), H):
        if dens[i] and not dentro: ini, dentro = i, True
        elif not dens[i] and dentro:
            if i - ini >= 9: out.append((ini, i))
            dentro = False
    return out

def recorta(p, doc):
    pg = doc[p-1]
    png = "tmp_folha.png"
    pg.get_pixmap(matrix=fitz.Matrix(Z, Z)).save(png)
    a = np.array(Image.open(png).convert("L")); H, W = a.shape
    # o limiar so define onde ha tinta; a imagem em si vai em cinza, porque
    # binarizar come o traco fino dos digitos nas paginas de scan mais fraco
    bw = a < 150
    saida = []
    for (y0, y1) in linhas_da_pagina(a, W, H):
        alto = max(4, int(0.55*(y1-y0)))
        # o nome acaba na ultima coluna escura da faixa de cima (os pontos ficam na base)
        sub = bw[y0:y0+alto, int(0.14*W):int(0.50*W)]
        c = np.where(sub.sum(axis=0) > 0)[0]
        if len(c) == 0: continue
        xa = int(0.14*W) + max(0, c[0]-6)
        xb = int(0.14*W) + min(sub.shape[1]-1, c[-1]+8)
        nome = a[max(0,y0-3):min(H,y1+3), xa:xb]
        # a faixa dos codigos vai inteira, na posicao original: e o que mantem os
        # digitos alinhados entre as linhas e legiveis depois da reducao da folha
        # os codigos vem colados ao nome, na zona nitida da folha: o de distrito
        # primeiro, o de municipio depois. Longe da margem direita eles sobrevivem
        # a reducao; a regua vertical da tabela sai fora do recorte.
        # os codigos sao datilografados um pouco acima da linha do nome: o recorte
        # precisa subir, senao o topo do digito some e o 0 vira U, o 7 vira 1
        def tira(f0, f1):
            ya, yb = max(0, y0-14), min(H, y1+5)
            faixa = bw[ya:yb, int(f0*W):int(f1*W)].copy()
            faixa[:, faixa.sum(axis=0) >= faixa.shape[0] - 2] = False
            cc = np.where(faixa.sum(axis=0) > 0)[0]
            if not len(cc): return np.full((max(1, yb-ya), 6), 255, dtype=np.uint8)
            return a[ya:yb, int(f0*W)+max(0,cc[0]-3):int(f0*W)+min(faixa.shape[1], cc[-1]+4)]
        cd_, cm_ = tira(0.845, 1.0), tira(0.60, 0.845)
        pedacos = [nome, cd_, cm_]
        h = max(x.shape[0] for x in pedacos)
        larg = sum(x.shape[1] for x in pedacos) + 34
        junta = np.full((h, larg), 255, dtype=np.uint8)
        x = 0
        for pe in pedacos:
            junta[:pe.shape[0], x:x+pe.shape[1]] = pe
            x += pe.shape[1] + 17
        rec = int((xa - 0.14*W) / (0.36*W) * 42)
        final = np.full((h, larg + 45), 255, dtype=np.uint8)
        final[:, rec:rec+larg] = junta
        saida.append((p, final))
    return saida

def monta(paginas, arquivo, colunas=2):
    doc = fitz.open(LIVRO)
    crops = []
    for p in paginas: crops += recorta(p, doc)
    doc.close()
    n = len(crops)
    porcol = (n + colunas - 1)//colunas
    larg = max(c.shape[1] for _, c in crops) + 34
    alt = max(sum(c.shape[0]+6 for _, c in crops[i*porcol:(i+1)*porcol]) for i in range(colunas)) + 24
    folha = Image.new("L", (larg*colunas, alt), 255)
    dr = ImageDraw.Draw(folha)
    for k in range(colunas):
        y = 12
        for i, (p, c) in enumerate(crops[k*porcol:(k+1)*porcol]):
            folha.paste(Image.fromarray(c), (k*larg + 30, y))
            dr.text((k*larg + 2, y + max(0, c.shape[0]//3)), f"{p}", fill=0)
            y += c.shape[0] + 6
        dr.line([(k*larg-4, 0), (k*larg-4, alt)], fill=160, width=2)
    folha.save(arquivo)
    return n, folha.size

if __name__ == "__main__":
    arq = sys.argv[1]
    pgs = [int(x) for x in sys.argv[2:]]
    n, tam = monta(pgs, arq)
    print(f"{arq}: {len(pgs)} paginas, {n} linhas, imagem {tam[0]}x{tam[1]}")
