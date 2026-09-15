# Transcreve as tabelas por unidade da federação do volume nacional dos resultados definitivos do Censo de 1960
# (IBGE, Censo Demográfico de 1960 — Brasil, Série Nacional, vol. I; Internet Archive, item censodem1960br) e grava
# references/censo_1960_resultados_definitivos_serie_nacional.csv.
#
# Tabelas: 32 (condição de presença), 33 (grupos de idade por sexo), 34 (situação do domicílio por sexo), 37 (cor
# por sexo), 40 (alfabetização de 5 anos e mais por sexo) e 7 dos domicílios (domicílios particulares permanentes e
# moradores por situação), todas "segundo as Regiões Fisiográficas e as Unidades da Federação": 34 linhas (Brasil,
# 5 regiões, 28 unidades) por tabela.
#
# Método. Duas leituras de OCR independentes — a do Internet Archive (ABBYY, arquivo censodem1960br_djvu.xml, com
# coordenadas) e a do Tesseract sobre as páginas renderizadas a 300 dpi do PDF versionado — são lidas com a mesma
# lógica: os números são alinhados à direita em cada coluna e escritos em blocos de três dígitos; as bordas
# direitas das colunas vêm das caixas do Tesseract e um bloco pertence à coluna em que termina (Tesseract) ou
# começa (ABBYY, cujas caixas avançam sobre o espaço). Onde as leituras divergem, decide a aritmética: homens +
# mulheres = total, partes = total, UFs = região, regiões = Brasil, faixas de idade = total; onde só falta uma
# célula, ela é deduzida. As poucas células em que as duas leituras erraram juntas foram conferidas na página e
# estão em CORRECOES, com a leitura errada anotada.
#
# Uso, da raiz do projeto:  python references/transcricao_1960_serie_nacional.py [--tmp DIR] [--tesseract EXE]
#                           [--tessdata DIR]
# Precisa de Python 3 com PyMuPDF (fitz) e do Tesseract 5 com o modelo "por".
import re, io, csv, html, json, os, sys, itertools, statistics, subprocess, urllib.request, argparse
from collections import Counter

ap = argparse.ArgumentParser()
ap.add_argument("--tmp", default="data_raw/serie_nacional_1960")
ap.add_argument("--tesseract", default="C:/Program Files/Tesseract-OCR/tesseract.exe")
ap.add_argument("--tessdata", default=None)
ap.add_argument("--pdf", default="references/fontes_1960/1960_serie_nacional_vol1_brasil.pdf")
ap.add_argument("--out", default="references/censo_1960_resultados_definitivos_serie_nacional.csv")
args = ap.parse_args()
TMP = args.tmp; os.makedirs(TMP, exist_ok=True)

# página do pdf -> (tabela, colunas)
PAGES = {
  121: ("32", ["presente_total", "presente_homens", "presente_mulheres", "residente_total", "residente_homens", "residente_mulheres"]),
  123: ("33", ["total_total", "total_homens", "total_mulheres", "0 a 4_homens", "0 a 4_mulheres", "5 a 9_homens", "5 a 9_mulheres"]),
  124: ("33", [f"{f}_{s}" for f in ("10 a 14", "15 a 19", "20 a 24", "25 a 29", "30 a 39", "40 a 49") for s in ("homens", "mulheres")]),
  125: ("33", [f"{f}_{s}" for f in ("50 a 59", "60 a 69", "70 e mais", "ignorada") for s in ("homens", "mulheres")]),
  126: ("34", [f"{f}_{s}" for f in ("total", "urbana", "rural") for s in ("total", "homens", "mulheres")]),
  131: ("37", [f"{f}_{s}" for f in ("total", "brancos", "pretos", "amarelos", "pardos", "sem declaracao") for s in ("homens", "mulheres")]),
  139: ("40", [f"{f}_{s}" for f in ("5 e mais", "sabem", "nao sabem") for s in ("total", "homens", "mulheres")]),
  169: ("dom7", [f"{f}_{s}" for f in ("total", "urbana", "rural") for s in ("domicilios", "pessoas")]),
}
TABS = {"32": [121], "33": [123, 124, 125], "34": [126], "37": [131], "40": [139], "dom7": [169]}
UNIDADES = ["Brasil", "Norte", "Rondônia", "Acre", "Amazonas", "Roraima", "Pará", "Amapá", "Nordeste", "Maranhão", "Piauí", "Ceará", "Rio Grande do Norte",
            "Paraíba", "Pernambuco", "Alagoas", "Fernando de Noronha", "Leste", "Sergipe", "Bahia", "Minas Gerais", "Serra dos Aimorés", "Espírito Santo",
            "Rio de Janeiro", "Guanabara", "Sul", "São Paulo", "Paraná", "Santa Catarina", "Rio Grande do Sul", "Centro-Oeste", "Mato Grosso", "Goiás", "Distrito Federal"]
REG = {1: list(range(2, 8)), 8: list(range(9, 17)), 17: list(range(18, 25)), 25: list(range(26, 30)), 30: list(range(31, 34))}
UF60 = {"Rondônia": 0, "Acre": 1, "Amazonas": 2, "Roraima": 3, "Pará": 4, "Amapá": 6, "Maranhão": 10, "Piauí": 12, "Ceará": 14, "Rio Grande do Norte": 17,
        "Paraíba": 19, "Pernambuco": 21, "Fernando de Noronha": 24, "Alagoas": 25, "Sergipe": 30, "Bahia": 31, "Minas Gerais": 40, "Serra dos Aimorés": 50,
        "Espírito Santo": 51, "Rio de Janeiro": 52, "Guanabara": 54, "São Paulo": 60, "Paraná": 71, "Santa Catarina": 74, "Rio Grande do Sul": 81,
        "Mato Grosso": 91, "Goiás": 94, "Distrito Federal": 97}
# as onze unidades apuradas pelo plano original (universo + amostra); as demais, so pelo Boletim de Amostra (25%)
UNIVERSO = {"Rondônia", "Roraima", "Amapá", "Acre", "Amazonas", "Pará", "Maranhão", "Piauí", "Espírito Santo", "Guanabara", "Santa Catarina"}
# celulas em que as duas leituras erraram e a aritmetica nao bastou: valor conferido na pagina
CORRECOES = {
  ("33", 4, "0 a 4_homens"): (67083, "OCR 67 063 / 47 083"), ("33", 4, "50 a 59_homens"): (15006, "OCR leu so '15'"),
  ("33", 3, "10 a 14_homens"): (10569, "OCR 10 559 / 569"), ("33", 3, "25 a 29_homens"): (5700, "OCR 5 700 / 700; deducao errada"),
  ("33", 2, "70 e mais_homens"): (378, "OCR 3 786 / 376"), ("33", 2, "25 a 29_homens"): (3781, "OCR 3 761"),
  ("33", 32, "25 a 29_mulheres"): (70404, "OCR 70 / 70 404"), ("33", 32, "40 a 49_mulheres"): (69145, "OCR 49 145 nas duas leituras"),
  ("33", 18, "20 a 24_mulheres"): (31468, "OCR 31 463 nas duas leituras"),
  ("37", 21, "pretos_homens"): (18868, "OCR 68 868"), ("37", 21, "pardos_homens"): (82090, "OCR 32 090 / 92 090"),
}
TR = {"O": "0", "o": "0", "D": "0", "Q": "0", "U": "0", "l": "1", "I": "1", "i": "1", "|": "1", "!": "1", "S": "5", "s": "5", "Z": "2", "z": "2", "B": "8", "T": "7",
      "G": "6", "b": "6", "q": "9", "g": "9", "A": "4", "C": "0", "«": "4", "ã": "3", "t": "1"}
CONF = ("ok", "manual", "aritmetica", "deduzido", "uma_ok", "zero")

# ---- as duas leituras ---------------------------------------------------------------------------------------------
xml_path = os.path.join(TMP, "censodem1960br_djvu.xml")
if not os.path.exists(xml_path):
    print("baixando o OCR do Internet Archive...")
    req = urllib.request.Request("https://archive.org/download/censodem1960br/censodem1960br_djvu.xml", headers={"User-Agent": "Mozilla/5.0"})
    io.open(xml_path, "wb").write(urllib.request.urlopen(req, timeout=600).read())
XML = re.split(r"<OBJECT ", io.open(xml_path, encoding="utf-8", errors="replace").read())[1:]
import fitz
doc = fitz.open(args.pdf)
for p in PAGES:
    png = os.path.join(TMP, "p-%03d.png" % p); tsv = os.path.join(TMP, "p-%03d.tsv" % p)
    if not os.path.exists(png): doc[p - 1].get_pixmap(dpi=300).save(png)
    if not os.path.exists(tsv):
        cmd = [args.tesseract, png, png[:-4], "-l", "por", "--psm", "6", "tsv"]
        if args.tessdata: cmd[3:3] = ["--tessdata-dir", args.tessdata]
        subprocess.run(cmd, check=True, capture_output=True)

def chunk(txt):
    t = re.sub(r"[ .,]", "", txt.strip(" .,;:*'`\"»-"))
    if not t or len(t) > 9: return None
    mapped = "".join(TR.get(c, c) for c in t)
    if not mapped.isdigit(): return None
    return mapped, (mapped != t), bool(re.search(r"\d", t))

def tokens_tesseract(p):
    out = []
    for r in csv.DictReader(io.open(os.path.join(TMP, "p-%03d.tsv" % p), encoding="utf-8", errors="replace"), delimiter="\t", quoting=csv.QUOTE_NONE):
        if r["level"] != "5" or not r["text"].strip(): continue
        l, t, w, h = int(r["left"]), int(r["top"]), int(r["width"]), int(r["height"])
        out.append((r["text"].strip(), l, t, l + w, t + h))
    return out

def tokens_abbyy(p):
    out = []
    for m in re.finditer(r'<WORD coords="(\d+),(\d+),(\d+),(\d+)"[^>]*>([^<]*)</WORD>', XML[p - 1]):
        x1, yb, x2, yt = map(int, m.groups()[:4]); txt = html.unescape(m.group(5)).strip()
        if txt: out.append((txt, x1, yt, x2, yb))
    return out

def linhas(tokens, tol=19):
    toks = sorted(tokens, key=lambda t: (t[2] + t[4]) / 2); out = []
    for t in toks:
        yc = (t[2] + t[4]) / 2
        if out and abs(yc - out[-1]["y"]) <= tol:
            out[-1]["t"].append(t); out[-1]["y"] = statistics.mean((u[2] + u[4]) / 2 for u in out[-1]["t"])
        else: out.append({"y": yc, "t": [t]})
    for l in out: l["t"].sort(key=lambda t: t[1])
    return out

def y_cabecalho(ls):
    ys = [l["y"] for l in ls if re.search(r"HOMENS|MULHERES|TOTAL|MORADORES|DOMIC|PESSOAS", " ".join(t[0] for t in l["t"]).upper()) and l["y"] < 900]
    return max(ys) if ys else 0

def blocos_da_linha(l):
    # blocos numericos: com digito, ou so letras confundiveis quando colados (<= 22 px) a um bloco com digito
    out = []; ts = l["t"]
    for i, t in enumerate(ts):
        c = chunk(t[0])
        if c is None: continue
        if not c[2]:
            prox = ts[i + 1] if i + 1 < len(ts) else None; ant = ts[i - 1] if i > 0 else None
            ok = (prox is not None and chunk(prox[0]) and chunk(prox[0])[2] and prox[1] - t[3] <= 22) or \
                 (ant is not None and chunk(ant[0]) and chunk(ant[0])[2] and t[1] - ant[3] <= 22)
            if not ok: continue
        out.append((c[0], t[1], t[3], c[1]))
    return out

def ancoras(tokens_t, K, y0):
    # bordas direitas das colunas: onde terminam os ultimos blocos dos numeros (Tesseract); a coluna do numero de
    # ordem (1 a 34) fica de fora
    rights = []
    for l in linhas(tokens_t):
        if l["y"] <= y0 + 30: continue
        b = blocos_da_linha(l)
        for i, x in enumerate(b):
            if i == len(b) - 1 or b[i + 1][1] - x[2] >= 26: rights.append((x[2], int(x[0])))
    cnt = Counter(round(x / 12) * 12 for x, _ in rights); maxv = {}
    for x, v in rights: maxv[round(x / 12) * 12] = max(maxv.get(round(x / 12) * 12, 0), v)
    sel = []
    for x, n in sorted(cnt.items(), key=lambda kv: -kv[1]):
        if n < 8: break
        if maxv[x] <= 34: continue
        if all(abs(x - s) >= 75 for s in sel): sel.append(x)
        if len(sel) == K: break
    return sorted(sel)

def grade(tokens, K, R, y0, por_direita):
    rows = []
    for l in linhas(tokens):
        if l["y"] <= y0 + 30: continue
        b = blocos_da_linha(l)
        if len(b) < 2: continue
        cells = {}
        for val, x0, x1, fl in b:
            xx = x1 if por_direita else x0
            c = next((k for k in range(K) if (R[k - 1] + (8 if por_direita else 5) if k else R[0] - 260) < xx <= R[k] + (10 if por_direita else -8)), None)
            if c is None: continue
            cells.setdefault(c, []).append((x0, val, fl))
        if not cells: continue
        rows.append({"y": l["y"], "cells": {c: "".join(v[1] for v in sorted(vs)) for c, vs in cells.items()}})
    return rows

def alinha(rows_t, rows_a):
    pares = []; usados = set()
    for r in rows_t:
        j = min(range(len(rows_a)), key=lambda k: abs(rows_a[k]["y"] - r["y"]), default=None)
        if j is not None and abs(rows_a[j]["y"] - r["y"]) <= 18 and j not in usados: pares.append((r["y"], r, rows_a[j])); usados.add(j)
        else: pares.append((r["y"], r, None))
    for j, r in enumerate(rows_a):
        if j not in usados: pares.append((r["y"], None, r))
    pares.sort(key=lambda x: x[0]); out = []
    for y, rt, ra in pares:
        if out and y - out[-1][0] < 26:
            prev = list(out[-1])
            for k, r in ((1, rt), (2, ra)):
                if r is None: continue
                if prev[k] is None: prev[k] = r
                else: prev[k]["cells"].update({c: v for c, v in r["cells"].items() if c not in prev[k]["cells"]})
            out[-1] = tuple(prev)
        else: out.append((y, rt, ra))
    return out

# ---- celulas com candidatos ----------------------------------------------------------------------------------------
cel = {}; cols_tab = {t: [] for t in TABS}
for p, (tab, cols) in PAGES.items():
    K = len(cols); cols_tab[tab] += cols
    tt = tokens_tesseract(p); ta = tokens_abbyy(p); y0 = y_cabecalho(linhas(tt))
    A = ancoras(tt, K, y0)
    assert len(A) == K, "p.%d: %d ancoras para %d colunas" % (p, len(A), K)
    pares = alinha(grade(tt, K, A, y0, True), grade(ta, K, A, y_cabecalho(linhas(ta)), False))
    assert len(pares) == 34, "p.%d: %d linhas" % (p, len(pares))
    for i, (y, rt, ra) in enumerate(pares):
        for c, col in enumerate(cols):
            vt = rt["cells"].get(c) if rt else None; va = ra["cells"].get(c) if ra else None
            cands = {int(v) for v in (vt, va) if v}
            key = (tab, i, col)
            if key in CORRECOES: cel[key] = {"cands": {CORRECOES[key][0]}, "val": CORRECOES[key][0], "st": "manual"}
            elif len(cands) == 1 and vt and va: cel[key] = {"cands": cands, "val": next(iter(cands)), "st": "ok"}
            elif len(cands) == 1: cel[key] = {"cands": cands, "val": None, "st": "uma"}
            elif not cands: cel[key] = {"cands": {0}, "val": None, "st": "vazio"}
            else: cel[key] = {"cands": cands, "val": None, "st": "conflito"}

# ---- as equacoes -------------------------------------------------------------------------------------------------
def eq_linha(tab):
    cols = cols_tab[tab]; eqs = []
    if tab == "32":
        for pref in ("presente", "residente"): eqs.append(([f"{pref}_homens", f"{pref}_mulheres"], f"{pref}_total"))
    if tab == "33":
        eqs.append((["total_homens", "total_mulheres"], "total_total"))
        for s in ("homens", "mulheres"): eqs.append(([x for x in cols if x.endswith("_" + s) and not x.startswith("total_")], f"total_{s}"))
    if tab == "34":
        for pref in ("total", "urbana", "rural"): eqs.append(([f"{pref}_homens", f"{pref}_mulheres"], f"{pref}_total"))
        for s in ("total", "homens", "mulheres"): eqs.append(([f"urbana_{s}", f"rural_{s}"], f"total_{s}"))
    if tab == "37":
        for s in ("homens", "mulheres"): eqs.append(([f"{x}_{s}" for x in ("brancos", "pretos", "amarelos", "pardos", "sem declaracao")], f"total_{s}"))
    if tab == "40":   # sabem + nao sabem < 5 e mais: a parcela sem declaracao nao foi publicada
        for pref in ("5 e mais", "sabem", "nao sabem"): eqs.append(([f"{pref}_homens", f"{pref}_mulheres"], f"{pref}_total"))
    if tab == "dom7":
        for s in ("domicilios", "pessoas"): eqs.append(([f"urbana_{s}", f"rural_{s}"], f"total_{s}"))
    return eqs

def equacoes(tab):
    eqs = []
    for i in range(34):
        for partes, total in eq_linha(tab): eqs.append(([(tab, i, x) for x in partes], (tab, i, total)))
    for col in cols_tab[tab]:
        for r, ufs in REG.items(): eqs.append(([(tab, u, col) for u in ufs], (tab, r, col)))
        eqs.append(([(tab, r, col) for r in REG], (tab, 0, col)))
    return eqs

def resolve(tab):
    eqs = equacoes(tab); mudou = True; rodadas = 0
    while mudou and rodadas < 20:
        mudou = False; rodadas += 1
        for partes, total in eqs:
            keys = partes + [total]; inc = [k for k in keys if cel[k]["st"] not in CONF]
            if not inc or len(inc) > 4: continue
            sol = []
            for esc in itertools.product(*[sorted(cel[k]["cands"]) for k in inc]):
                v = {k: cel[k]["val"] for k in keys}
                for k, e in zip(inc, esc): v[k] = e
                if sum(v[k] for k in partes) == v[total]: sol.append(esc)
            if len(sol) == 1:
                for k, e in zip(inc, sol[0]):
                    cel[k]["val"] = e; cel[k]["st"] = {"uma": "uma_ok", "vazio": "zero", "conflito": "aritmetica"}[cel[k]["st"]]; mudou = True
            elif not sol and len(inc) == 1:
                k = inc[0]
                novo = sum(cel[q]["val"] for q in partes) if k == total else cel[total]["val"] - sum(cel[q]["val"] for q in partes if q != k)
                if novo is not None and novo >= 0: cel[k]["val"] = novo; cel[k]["st"] = "deduzido"; mudou = True

for tab in TABS:
    resolve(tab)
    falhas = [(partes, total) for partes, total in equacoes(tab)
              if None in [cel[k]["val"] for k in partes + [total]] or sum(cel[k]["val"] for k in partes) != cel[total]["val"]]
    pend = [k for k, v in cel.items() if k[0] == tab and v["st"] not in CONF]
    print("tabela %-4s equacoes que nao fecham: %d | celulas sem valor: %d" % (tab, len(falhas), len(pend)))
    assert not falhas and not pend, "tabela %s: conferir na pagina %s %s" % (tab, falhas[:3], pend[:5])
for i in (0, 1, 8, 17, 25, 30):
    tot = {cel[("32", i, "presente_total")]["val"], cel[("33", i, "total_total")]["val"], cel[("34", i, "total_total")]["val"],
           cel[("37", i, "total_homens")]["val"] + cel[("37", i, "total_mulheres")]["val"]}
    assert len(tot) == 1, "totais divergentes em %s: %s" % (UNIDADES[i], tot)

# ---- o csv -------------------------------------------------------------------------------------------------------
REGIAO_DE = {}; atual = None
for i, u in enumerate(UNIDADES):
    if i == 0: continue
    if u in ("Norte", "Nordeste", "Leste", "Sul", "Centro-Oeste"): atual = u
    REGIAO_DE[u] = atual
PAG = {"32": {"": 80}, "33": {"total": 82, "0 a 4": 82, "5 a 9": 82, "10 a 14": 83, "15 a 19": 83, "20 a 24": 83, "25 a 29": 83, "30 a 39": 83, "40 a 49": 83,
       "50 a 59": 84, "60 a 69": 84, "70 e mais": 84, "ignorada": 84}, "34": {"": 85}, "37": {"": 90}, "40": {"": 98}, "dom7": {"": 128}}
TABELA = {"32": "32", "33": "33", "34": "34", "37": "37", "40": "40", "dom7": "7"}
rows = []
for (tab, i, col), v in cel.items():
    u = UNIDADES[i]; item, sexo = col.rsplit("_", 1); medida = ""
    if tab == "dom7": medida, sexo = sexo, ""
    nivel = "brasil" if i == 0 else ("regiao" if REGIAO_DE[u] == u else "uf")
    rows.append(dict(tabela=TABELA[tab], nivel=nivel, regiao="" if i == 0 else REGIAO_DE[u], uf60="" if nivel != "uf" else UF60[u], nome=u, item=item, sexo=sexo,
                     medida=medida, valor=v["val"], pagina=PAG[tab].get(item, PAG[tab].get("", "")),
                     fonte="" if nivel != "uf" else ("universo" if u in UNIVERSO else "amostra 25%"), status=v["st"],
                     nota=CORRECOES[(tab, i, col)][1] if (tab, i, col) in CORRECOES else ""))
ordem_t = {"32": 0, "33": 1, "34": 2, "37": 3, "40": 4, "7": 5}
rows.sort(key=lambda r: (ordem_t[r["tabela"]], UNIDADES.index(r["nome"]), r["pagina"], r["item"], r["sexo"], r["medida"]))
with io.open(args.out, "w", encoding="utf-8-sig", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=["tabela", "nivel", "regiao", "uf60", "nome", "item", "sexo", "medida", "valor", "pagina", "fonte", "status", "nota"])
    w.writeheader(); w.writerows(rows)
print("gravado", args.out, "|", len(rows), "linhas |", dict(Counter(r["status"] for r in rows)))
