"""Buscas adicionais dos danos de texto, sem alterar microdados ou decisoes."""
import argparse
from collections import Counter, defaultdict
from difflib import SequenceMatcher
import gzip
import json
from pathlib import Path
import re
import sqlite3

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, UF, load_guides, parse_profile, profile_hash, rows,
)
from auditoria_pendencias_texto_1960 import checksum


def body(text, sample):
    return (text[18:54].replace('-', ' ') if sample == '127'
            else text[14:24] + text[25:51])


def pattern(text, sample, guides, partial=True):
    profile, invalid = parse_profile(text, guides[(sample, 'pessoas')], PERSON_NAMES)
    pieces = []
    for name, value in zip(PERSON_NAMES, profile):
        start, end, valid = guides[(sample, 'pessoas')][name]
        literal = text[start:end]
        if value is not None:
            pieces.append(str(value).zfill(end - start))
        elif partial:
            pieces.append(''.join(c if c.isdigit() else '.' for c in literal))
        else:
            pieces.append(' ' * (end - start))
    result = ''.join(pieces)
    assert len(result) == 36
    return result


def assignment(cost):
    """Minimo global, com dummies explicitos; nao e prova de identidade."""
    n = len(cost)
    if not n:
        return []
    u = [0] * (n + 1); v = [0] * (n + 1)
    p = [0] * (n + 1); way = [0] * (n + 1)
    for i in range(1, n + 1):
        p[0] = i; j0 = 0; minimum = [10 ** 9] * (n + 1); used = [False] * (n + 1)
        while True:
            used[j0] = True; i0 = p[j0]; delta = 10 ** 9; j1 = 0
            for j in range(1, n + 1):
                if not used[j]:
                    cur = cost[i0 - 1][j - 1] - u[i0] - v[j]
                    if cur < minimum[j]:
                        minimum[j] = cur; way[j] = j0
                    if minimum[j] < delta:
                        delta = minimum[j]; j1 = j
            for j in range(n + 1):
                if used[j]:
                    u[p[j]] += delta; v[j] -= delta
                else:
                    minimum[j] -= delta
            j0 = j1
            if p[j0] == 0:
                break
        while True:
            j1 = way[j0]; p[j0] = p[j1]; j0 = j1
            if j0 == 0:
                break
    return sorted((p[j] - 1, j - 1) for j in range(1, n + 1))


def candidate_mask(text, mask):
    return all(a == '.' or a == b for a, b in zip(mask, text)) and len(text) == len(mask)


def make_search(queries):
    anchors = defaultdict(lambda: defaultdict(list)); insufficient = []
    for identifier, query in queries.items():
        runs = list(re.finditer(r'[0-9 ]+', query['mask']))
        if not runs or max(len(r.group()) for r in runs) < 6:
            insufficient.append(identifier); continue
        run = max(runs, key=lambda r: (len(r.group()), len(set(r.group())), -r.start()))
        # Uma ancora acelera a busca; a mascara inteira e sempre verificada.
        width = min(12, len(run.group())); start = run.start()
        anchors[(start, width)][query['mask'][start:start + width]].append(identifier)
    return anchors, insufficient


def hits(text, anchors, queries):
    found = []
    for (start, width), values in anchors.items():
        for identifier in values.get(text[start:start + width], ()):
            if candidate_mask(text, queries[identifier]['mask']):
                found.append(identifier)
    return found


def record_hit(result, identifier, uf, number, text, card, sample, queries):
    target = result.setdefault(identifier, {'total': 0, 'por_uf': Counter(),
                              'chaves_mesma_uf': Counter(), 'exemplos': [], 'mesma_chave': []})
    target['total'] += 1; target['por_uf'][str(uf)] += 1
    key = text[:8] if sample == '25' else text[8:16]
    evidence = {'uf': uf, 'linha': number, 'texto': text, 'cartao': card}
    if len(target['exemplos']) < 20:
        target['exemplos'].append(evidence)
    query = queries[identifier]
    if uf == query.get('uf'):
        target['chaves_mesma_uf'][key] += 1
        if key == query.get('key'):
            target['mesma_chave'].append(evidence)


def context_cases(residues, guides):
    output = []; seen = set()
    for case in residues:
        key = tuple(case['chave'])
        if key in seen:
            continue
        seen.add(key)
        a = [r for r in case['grupo127'] if r['texto'][16] in '23']
        b = [r for r in case['grupo25'] if r['tipo'] == 'pessoas']
        aa = [parse_profile(r['texto'], guides[('127', 'pessoas')], PERSON_NAMES) for r in a]
        bb = [parse_profile(r['texto'], guides[('25', 'pessoas')], PERSON_NAMES) for r in b]
        n = max(len(a), len(b)); cost = [[100] * n for _ in range(n)]
        for i, (p, invalid) in enumerate(aa):
            for j, (q, bad) in enumerate(bb):
                cost[i][j] = sum(x is not None and y is not None and x != y
                                 for x, y in zip(p, q))
        pairs = []; absent = []; surplus = []
        for i, j in assignment(cost):
            if i >= len(a):
                absent.append(b[j]); continue
            if j >= len(b):
                surplus.append(a[i]); continue
            p, invalid = aa[i]; q, bad = bb[j]
            pairs.append({'linha127': a[i]['linha'], 'linha25': b[j]['linha'],
                          'invalidos127': invalid, 'invalidos25': bad,
                          'diferencas': {name: [x, y] for name, x, y in zip(PERSON_NAMES, p, q) if x != y},
                          'igualdades_artificiais_NA': [name for name, x, y in zip(PERSON_NAMES, p, q)
                                                       if name in invalid and x is None and y is None]})
        output.append({'chave': key, 'pareamento_descritivo_minimo': pairs,
                       'pessoas25_sem_par': absent, 'pessoas127_sem_par': surplus,
                       'limite': 'Uma solucao de menor numero de divergencias, nao identidade demonstrada; empates nao excluidos.'})
    return output


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True); parser.add_argument('--uf', nargs='*')
    args = parser.parse_args(); root = Path(__file__).resolve().parents[1]
    out = root / args.out; out.mkdir(parents=True, exist_ok=False)
    guides = load_guides(root)
    path_cases = root / 'tmp/fechamento_registros_1960_20260922/texto/completo01/casos.json'
    all_cases = json.loads(path_cases.read_text(encoding='utf-8'))
    path_final = root / 'references/fechamento_registros_1960_evidencias/texto_selecao_final33.json'
    final = json.loads(path_final.read_text(encoding='utf-8')); residues = final['residuos']
    raw = root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt'
    corrections_path = root / 'read_guides/1960_amostra_127_correcoes.csv'
    corrections = {int(r['linha']): r for r in rows(corrections_path)}
    paths = [path_cases, path_final, raw, corrections_path, Path(__file__)]
    paths += [root / f'read_guides/readguide_1960_amostra_{sample}_{kind}.csv'
              for sample in ['127', '25'] for kind in ['familias', 'pessoas']]
    hashes = {str(p.relative_to(root)): checksum(p) for p in paths}
    ledger = []; queries = {}; reverse = {}
    for case in all_cases:
        line = case['linha']; current = corrections[line]
        text = current['texto_corrigido'] or current['texto_original']
        kind = 'familias' if text[16] == '1' else 'pessoas'
        profile, invalid = parse_profile(text, guides[('127', kind)],
                                         FAMILY_NAMES if kind == 'familias' else PERSON_NAMES)
        ledger.append({'linha': line, 'status_anterior': case['status'],
                       'decisao_atual': current['decisao'], 'tipo_atual': kind,
                       'invalidos_atuais': invalid, 'texto_original': current['texto_original'],
                       'texto_atual': text, 'explicacao_atual': current['explicacao']})
        if kind == 'pessoas' and current['decisao'] not in {'corrompida', 'cartao_uf'}:
            queries[f'alvo127_{line}'] = {'mask': pattern(text, '127', guides), 'linha': line,
                'texto': text, 'uf': int(text[:2]) if text[:2].isdigit() else None, 'key': text[8:16],
                'finalidade': 'todos_os_campos_legiveis_sem_usar_chave'}
    for case in residues:
        for row in case['grupo127']:
            if row['texto'][16] not in '23':
                continue
            key = f'contexto127_{row["linha"]}'
            values, invalid = parse_profile(row['texto'], guides[('127', 'pessoas')], PERSON_NAMES)
            queries[key] = {'mask': pattern(row['texto'], '127', guides, bool(invalid)),
                            'texto': row['texto'], 'uf': case['chave'][0], 'key': row['texto'][8:16],
                            'invalidos127': invalid,
                            'finalidade': ('campos_legiveis_contexto_danificado' if invalid else
                                           'perfil_exato_contexto_sem_usar_chave')}
        for row in case['grupo25']:
            if row['tipo'] != 'pessoas':
                continue
            key = f'fonte25_{case["chave"][0]}_{row["linha"]}'
            reverse[key] = {'mask': pattern(row['texto'], '25', guides, False), 'texto': row['texto'],
                            'uf': case['chave'][0], 'key': row['texto'][:8]}
    # O grupo paulista adicional foi congelado na rodada precedente.
    geo = json.loads((root / 'tmp/fechamento_registros_1960_20260922/texto/inferencias04/inferencias.json').read_text(encoding='utf-8'))
    for row in geo['municipios']['sp']['grupo25']:
        if row['texto'][8:10] != '00':
            reverse[f'fonte25_60_{row["linha"]}'] = {'mask': pattern(row['texto'], '25', guides, False),
                    'texto': row['texto'], 'uf': 60, 'key': row['texto'][:8]}
    anchors, insufficient = make_search(queries); anchors127, bad_reverse = make_search(reverse)
    result = {}; result127 = {}; counts = {}; fragment_hits = defaultdict(list)
    fragment_counts = defaultdict(Counter)
    fragments = {
        '855822_primeiro_sem_espacos': corrections[855822]['texto_original'].split('\\')[0].replace(' ', ''),
        '951430_prefixo_sem_espacos': corrections[951430]['texto_original'].split('\\')[0].replace(' ', ''),
        '951433_apenas_digitos_antes_barra': ''.join(re.findall(r'\d', corrections[951433]['texto_original'].split('\\')[0])),
    }
    seeds = {}
    for name, fragment in fragments.items():
        words = {fragment[i:i + 16] for i in range(len(fragment) - 15)
                 if len(set(fragment[i:i + 16])) >= 4}
        seeds[name] = re.compile('|'.join(re.escape(s) for s in sorted(words))) if words else None
    def search_fragments(text, sample, uf, number):
        b = body(text, sample)
        for name, seed in seeds.items():
            if seed and seed.search(b):
                match = SequenceMatcher(None, fragments[name], b, autojunk=False).find_longest_match()
                fragment_counts[name][f'{sample}/{uf}/{match.size}'] += 1
                evidence = {'amostra': sample, 'uf': uf, 'linha': number, 'texto': text,
                    'inicio_fragmento': match.a, 'inicio_corpo': match.b, 'comprimento': match.size,
                    'trecho': fragments[name][match.a:match.a + match.size]}
                saved = fragment_hits[name]
                if len(saved) < 100 or match.size > saved[-1]['comprimento']:
                    saved.append(evidence); saved.sort(key=lambda r: -r['comprimento'])
                    del saved[100:]
    for uf, abbrev in UF.items():
        if args.uf and abbrev not in args.uf:
            continue
        path = root / f'data/release_legacy/Censo.1960.amostra.25porcento.{abbrev}.gz'
        if not path.exists():
            continue
        hashes[str(path.relative_to(root))] = checksum(path); card = None; n = 0
        with gzip.open(path, 'rt', encoding='latin1') as source:
            for n, raw_line in enumerate(source, 1):
                text = raw_line.rstrip('\r\n')
                if text[8:10] == '00':
                    card = {'linha': n, 'texto': text}; continue
                b = body(text, '25')
                for identifier in hits(b, anchors, queries):
                    values, invalid = parse_profile(text, guides[('25', 'pessoas')], PERSON_NAMES)
                    if not invalid:
                        record_hit(result, identifier, uf, n, text, card, '25', queries)
                search_fragments(text, '25', uf, n)
        counts[abbrev] = n; print(f'{abbrev}: {n}', flush=True)
    preceding = None
    with raw.open(encoding='latin1') as source:
        for n, raw_line in enumerate(source, 1):
            original = raw_line.rstrip('\r\n'); decision = corrections.get(n, {})
            if decision:
                assert original == decision['texto_original']
            text = decision.get('texto_corrigido') or original
            uf = int(text[:2]) if text[:2].isdigit() else None
            if text[16] == '1':
                preceding = {'linha': n, 'texto': text}; continue
            if text[16] not in '23' or decision.get('decisao') == 'corrompida':
                continue
            for identifier in hits(body(text, '127'), anchors127, reverse):
                values, invalid = parse_profile(text, guides[('127', 'pessoas')], PERSON_NAMES)
                if not invalid:
                    record_hit(result127, identifier, uf, n, text, preceding, '127', reverse)
            search_fragments(text, '127', uf, n)
    index_path = root / 'tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite'
    con = sqlite3.connect(index_path.resolve().as_uri() + '?mode=ro', uri=True); con.row_factory = sqlite3.Row
    gb = {'candidatos_cartao_por_chave_parcial': [dict(r) for r in con.execute(
              "SELECT linha,corrigido,uf,pasta,boletim,distrito,municipio,situacao FROM familias "
              "WHERE uf=54 AND boletim=101 AND distrito=18 AND CAST(pasta AS TEXT) LIKE '541%'")],
          'alternativas_pasta_e_boletim_sem_distrito': [dict(r) for r in con.execute(
              "SELECT linha,corrigido,distrito FROM familias WHERE uf=54 AND boletim=101 AND CAST(pasta AS TEXT) LIKE '541%'")]}
    for card in gb['candidatos_cartao_por_chave_parcial']:
        card['pessoas_ja_vinculadas'] = [dict(r) for r in con.execute(
            'SELECT linha,corrigido,familia_atual FROM pessoas WHERE familia_atual=?', (card['linha'],))]
    con.close()
    for path, digest in hashes.items():
        assert checksum(root / path) == digest, 'Fonte mudou: ' + path
    payload = {'escopo': 'Investigacao sem novos reparos. Correspondencia parcial nao identifica pessoa.',
        'inventario124': ledger, 'residuos14_contextos': context_cases(residues, guides),
        'consultas25': queries, 'resultados25': result, 'consultas127': reverse, 'resultados127': result127,
        'consultas_sem_ancora': insufficient, 'reversas_sem_ancora': bad_reverse,
        'fragmentos_hipoteses': fragments, 'fragmentos_coincidencias16_ou_mais': dict(fragment_hits),
        'fragmentos_contagens_amostra_uf_comprimento': dict(fragment_counts),
        'limite_fragmentos': 'Trechos compactados sao hipoteses; apenas coincidencias contiguas >=16 com >=4 caracteres distintos. Cem maiores exemplos porhipotese, contagens completas; nao busca aproximada irrestrita.',
        'guanabara611254': gb, 'linhas25_examinadas': counts, 'fontes_sha256': hashes}
    (out / 'investigacao_texto.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'inventario': len(ledger), 'consultas25': len(queries), 'consultas127': len(reverse),
                      'fontes': counts, 'residuos': len(residues), 'sem_ancora': insufficient}, ensure_ascii=False))


if __name__ == '__main__':
    main()
