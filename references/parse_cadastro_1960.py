# -*- coding: utf-8 -*-
"""Le a transcricao integral do Codigo de Zonas Fisiograficas, Municipios e
Distritos de 1960 e devolve a tabela de distritos."""
import csv
import io
import os
import re
import unicodedata

F = r"C:/Users/antro/Documents/Codex/2026-09-16/ess/outputs/Censo_1960_Transcricao_integral.html"
S = (r"C:\Users\antro\AppData\Local\Temp\claude"
     r"\d--Dropbox-Software-R-Packages-censobr-e-prepData-censobr-prep-data"
     r"\a92948e6-3172-480f-8e50-830e5966ad4b\scratchpad")


def texto(x):
    x = re.sub(r"<[^>]+>", "", x)
    x = x.replace("&nbsp;", " ").replace("&amp;", "&").replace("&#39;", "'")
    return re.sub(r"\s+", " ", x).strip()


t = io.open(F, encoding="utf-8").read()
secs = re.findall(r"<section.*?</section>", t, re.S)

linhas = []
uf_nome = uf_cod = None
zona_cod = zona_nome = None
mun_cod = mun_nome = None
paginas_uf = {}

for sec in secs:
    pagina = int(re.search(r'id="p(\d+)"', sec).group(1))
    h2 = re.search(r"<h2>(.*?)</h2>", sec, re.S)
    if h2:
        uf_nome = texto(h2.group(1))
    # o cabecalho da pagina de abertura traz o codigo da UF: "... - 00"
    for p in re.findall(r'<p class="source">(.*?)</p>', sec, re.S):
        m = re.match(r"^(.*?)\s*[-–]\s*(\d{2})$", texto(p))
        if m and m.group(1).isupper() and len(m.group(1)) > 3:
            uf_cod = int(m.group(2))
    paginas_uf.setdefault(uf_nome, uf_cod)

    for tr in re.findall(r"<tr\b[^>]*>.*?</tr>", sec, re.S):
        if "<th" in tr:
            continue
        tds = [texto(x) for x in re.findall(r"<td\b[^>]*>(.*?)</td>", tr, re.S)]
        if len(tds) != 4:
            continue
        nome, z, m, d = tds
        # o transcritor marcou com ? o que nao conseguiu ler com certeza
        duvida = "?" in (z + m + d)
        z, m, d = (re.sub(r"[^0-9]", "", x) for x in (z, m, d))
        # na pagina das unidades especiais uma linha so traz zona, municipio e
        # distrito ao mesmo tempo, entao os tres casos se testam em sequencia e
        # nao em alternativa
        if z:
            zona_cod, zona_nome = z, nome
        if m:
            mun_cod, mun_nome = m, nome
        if d:
            linhas.append({
                "uf60": uf_cod, "nome_uf": uf_nome,
                "zona_cod": zona_cod, "zona": zona_nome,
                "code_muni_1960": int(mun_cod) if mun_cod else None,
                "name_muni_1960": mun_nome,
                "code_district_1960": int(d),
                "name_district_1960": nome,
                "duvida": duvida,
                "pagina": pagina})

print("distritos lidos:", len(linhas))
print("com marca de duvida:", sum(1 for x in linhas if x["duvida"]))
print("sem codigo de municipio:", sum(1 for x in linhas if not x["code_muni_1960"]))
print("unidades da federacao:", len(paginas_uf))
for k, v in paginas_uf.items():
    print("   %-28s uf60=%s" % (k, v))

dest = os.path.join(S, "cadastro_1960.csv")
with io.open(dest, "w", encoding="utf-8", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(linhas[0].keys()))
    w.writeheader()
    w.writerows(linhas)
print("\ngravado:", dest)
