"""Identifica contexto MG usando apenas os dois integrantes intactos, sem reparar texto."""
import argparse
from collections import defaultdict, Counter
import gzip
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as core
import investigacao_residual_vinculos_1960 as sig
from fechamento_integral_1960_vinculos import ROOT, INDEX, read, dump, serial


def main(out):
    out.mkdir(parents=True, exist_ok=False)
    guides = core.load_guides(ROOT)
    conn = sqlite3.connect((ROOT / INDEX).as_uri() + '?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    persons = core.fetch(conn, 'SELECT * FROM pessoas WHERE linha BETWEEN 405457 AND 405459 ORDER BY linha')
    assert [p['linha'] for p in persons] == [405457, 405458, 405459]
    intact = [persons[0], persons[2]]
    damaged = persons[1]
    raw = sig.signatures(damaged['corrigido'], '127')[0]
    assert damaged['corrigido'][19] == ' ' and damaged['corrigido'][21:23] == ' 9'
    mask = raw[:1] + '?' + raw[2:3] + '?' + raw[4:]
    profiles = {p['linha']: sig.signatures(p['corrigido'], '127')[0] for p in intact}
    hits = {n: [] for n in profiles}; damaged_hits = []; source_hashes = {}
    for uf, label in sorted(core.UF.items()):
        path = ROOT / f'data/release_legacy/Censo.1960.amostra.25porcento.{label}.gz'
        source_hashes[str(path.relative_to(ROOT))] = core.sha256(path)
        with gzip.open(path, 'rt', encoding='latin1') as stream:
            for line, text in enumerate(stream, 1):
                text = text.rstrip('\r\n')
                if text[8:10] == '00':
                    continue
                full = sig.signatures(text, '25')[0]
                matches = [n for n, profile in profiles.items() if profile == full]
                compatible = all(a == '?' or a == b for a, b in zip(mask, full)) and len(full) == len(mask)
                if not matches and not compatible:
                    continue
                _, invalid = core.parse_profile(text, guides['25', 'pessoas'], core.PERSON_NAMES)
                if invalid:
                    continue
                item = {'UF': uf, 'linha': line, 'texto': text,
                        'chave': [uf, core.integer(text[:5]), core.integer(text[5:8])]}
                for n in matches:
                    hits[n].append(item)
                if compatible:
                    damaged_hits.append(item)
        print('Testemunhas intactas e caracteres preservados:', label, flush=True)
    key_sets = [{tuple(h['chave']) for h in hits[n]} for n in profiles]
    joint25 = set.intersection(*key_sets)
    assert joint25 == {(40, 40880, 1)}
    hits127 = {}
    keys127 = []
    for p in intact:
        found = core.fetch(conn, 'SELECT linha,uf,pasta,boletim,familia_atual,original,corrigido FROM pessoas WHERE perfil=? AND excluida=0', (p['perfil'],))
        hits127[p['linha']] = found
        keys127.append({(r['uf'], r['pasta'], r['boletim']) for r in found})
    joint127 = set.intersection(*keys127)
    assert joint127 == {(40, 40880, 1)}
    assert len(damaged_hits) == 1 and damaged_hits[0]['chave'] == [40, 40880, 1]
    fs, ps = core.read_source(ROOT, 40, {(40880, 1)})
    source_card = fs[40880, 1][0]
    source_people = ps[40880, 1]
    assert len(fs[40880, 1]) == 1 and not core.source_structure(source_card, source_people)
    assert len(source_people) == 3
    assert all(p['uf'] == 40 and p['pasta'] == 40880 and p['boletim'] == 1 and
        p['municipio'] == core.integer(source_card['texto'][29:33]) and
        p['distrito'] == core.integer(source_card['texto'][33:35]) and
        p['situacao'] == core.integer(source_card['texto'][35]) for p in persons)
    # Localizadores de correcao e corpo legivel nunca entram na identificacao conjunta.
    candidate_text = damaged['corrigido'][:19] + '7' + damaged['corrigido'][20:21] + '79' + damaged['corrigido'][23:]
    changed_positions = [i + 1 for i, (a, b) in enumerate(zip(damaged['corrigido'], candidate_text)) if a != b]
    assert changed_positions == [20, 22]
    candidate_profile, bad = core.parse_profile(candidate_text, guides['127', 'pessoas'], core.PERSON_NAMES)
    source_profile, bad25 = core.parse_profile(damaged_hits[0]['texto'], guides['25', 'pessoas'], core.PERSON_NAMES)
    assert not bad and not bad25 and candidate_profile == source_profile
    scan = read('tmp/fechamento_integral_1960/vinculos/integral02/resultado.json')
    exclusions = {n: scan['alternativas'][n] for n in ['405480', '405486']}
    for c in exclusions.values():
        assert c['via_composicao24_unica_nas_duas_fontes']
        for p in c['pares_nova_busca']:
            assert set(p['diferencas']) <= {'V216'}
            assert not p['diferencas'] or set(p['diferencas']['V216']) == {0, 63}
    result = {'situacao': 'evidencia_para_revisao_sem_aplicacao',
        'pessoas127': [serial(p) for p in persons], 'cartao25': source_card, 'pessoas25': source_people,
        'identificacao_sem_usar_405458': {'linhas_intactas': [405457, 405459],
            'ocorrencias_completas25': hits, 'ocorrencias_completas127': hits127,
            'chaves_conjuntas25_todas17UF': sorted(joint25), 'chaves_conjuntas127_todasUF': sorted(joint127)},
        'consulta_independente_caracteres_legiveis_405458': {'mascara': mask,
            'posicoes_ignoradas_na_linha127': [20, 22], 'ocorrencias_todas17UF': damaged_hits},
        'proposta_textual_nao_aplicada': {'linha': 405458, 'antes': damaged['corrigido'],
            'depois_apenas_em_memoria': candidate_text, 'posicoes_alteradas': changed_positions,
            'V203': [' ', '7'], 'AGE': [' 9', '79'], 'digito_9_preservado': True},
        'alternativas_explicadas_sem_usar_texto_alvo': exclusions,
        'fontes25_sha256': source_hashes, 'indice127': INDEX, 'indice127_sha256': core.sha256(ROOT / INDEX),
        'limite': 'A conjuncao das duas testemunhas intactas localiza somente40880/001 nasfontesdisponiveis. Nenhuma resposta foi preenchida ou dado reconstruido.'}
    dump(out / 'mg405458.json', result)
    print({'intactos25': {n: len(v) for n, v in hits.items()}, 'chaves_conjuntas25': sorted(joint25),
           'candidatos_preservando_caracteres_danificados': len(damaged_hits), 'decisoes_aplicadas': 0})


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / 'tmp/fechamento_integral_1960/vinculos'):
        raise ValueError('Saida fora do escopo')
    main(out)
