"""Extrai caderno pequeno da busca integral de texto, sem promover decisoes."""
import argparse
from collections import Counter
import json
from pathlib import Path
import sqlite3

from auditoria_recuperacao_cartoes_1960 import (
    FAMILY_NAMES, PERSON_NAMES, load_guides, parse_profile, profile_hash,
)
from auditoria_pendencias_texto_1960 import checksum
from investigacao_residual_texto_1960 import context_cases


def compact_result(result):
    return {'total': result.get('total', 0), 'por_uf': result.get('por_uf', {}),
            'numero_chaves_mesma_uf': len(result.get('chaves_mesma_uf', {})),
            'mesma_chave': result.get('mesma_chave', []),
            'exemplos': result.get('exemplos', []) if result.get('total', 0) <= 20 else []}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--entrada', required=True); parser.add_argument('--out', required=True)
    args = parser.parse_args(); root = Path(__file__).resolve().parents[1]
    source_path = root / args.entrada; out = root / args.out
    assert not out.exists()
    source = json.loads(source_path.read_text(encoding='utf-8')); guides = load_guides(root)
    all_cases = json.loads((root / 'tmp/fechamento_registros_1960_20260922/texto/completo01/casos.json').read_text(encoding='utf-8'))
    byline = {r['linha']: r for r in all_cases}
    final = json.loads((root / 'references/fechamento_registros_1960_evidencias/texto_selecao_final33.json').read_text(encoding='utf-8'))
    index = root / 'tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite'
    con = sqlite3.connect(index.resolve().as_uri() + '?mode=ro', uri=True); con.row_factory = sqlite3.Row
    ledger = []; false_na = []; historical = []; witness = []
    for row in source['inventario124']:
        row = dict(row); case = byline[row['linha']]
        query = 'alvo127_' + str(row['linha'])
        row['busca_pessoal_global_aplicada'] = query in source['consultas25']
        row['busca_global'] = compact_result(source['resultados25'].get(query, {})) if row['busca_pessoal_global_aplicada'] else None
        row['melhor_candidato_antigo'] = case['candidatos25'][0] if case['candidatos25'] else None
        row['igualdades_artificiais_NA'] = []
        if row['melhor_candidato_antigo']:
            kind = row['tipo_atual']; names = PERSON_NAMES if kind == 'pessoas' else FAMILY_NAMES
            a, invalid = parse_profile(row['texto_atual'], guides[('127', kind)], names)
            b, bad = parse_profile(row['melhor_candidato_antigo']['texto'], guides[('25', kind)], names)
            row['igualdades_artificiais_NA'] = [name for name, x, y in zip(names, a, b)
                                               if name in invalid and x is None and y is None]
            row['diferencas_atuais_com_candidato_antigo'] = {name: [x, y] for name, x, y in zip(names, a, b) if x != y}
        if row['status_anterior'] == 'candidato_igual_nos_campos_comuns' and row['igualdades_artificiais_NA']:
            false_na.append(row['linha'])
        if row['decisao_atual'] in {'reparo', 'recuperada', 'realocada'}:
            historical.append(row['linha'])
        ledger.append(row)
    for key, query in source['consultas25'].items():
        if not key.startswith('contexto127_'):
            continue
        values, invalid = parse_profile(query['texto'], guides[('127', 'pessoas')], PERSON_NAMES)
        literal127 = [dict(r) for r in con.execute('SELECT linha,uf,corrigido,excluida FROM pessoas WHERE perfil=?',
                                                  (profile_hash(values),))] if not invalid else []
        witness.append({'linha127': int(key.split('_')[-1]), 'invalidos': invalid,
                        'ocorrencias127_validas': len(literal127), 'ocorrencias127': literal127,
                        'busca25': compact_result(source['resultados25'].get(key, {}))})
    con.close()
    # Os grupos desta lista nova nao pertenciam todos aos47 candidatos anteriores.
    false_groups = []
    for line in false_na:
        case = byline[line]
        false_groups.append({'chave': case['chave'], 'grupo127': case['grupo127'], 'grupo25': case['grupo25']})
    payload = {
        'nota': 'Investigacao adicional; nenhuma proposta foi aplicada. Coincidencia de respostas nao e identidade civil.',
        'cobertura': {'decisoes': len(ledger), 'residuos_mecanismo_anterior': len(final['residuos']),
                     'alvos_pessoais_globais': sum(r['busca_pessoal_global_aplicada'] for r in ledger),
                     'consultas_pessoais_e_contexto': len(source['consultas25']),
                     'consultas_reversas': len(source['consultas127']),
                     'linhas25': sum(source['linhas25_examinadas'].values()),
                     'linhas25_por_uf': source['linhas25_examinadas'],
                     'decisoes_por_tipo': dict(Counter(r['decisao_atual'] for r in ledger)),
                     'dez_falsas_igualdades_nos22_antigos': false_na,
                     'reparos_historicos_revisitados': historical},
        'inventario124': ledger, 'residuos14_com_literais': final['residuos'],
        'residuos14_comparacao_contexto': source['residuos14_contextos'],
        'testemunhas_contexto': witness,
        'contextos_dez_falsas_igualdades': context_cases(false_groups, guides),
        'grupos_dez_falsas_igualdades': false_groups,
        'reversas92': {key: {'consulta': query, 'resultado': compact_result(source['resultados127'].get(key, {}))}
                       for key, query in source['consultas127'].items()},
        'guanabara611254': source['guanabara611254'],
        'fragmentos_hipoteses': source['fragmentos_hipoteses'],
        'fragmentos_contagens': source['fragmentos_contagens_amostra_uf_comprimento'],
        'fragmentos_maiores_coincidencias': source['fragmentos_coincidencias16_ou_mais'],
        'limite_fragmentos': source['limite_fragmentos'],
        'fontes_sha256': source['fontes_sha256'],
        'auditoria_integral': {'arquivo': str(source_path.relative_to(root)), 'sha256': checksum(source_path)},
        'exportador_sha256': checksum(Path(__file__)),
        'limites': ['Familias nao foram pesquisadas globalmente por seusatributos genericos nesteauditor; oscartoes/gruposdos14residuos foramcomparados.',
                    'Ausencia de fonte estadual de25 impede excluir coincidencias fora das17UFsdisponiveis.',
                    'Um pareamento que minimiza divergencias e descritivo; nao elimina empates nem demonstra identidade.',
                    'Uma mascara conserva todo digito legivel, inclusive em campo invalido. Dano nao vira igualdade a branco.',
                    'As novas consultas pessoais contam coincidencias sem exigir chave; grupos e fontes devem ser conferidos antes de qualquer decisao.']}
    assert len(ledger) == 124 and len(final['residuos']) == 14 and len(false_na) == 10
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'arquivo': str(out.relative_to(root)), 'bytes': out.stat().st_size, 'cobertura': payload['cobertura']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
