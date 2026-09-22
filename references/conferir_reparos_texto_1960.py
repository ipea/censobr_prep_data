"""Prova de composicao integral para candidatos de reparo de texto; sem aplicacao."""
import argparse
from collections import Counter
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import rows, load_guides, parse_profile, PERSON_NAMES, FAMILY_NAMES, source_structure
from auditoria_pendencias_texto_1960 import checksum


def matching(edges, size, forced=None):
    assigned = {}
    if forced:
        if forced[1] not in edges[forced[0]]:
            return None
        assigned[forced[1]] = forced[0]

    def place(left, visited):
        for right in edges[left]:
            if right in visited or (forced and right == forced[1]):
                continue
            visited.add(right)
            if right not in assigned or place(assigned[right], visited):
                assigned[right] = left
                return True
        return False

    for left in range(size):
        if forced and left == forced[0]:
            continue
        if not place(left, set()):
            return None
    return {left: right for right, left in assigned.items()}


def compatible(text, other, kind, decision, guides, required=frozenset(), context_v216=False):
    names = PERSON_NAMES if kind == 'pessoas' else FAMILY_NAMES
    p, invalid = parse_profile(text, guides[('127', kind)], names)
    q, bad = parse_profile(other, guides[('25', kind)], names)
    if bad:
        return False
    for name, a, b in zip(names, p, q):
        if a == b:
            continue
        if context_v216 and name == 'V216' and {a, b} == {0, 63}:
            continue
        start, end, _ = guides[('127', kind)][name]
        damaged = name in invalid or (decision and name in required and a is None) or (decision and decision['decisao'] in {'reparo', 'recuperada'}
                                      and not text[start:end].strip())
        if a is not None or b is None or not damaged:
            return False
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inventario', required=True)
    parser.add_argument('--out', required=True)
    parser.add_argument('--contexto-v216', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = root / args.out; out.mkdir(parents=True, exist_ok=False)
    source_inventory = root / args.inventario
    cases = json.loads(source_inventory.read_text(encoding='utf-8'))
    inventory_sources = json.loads((source_inventory.parent / 'resumo.json').read_text(encoding='utf-8'))['fontes_sha256']
    for path, digest in inventory_sources.items():
        assert checksum(root / path) == digest, 'Fonte do inventario mudou: ' + path
    decisions = {int(r['linha']): r for r in rows(root / 'read_guides/1960_amostra_127_correcoes.csv')}
    dup_path = root / 'read_guides/1960_amostra_127_duplicatas.csv'
    hashes = dict(inventory_sources)
    for p in [source_inventory, dup_path, Path(__file__),
              root / 'references/auditoria_recuperacao_cartoes_1960.py',
              root / 'references/auditoria_pendencias_texto_1960.py']:
        hashes[str(p.relative_to(root))] = checksum(p)
    required = {}
    for kind in ['familias', 'pessoas']:
        path = root / f'read_guides/readguide_1960_amostra_25_{kind}.csv'
        hashes[str(path.relative_to(root))] = checksum(path)
        guide127 = rows(root / f'read_guides/readguide_1960_amostra_127_{kind}.csv')
        required[kind] = {r['variavel'] for r in guide127
                          if r['valores_validos'] and not {'', 'NA'} & set(r['valores_validos'].split(';'))}
    removed = {int(r['linha']) for r in rows(dup_path) if r['acao'] == 'remover'}
    guides = load_guides(root); result = []; groups = {}
    for case in cases:
        if case['status'] != 'candidato_compativel_campos_danificados_ou_ausentes':
            continue
        group_key = tuple(case['chave'])
        if group_key not in groups:
            group127 = [r for r in case['grupo127'] if r['linha'] not in removed]
            p127 = [r for r in group127 if r['texto'][16] in '23']
            f127 = [r for r in group127 if r['texto'][16] == '1']
            p25 = [r for r in case['grupo25'] if r['tipo'] == 'pessoas']
            f25 = [r for r in case['grupo25'] if r['tipo'] == 'familias']
            reasons = []; edges = []; match = None; source = f25[0] if len(f25) == 1 else None
            if len(f127) != 1:
                reasons.append('cartao127_nao_unico')
            if len(f25) != 1:
                reasons.append('cartao25_nao_unico')
            if len(p127) != len(p25):
                reasons.append('contagem_pessoas_diverge')
            if source:
                reasons.extend(source_structure(source, p25))
                if len(f127) == 1 and not compatible(f127[0]['texto'], source['texto'], 'familias',
                                                      decisions.get(f127[0]['linha']), guides, required['familias']):
                    reasons.append('campos_cartao_divergem')
                for row in group127:
                    text = row['texto']
                    for name, value, other in [('municipio', text[2:6], source['texto'][29:33]),
                                               ('distrito', text[6:8], source['texto'][33:35]),
                                               ('situacao', text[17:18], source['texto'][35:36])]:
                        if value != other:
                            reasons.append('geografia_diverge_' + name)
                for row in p127:
                    edges.append([i for i, other in enumerate(p25) if compatible(row['texto'], other['texto'],
                                  'pessoas', decisions.get(row['linha']), guides, required['pessoas'], args.contexto_v216)])
                if len(p127) == len(p25):
                    match = matching(edges, len(p127))
                    if match is None:
                        reasons.append('composicao_integral_nao_confere')
            groups[group_key] = {'pessoas127': p127, 'familias127': f127, 'pessoas25': p25,
                                  'familias25': f25, 'edges': edges, 'match': match,
                                  'motivos': sorted(set(reasons))}
        group = groups[group_key]; reasons = list(group['motivos']); possible = []
        if case['tipo'] == 'familias':
            possible = group['familias25'] if not reasons else []
        elif not reasons:
            left = next(i for i, r in enumerate(group['pessoas127']) if r['linha'] == case['linha'])
            possible = [group['pessoas25'][right] for right in group['edges'][left]
                        if matching(group['edges'], len(group['pessoas127']), (left, right)) is not None
                        and compatible(group['pessoas127'][left]['texto'], group['pessoas25'][right]['texto'],
                                       'pessoas', decisions.get(case['linha']), guides, required['pessoas'])]
        proposals = []; text = case['texto_corrigido'] or case['texto_original']
        if possible:
            names = PERSON_NAMES if case['tipo'] == 'pessoas' else FAMILY_NAMES
            profiles = [parse_profile(r['texto'], guides[('25', case['tipo'])], names)[0] for r in possible]
            current = parse_profile(text, guides[('127', case['tipo'])], names)[0]
            for pos, name in enumerate(names):
                values = set(p[pos] for p in profiles)
                if len(values) != 1:
                    reasons.append('valor_ambiguo_' + name)
                elif current[pos] != profiles[0][pos]:
                    start, end, _ = guides[('127', case['tipo'])][name]
                    replacement = str(profiles[0][pos]).zfill(end - start)
                    if len(replacement) != end - start:
                        reasons.append('valor_nao_cabe_' + name)
                    proposals.append({'campo': name, 'inicio': start + 1, 'fim': end, 'antes': text[start:end],
                                      'depois': replacement, 'linhas25': [r['linha'] for r in possible]})
        corrected = text
        for proposal in proposals:
            corrected = corrected[:proposal['inicio'] - 1] + proposal['depois'] + corrected[proposal['fim']:]
        context_pairs = []
        context_match = group['match']
        if possible and case['tipo'] == 'pessoas':
            right = next(i for i, r in enumerate(group['pessoas25']) if r['linha'] == possible[0]['linha'])
            context_match = matching(group['edges'], len(group['pessoas127']), (left, right))
        if context_match is not None:
            for i, j in context_match.items():
                one = group['pessoas127'][i]; other = group['pessoas25'][j]
                p = parse_profile(one['texto'], guides[('127', 'pessoas')], PERSON_NAMES)[0]
                q = parse_profile(other['texto'], guides[('25', 'pessoas')], PERSON_NAMES)[0]
                context_pairs.append({'linha127': one['linha'], 'linha25': other['linha'],
                                      'diferencas_preservadas': {n: [a, b] for n, a, b in zip(PERSON_NAMES, p, q) if a != b}})
        result.append({'linha127': case['linha'], 'chave': case['chave'], 'motivos': sorted(set(reasons)),
                       'propostas': proposals, 'aprovavel_no_criterio': not reasons and bool(proposals),
                       'pessoas127': len(group['pessoas127']), 'pessoas25': len(group['pessoas25']),
                       'texto_original': case['texto_original'], 'texto_antes': text,
                       'texto_corrigido_proposto': corrected,
                       'fontes25_possiveis': possible,
                       'correspondencias_contexto': context_pairs,
                       'criterio_contexto_v216': args.contexto_v216,
                       'grupo127': group['familias127'] + group['pessoas127'],
                       'grupo25': group['familias25'] + group['pessoas25']})
    for path, digest in hashes.items():
        assert checksum(root / path) == digest
    payload = {'resumo': {'casos': len(result), 'aprovaveis': sum(x['aprovavel_no_criterio'] for x in result),
                         'motivos': dict(Counter(m for x in result for m in x['motivos']))},
               'fontes_sha256': hashes, 'casos': result,
               'limites': ['Nenhuma proposta aplicada.', 'Nao iguala V216=00 e63.',
                          'Exige cartao127 existente e unico; recuperacoes de cartao tratadas por outro manifesto.']}
    (out / 'provas_reparo.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(payload['resumo'], ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
