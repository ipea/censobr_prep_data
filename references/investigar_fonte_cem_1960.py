"""Consulta o arquivo publico ligado pelo CEM, sem login nem formulario de pedido."""
import hashlib
import json
from pathlib import Path
import tempfile

import requests

root = Path(__file__).resolve().parents[1]
base = root / "tmp/fechamento_integral_1960/fonte_cem"
base.mkdir(parents=True, exist_ok=True)
out = Path(tempfile.mkdtemp(prefix="consulta_", dir=base))
print(out, flush=True)
url = "https://drive.usercontent.google.com/download?id=1ehlPo10QweI9xCj_3L6QnYRNfEnGP1nv&export=download"
with requests.get(url, stream=True, timeout=(15, 45)) as response:
    info = {"origem": "https://centrodametropole.fflch.usp.br/pt-br/node/8857",
            "url": url, "status": response.status_code,
            "content_type": response.headers.get("content-type"), "bytes": 0}
    sha = hashlib.sha256()
    with (out / "resposta.download").open("xb") as stream:
        for chunk in response.iter_content(1024 * 1024):
            info["bytes"] += len(chunk)
            if info["bytes"] > 150 * 1024**2:
                raise ValueError("Resposta acima do limite de 150 MiB; examinar cabecalhos")
            stream.write(chunk)
            sha.update(chunk)
    info["sha256"] = sha.hexdigest()
    with (out / "consulta.json").open("x", encoding="utf-8") as stream:
        json.dump(info, stream, indent=2)
    print(json.dumps(info))
