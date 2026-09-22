"""Passagem final dos47 candidatos: criterio unico, sem aplicar respostas."""
import argparse
from collections import Counter
import gzip
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import load_guides, parse_profile, PERSON_NAMES, FAMILY_NAMES, source_structure, rows
from auditoria_pendencias_texto_1960 import checksum
from conferir_reparos_texto_1960 import matching


def compare_profile(text, source, kind, permitted, guides, context=False):
    names = PERSON_NAMES if kind == 'pessoas' else FAMILY_NAMES
    a, invalid = parse_profile(text, guides[('127', kind)], names)
    b, bad = parse_profile(source, guides[('25', kind)], names)
    if bad:
        return False, {}
    differences = {}
    for name, x, y in zip(names, a, b):
        # Dano que vira NA nao demonstra igualdade a salto/ausencia legitima.
        if name in invalid and y is None:
            return False, {}
        if x == y:
            continue
        differences[name] = [x, y]
        if context and name == 'V216' and {x, y} == {0, 63}:
            continue
        if name in permitted and x is None and y is not None:
            start, end, _ = guides[('127', kind)][name]
            replacement = str(y).zfill(end - start)
            literal = text[start:end]
            if len(replacement) != len(literal) or any(c.isdigit() and c != replacement[i] for i, c in enumerate(literal)):
                return False, differences
            continue
        return False, differences
    return True, differences


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--out', required=True)
    args = parser.parse_args(); root = Path(__file__).resolve().parents[1]
    out = root / args.out; out.mkdir(parents=True, exist_ok=False)
    frozen = root / 'tmp/fechamento_registros_1960_20260922/texto/completo01'
    all_cases = json.loads((frozen / 'casos.json').read_text(encoding='utf-8'))
    snapshot = json.loads((frozen / 'resumo.json').read_text(encoding='utf-8'))
    guides = load_guides(root)
    cases = [c for c in all_cases if c['status'] == 'candidato_compativel_campos_danificados_ou_ausentes']
    assert len(cases) == 47
    byline = {c['linha']: c for c in all_cases}
    allowed = {}
    for c in cases:
        good = [s for s in c['candidatos25'] if not s['diferencas_legiveis']]
        allowed[c['linha']] = {name for s in good for name, (a, b) in s['diferencas'].items()
                              if a is None and b is not None}
    dup_path = root / 'read_guides/1960_amostra_127_duplicatas.csv'
    removed = {int(r['linha']) for r in rows(dup_path) if r['acao'] == 'remover'}
    hashes = {str(p.relative_to(root)): checksum(p) for p in [frozen / 'casos.json', frozen / 'resumo.json', dup_path, Path(__file__)]}
    # O snapshot precede reparos desta rodada. Revalidar dados originais/guia,
    # sem exigir que o manifesto de correcoes posterior continue byte-identico.
    for path, digest in snapshot['fontes_sha256'].items():
        if path.replace('\\', '/').endswith('1960_amostra_127_correcoes.csv'):
            continue
        assert checksum(root / path) == digest, 'Fonte mudou: ' + path
        hashes[path] = digest
    for kind in ['familias', 'pessoas']:
        path = root / f'read_guides/readguide_1960_amostra_25_{kind}.csv'
        hashes[str(path.relative_to(root))] = checksum(path)
    groups = {}; result = []
    for case in cases:
        k = tuple(case['chave'])
        if k not in groups:
            a = [r for r in case['grupo127'] if r['linha'] not in removed and r['texto'][16] in '23']
            b = [r for r in case['grupo25'] if r['tipo'] == 'pessoas']
            fa = [r for r in case['grupo127'] if r['texto'][16] == '1']
            fb = [r for r in case['grupo25'] if r['tipo'] == 'familias']
            reasons = []; card_delta = {}; edges = []; m = None
            if len(fa) != 1:
                reasons.append('cartao127_nao_unico')
            if len(fb) != 1:
                reasons.append('cartao25_nao_unico')
            if len(a) != len(b):
                reasons.append('contagem_pessoas_diverge')
            if len(fa) == len(fb) == 1:
                reasons.extend(source_structure(fb[0], b))
                p, pinvalid = parse_profile(fa[0]['texto'], guides[('127', 'familias')], FAMILY_NAMES)
                q, qinvalid = parse_profile(fb[0]['texto'], guides[('25', 'familias')], FAMILY_NAMES)
                card_delta = {name: [x, y] for name, x, y in zip(FAMILY_NAMES, p, q) if x != y}
                if qinvalid:
                    reasons.append('cartao25_codigo_invalido')
                if any(name in card_delta for name in ['V101', 'V116', 'V118']):
                    reasons.append('identidade_cartao_diverge')
                if any(name in pinvalid for name in ['V101', 'V116', 'V118']):
                    reasons.append('identidade_cartao_danificada')
                for row in fa + a:
                    text = row['texto']; source = fb[0]['texto']
                    for name, left, right in [('municipio', text[2:6], source[29:33]),
                                              ('distrito', text[6:8], source[33:35]),
                                              ('situacao', text[17:18], source[35:36])]:
                        if left != right:
                            reasons.append('geografia_diverge_' + name)
                    if (text[:2], text[8:13], text[13:16]) != (str(k[0]).zfill(2), source[:5], source[5:8]):
                        reasons.append('chave_diverge')
            for row in a:
                edges.append([j for j, source in enumerate(b) if compare_profile(row['texto'], source['texto'],
                              'pessoas', allowed.get(row['linha'], set()), guides, True)[0]])
            if len(a) == len(b):
                m = matching(edges, len(a))
                if m is None:
                    reasons.append('composicao_integral_nao_confere_sem_igualar_dano_a_NA')
            groups[k] = (a, b, fa, fb, sorted(set(reasons)), card_delta, edges, m)
        a, b, fa, fb, reasons0, card_delta, edges, m = groups[k]
        reasons = list(reasons0); possible = []; context_match = m
        if not reasons:
            if case['tipo'] == 'familias':
                ok, _ = compare_profile(fa[0]['texto'], fb[0]['texto'], 'familias', allowed[case['linha']], guides)
                if not ok:
                    reasons.append('alvo_familiar_tem_resposta_legivel_divergente')
                else:
                    possible = fb
            else:
                left = next(i for i, r in enumerate(a) if r['linha'] == case['linha'])
                for j, source in enumerate(b):
                    ok, _ = compare_profile(a[left]['texto'], source['texto'], 'pessoas', allowed[case['linha']], guides)
                    if ok and j in edges[left] and matching(edges, len(a), (left, j)) is not None:
                        possible.append(source)
                if not possible:
                    reasons.append('alvo_sem_correspondencia_integral_dos_campos_restantes')
                else:
                    chosen = next(j for j, source in enumerate(b) if source['linha'] == possible[0]['linha'])
                    context_match = matching(edges, len(a), (left, chosen))
        proposals = []; before = case['texto_corrigido'] or case['texto_original']; after = before
        if possible:
            names = PERSON_NAMES if case['tipo'] == 'pessoas' else FAMILY_NAMES
            current = parse_profile(before, guides[('127', case['tipo'])], names)[0]
            possible_profiles = [parse_profile(r['texto'], guides[('25', case['tipo'])], names)[0] for r in possible]
            for index, name in enumerate(names):
                values = {p[index] for p in possible_profiles}
                if len(values) != 1:
                    reasons.append('valor_recuperado_ambiguo_' + name)
                    continue
                value = possible_profiles[0][index]
                if current[index] == value:
                    continue
                assert current[index] is None and value is not None and name in allowed[case['linha']]
                start, end, _ = guides[('127', case['tipo'])][name]
                replacement = str(value).zfill(end - start); assert len(replacement) == end - start
                proposals.append({'campo': name, 'inicio': start + 1, 'fim': end, 'antes': before[start:end],
                                  'depois': replacement, 'linhas25': [r['linha'] for r in possible]})
                after = after[:start] + replacement + after[end:]
        pairs = []
        if context_match is not None:
            for i, j in sorted(context_match.items()):
                ok, differences = compare_profile(a[i]['texto'], b[j]['texto'], 'pessoas', allowed.get(a[i]['linha'], set()), guides, True)
                assert ok
                pairs.append({'linha127': a[i]['linha'], 'linha25': b[j]['linha'], 'diferencas_preservadas': differences})
        result.append({'linha127': case['linha'], 'tipo': case['tipo'], 'chave': case['chave'],
                       'motivos': sorted(set(reasons)), 'aprovavel_no_criterio': not reasons and bool(proposals),
                       'propostas': proposals, 'pessoas127': len(a), 'pessoas25': len(b),
                       'texto_original': case['texto_original'], 'texto_antes': before,
                       'texto_corrigido_proposto': after, 'fontes25_possiveis': possible,
                       'grupo127': fa + a, 'grupo25': fb + b, 'correspondencias_contexto': pairs,
                       'divergencias_cartao_preservadas': card_delta})
    # Conferir dependencia conjunta: nao usar como prova reparo de outro integrante
    # que esta propria passagem nao conseguiu aprovar.
    changed = True
    while changed:
        approved = {r['linha127']: {p['campo'] for p in r['propostas']} for r in result if r['aprovavel_no_criterio']}
        changed = False
        for r in result:
            if not r['aprovavel_no_criterio']:
                continue
            for pair in r['correspondencias_contexto']:
                for field, (x, y) in pair['diferencas_preservadas'].items():
                    if field == 'V216' and {x, y} == {0, 63}:
                        continue
                    if field not in approved.get(pair['linha127'], set()):
                        r['motivos'].append('contexto_depende_reparo_nao_aprovado')
                        r['aprovavel_no_criterio'] = False; changed = True
    raw_path = root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt'
    expected = {r['linha']: r['texto'] for c in cases for r in c['grupo127']}
    with raw_path.open(encoding='latin1') as f:
        for n, line in enumerate(f, 1):
            if n not in expected:
                continue
            raw = line.rstrip('\r\n')
            if n in byline:
                assert byline[n]['texto_original'] == raw
                raw = byline[n]['texto_corrigido'] or raw
            assert raw == expected[n]
    source_rows = {}
    for c in cases:
        for r in c['grupo25']:
            source_rows.setdefault(r['arquivo'], {})[r['linha']] = r['texto']
    for name, expected_rows in source_rows.items():
        seen = set()
        with gzip.open(root / name, 'rt', encoding='latin1') as f:
            for n, line in enumerate(f, 1):
                if n in expected_rows:
                    assert line.rstrip('\r\n') == expected_rows[n]; seen.add(n)
        assert seen == set(expected_rows)
    for name, digest in hashes.items():
        assert checksum(root / name) == digest, 'Fonte mudou durante leitura: ' + name
    summary = {'casos': len(result), 'aprovaveis': sum(r['aprovavel_no_criterio'] for r in result),
               'residuos': sum(not r['aprovavel_no_criterio'] for r in result),
               'motivos': dict(Counter(m for r in result if not r['aprovavel_no_criterio'] for m in set(r['motivos'])))}
    payload = {'criterio': 'Identidade geografica e cartao mantidos; grupo completo, multiplicidades e ordens. Campos legiveis do alvo exatos. Conflitos V21600/63 e atributos domiciliares nao identificadores documentados somente no contexto. Dano127 convertido emNA nao conta como igualdade a ausencia25. Dependencias de reparo conjuntas aprovadas.',
               'resumo': summary, 'fontes_sha256': hashes, 'casos': result,
               'reparos': [r for r in result if r['aprovavel_no_criterio']],
               'residuos': [r for r in result if not r['aprovavel_no_criterio']]}
    (out / 'selecao_final_reparos.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    print('Aprovaveis:', [r['linha127'] for r in payload['reparos']])


if __name__ == '__main__':
    main()
