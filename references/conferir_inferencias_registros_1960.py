"""Examina inferencias antigas e correspondencia sem usar V216 como prova."""
import argparse
from collections import defaultdict
import gzip
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import rows, load_guides, parse_profile, PERSON_NAMES, FAMILY_NAMES, source_structure
from auditoria_pendencias_texto_1960 import checksum
from conferir_reparos_texto_1960 import matching


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--out', required=True)
    args = parser.parse_args(); root = Path(__file__).resolve().parents[1]
    out = root / args.out; out.mkdir(parents=True, exist_ok=False)
    previous = root / 'tmp/fechamento_registros_1960_20260922/texto/completo01/casos.json'
    cases = json.loads(previous.read_text(encoding='utf-8')); by = {c['linha']: c for c in cases}
    guides = load_guides(root); results = []
    remaining = [238423, 540394, 540399, 540461, 541238, 963286, 998640, 1019837]
    original_nationality_cases = {224345, 228629, 238423, 445777, 540394, 540399, 540461, 541238,
                                 766772, 827521, 831654, 963286, 983242, 997505, 998640, 1019837,
                                 1019901, 1020372, 1023596}
    dup_path = root / 'read_guides/1960_amostra_127_duplicatas.csv'
    removed = {int(r['linha']) for r in rows(dup_path) if r['acao'] == 'remover'}
    hashes = {str(p.relative_to(root)): checksum(p) for p in [previous, dup_path]}
    for line in remaining:
        c = by[line]; a = [r for r in c['grupo127'] if r['texto'][16] in '23' and r['linha'] not in removed]
        b = [r for r in c['grupo25'] if r['tipo'] == 'pessoas']
        fa = [r for r in c['grupo127'] if r['texto'][16] == '1']; fb = [r for r in c['grupo25'] if r['tipo'] == 'familias']
        edges = []; p = []; q = []
        for r in a:
            p.append(parse_profile(r['texto'], guides[('127', 'pessoas')], PERSON_NAMES)[0])
        for r in b:
            q.append(parse_profile(r['texto'], guides[('25', 'pessoas')], PERSON_NAMES)[0])
        for i, profile in enumerate(p):
            allowed = []
            for j, other in enumerate(q):
                bad = [(name, u, v) for name, u, v in zip(PERSON_NAMES, profile, other)
                       if name != 'V216' and u != v and not
                       (name == 'V208' and u is None and v == 9 and a[i]['linha'] in original_nationality_cases)]
                if not bad:
                    allowed.append(j)
            edges.append(allowed)
        m = matching(edges, len(a)) if len(a) == len(b) else None
        pairs = []
        if m is not None:
            for i, j in sorted(m.items()):
                pairs.append({'linha127': a[i]['linha'], 'linha25': b[j]['linha'],
                              'diferencas_preservadas': {name: [u, v] for name, u, v in zip(PERSON_NAMES, p[i], q[j]) if u != v},
                              'alternativas': [b[k]['linha'] for k in edges[i]
                                              if matching(edges, len(a), (i, k)) is not None]})
        f_diff = {}
        if len(fa) == len(fb) == 1:
            x = parse_profile(fa[0]['texto'], guides[('127', 'familias')], FAMILY_NAMES)[0]
            y = parse_profile(fb[0]['texto'], guides[('25', 'familias')], FAMILY_NAMES)[0]
            f_diff = {name: [u, v] for name, u, v in zip(FAMILY_NAMES, x, y) if u != v}
        results.append({'linha127': line, 'chave': c['chave'], 'n127': len(a), 'n25': len(b),
                        'composicao_24_campos_compativel': m is not None, 'pares': pairs,
                        'diferencas_cartao': f_diff, 'grupo127': c['grupo127'], 'grupo25': c['grupo25'],
                        'limite': 'Diagnostico de correspondencia; V216 nao foi igualado nem descartado dos dados. Nao aprova reparo.'})
    raw_path = root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt'
    hashes[str(raw_path.relative_to(root))] = checksum(raw_path)
    geography = {}; selected127 = defaultdict(list)
    with raw_path.open(encoding='latin1') as f:
        for n, line in enumerate(f, 1):
            t = line.rstrip('\r\n')
            if (t[:2], t[8:16]) in {('60', '60158119'), ('71', '71038216')}:
                selected127[(t[:2], t[8:16])].append({'linha': n, 'texto': t})
    for uf, key in [('sp', '60158119'), ('pr', '71038216')]:
        path = root / f'data/release_legacy/Censo.1960.amostra.25porcento.{uf}.gz'
        hashes[str(path.relative_to(root))] = checksum(path); selected25 = []
        with gzip.open(path, 'rt', encoding='latin1') as f:
            for n, line in enumerate(f, 1):
                t = line.rstrip('\r\n')
                if t[:8] == key:
                    selected25.append({'linha': n, 'texto': t, 'arquivo': str(path.relative_to(root))})
        aa = selected127[('60' if uf == 'sp' else '71', key)]
        card127 = [r for r in aa if r['texto'][16] == '1']; card25 = [r for r in selected25 if r['texto'][8:10] == '00']
        ff = {}
        if len(card127) == len(card25) == 1:
            x = parse_profile(card127[0]['texto'], guides[('127', 'familias')], FAMILY_NAMES)[0]
            y = parse_profile(card25[0]['texto'], guides[('25', 'familias')], FAMILY_NAMES)[0]
            ff = {name: [u, v] for name, u, v in zip(FAMILY_NAMES, x, y) if u != v}
        geography[uf] = {'grupo127': aa, 'grupo25': selected25, 'diferencas_cartao': ff}
    for path, digest in hashes.items():
        assert checksum(root / path) == digest
    payload = {'nacionalidades_restantes': results, 'municipios': geography, 'fontes_sha256': hashes}
    # Municipio com um caractere perdido: fonte geografica e o cartao25,
    # nao o consenso de outras familias da pasta.
    pr = geography['pr']
    fa = [r for r in pr['grupo127'] if r['texto'][16] == '1']
    fb = [r for r in pr['grupo25'] if r['texto'][8:10] == '00']
    aa = [r for r in pr['grupo127'] if r['texto'][16] in '23']
    bb = [r for r in pr['grupo25'] if r['texto'][8:10] != '00']
    assert len(fa) == len(fb) == 1 and len(aa) == len(bb) == 3
    assert pr['diferencas_cartao'] == {'V116': [None, 7240]}
    assert not source_structure(fb[0], bb)
    for r in fa + aa:
        t = r['texto']; s = fb[0]['texto']
        assert t[6:8] == s[33:35] == '07' and t[17] == s[35] == '5'
        assert t[:2] == '71' and t[8:16] == s[:8] == '71038216'
        assert t[2:6] == ('724Z' if r['linha'] in {887255, 887256} else '7240')
    edges = []
    for r in aa:
        p, bad = parse_profile(r['texto'], guides[('127', 'pessoas')], PERSON_NAMES)
        assert not bad
        candidates_pr = []
        for j, s in enumerate(bb):
            q, bad25 = parse_profile(s['texto'], guides[('25', 'pessoas')], PERSON_NAMES)
            assert not bad25
            differences = {n: [a, b] for n, a, b in zip(PERSON_NAMES, p, q) if a != b}
            if all(n == 'V216' and set(v) == {0, 63} for n, v in differences.items()):
                candidates_pr.append(j)
        edges.append(candidates_pr)
    assignment = matching(edges, 3); assert assignment is not None
    pairs_pr = []
    for i, j in sorted(assignment.items()):
        p = parse_profile(aa[i]['texto'], guides[('127', 'pessoas')], PERSON_NAMES)[0]
        q = parse_profile(bb[j]['texto'], guides[('25', 'pessoas')], PERSON_NAMES)[0]
        delta = {n: [a, b] for n, a, b in zip(PERSON_NAMES, p, q) if a != b}
        if aa[i]['linha'] == 887256:
            assert not delta
        pairs_pr.append({'linha127': aa[i]['linha'], 'linha25': bb[j]['linha'], 'diferencas_preservadas': delta})
    geo_candidates = [{
        'linha127': r['linha'], 'tipo': 'familias' if r['texto'][16] == '1' else 'pessoas',
        'texto_original': r['texto'], 'campo_literal_danificado': {'V116': '724Z'},
        'valor_geografico_proposto': {'code_muni_1960': 7240},
        'fonte_geografica25': fb[0], 'grupo127': pr['grupo127'], 'grupo25': pr['grupo25'],
        'correspondencias_contexto': pairs_pr,
        'criterio': 'Cartao unico,14outroscamposfamiliaresiguais;3pessoas com todoscamposiguais excetoV21600/63preservado emumcontexto;distrito07/situacao5/chave71038-216;724conservado.',
        'limite': 'Candidato separado para geografia derivada. Nao aplicar automaticamente ao texto ou substituirV116original;nao usarconsensogenerico.'}
        for r in pr['grupo127'] if r['linha'] in {887255, 887256}]
    (out / 'candidatos_geografia_pr.json').write_text(json.dumps(
        {'fontes_sha256': hashes, 'candidatos': geo_candidates}, ensure_ascii=False, indent=2), encoding='utf-8')
    # Selecionar apenas os quatro casos autorizados apos examinar os conflitos.
    candidates = []
    for result in results:
        if result['linha127'] not in {541238, 963286, 998640, 1019837}:
            continue
        assert result['composicao_24_campos_compativel']
        case = by[result['linha127']]
        fa = [r for r in case['grupo127'] if r['texto'][16] == '1']
        fb = [r for r in case['grupo25'] if r['tipo'] == 'familias']
        assert len(fa) == len(fb) == 1
        assert not source_structure(fb[0], [r for r in case['grupo25'] if r['tipo'] == 'pessoas'])
        expected_card_delta = {'V102': [5, 4]} if result['linha127'] == 541238 else {}
        assert result['diferencas_cartao'] == expected_card_delta
        for row in case['grupo127']:
            t = row['texto']; s = fb[0]['texto']
            assert (t[2:6], t[6:8], t[17:18]) == (s[29:33], s[33:35], s[35:36])
        for pair in result['pares']:
            for name, values in pair['diferencas_preservadas'].items():
                assert (name == 'V208' and values == [None, 9]) or (name == 'V216' and set(values) == {0, 63})
        target = next(p for p in result['pares'] if p['linha127'] == result['linha127'])
        possible = [r for r in case['grupo25'] if r['linha'] in target['alternativas']]
        assert possible
        for source in possible:
            p = parse_profile(case['texto_corrigido'] or case['texto_original'], guides[('127', 'pessoas')], PERSON_NAMES)[0]
            q = parse_profile(source['texto'], guides[('25', 'pessoas')], PERSON_NAMES)[0]
            delta = {name: [u, v] for name, u, v in zip(PERSON_NAMES, p, q) if u != v}
            assert delta == {'V208': [None, 9]}
        before = case['texto_corrigido'] or case['texto_original']
        assert before[27] == ' '
        candidates.append({'linha127': result['linha127'], 'chave': case['chave'], 'motivos': [],
                           'propostas': [{'campo': 'V208', 'inicio': 28, 'fim': 28, 'antes': ' ', 'depois': '9',
                                          'linhas25': [r['linha'] for r in possible]}],
                           'aprovavel_no_criterio': True, 'pessoas127': result['n127'], 'pessoas25': result['n25'],
                           'texto_original': case['texto_original'], 'texto_antes': before,
                           'texto_corrigido_proposto': before[:27] + '9' + before[28:],
                           'fontes25_possiveis': possible, 'grupo127': case['grupo127'], 'grupo25': case['grupo25'],
                           'criterio_adicional': 'Identidade do alvo por24campos exatos; composicao integral por24campos; divergencias V21600/63 eV102 do cartao somente documentadas, sem mudar valores.',
                           'divergencias_cartao_preservadas': result['diferencas_cartao'],
                           'correspondencias_contexto': result['pares']})
    expected127 = {r['linha']: r['texto'] for c in candidates for r in c['grupo127']}
    with raw_path.open(encoding='latin1') as f:
        for n, line in enumerate(f, 1):
            if n in expected127:
                assert line.rstrip('\r\n') == expected127[n]
    source_rows = defaultdict(dict)
    for case in candidates:
        for row in case['grupo25']:
            source_rows[row['arquivo']][row['linha']] = row['texto']
    for name, selected in source_rows.items():
        path = root / name; hashes[name] = checksum(path)
        seen = set()
        with gzip.open(path, 'rt', encoding='latin1') as f:
            for n, line in enumerate(f, 1):
                if n in selected:
                    assert line.rstrip('\r\n') == selected[n]
                    seen.add(n)
        assert seen == set(selected)
        assert checksum(path) == hashes[name]
    (out / 'candidatos_nacionalidade_adicionais.json').write_text(json.dumps(
        {'fontes_sha256': hashes, 'reparos': candidates}, ensure_ascii=False, indent=2), encoding='utf-8')
    (out / 'inferencias.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps([{'linha': r['linha127'], 'composicao24': r['composicao_24_campos_compativel'],
                      'diferencas_cartao': r['diferencas_cartao']} for r in results], ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
