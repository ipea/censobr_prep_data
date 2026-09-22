"""Inventario independente dos defeitos de texto; nao corrige nem exclui dados."""
import argparse
from collections import Counter, defaultdict
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re

from auditoria_recuperacao_cartoes_1960 import UF, PERSON_NAMES, FAMILY_NAMES, rows, load_guides, parse_profile


def checksum(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        while block := f.read(4 * 1024 ** 2):
            h.update(block)
    return h.hexdigest()


def fields(text, guide):
    result = {}
    for name, start, end, valid, blank in guide:
        raw = text[start:end]
        jump = raw.startswith('-') and not raw[1:].strip()
        ok = ((raw in valid or (blank and not raw.strip())) if valid else
              not re.search('[^0-9 ]', raw)) or jump
        result[name] = {'literal': raw, 'valido': bool(ok), 'salto_local': jump}
    return result


def issues(text, guide):
    values = fields(text, guide)
    return {
        'dicionario': [k for k, v in values.items() if not v['valido']],
        'caractere': bool(re.search(r'[^0-9 \\-]', text)),
        'espaco': bool(re.search('[0-9] {1,3}[0-9]', text)),
        'estrutura': (any(i + 1 not in {20, 21, 33, 36, 47} for i, c in enumerate(text) if c == '-') or
                      text[54:55] != '\\' or '\\' in text[:54]),
        'comprimento': len(text) != 62,
        'chave': not text[:16].isdigit(),
    }


def key(text):
    parts = [text[:2], text[8:13], text[13:16]]
    return tuple(int(x) for x in parts) if all(x.isdigit() for x in parts) else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    parser.add_argument('--linhas', nargs='*', type=int)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = root / args.out
    out.mkdir(parents=True, exist_ok=False)
    paths = [root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt',
             root / 'read_guides/1960_amostra_127_correcoes.csv']
    guides = {}; matching_guides = load_guides(root)
    for kind in ['familias', 'pessoas']:
        path = root / f'read_guides/readguide_1960_amostra_127_{kind}.csv'
        paths.append(path)
        guides[kind] = [(r['variavel'], int(r['inicio']) - 1, int(r['fim']),
                        set(r['valores_validos'].split(';')) - {'', 'NA'},
                        bool({'', 'NA'} & set(r['valores_validos'].split(';'))))
                       for r in rows(path) if r['variavel'] not in {'BARRA', 'ID'}]
    decisions = {int(r['linha']): r for r in rows(paths[1])}
    selected = {n: r for n, r in decisions.items() if not args.linhas or n in args.linhas}
    hashes = {str(p.relative_to(root)): checksum(p) for p in paths}
    wanted = {key(r['texto_corrigido'] or r['texto_original']) for r in selected.values()}
    wanted.discard(None)
    groups127 = defaultdict(list); cases = []; suspect = []; lengths = Counter(); count = 0
    context = {n + offset for n in [855822, 951432, 951433] for offset in range(-5, 6)}
    context_rows = []
    with paths[0].open(encoding='latin1') as f:
        for n, raw in enumerate(f, 1):
            text = raw.rstrip('\r\n'); count += 1; lengths[len(text)] += 1
            if n in context:
                context_rows.append({'linha': n, 'texto': text})
            kind = 'familias' if text[16:17] == '1' else 'pessoas'
            found = issues(text, guides[kind]) if not args.linhas or n in selected else None
            if found and any(found.values()):
                suspect.append({'linha': n, 'tipo': text[16:17], 'falhas': found,
                                'decisao': decisions.get(n, {}).get('decisao')})
            decision = decisions.get(n)
            corrected = (decision['texto_corrigido'] or text) if decision else text
            if key(corrected) in wanted:
                groups127[key(corrected)].append({'linha': n, 'texto': corrected,
                                                 'decisao': decision['decisao'] if decision else None})
            if n not in selected:
                continue
            assert text == decision['texto_original'], f'Original difere: {n}'
            before = fields(text, guides[kind]); after = fields(corrected, guides[kind])
            cases.append({'linha': n, 'tipo': kind, 'decisao': decision['decisao'],
                          'texto_original': text, 'texto_corrigido': decision['texto_corrigido'],
                          'chave': key(corrected), 'justificativa': decision['explicacao'],
                          'campos_alterados': {k: [before[k]['literal'], v['literal']] for k, v in after.items()
                                               if before[k]['literal'] != v['literal']},
                          'falhas_apos_texto': issues(corrected, guides[kind]), 'campos_apos': after})
    groups25 = defaultdict(list)
    for uf in sorted({k[0] for k in wanted if k[0] in UF}):
        path = root / f'data/release_legacy/Censo.1960.amostra.25porcento.{UF[uf]}.gz'
        if not path.exists():
            continue
        paths.append(path); hashes[str(path.relative_to(root))] = checksum(path)
        keys_uf = {(k[1], k[2]) for k in wanted if k[0] == uf}
        with gzip.open(path, 'rt', encoding='latin1') as f:
            for n, raw in enumerate(f, 1):
                text = raw.rstrip('\r\n')
                if not text[:8].isdigit() or (int(text[:5]), int(text[5:8])) not in keys_uf:
                    continue
                k = (uf, int(text[:5]), int(text[5:8]))
                groups25[k].append({'linha': n, 'texto': text,
                                    'tipo': 'familias' if text[8:10] == '00' else 'pessoas',
                                    'arquivo': str(path.relative_to(root))})
        print(f'Conferida fonte25 {UF[uf]}', flush=True)
    for case in cases:
        k = case['chave']; kind = case['tipo']; names = PERSON_NAMES if kind == 'pessoas' else FAMILY_NAMES
        text = case['texto_corrigido'] or case['texto_original']
        profile, invalid = parse_profile(text, matching_guides[('127', kind)], names)
        candidates = []
        for source in groups25.get(k, []):
            if source['tipo'] != kind:
                continue
            other, bad = parse_profile(source['texto'], matching_guides[('25', kind)], names)
            diff = {name: [a, b] for name, a, b in zip(names, profile, other) if a != b}
            known_diff = {name: val for name, val in diff.items() if val[0] is not None and val[1] is not None}
            candidates.append({**source, 'diferencas': diff, 'diferencas_legiveis': known_diff,
                               'iguais_legiveis': sum(a is not None and a == b for a, b in zip(profile, other)),
                               'campos_invalidos25': bad})
        candidates.sort(key=lambda r: (len(r['diferencas_legiveis']), -r['iguais_legiveis'], len(r['diferencas'])))
        case['candidatos25'] = candidates
        case['grupo127'] = groups127.get(k, [])
        case['grupo25'] = groups25.get(k, [])
        case['campos_invalidos127_comuns'] = invalid
        if case['decisao'] == 'corrompida':
            case['status'] = 'conteudo_ilegivel_sem_correspondencia_demonstrada'
        elif case['decisao'] == 'cartao_uf':
            case['status'] = 'cabecalho_nao_pessoal'
        elif not candidates:
            case['status'] = 'sem_candidato25_pela_chave'
        elif candidates[0]['diferencas_legiveis']:
            case['status'] = 'melhor_candidato_tem_divergencia_legivel'
        elif candidates[0]['diferencas']:
            case['status'] = 'candidato_compativel_campos_danificados_ou_ausentes'
        else:
            case['status'] = 'candidato_igual_nos_campos_comuns'
    for p in paths:
        assert checksum(p) == hashes[str(p.relative_to(root))], f'Fonte mudou: {p}'
    report = {'linhas_HHOLDA': count, 'comprimentos': dict(lengths),
              'decisoes_examinadas': len(cases), 'decisoes_por_tipo': dict(Counter(c['decisao'] for c in cases)),
              'status': dict(Counter(c['status'] for c in cases)),
              'suspeitas': len(suspect), 'suspeitas_sem_decisao': [s for s in suspect if not s['decisao']],
              'fontes_sha256': hashes, 'limite': 'Candidato nao e decisao de correspondencia nem correcao aprovada.'}
    for name, content in [('resumo.json', report), ('casos.json', cases), ('suspeitas.json', suspect),
                          ('contexto_corrompidas.json', context_rows)]:
        (out / name).write_text(json.dumps(content, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
