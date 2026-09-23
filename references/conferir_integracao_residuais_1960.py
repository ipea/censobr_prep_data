"""Segunda leitura dos manifestos atuais; propoe hashes, nunca os altera."""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

from conferir_investigacao_residual_1960 import guide, profile, PNAMES

ROOT = Path(__file__).resolve().parents[1]
RECOVERY = 'read_guides/1960_amostra_127_cartoes_recuperados.json'
DECISIONS = ['read_guides/1960_amostra_127_' + n + '.csv'
             for n in ['correcoes', 'duplicatas', 'vinculos']]


def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        return list(csv.DictReader(f))


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        while block := f.read(4 * 1024 ** 2):
            h.update(block)
    return h.hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / 'tmp'):
        raise ValueError('Saida deve ficar dentro de tmp')
    out.mkdir(parents=True, exist_ok=False)
    manifest = json.loads((ROOT / RECOVERY).read_text(encoding='utf-8'))
    previous = json.loads(subprocess.check_output(['git', 'show', '790d9d7:' + RECOVERY], cwd=ROOT))
    old = {r['id_recuperacao']: r for r in previous['cartoes']}
    current = {r['id_recuperacao']: r for r in manifest['cartoes']}
    assert len(current) == len(manifest['cartoes'])
    assert old.keys() <= current.keys()
    for key, row in old.items():
        assert all(current[key][name] == value for name, value in row.items()), key
    corrections, duplicates, links = [{int(r['linha']): r for r in rows(ROOT / p)} for p in DECISIONS]
    removed = {n for n, r in duplicates.items() if r['acao'] == 'remover'}
    wanted = {int(p['linha']): p for c in current.values() for p in c['pessoas']}
    assert len(wanted) == sum(len(c['pessoas']) for c in current.values())
    assert not set(wanted) & (removed | set(links))
    raw = ROOT / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt'
    real_keys = set()
    with raw.open(encoding='latin1', newline='') as f:
        for n, original in enumerate(f, 1):
            original = original.rstrip('\r\n')
            correction = corrections.get(n, {})
            if correction:
                assert correction['texto_original'] == original, n
            if correction.get('decisao') == 'cartao_uf':
                continue
            corrected = correction.get('texto_corrigido') or original
            if corrected[16] == '1':
                real_keys.add((corrected[:2], corrected[8:16]))
            if n in wanted:
                assert (original, corrected) == (wanted[n]['texto_original'], wanted[n]['texto_corrigido']), n
    texts25 = defaultdict(dict)
    for c in current.values():
        assert (c['UF'], c['pasta'] + c['boletim']) not in real_keys
        assert (c['UF'], c['texto_25'][:8]) not in real_keys
        texts25[c['arquivo_25']][int(c['linha_25'])] = c['texto_25']
        for p in c['pessoas']:
            texts25[c['arquivo_25']][int(p['linha_25'])] = p['texto_25']
    for filename, wanted25 in texts25.items():
        remaining = set(wanted25)
        with gzip.open(ROOT / filename, 'rt', encoding='latin1', newline='') as f:
            for n, line in enumerate(f, 1):
                if n in remaining:
                    assert line.rstrip('\r\n') == wanted25[n], (filename, n)
                    remaining.remove(n)
                    if not remaining:
                        break
        assert not remaining
    g127 = guide('127', 'pessoas')
    g25 = guide('25', 'pessoas')
    checked = []
    for key, c in current.items():
        persons = c['pessoas']
        assert len(persons) == c['n_pessoas'] == int(c['texto_25'][11:13])
        assert sorted(int(p['texto_25'][8:10]) for p in persons) == list(range(1, len(persons) + 1))
        differences = []
        for p in persons:
            a = profile(p['texto_corrigido'], g127, PNAMES)
            b = profile(p['texto_25'], g25, PNAMES)
            diff = [name for name, x, y in zip(PNAMES, a, b) if x != y]
            assert not diff or (key == '14-15004-116' and diff == ['V216'] and {a[16], b[16]} == {0, 63}), (key, p['linha'], diff)
            if diff:
                differences.append({'linha127': p['linha'], 'campos': diff})
            text = p['texto_corrigido']
            assert (text[:2], text[2:6], text[6:8], text[8:13], text[13:16], text[17]) == (
                c['UF'], c['V116'], c['distrito'], c['pasta'], c['boletim'], c['V118']), (key, p['linha'])
            assert p['texto_25'][:8] == c['texto_25'][:8]
        assert (c['texto_25'][29:33], c['texto_25'][33:35], c['texto_25'][35]) == (c['V116'], c['distrito'], c['V118'])
        checked.append({'id': key, 'pessoas': len(persons), 'diferencas_preservadas': differences,
                        'anterior': key in old})
    hashes = []
    for row in manifest['fontes']:
        path = row['arquivo'].replace('\\', '/')
        now = digest(ROOT / path)
        changed = now != row['sha256']
        assert not changed or path in DECISIONS, path
        hashes.append({'arquivo': path, 'antes': row['sha256'], 'atual': now, 'mudou': changed})
    result = {'modo': 'somente conferencia; nao altera manifesto nem dados',
              'cartoes': len(current), 'pessoas': len(wanted), 'cartoes_anteriores_preservados': len(old),
              'novos_cartoes': sorted(current.keys() - old.keys()), 'cartoes_conferidos': checked,
              'assinaturas_para_revalidar': hashes,
              'literal25_conferidos': sum(len(x) for x in texts25.values()),
              'limite': 'Confere integracao e literais. A prova de alternativas e testemunhos e testada separadamente nos auditores e em R.'}
    (out / 'integracao.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k not in ['cartoes_conferidos', 'assinaturas_para_revalidar']}, ensure_ascii=False))
    for row in hashes:
        if row['mudou']:
            print(json.dumps(row))


if __name__ == '__main__':
    main()
