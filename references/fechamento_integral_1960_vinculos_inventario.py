"""Concilia inventario atual, deltas e causas nominais sem somar sobreposicoes."""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as core

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))


def main(out):
    out.mkdir(parents=True, exist_ok=False)
    inventory_path = 'tmp/fechamento_integral_1960/vinculos/inventario_final01/inventario_final.json'
    inventory = read(inventory_path)
    prior = read('references/resolucao_residuais_1960_evidencias/inventario_atual.json')
    old_links = read('tmp/fechamento_integral_1960/vinculos/integral02/cobertura.json')
    old_duplicates = read('tmp/fechamento_integral_1960/duplicatas/testemunhos458.json')
    scan = read('tmp/fechamento_integral_1960/vinculos/reauditoria01/composicoes/resultado.json')
    families = read('read_guides/1960_amostra_127_familias_coincidentes.json')
    cards = read('read_guides/1960_amostra_127_cartoes_recuperados.json')
    repairs = read('read_guides/1960_amostra_127_reparos_fonte25.json')
    for source in inventory['fontes']:
        assert core.sha256(ROOT / source['arquivo']) == source['sha256']
    old_orphans = {p['linha'] for p in prior['vinculos_pendentes']}
    orphans = {p['linha'] for p in inventory['vinculos_pendentes']}
    geo = {p['linha'] for key in ['conflitos_municipais', 'conflitos_situacao'] for p in inventory[key]}
    old_geo = {p['linha'] for key in ['conflitos_municipais', 'conflitos_situacao'] for p in prior[key]}
    added_cards = [c for c in cards['cartoes'] if 'prova_composta' in c]
    rescued = {p['linha'] for c in added_cards for p in c['pessoas']}
    assert old_orphans - orphans == rescued and len(rescued) == 23
    assert not orphans - old_orphans and geo == old_geo
    actual_groups = {tuple(x['linhas']) for x in inventory['duplicatas_pendentes']}
    old_groups = {tuple(x['linhas']) for x in prior['duplicatas_pendentes']}
    assert old_groups - actual_groups == {(773911, 773913)}
    assert not actual_groups - old_groups
    duplicate_cases = []
    for old in old_duplicates['casos']:
        if tuple(old['linhas127']) not in actual_groups:
            continue
        item = {k: old[k] for k in ['grupo', 'chave', 'linhas127',
            'exclusoes_historicas_sem_prova', 'razao_historica', 'informacao_faltante']}
        item['motivos_atuais'] = old.get('motivos_atuais', ['texto_corrompido_nao_identidade'])
        duplicate_cases.append(item)
    assert {tuple(c['linhas127']) for c in duplicate_cases} == actual_groups
    link_cases = [dict(c) for c in old_links['linhas'] if c['linha'] in orphans | geo]
    assert {c['linha'] for c in link_cases} == orphans | geo
    new_search = {n: c for c in scan['grupos'] for n in c['linhas127']}
    for row in link_cases:
        n = row['linha']
        row['sem_cartao'] = n in orphans
        row['conflito_geografico'] = n in geo
        row['classe'] = row.pop('classe_pesquisa_anterior')
        if n in geo:
            row['informacao_faltante'] = ('Documento que determine qual geografia legivel e correta; '
                'identidade pessoal nao decide municipio ou situacao conflitante.')
        elif row['classe'] == 'fonte_da_uf_ausente':
            row['informacao_faltante'] = 'Fonte estadual25 ou boletim original; HHOLDA identico nao restitui cartao ausente.'
        elif row['classe'] == 'fragmento_sem_identidade':
            row['informacao_faltante'] = 'Texto anterior ao dano, com chave e respostas pessoais legiveis; NA nao identifica registros.'
        elif n in new_search:
            group = new_search[n]
            row['cartoes_concorrentes_apos_nova_pesquisa'] = group['alternativas_restantes_nova_via']
            if group['candidato_sem_alternativa_sob_nova_via']:
                assert group['chave'] in [[71, 70078, 238], [71, 70078, 239]]
                row['cartoes_concorrentes_apos_nova_pesquisa'] = [866162]
                row['informacao_faltante'] = ('Concorrente866162 so seria identificado omitindo divergencia V21619/17; '
                    'fora do criterio estrito00/63 aprovado. Nao substituir nem declarar equivalentes respostas legiveis.')
            else:
                row['informacao_faltante'] = 'Eliminar com prova independente os cartoes concorrentes enumerados; proximidade de chave nao basta.'
        elif row['classe'] == 'composicao24_na_chave_diferencas_preservadas':
            row['informacao_faltante'] = 'Reconciliar diferencas pessoais legiveis sem substituir respostas; o alvo exige composicao25 exata.'
        elif row['classe'] == 'composicao_diverge_mas_ha_duas_testemunhas_unicas':
            row['informacao_faltante'] = 'Explicar a composicao inteira e multiplicidades; duas pessoas nao autorizam importar ou excluir os demais membros.'
        else:
            row['informacao_faltante'] = 'Correspondente integral e cartao identificados com multiplicidades e caracteres preservados; similaridade parcial nao basta.'
    pending_families = [g for g in families['conjuntos'] if g['acao'] == 'pendente']
    damage = [760807, 760919, 760923, 760925, 761056, 761057, 761058, 806791, 806800, 806801]
    records = defaultdict(set)
    for case in duplicate_cases:
        for n in case['linhas127']:
            records[n].add('perfil_pessoal_repetido_pendente')
    for row in link_cases:
        if row['sem_cartao']: records[row['linha']].add('sem_cartao')
        if row['conflito_geografico']: records[row['linha']].add('conflito_geografico')
    for key in ['cartoes_sem_pessoas', 'conviventes_sem_principal', 'corrompidas_sem_grupo_identificavel']:
        for row in inventory[key]: records[row['linha']].add(key)
    for n in damage: records[n].add('dano_textual_nao_resolvido')
    for group in pending_families:
        for n in group['linhas_cartoes']: records[n].add('cartao_de_familia_inteira_coincidente_pendente')
        for n in group['linhas_pessoas']: records[n].add('pessoa_de_familia_inteira_coincidente_pendente')
    con = sqlite3.connect((ROOT / 'tmp/fechamento_integral_1960/vinculos/reauditoria01/indice127.sqlite').as_uri() + '?mode=ro', uri=True)
    ufs = {r[0] for r in con.execute('SELECT DISTINCT uf FROM familias')}
    con.close()
    missing = sorted(ufs - set(core.UF))
    counts = Counter(tag for tags in records.values() for tag in tags)
    summary = {'inventario_atual': inventory['resumo'], 'reparos_textuais': len(repairs['reparos']),
        'duplicatas_particao_exclusiva_por_informacao_faltante': dict(Counter(c['informacao_faltante'] for c in duplicate_cases)),
        'duplicatas_exclusoes_historicas_sem_prova_subconjunto': sum(len(c['exclusoes_historicas_sem_prova']) for c in duplicate_cases),
        'vinculos_e_conflitos_uniao': len(link_cases),
        'vinculos_e_conflitos_particao_exclusiva': dict(Counter(c['classe'] for c in link_cases)),
        'fonte25_ausente_sem_cartao': sum(c['sem_cartao'] and c['classe'] == 'fonte_da_uf_ausente' for c in link_cases),
        'fonte25_ausente_conflito': sum(c['conflito_geografico'] and c['classe'] == 'fonte_da_uf_ausente' for c in link_cases),
        'UFs_com_fonte25': sorted(core.UF), 'UFs_sem_fonte25': missing,
        'familias_inteiras_coincidentes_pendentes': len(pending_families),
        'dez_danos_textuais': len(damage), 'posicoes_unicas_em_alguma_pendencia': len(records),
        'contagens_de_marcas_sobrepostas_nao_somar': dict(counts),
        'nota': 'Uniao de posicoes de pessoas e cartoes, nao numero de pessoas; tres fragmentos nao provam tres pessoas nem uma familia. Inventario independente, nao reconstrucao R.'}
    result = {'versao': 1, 'resumo': summary,
        'deltas_exatos': {'cartoes_recuperados_adicionais': [c['id_recuperacao'] for c in added_cards],
            'linhas_que_deixaram_sem_cartao': sorted(rescued), 'par_pessoal_agora_preservado': [773911, 773913],
            'geoconflitos_alterados': [], 'reparo_textual_novo': {'linha': 405458, 'posicoes': [20, 22], 'tipo_preservado': '3'}},
        'duplicatas_pendentes': duplicate_cases, 'vinculos_e_conflitos': link_cases,
        'familias_inteiras_pendentes': [{k: g[k] for k in ['id', 'UF', 'linhas_cartoes', 'linhas_pessoas', 'acao', 'justificativa']} for g in pending_families],
        'danos_textuais': damage, 'cartoes_vazios': inventory['cartoes_sem_pessoas'],
        'conviventes_sem_principal': inventory['conviventes_sem_principal'],
        'registros_por_posicao': [{'linha': n, 'marcacoes': sorted(tags)} for n, tags in sorted(records.items())],
        'fontes': inventory['fontes'] + [{'arquivo': p, 'sha256': core.sha256(ROOT / p)} for p in
            ['read_guides/1960_amostra_127_familias_coincidentes.json', 'read_guides/1960_amostra_127_reparos_fonte25.json',
             'references/inventario_final_registros_1960.py', 'references/fechamento_integral_1960_vinculos_inventario.py']],
        'limites': ['As classificacoes de impedimento mantem a pesquisa nominal anterior quando nenhum dado mudou; as23linhas resolvidas e o parSP foram retirados por igualdade de conjuntos.',
            'Motivos atuais de duplicatas podem se sobrepor; somente informacao_faltante oferece particao exclusiva.',
            'A ausencia local de fonte nao prova inexistencia de outro acervo. Vinte e tres registros recuperados nao foram acrescidos a amostra.']}
    for name, value in [('pendencias_nominais.json', result), ('resumo.json', summary)]:
        with (out / name).open('x', encoding='utf-8') as stream:
            json.dump(value, stream, ensure_ascii=False, indent=2)
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--out', required=True); args = parser.parse_args()
    out = (ROOT / args.out).resolve()
    if not out.is_relative_to(ROOT / 'tmp/fechamento_integral_1960/vinculos'):
        raise ValueError('Saida fora do escopo')
    main(out)
