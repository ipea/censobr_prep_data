"""Busca literal dos fragmentos perdidos, sem reconstruir pessoas por posicao."""
import argparse
from collections import Counter, defaultdict
import gzip
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import UF, PERSON_NAMES, rows, load_guides, parse_profile
from auditoria_pendencias_texto_1960 import checksum


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--out', required=True)
    args = parser.parse_args(); root = Path(__file__).resolve().parents[1]
    out = root / args.out; out.mkdir(parents=True, exist_ok=False)
    raw = root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt'
    decisions_path = root / 'read_guides/1960_amostra_127_correcoes.csv'
    dec = {int(r['linha']): r for r in rows(decisions_path)}
    fragment = dec[855822]['texto_original'].split('\\')[0].replace(' ', '')
    assert len(fragment) == 35
    alternate = fragment[:19] + '63' + fragment[21:]
    keys = {60: {(66274, 209)}, 81: {(81076, 15), (81076, 16), (81076, 17),
                                   (82402, 101), (82402, 103)}}
    hashes = {str(p.relative_to(root)): checksum(p) for p in [raw, decisions_path]}
    group127 = defaultdict(list); matches127 = []; prefix127 = []; boundaries = []
    with raw.open(encoding='latin1') as f:
        for n, line in enumerate(f, 1):
            original = line.rstrip('\r\n'); text = dec.get(n, {}).get('texto_corrigido') or original
            if text[:2].isdigit() and text[8:16].isdigit():
                uf = int(text[:2]); k = (int(text[8:13]), int(text[13:16]))
                if k in keys.get(uf, set()):
                    group127[f'{uf}-{k[0]}-{k[1]}'].append({'linha': n, 'texto': text})
            if text[19:54] in {fragment, alternate}:
                matches127.append({'linha': n, 'texto': text, 'igual_fragmento': text[19:54] == fragment})
            if text.startswith('60643301644'):
                prefix127.append({'linha': n, 'texto': text})
            if 855807 <= n <= 855823 or 951424 <= n <= 951435:
                boundaries.append({'linha': n, 'texto_original': original, 'texto_corrigido': text})
    group25 = defaultdict(list); matches25 = []; source_counts = {}
    for uf, abbrev in UF.items():
        path = root / f'data/release_legacy/Censo.1960.amostra.25porcento.{abbrev}.gz'
        if not path.exists():
            continue
        digest = checksum(path); hashes[str(path.relative_to(root))] = digest
        number = 0; preceding = None
        with gzip.open(path, 'rt', encoding='latin1') as f:
            for n, line in enumerate(f, 1):
                text = line.rstrip('\r\n'); number += 1
                if text[8:10] == '00':
                    preceding = {'linha': n, 'texto': text}
                if text[:8].isdigit() and (int(text[:5]), int(text[5:8])) in keys.get(uf, set()):
                    k = (int(text[:5]), int(text[5:8]))
                    group25[f'{uf}-{k[0]}-{k[1]}'].append({'linha': n, 'texto': text,
                                                                        'arquivo': str(path.relative_to(root))})
                if text[8:10] != '00':
                    tail = text[15:24] + text[25:51]
                    if tail in {fragment, alternate}:
                        matches25.append({'uf': uf, 'linha': n, 'texto': text,
                                          'arquivo': str(path.relative_to(root)),
                                          'igual_fragmento': tail == fragment, 'cartao_anterior': preceding})
        source_counts[abbrev] = number
        assert checksum(path) == digest
        print(f'{abbrev}: {number}', flush=True)
    guides = load_guides(root); comparisons = []
    for k, people in group127.items():
        p127 = [r for r in people if r['texto'][16] in '23']
        all25 = group25.get(k, []); p25 = [r for r in all25 if r['texto'][8:10] != '00']
        profiles127 = Counter(parse_profile(r['texto'], guides[('127', 'pessoas')], PERSON_NAMES)[0] for r in p127)
        profiles25 = Counter(parse_profile(r['texto'], guides[('25', 'pessoas')], PERSON_NAMES)[0] for r in p25)
        comparisons.append({'chave': k, 'pessoas127': len(p127), 'pessoas25': len(p25),
                            'composicao_exata': profiles127 == profiles25})
    for path, digest in hashes.items():
        assert checksum(root / path) == digest
    result = {'hipotese_fragmento_855822': {'literal_compactado': fragment,
              'interpretacao_testada': 'Cauda completa V203..V224 alinhada a direita; nao e reconstrucao aprovada.',
              'alternativa_v216': 'Busca separada63, sem impor equivalencia com00.'},
              'coincidencias127': matches127, 'coincidencias25': matches25,
              'prefixo_segundo_fragmento127': prefix127, 'contextos': boundaries,
              'grupos127': group127, 'grupos25': group25, 'comparacao_contextos': comparisons,
              'linhas25_examinadas': source_counts, 'fontes_sha256': hashes,
              'limite': 'Ausencia de coincidencia literal nao prova ausencia historica. Nao se altera qualquer registro.'}
    (out / 'fragmentos.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'matches127': len(matches127), 'matches25': len(matches25), 'comparacao': comparisons}, indent=2))


if __name__ == '__main__':
    main()
