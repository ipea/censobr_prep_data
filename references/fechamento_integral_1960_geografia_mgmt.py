"""Rele todos os cartoes25 de MG/MT e documenta os dois codigos ainda sem nome."""
from collections import Counter, defaultdict
import gzip
import hashlib
import json
from pathlib import Path
import fitz

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/geografia_mgmt"

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=False)
    cases = []
    for uf, municipality in [("mg", "4096"), ("mt", "9162")]:
        path = ROOT / f"data/release_legacy/Censo.1960.amostra.25porcento.{uf}.gz"
        before = hashlib.file_digest(path.open("rb"), "sha256").hexdigest()
        cards = []
        current = None
        for number, text in enumerate(gzip.open(path, "rt", encoding="latin1"), 1):
            text = text.rstrip("\r\n")
            if text[8:10] == "00":
                current = None
                if text[29:33] == municipality:
                    current = {"linha": number, "texto": text, "chave": text[:8],
                        "pasta": text[:5], "distrito": text[33:35], "situacao": text[35:36],
                        "pessoas": 0, "presentes": 0, "residentes": 0}
                    cards.append(current)
            elif current is not None:
                assert current["chave"] == text[:8]
                current["pessoas"] += 1
                current["presentes"] += int(text[14] in "1256")
                current["residentes"] += int(text[14] in "1234")
        assert hashlib.file_digest(path.open("rb"), "sha256").hexdigest() == before
        summary = defaultdict(Counter)
        for card in cards:
            key = (card["distrito"], card["pasta"], card["situacao"])
            summary[key].update({k: card[k] for k in ["pessoas", "presentes", "residentes"]})
            summary[key].update(domicilios=1)
        cases.append({"uf": uf, "municipio": municipality, "fonte": path.relative_to(ROOT).as_posix(),
            "sha256": before, "registros_uf_examinados": number, "cartoes": cards,
            "resumo": [{"distrito": k[0], "pasta": k[1], "situacao": k[2], **v} for k, v in sorted(summary.items())]})
        print(uf, "domicilios", len(cards), "distritos", Counter(c["distrito"] for c in cards), flush=True)
    doc = fitz.open(ROOT / "tmp/fechamento_integral_1960/geografia_fontes/dtb1960.pdf")
    for page in [139, 140]:
        doc[page-1].get_pixmap(dpi=180).save(OUT / f"dtb1960_pdf{page}.png")
    with (OUT / "cartoes_e_contagens.json").open("x", encoding="utf-8") as stream:
        json.dump({"casos": cases, "nota": "Contagens nao identificam nomes. Peso4 nao demonstra fracao efetiva municipal nem motivo de sobrerrepresentacao."}, stream, ensure_ascii=False, indent=2)
