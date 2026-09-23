"""Rele alvos e alternativas dos dez candidatos compostos, sem promover manifestos."""
import argparse
from collections import Counter
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as core
from fechamento_integral_1960_vinculos import ROOT, INDEX, INV, read, dump, serial


def main(base, out):
    out.mkdir(parents=True, exist_ok=False)
    scan = read(str(base.relative_to(ROOT) / 'resultado.json'))
    selected = [g for g in scan['grupos'] if g['candidato_sem_alternativa_sob_nova_via']]
    assert len(selected) == 10 and sum(len(g['linhas127']) for g in selected) == 27
    guides = core.load_guides(ROOT)
    conn = sqlite3.connect((ROOT / INDEX).as_uri() + '?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    inv = read(INV)
    pending = {n for g in inv['duplicatas_pendentes'] for n in g['linhas']}
    corrections = {int(r['linha']): r for r in core.rows(ROOT / core.FIXED_SOURCES[1])}
    prepared = []; analyses = []; cards = []; snapshot = {}
    for uf in sorted({g['chave'][0] for g in selected}):
        group_uf = [g for g in selected if g['chave'][0] == uf]
        fs, ps = core.read_source(ROOT, uf, {tuple(g['chave'][1:]) for g in group_uf})
        ownkeys = set(); todo = []
        for group in group_uf:
            key = tuple(group['chave'])
            people = core.fetch(conn, 'SELECT * FROM pessoas WHERE uf=? AND pasta=? AND boletim=? AND excluida=0 ORDER BY linha', key)
            assert sorted(p['linha'] for p in people) == sorted(group['linhas127'])
            reasons, card = core.evaluate_group(key, fs[key[1:]], ps[key[1:]], people, guides, pending)
            assert not reasons and card is not None, (key, reasons)
            candidates, evidence = core.candidate_families(conn, key, fs[key[1:]][0], people, guides)
            ownkeys.update((f['pasta'], f['boletim']) for f in candidates.values())
            todo.append((group, key, people, card, candidates, evidence))
        ownfs, ownps = core.read_source(ROOT, uf, ownkeys)
        for group, key, people, card, candidates, evidence in todo:
            target = Counter(p['perfil'] for p in people)
            fprofile, invalid = core.parse_profile(card['texto_25'], guides['25', 'familias'], core.FAMILY_NAMES)
            assert not invalid
            evaluated = []; relied = []; exceptional = []
            for line, family in sorted(candidates.items()):
                own, direct = core.own_group_proof(conn, family, ownfs, ownps, guides, pending, permitir_contexto=True)
                physical = Counter(p['perfil'] for p in core.fetch(conn, 'SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0', (line,)))
                samegeo = (family['uf'], family['municipio'], family['situacao']) == (uf, core.integer(card['V116']), core.integer(card['V118']))
                samebody = family['perfil'] == core.profile_hash(fprofile) and not family['invalidos']
                strong = bool(evidence[line] & {'mesmo_municipio_distrito_boletim', 'chave_ate_um_caractere'})
                species = family['corrigido'][18] == card['familias']['V101']
                before = core.alternative_reasons(samegeo, samebody, strong, direct, physical, target, own['confirmado'], species)
                compound = None
                if before:
                    compound = scan['alternativas'].get(str(line))
                    assert compound and compound['via_composicao24_unica_nas_duas_fontes'], (key, line)
                    current_people = core.fetch(conn, 'SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha', (line,))
                    assert compound['cartao127'] == serial(family)
                    assert compound['pessoas127'] == [serial(p) for p in current_people]
                    assert compound['cartoes25'] == ownfs[family['pasta'], family['boletim']]
                    assert compound['pessoas25'] == ownps[family['pasta'], family['boletim']]
                    assert own['motivos_estritos'] == ['composicao_propria_diverge']
                    assert len(compound['ocorrencias_grupo24_na127']) == len(compound['ocorrencias_grupo24_na25']) == 1
                    assert compound['ocorrencias_grupo24_na127'][0]['cartao'] == line
                    assert compound['ocorrencias_grupo24_na25'][0]['chave'] == f"{family['pasta']:05d}{family['boletim']:03d}"
                    assert compound['pares_nova_busca']
                    for pair in compound['pares_nova_busca']:
                        assert set(pair['diferencas']) <= {'V216'}
                        if pair['diferencas'] and set(pair['diferencas']['V216']) != {0, 63}:
                            exceptional.append(pair)
                    relied.append(line)
                    snapshot[line] = compound
                    own['confirmado'] = True
                    own['criterio'] = 'multiconjunto24_unico_ambas_fontes_da_UF_respostas_preservadas'
                after = core.alternative_reasons(samegeo, samebody, strong, direct, physical, target, own['confirmado'], species)
                assert not after, (key, line, after)
                evaluated.append({'linha_cartao127': line, 'pistas': sorted(evidence[line]),
                    'motivos_antes': before, 'motivos_depois': after, 'prova_grupo_proprio': own,
                    'usou_prova_composta': compound is not None})
            card['verificacoes'] = {'perfil_pessoal_campos': core.PERSON_NAMES, 'composicao_integral': True,
                'ordens_redundancias_v100': True, 'geografia_integral': True,
                'pessoas_nao_acrescentadas_nem_corrigidas': True, 'cartao127_ausente_chave_sem_distrito': True,
                'cartoes127_examinados': len(candidates), 'alternativas_plausiveis': 0,
                'busca': 'Auditor historico refeito; alternativas identificadas por composicao24 conjunta unica nas duas fontes estaduais.',
                'evidencia_alternativas': str((out / 'pacote.json').relative_to(ROOT)).replace('\\', '/')}
            card['prova_composta_candidata'] = {'cartoes_decisivos': relied, 'V216_apenas_00_63': not exceptional,
                                               'divergencias_V216_adicionais': exceptional}
            cards.append(card)
            analyses.append({'id_recuperacao': card['id_recuperacao'], 'cartoes_examinados': evaluated})
    # Releitura binaria independente do indice127 de todos os literais decisivos.
    records = {}
    for card in cards:
        for p in card['pessoas']:
            records[p['linha']] = (p['texto_original'], p['texto_corrigido'])
    for c in snapshot.values():
        for p in [c['cartao127']] + c['pessoas127']:
            records[p['linha']] = (p['original'], p['corrigido'])
    with (ROOT / core.FIXED_SOURCES[0]).open('rb') as stream:
        for line, (original, corrected) in records.items():
            stream.seek((line - 1) * 64)
            assert stream.read(62).decode('latin1') == original
            assert corrected == (corrections.get(line, {}).get('texto_corrigido') or original)
    files = core.FIXED_SOURCES + [INV, INDEX, str((base / 'resultado.json').relative_to(ROOT)),
        'references/fechamento_integral_1960_vinculos.py', 'references/fechamento_integral_1960_vinculos_pacote.py']
    files.extend(scan['fontes25_sha256'])
    sources = [{'arquivo': p.replace('\\', '/'), 'sha256': core.sha256(ROOT / p)} for p in files]
    result = {'versao': 1, 'situacao': 'candidatos_para_revisao_sem_promocao', 'pessoas_novas': 0,
        'respostas_alteradas': 0, 'cartoes': cards, 'analises': analyses,
        'provas_compostas': snapshot, 'fontes': sources,
        'chaves25_repartidas_reagrupadas': scan['chaves25_repartidas_reagrupadas'],
        'contraprovas_MG40880': {n: scan['alternativas'][n] for n in ['405480', '405486']},
        'limite_MG': 'Elimina dois concorrentes de cartao; nao aplica nem torna independente a proposta textual de405458.'}
    dump(out / 'pacote.json', result)
    print(json.dumps({'cartoes': len(cards), 'pessoas': sum(c['n_pessoas'] for c in cards),
        'cartoes_apenas_00_63': sum(c['prova_composta_candidata']['V216_apenas_00_63'] for c in cards),
        'cartoes_com_V216_adicional': [c['id_recuperacao'] for c in cards if not c['prova_composta_candidata']['V216_apenas_00_63']],
        'literais127_relidos': len(records), 'provas_compostas_decisivas': len(snapshot)}))


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--base', required=True)
    p.add_argument('--out', required=True)
    a = p.parse_args()
    output = (ROOT / a.out).resolve()
    if not output.is_relative_to(ROOT / 'tmp/fechamento_integral_1960/vinculos'):
        raise ValueError('Saida fora do escopo')
    main((ROOT / a.base).resolve(), output)
