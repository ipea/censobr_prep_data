"""Confere outras copias locais do bruto e as paginas sobre estado conjugal."""
import argparse
import hashlib
import json
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive-root', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / 'tmp'):
        raise ValueError('Saida deve ficar em tmp')
    out.mkdir(parents=True, exist_ok=False)
    local = ROOT / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt'
    expected = hashlib.sha256(local.read_bytes()).hexdigest()
    copies = []
    for path in sorted(args.archive_root.rglob('HHOLDA.txt')):
        content = path.read_bytes()
        checksum = hashlib.sha256(content).hexdigest()
        copies.append({'arquivo_relativo_ao_acervo': str(path.relative_to(args.archive_root)),
                       'bytes': len(content), 'linhas': content.count(b'\n'),
                       'sha256': checksum, 'identico_ao_bruto_local': checksum == expected})
        del content
    pdf = ROOT / 'references/fontes_1960/1965_resultados_preliminares_vol2.pdf'
    pages = []
    with fitz.open(pdf) as doc:
        for n in [7, 23]:
            name = 'q5_pdf_' + str(n + 1) + '.png'
            doc[n].get_pixmap(matrix=fitz.Matrix(1.5, 1.5)).save(out / name)
            pages.append({'pagina_pdf': n + 1, 'texto_extraido': doc[n].get_text(), 'imagem': name})
    result = {'copias_bruto': copies, 'bruto_sha256': expected,
              'pdf': str(pdf.relative_to(ROOT)), 'pdf_sha256': hashlib.sha256(pdf.read_bytes()).hexdigest(),
              'paginas_q5': pages,
              'conclusao_limitada': 'As copias iguais nao recuperam os danos. As paginas de estado conjugal dizem residentes de15anos emais, sem esclarecer idade ignorada. Nao comparar diretamente com presentes nem estender a identidade deq3/q4.'}
    (out / 'fontes_adicionais.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'copias': len(copies), 'copias_iguais': sum(x['identico_ao_bruto_local'] for x in copies), 'paginas': [8, 24]}))


if __name__ == '__main__':
    main()
