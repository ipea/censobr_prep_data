"""Propostas MG para teste isolado; nao escreve manifestos reais."""
import argparse
from collections import Counter
import copy
import sqlite3

import auditoria_recuperacao_cartoes_1960 as core
from fechamento_integral_1960_vinculos import ROOT, INDEX, INV, read, dump


def main(out):
    out.mkdir(parents=True, exist_ok=False)
    proof = read('tmp/fechamento_integral_1960/vinculos/mg01/mg405458.json')
    guides = core.load_guides(ROOT)
    conn = sqlite3.connect((ROOT / INDEX).as_uri() + '?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    people = core.fetch(conn, 'SELECT * FROM pessoas WHERE linha BETWEEN 405457 AND 405459 ORDER BY linha')
    prior = copy.deepcopy(people)
    people[1]['corrigido'] = proof['proposta_textual_nao_aplicada']['depois_apenas_em_memoria']
    p, bad = core.parse_profile(people[1]['corrigido'], guides['127', 'pessoas'], core.PERSON_NAMES)
    assert not bad
    people[1]['perfil'] = core.profile_hash(p)
    people[1]['invalidos'] = ''
    key = (40, 40880, 1)
    pending = {n for g in read(INV)['duplicatas_pendentes'] for n in g['linhas']}
    reasons, card = core.evaluate_group(key, [proof['cartao25']], proof['pessoas25'], people, guides, pending)
    assert not reasons, reasons
    candidates, evidence = core.candidate_families(conn, key, proof['cartao25'], people, guides)
    fs, ps = core.read_source(ROOT, 40, {(f['pasta'], f['boletim']) for f in candidates.values()})
    fprofile, _ = core.parse_profile(proof['cartao25']['texto'], guides['25', 'familias'], core.FAMILY_NAMES)
    target = Counter(p['perfil'] for p in people)
    evaluated = []; decisive = []
    for line, family in sorted(candidates.items()):
        own, direct = core.own_group_proof(conn, family, fs, ps, guides, pending, permitir_contexto=True)
        physical = Counter(p['perfil'] for p in core.fetch(conn, 'SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0', (line,)))
        samegeo = (family['uf'], family['municipio'], family['situacao']) == (40, core.integer(card['V116']), core.integer(card['V118']))
        samebody = family['perfil'] == core.profile_hash(fprofile) and not family['invalidos']
        strong = bool(evidence[line] & {'mesmo_municipio_distrito_boletim', 'chave_ate_um_caractere'})
        species = family['corrigido'][18] == card['familias']['V101']
        before = core.alternative_reasons(samegeo, samebody, strong, direct, physical, target, own['confirmado'], species)
        if before:
            compound = proof['alternativas_explicadas_sem_usar_texto_alvo'][str(line)]
            assert compound['via_composicao24_unica_nas_duas_fontes']
            assert all((p['uf'], p['municipio'], p['distrito'], p['pasta'], p['boletim'], p['situacao']) ==
                       (family['uf'], family['municipio'], family['distrito'], family['pasta'], family['boletim'], family['situacao'])
                       for p in core.fetch(conn, 'SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0', (line,)))
            own['confirmado'] = True
            own['criterio'] = 'multiconjunto24_unico_ambas_fontes_da_UF_respostas_preservadas'
            decisive.append(line)
        after = core.alternative_reasons(samegeo, samebody, strong, direct, physical, target, own['confirmado'], species)
        assert not after, (line, after)
        evaluated.append({'linha_cartao127': line, 'pistas': sorted(evidence[line]), 'motivos_antes': before,
            'motivos_depois': after, 'prova_grupo_proprio': own, 'usou_prova_composta': bool(before)})
    assert decisive == [405480, 405486]
    card['prova_composta_candidata'] = {'cartoes_decisivos': decisive, 'V216_apenas_00_63': True, 'divergencias_V216_adicionais': []}
    card['verificacoes'] = {'perfil_pessoal_campos': core.PERSON_NAMES, 'composicao_integral': True,
        'ordens_redundancias_v100': True, 'geografia_integral': True, 'pessoas_nao_acrescentadas_nem_corrigidas': False,
        'reparo_pessoal_localizado_previo': 405458, 'cartao127_ausente_chave_sem_distrito': True,
        'cartoes127_examinados': len(candidates), 'alternativas_plausiveis': 0,
        'evidencia_alternativas': str((out / 'proposta_mg.json').relative_to(ROOT)).replace('\\', '/')}
    source = card['arquivo_25']
    repair = {'linha127': 405458, 'tipo': 'pessoas', 'chave': list(key), 'motivos': [], 'aprovavel_no_criterio': True,
        'propostas': [{'campo': 'V203', 'inicio': 20, 'fim': 20, 'antes': ' ', 'depois': '7', 'linhas25': [567047]},
                      {'campo': 'AGE', 'inicio': 22, 'fim': 23, 'antes': ' 9', 'depois': '79', 'linhas25': [567047]}],
        'pessoas127': 3, 'pessoas25': 3, 'texto_original': prior[1]['original'], 'texto_antes': prior[1]['original'],
        'texto_corrigido_proposto': people[1]['corrigido'],
        'fontes25_possiveis': [{**p, 'tipo': 'pessoas', 'arquivo': source} for p in proof['pessoas25'] if p['linha'] == 567047],
        'grupo127': [{'linha': p['linha'], 'texto': p['original'], 'decisao': 'valor_isolado' if p['linha'] == 405458 else None} for p in prior],
        'grupo25': [{**proof['cartao25'], 'tipo': 'familias', 'arquivo': source}] +
                  [{**p, 'tipo': 'pessoas', 'arquivo': source} for p in proof['pessoas25']],
        'criterio_identidade_contexto': 'duas_testemunhas_intactas_conjuntas_v1',
        'testemunhas_identidade': [{'linha127': 405457, 'linha25': 567048, 'campos_ignorados': []},
                                  {'linha127': 405459, 'linha25': 567049, 'campos_ignorados': []}],
        'divergencias_cartao_preservadas': {}, 'divergencias_pessoais_preservadas': [],
        'geografia_parcial_preservada': [], 'tipo_registro_preservado': '3',
        'ressalva': 'V203=7 e resposta recuperada; REC_TYPE=3 e conservado literalmente, nao recodificado para2.'}
    files = core.FIXED_SOURCES + [source, INDEX, 'tmp/fechamento_integral_1960/vinculos/mg01/mg405458.json']
    sources = [{'arquivo': p, 'sha256': core.sha256(ROOT / p)} for p in files]
    dump(out / 'proposta_mg.json', {'versao': 1, 'pessoas_novas': 0, 'respostas_alteradas': 0,
        'nota': 'A prova de cartao nao altera respostas; o reparo abaixo e etapa anterior separada.',
        'cartoes': [card], 'analises': [{'id_recuperacao': card['id_recuperacao'], 'cartoes_examinados': evaluated}],
        'provas_compostas': proof['alternativas_explicadas_sem_usar_texto_alvo'],
        'fontes': sources, 'reparo_proposto': repair})
    print({'cartao': card['id_recuperacao'], 'cartoes_examinados': len(candidates), 'decisivos': decisive,
           'reparo_nao_aplicado': 405458, 'tipo_preservado': people[1]['corrigido'][16]})


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--out', required=True); args = parser.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / 'tmp/fechamento_integral_1960/vinculos'):
        raise ValueError('Saida fora do escopo')
    main(out)
