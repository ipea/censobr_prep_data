"""Confere copias preservadas e relacoes publicadas; nao executa o pipeline."""
import argparse
import csv
import gzip
import hashlib
import json
import sqlite3
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def digest_stream(stream):
    h = hashlib.sha256()
    size = 0
    lines = 0
    while data := stream.read(1024 * 1024):
        h.update(data)
        size += len(data)
        lines += data.count(b"\n")
    return {"sha256": h.hexdigest(), "bytes": size, "linhas": lines}


def published_identities(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        rows = list(csv.DictReader(f))
    values = {(r["quadro"], r["regiao"], r["linha"], r["coluna"]): int(r["valor"]) for r in rows}
    checks = []
    # Norte/Centro-Oeste e derivado por diferenca: nao contar como prova independente.
    for region in ["Brasil", "Nordeste", "Leste", "Sul", "Norte e Centro-Oeste"]:
        for sex in ["total", "homens", "mulheres"]:
            total = values["1", region, "TOTAIS", sex]
            under5 = values["1", region, "0 a 4", sex]
            under10 = values["1", region, "5 a 9", sex]
            expected = total - under5 - under10
            q2 = values["2", region, "10 e mais", sex]
            q3 = values["3", region, "TOTAIS", sex]
            q4 = values["4", region, "TOTAIS", "total"] if sex == "total" else sum(
                values["4", region, "TOTAIS", group + "_" + sex]
                for group in ["agro", "ind", "outras", "inativas"])
            checks.append({"regiao": region, "sexo": sex,
                           "dominio_publicado": region != "Norte e Centro-Oeste",
                           "q1_total": total, "q1_0a4": under5, "q1_5a9": under10,
                           "q1_menos_0a9": expected, "q2_10mais": q2,
                           "q3_total": q3, "q4_total_ou_soma_sexo": q4,
                           "iguais": expected == q2 == q3 == q4})
    return checks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--archive", type=Path)
    ap.add_argument("--raw25", type=Path)
    ap.add_argument("--uf", nargs="+")
    ap.add_argument("--render", action="store_true")
    ap.add_argument("--index127", type=Path)
    args = ap.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / "tmp"):
        raise ValueError("Saida deve ficar sob tmp")
    out.mkdir(parents=True, exist_ok=False)
    result = {"modo": "somente leitura das fontes; nao aplica correcoes", "copias": []}
    raw = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"
    with raw.open("rb") as f:
        result["hholda_local"] = digest_stream(f)
    content_lf = raw.read_bytes().replace(b"\r\n", b"\n")
    result["hholda_git_blob_lf"] = hashlib.sha1(
        ("blob " + str(len(content_lf)) + "\0").encode() + content_lf).hexdigest()
    result["hholda_bytes_lf"] = len(content_lf)
    del content_lf
    if args.index127:
        connection = sqlite3.connect(args.index127.resolve().as_uri() + "?mode=ro", uri=True)
        result["idade_ignorada_presentes_retidos_por_uf"] = dict(connection.execute("""
            SELECT uf,count(*) FROM pessoas WHERE excluida=0 AND substr(corrigido,21,1)='9'
            AND substr(corrigido,19,1) IN ('1','2','5','6') GROUP BY uf
        """))
        result["idade_ignorada_presentes_retidos_total"] = sum(result["idade_ignorada_presentes_retidos_por_uf"].values())
        result["limite_contagem_idade"] = "Contagem de registros apos decisoes atuais, nao estimativa populacional; repeticoes pendentes preservadas."
        connection.close()
    if args.archive:
        with zipfile.ZipFile(args.archive) as archive:
            result["archive_name"] = args.archive.name
            with archive.open("1%/HHOLDA.txt") as f:
                result["hholda_pacote_recebido"] = digest_stream(f)
            result["hholda_copias_iguais"] = result["hholda_local"] == result["hholda_pacote_recebido"]
            result["membros25_no_pacote"] = [i.filename for i in archive.infolist() if i.filename.endswith(".Z")]
            result["scripts_sas"] = []
            for name in archive.namelist():
                if name.endswith((".sas", ".txt")) and name != "1%/HHOLDA.txt":
                    data = archive.read(name)
                    text = data.decode("latin1")
                    hits = [{"linha": i, "texto": t} for i, t in enumerate(text.splitlines(), 1)
                            if any(term in t.lower() for term in ["dupli", "hholda", "_n_", "delete", "v208", "v216"])]
                    result["scripts_sas"].append({"nome": name, "sha256": hashlib.sha256(data).hexdigest(), "trechos": hits})
    if args.raw25:
        sources = sorted((ROOT / "data/release_legacy").glob("Censo.1960.amostra.25porcento.*.gz"))
        for source in sources:
            uf = source.name.split(".")[-2]
            if args.uf and uf not in args.uf:
                continue
            with gzip.open(source, "rb") as f:
                current = digest_stream(f)
            with (args.raw25 / uf).open("rb") as f:
                preserved = digest_stream(f)
            result["copias"].append({"uf": uf, "gzip_local_descomprimido": current,
                                      "copia_preservada_descomprimida": preserved, "iguais": current == preserved})
            print(uf, current["linhas"], current == preserved, flush=True)
    published = ROOT / "references/censo_1960_resultados_preliminares_1965.csv"
    result["identidades_publicadas"] = published_identities(published)
    with published.open("rb") as f:
        result["transcricao"] = digest_stream(f)
    if args.render:
        import fitz
        pdf = ROOT / "references/fontes_1960/1965_resultados_preliminares_vol2.pdf"
        with pdf.open("rb") as f:
            result["pdf"] = digest_stream(f)
        doc = fitz.open(pdf)
        result["paginas_pdf"] = len(doc)
        result["recortes"] = []
        for page_number in [20, 21, 22, 23, 28, 29, 30, 31, 36, 37, 38, 39, 44, 45, 46, 47]:
            page = doc[page_number - 1]
            name = f"preliminar_p{page_number:02d}_cabecalho.png"
            # Cabecalhos, primeiras faixas e totais; a faixa final esta no recorte separado.
            clip = fitz.Rect(0, 0, page.rect.width, page.rect.height * .45)
            page.get_pixmap(matrix=fitz.Matrix(1.4, 1.4), clip=clip).save(out / name)
            result["recortes"].append({"pagina_pdf": page_number, "arquivo": name})
        page = doc[19]
        page.get_pixmap(matrix=fitz.Matrix(1.4, 1.4)).save(out / "preliminar_p20_inteira.png")
    (out / "fontes.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print("identidades", sum(c["iguais"] for c in result["identidades_publicadas"]), flush=True)


if __name__ == "__main__":
    main()
