"""Guarda fontes publicas para conferir pendencias geograficas, sem mudar guias."""
import hashlib
import json
from pathlib import Path
import requests

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/geografia_fontes"
SOURCES = {
    "dtb1960.pdf": "https://biblioteca.ibge.gov.br/visualizacao/livros/liv13611.pdf",
    "itutinga.pdf": "https://biblioteca.ibge.gov.br/visualizacao/dtb/minasgerais/itutinga.pdf",
    "livramento.pdf": "https://biblioteca.ibge.gov.br/visualizacao/dtb/matogrosso/nossasenhoradolivramento.pdf",
    "livramento_turismo.pdf": "https://www.nossasenhoradolivramento.mt.gov.br/fotos_secretarias_downloads/20.pdf",
}

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    record = []
    for name, url in SOURCES.items():
        target = OUT / name
        if target.exists():
            raise FileExistsError(target)
        try:
            response = requests.get(url, timeout=(15, 45))
            response.raise_for_status()
            data = response.content
            if not data.startswith(b"%PDF-") or len(data) > 40_000_000:
                raise ValueError("Resposta nao e PDF dentro do limite")
            with target.open("xb") as stream:
                stream.write(data)
            result = {"arquivo": target.relative_to(ROOT).as_posix(), "url": url,
                "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}
        except Exception as exc:
            result = {"url": url, "erro": str(exc)}
        record.append(result)
        print(json.dumps(result, ensure_ascii=False), flush=True)
    with (OUT / "consultas.json").open("x", encoding="utf-8") as stream:
        json.dump(record, stream, ensure_ascii=False, indent=2)
