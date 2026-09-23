"""Cobertura integral e unicidade de composicoes familiares; nenhuma decisao aplicada."""
import argparse
from collections import Counter, defaultdict
import gzip
import hashlib
import itertools
import json
from pathlib import Path
import sqlite3
import time

import psutil
import auditoria_recuperacao_cartoes_1960 as core
import investigacao_residual_vinculos_1960 as signatures

ROOT = Path(__file__).resolve().parents[1]
INV = 'references/resolucao_residuais_1960_evidencias/inventario_atual.json'
INDEX = 'tmp/resolver_residuais_1960_20260922/cartoes_reauditoria_fechada/indice127.sqlite'
OLD = 'tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01'
DETAIL = 'tmp/investigacao_residual_1960_20260922/vinculos/detalhes01/detalhes.json'


def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))


def dump(path, value):
    with path.open('x', encoding='utf-8') as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)


def guard():
    if psutil.Process().memory_info().rss >= 2 * 1024 ** 3:
        raise MemoryError('Limite desta investigacao: 2 GiB')


def serial(row):
    return {k: v for k, v in row.items() if k != 'perfil'}


def signature_group(people):
    return hashlib.sha256('\n'.join(sorted(people)).encode()).hexdigest()


def matching(a, b, maximum=1):
    """Pareamentos completos possiveis; limite declarado de quesitos alem de V216."""
    if not a or len(a) != len(b) or len(a) > 30:
        return []
    edges = [[j for j, q in enumerate(b) if sum(x != y for k, (x, y) in enumerate(zip(p, q)) if k != 16) <= maximum]
             for p in a]
    order = sorted(range(len(a)), key=lambda i: len(edges[i]))
    result = []

    def visit(pos, used, pairs):
        if len(result) >= 2:
            return
        if pos == len(order):
            result.append(dict(pairs))
            return
        i = order[pos]
        for j in edges[i]:
            if j not in used:
                visit(pos + 1, used | {j}, pairs + [(i, j)])

    visit(0, set(), [])
    return result


def main(out, pilot, extended):
    start = time.monotonic()
    out.mkdir(parents=True, exist_ok=False)
    guides = core.load_guides(ROOT)
    inv = read(INV)
    old = read(OLD + '/resultado.json')
    details = read(DETAIL)
    unresolved = {r['linha'] for r in inv['vinculos_pendentes']}
    conflicts = {r['linha'] for k in ['conflitos_municipais', 'conflitos_situacao'] for r in inv[k]}
    coverage = {r['linha']: {'linha': r['linha'], 'classe_pesquisa_anterior': r['classe'],
                 'grupo_anterior': r['grupo']} for r in details['casos'] if r['linha'] in unresolved | conflicts}
    for r in inv['corrompidas_sem_grupo_identificavel']:
        coverage[r['linha']] = {'linha': r['linha'], 'classe_pesquisa_anterior': 'fragmento_sem_identidade'}
    assert set(coverage) == unresolved | conflicts
    for n, r in coverage.items():
        r.update(sem_cartao=n in unresolved, conflito_geografico=n in conflicts)
    dump(out / 'cobertura.json', {'inventario_sha256': core.sha256(ROOT / INV),
         'registros_sem_cartao': len(unresolved), 'chaves_sem_cartao': inv['resumo']['grupos_sem_cartao_apos_manifesto'],
         'conflitos': len(conflicts), 'uniao': len(coverage),
         'classes': dict(Counter(r['classe_pesquisa_anterior'] for r in coverage.values())),
         'linhas': list(coverage.values())})

    groups = [g for g in old['grupos'] if set(g['linhas127']) <= unresolved
              and g['motivos'] == ['cartao127_alternativo_nao_descartado']
              and (not pilot or g['chave'] == [40, 40090, 4])]
    needed_cards = {a['linha_cartao127'] for g in groups for a in g['alternativas_plausiveis']}
    # O caso MG danificado entra so como contraprova; nao e reparado ou aprovado.
    if not pilot:
        needed_cards.update([405480, 405486])
    conn = sqlite3.connect((ROOT / INDEX).as_uri() + '?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    conn.execute('PRAGMA cache_size=-16384')
    pending = {n for g in inv['duplicatas_pendentes'] for n in g['linhas']}
    cards = {n: core.fetch(conn, 'SELECT * FROM familias WHERE linha=?', (n,))[0] for n in needed_cards}
    own = {n: core.fetch(conn, 'SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha', (n,))
           for n in needed_cards}
    source = {}
    for uf in sorted({c['uf'] for c in cards.values()}):
        keys = {(c['pasta'], c['boletim']) for c in cards.values() if c['uf'] == uf}
        fs, ps = core.read_source(ROOT, uf, keys)
        for key in keys:
            source[(uf, *key)] = (fs[key], ps[key])
    checks = {}
    targets = defaultdict(set)
    spans = {}; position = 0
    for name in core.PERSON_NAMES:
        begin, end, _ = guides['25', 'pessoas'][name]
        spans[name] = tuple(range(position, position + end - begin))
        position += end - begin

    def projected(full, omitted):
        removed = {i for name in omitted for i in spans[name]}
        return ''.join(c for i, c in enumerate(full) if i not in removed)
    for n, c in cards.items():
        f25, p25 = source[(c['uf'], c['pasta'], c['boletim'])]
        a = [core.parse_profile(p['corrigido'], guides['127', 'pessoas'], core.PERSON_NAMES) for p in own[n]]
        b = [core.parse_profile(p['texto'], guides['25', 'pessoas'], core.PERSON_NAMES) for p in p25]
        proof, _ = core.own_group_proof(conn, c, { (c['pasta'], c['boletim']): f25},
                       {(c['pasta'], c['boletim']): p25}, guides, pending, permitir_contexto=True)
        pa = [signatures.canonical(p, guides)[1] for p, bad in a]
        pb = [signatures.canonical(p, guides)[1] for p, bad in b]
        valid = not any(bad for p, bad in a + b)
        same24 = bool(pa) and Counter(pa) == Counter(pb) and valid
        match = matching([p for p, bad in a], [p for p, bad in b], 2 if extended else 1) if valid else []
        pairs = []
        if len(match) == 1:
            for i, j in sorted(match[0].items()):
                pairs.append({'linha127': own[n][i]['linha'], 'linha25': p25[j]['linha'],
                    'diferencas': {name: [x, y] for name, x, y in zip(core.PERSON_NAMES, a[i][0], b[j][0]) if x != y}})
        sig = signature_group(pa)
        omitted = ['V216']
        if extended and len(match) == 1:
            omitted = sorted(set(omitted) | {name for pair in pairs for name in pair['diferencas']})
        # No maximo dois quesitos adicionais; nunca apaga divergencias na evidencia.
        new_omitted = tuple(omitted) if len(omitted) <= 3 and valid and len(match) == 1 else ('V216',)
        projected_a = [projected(signatures.canonical(p, guides)[0], new_omitted) for p, bad in a]
        projected_b = [projected(signatures.canonical(p, guides)[0], new_omitted) for p, bad in b]
        same_projected = bool(a) and Counter(projected_a) == Counter(projected_b) and valid
        sig_projected = signature_group(projected_a)
        if same24:
            targets[c['uf'], ('V216',)].add(sig)
        if same_projected:
            targets[c['uf'], new_omitted].add(sig_projected)
        checks[n] = {'cartao127': serial(c), 'pessoas127': [serial(p) for p in own[n]],
                     'cartoes25': f25, 'pessoas25': p25, 'prova_anterior': proof,
                     'composicao24_exata': same24, 'assinatura24': sig,
                     'pareamento_limitado_unico': len(match) == 1,
                     'maximo_diferencas_alem_V216_por_pessoa': 2 if extended else 1,
                     'quesitos_omitidos_apenas_na_busca': list(new_omitted),
                     'composicao_projetada_exata': same_projected, 'assinatura_projetada': sig_projected,
                     'pares_nova_busca': pairs}
    # Frequencias de grupos inteiros nas duas fontes, nunca frequencias individuais.
    counts127 = defaultdict(list)
    query = '''SELECT uf,familia_atual,chave,linha,corrigido,invalidos FROM pessoas
      WHERE excluida=0 ORDER BY uf,familia_atual,chave,linha'''
    rows = conn.execute(query)
    for key, rows_group in itertools.groupby(rows, lambda r: (r['uf'], r['familia_atual'], r['chave'] if r['familia_atual'] is None else '')):
        records = list(rows_group)
        masks = [mask for uf, mask in targets if uf == key[0]]
        if not masks or any(r['invalidos'] for r in records):
            continue
        fulls = [signatures.signatures(r['corrigido'], '127')[0] for r in records]
        for mask in masks:
            sig = signature_group([projected(full, mask) for full in fulls])
            if sig in targets[key[0], mask]:
                counts127[key[0], mask, sig].append({'cartao': key[1], 'chave': key[2], 'linhas': [r['linha'] for r in records]})
        guard()
    counts25 = defaultdict(list)
    source_hashes = {}
    repartidas = {}
    for uf in sorted({uf for uf, mask in targets}):
        masks = [mask for source_uf, mask in targets if source_uf == uf]
        path = ROOT / f'data/release_legacy/Censo.1960.amostra.25porcento.{core.UF[uf]}.gz'
        source_hashes[str(path.relative_to(ROOT))] = core.sha256(path)
        seen_keys = set(); repeated_keys = set()
        with gzip.open(path, 'rt', encoding='latin1') as stream:
            for rawkey, iterator in itertools.groupby(enumerate(stream, 1), lambda x: x[1][:8]):
                if rawkey in seen_keys:
                    repeated_keys.add(rawkey)
                seen_keys.add(rawkey)
                lines = [(i, t.rstrip('\r\n')) for i, t in iterator]
                persons = [(i, t) for i, t in lines if t[8:10] != '00']
                fulls = [signatures.signatures(t, '25')[0] for i, t in persons]
                for mask in masks:
                    sig = signature_group([projected(full, mask) for full in fulls])
                    if sig in targets[uf, mask]:
                        counts25[uf, mask, sig].append({'chave': rawkey, 'linhas': [i for i, t in lines],
                                                     'textos': [t for i, t in lines]})
        repartidas[uf] = sorted(repeated_keys)
        # Blocos separados da mesma chave precisam ser reagrupados antes da unicidade.
        if repeated_keys:
            fs, ps = core.read_source(ROOT, uf, {(core.integer(k[:5]), core.integer(k[5:])) for k in repeated_keys})
            for key in list(counts25):
                if key[0] == uf:
                    counts25[key] = [r for r in counts25[key] if r['chave'] not in repeated_keys]
            for rawkey in repeated_keys:
                k = (core.integer(rawkey[:5]), core.integer(rawkey[5:]))
                for mask in masks:
                    sig = signature_group([projected(signatures.signatures(p['texto'], '25')[0], mask) for p in ps[k]])
                    if sig in targets[uf, mask]:
                        lines = sorted(fs[k] + ps[k], key=lambda r: r['linha'])
                        counts25[uf, mask, sig].append({'chave': rawkey, 'linhas': [r['linha'] for r in lines],
                                                      'textos': [r['texto'] for r in lines], 'reagrupada': True})
        print(f'Composicoes completas: {core.UF[uf]}', flush=True)
        guard()
    for n, check in checks.items():
        key = (check['cartao127']['uf'], ('V216',), check['assinatura24'])
        check['ocorrencias_grupo24_na127'] = counts127[key]
        check['ocorrencias_grupo24_na25'] = counts25[key]
        check['via_composicao24_unica_nas_duas_fontes'] = (
            check['composicao24_exata'] and len(counts127[key]) == len(counts25[key]) == 1
            and check['prova_anterior']['motivos_estritos'] == ['composicao_propria_diverge'])
        keyp = (check['cartao127']['uf'], tuple(check['quesitos_omitidos_apenas_na_busca']), check['assinatura_projetada'])
        check['ocorrencias_grupo_projetado_na127'] = counts127[keyp]
        check['ocorrencias_grupo_projetado_na25'] = counts25[keyp]
        check['via_composicao_projetada_unica_nas_duas_fontes'] = (
            check['composicao_projetada_exata'] and len(counts127[keyp]) == len(counts25[keyp]) == 1
            and check['prova_anterior']['motivos_estritos'] == ['composicao_propria_diverge'])
    results = []
    for g in groups:
        remaining = [a['linha_cartao127'] for a in g['alternativas_plausiveis']
                     if not checks[a['linha_cartao127']]['via_composicao24_unica_nas_duas_fontes']
                     and not checks[a['linha_cartao127']]['via_composicao_projetada_unica_nas_duas_fontes']
                     and not checks[a['linha_cartao127']]['prova_anterior']['confirmado']]
        results.append({**g, 'alternativas_restantes_nova_via': remaining,
                        'candidato_sem_alternativa_sob_nova_via': not remaining})
    summary = {'grupos_exatos_examinados': len(groups), 'pessoas': sum(len(g['linhas127']) for g in groups),
               'cartoes_alternativos_distintos': len(checks),
               'novas_composicoes24_unicas': sum(c['via_composicao24_unica_nas_duas_fontes'] for c in checks.values()),
               'novas_composicoes_projetadas_unicas': sum(c['via_composicao_projetada_unica_nas_duas_fontes'] for c in checks.values()),
               'grupos_sem_alternativa_nova_via': sum(not r['alternativas_restantes_nova_via'] for r in results),
               'novas_decisoes_aplicadas': 0, 'rss_mib': psutil.Process().memory_info().rss / 1024 ** 2,
               'segundos': time.monotonic() - start}
    dump(out / 'resultado.json', {'resumo': summary, 'grupos': results, 'alternativas': checks,
          'fontes25_sha256': source_hashes, 'chaves25_repartidas_reagrupadas': repartidas,
          'indice127': INDEX, 'indice127_sha256': core.sha256(ROOT / INDEX),
          'limite': 'Unicidade conjunta nao e identidade civil. V216 nao foi substituido. Nenhuma fonte ausente inferida.'})
    conn.close()
    print(json.dumps(summary), flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    parser.add_argument('--pilot', action='store_true')
    parser.add_argument('--extended', action='store_true')
    args = parser.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / 'tmp/fechamento_integral_1960/vinculos'):
        raise ValueError('Saida fora do escopo desta frente')
    main(out, args.pilot, args.extended)
