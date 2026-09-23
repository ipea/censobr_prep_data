"""Reauditoria atual e patches de integracao; nao executa R nem escreve producao.

Os patches sao emitidos para apply_patch. Produtos calculados ficam em tmp.
"""
import argparse
from collections import Counter
import copy
import csv
import difflib
import io
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as core
import fechamento_integral_1960_vinculos as scan
import resolver_cartoes_chaves_fonte25_1960 as different

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'tmp/fechamento_integral_1960/vinculos'
MANIFEST = 'read_guides/1960_amostra_127_cartoes_recuperados.json'
REPAIRS = 'read_guides/1960_amostra_127_reparos_fonte25.json'
COMPOSITE = 'references/fechamento_integral_1960_evidencias/cartoes_compostos.json'
DIFFERENT = 'references/resolucao_residuais_1960_evidencias/cartoes_fora_chave_integral20260923.json'
MG_PROOF = 'references/fechamento_integral_1960_evidencias/mg405458_identidade.json'


def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))


def json_text(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + '\n'


def patch_text(path, new):
    """Diff localizado, sem reformatar trechos inalterados dos manifestos."""
    target = ROOT / path
    if not target.exists():
        return '*** Add File: ' + path + '\n' + ''.join('+' + x + '\n' for x in new.splitlines())
    old = target.read_text(encoding='utf-8')
    if old.rstrip('\n') == new.rstrip('\n'):
        return ''
    difference = list(difflib.unified_diff(old.splitlines(), new.splitlines(), n=3, lineterm=''))[2:]
    return '*** Update File: ' + path + '\n' + '\n'.join('@@' if x.startswith('@@') else x for x in difference) + '\n'


def emit(parts):
    print('*** Begin Patch\n' + ''.join(parts) + '*** End Patch', end='\n')


def records_patch():
    proposal = read('tmp/fechamento_integral_1960/vinculos/mg_proposta01/proposta_mg.json')['reparo_proposto']
    correction_path = core.FIXED_SOURCES[1]
    text = (ROOT / correction_path).read_text(encoding='utf-8')
    rows = core.rows(ROOT / correction_path)
    target = next(r for r in rows if r['linha'] == '405458')
    assert target['decisao'] == 'valor_isolado' and not target['texto_corrigido']
    old_line = next(line for line in text.splitlines() if line.startswith('405458,'))
    target['decisao'] = 'reparo_fonte25'
    target['texto_corrigido'] = proposal['texto_corrigido_proposto']
    target['explicacao'] = ('MG405458: duas testemunhas intactas identificam conjuntamente o grupo unico '
        'nas fontes127 e25 antes do reparo; fonte25 confirma V203=7 e AGE=79. Apenas caracteres20/22 '
        'ilegíveis recuperados, unidade9 e REC_TYPE3 preservados; nenhuma geografia alterada. '
        'Prova: references/fechamento_integral_1960_evidencias/mg405458_identidade.json.')
    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=list(target), lineterminator='\n', quoting=csv.QUOTE_ALL)
    writer.writerow(target)
    corrected_text = text.replace(old_line, output.getvalue().rstrip('\n'))
    duplicate_path = core.FIXED_SOURCES[2]
    duplicates = (ROOT / duplicate_path).read_text(encoding='utf-8')
    additions = (ROOT / 'tmp/fechamento_integral_1960/duplicatas/duplicata_sp_decisoes_propostas.csv').read_text(encoding='utf-8').splitlines()
    assert not {773911, 773913} & {int(x['linha']) for x in core.rows(ROOT / duplicate_path)}
    repairs = read(REPAIRS)
    assert len(repairs['reparos']) == 37 and 405458 not in {r['linha127'] for r in repairs['reparos']}
    repairs['reparos'].append(proposal)
    repairs['criterio'] += (' MG405458 usa a conjuncao unica de duas testemunhas intactas anteriores ao reparo; '
        'somente dois caracteres ilegíveis de V203/AGE sao recuperados, preservando unidade9, REC_TYPE3 e geografia.')
    emit([patch_text(correction_path, corrected_text),
          patch_text(duplicate_path, duplicates.rstrip('\n') + '\n' + '\n'.join(additions[1:]) + '\n'),
          patch_text(REPAIRS, json_text(repairs))])


def audit(out):
    out.mkdir(parents=True, exist_ok=False)
    guides = core.load_guides(ROOT)
    index = out / 'indice127.sqlite'
    conn = core.build_index(ROOT, index, guides)
    conn.close()
    scan.INDEX = index.relative_to(ROOT).as_posix()
    scan.main(out / 'composicoes', False, False)
    current = read((out / 'composicoes/resultado.json').relative_to(ROOT))
    # BA/CE tem numeracoes diferentes e passa integralmente pelo auditor proprio.
    different.run(ROOT, out / 'fora_chave', (out / 'fora_chave_prova.json').relative_to(ROOT).as_posix())
    separate = read((out / 'fora_chave_prova.json').relative_to(ROOT))
    for card in separate['cartoes']:
        card['reconciliacao_chave']['prova_arquivo'] = DIFFERENT
    old = read(MANIFEST)
    assert len(old['cartoes']) in (32, 41)
    proposed = read('tmp/fechamento_integral_1960/vinculos/pacote01/pacote.json')['cartoes']
    new = [x for x in proposed if x['prova_composta_candidata']['V216_apenas_00_63']]
    new += read('tmp/fechamento_integral_1960/vinculos/mg_proposta01/proposta_mg.json')['cartoes']
    assert len(new) == 9 and sum(x['n_pessoas'] for x in new) == 23
    newids = {c['id_recuperacao'] for c in new}
    wanted = [c for c in old['cartoes'] if 'reconciliacao_chave' not in c and c['id_recuperacao'] not in newids] + new
    assert len(wanted) == 39
    pending = {n for g in read(scan.INV)['duplicatas_pendentes'] for n in g['linhas']}
    pending -= {773911, 773913}
    conn = sqlite3.connect(index.as_uri() + '?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    cards = []; analyses = []; compounds = {}
    for uf in sorted({int(c['UF']) for c in wanted}):
        cases = [c for c in wanted if int(c['UF']) == uf]
        fs, ps = core.read_source(ROOT, uf, {(int(c['pasta']), int(c['boletim'])) for c in cases})
        tasks = []; ownkeys = set()
        for expected in cases:
            key = (uf, int(expected['pasta']), int(expected['boletim']))
            people = core.fetch(conn, 'SELECT * FROM pessoas WHERE uf=? AND pasta=? AND boletim=? AND excluida=0 ORDER BY linha', key)
            reasons, card = core.evaluate_group(key, fs[key[1:]], ps[key[1:]], people, guides, pending)
            assert not reasons and card is not None, (key, reasons)
            for field in ['id_recuperacao', 'UF', 'distrito', 'pasta', 'boletim', 'V116', 'V118',
                          'linha_25', 'arquivo_25', 'texto_25', 'n_pessoas', 'familias', 'pessoas']:
                assert card[field] == expected[field], (key, field)
            candidates, evidence = core.candidate_families(conn, key, fs[key[1:]][0], people, guides)
            ownkeys.update((f['pasta'], f['boletim']) for f in candidates.values())
            tasks.append((expected, key, people, candidates, evidence))
        ownfs, ownps = core.read_source(ROOT, uf, ownkeys)
        for expected, key, people, candidates, evidence in tasks:
            card = copy.deepcopy(expected)
            target = Counter(p['perfil'] for p in people)
            fprofile, bad = core.parse_profile(card['texto_25'], guides['25', 'familias'], core.FAMILY_NAMES)
            assert not bad
            evaluated = []; decisive = []
            for line, family in sorted(candidates.items()):
                own, direct = core.own_group_proof(conn, family, ownfs, ownps, guides, pending, permitir_contexto=True)
                physical = Counter(p['perfil'] for p in core.fetch(conn, 'SELECT perfil FROM pessoas WHERE familia_fisica=? AND excluida=0', (line,)))
                samegeo = (family['uf'], family['municipio'], family['situacao']) == (uf, core.integer(card['V116']), core.integer(card['V118']))
                samebody = family['perfil'] == core.profile_hash(fprofile) and not family['invalidos']
                strong = bool(evidence[line] & {'mesmo_municipio_distrito_boletim', 'chave_ate_um_caractere'})
                species = family['corrigido'][18] == card['familias']['V101']
                before = core.alternative_reasons(samegeo, samebody, strong, direct, physical, target, own['confirmado'], species)
                if before:
                    # Apenas os nove novos casos podem recorrer a composicao24.
                    assert card['id_recuperacao'] in {c['id_recuperacao'] for c in new}, (key, line)
                    compound = current['alternativas'][str(line)]
                    assert compound['via_composicao24_unica_nas_duas_fontes']
                    actual = core.fetch(conn, 'SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha', (line,))
                    assert compound['cartao127'] == scan.serial(family)
                    assert compound['pessoas127'] == [scan.serial(p) for p in actual]
                    assert compound['cartoes25'] == ownfs[family['pasta'], family['boletim']]
                    assert compound['pessoas25'] == ownps[family['pasta'], family['boletim']]
                    assert all((p['uf'], p['municipio'], p['distrito'], p['pasta'], p['boletim'], p['situacao']) ==
                               (family['uf'], family['municipio'], family['distrito'], family['pasta'], family['boletim'], family['situacao']) for p in actual)
                    assert own['motivos_estritos'] == ['composicao_propria_diverge']
                    assert compound['pares_nova_busca']
                    for pair in compound['pares_nova_busca']:
                        assert set(pair['diferencas']) <= {'V216'}
                        assert not pair['diferencas'] or set(pair['diferencas']['V216']) == {0, 63}
                    compounds[str(line)] = compound
                    decisive.append(line)
                    own['confirmado'] = True
                    own['criterio'] = 'multiconjunto24_unico_ambas_fontes_da_UF_respostas_preservadas'
                after = core.alternative_reasons(samegeo, samebody, strong, direct, physical, target, own['confirmado'], species)
                assert not after, (key, line, after)
                evaluated.append({'linha_cartao127': line, 'pistas': sorted(evidence[line]), 'motivos_antes': before,
                    'motivos_depois': after, 'prova_grupo_proprio': own, 'usou_prova_composta': bool(before)})
            card['verificacoes']['cartoes127_examinados'] = len(candidates)
            card['verificacoes']['alternativas_plausiveis'] = 0
            if decisive:
                assert decisive == card.pop('prova_composta_candidata')['cartoes_decisivos']
                card['prova_composta'] = {'modalidade': 'grupos_proprios24_V216_00_63_preservado',
                    'prova_arquivo': COMPOSITE, 'cartoes_decisivos': decisive}
                card['verificacoes']['evidencia_alternativas'] = COMPOSITE
            cards.append(card)
            analyses.append({'id_recuperacao': card['id_recuperacao'], 'cartoes_examinados': evaluated})
        print('Reauditoria mesma chave:', core.UF[uf], flush=True)
    conn.close()
    files = list(core.FIXED_SOURCES) + [f'data/release_legacy/Censo.1960.amostra.25porcento.{s}.gz' for s in core.UF.values()]
    files += ['references/auditoria_recuperacao_cartoes_1960.py', 'references/fechamento_integral_1960_vinculos.py',
              'references/fechamento_integral_1960_vinculos_integrar.py']
    sources = [{'arquivo': p, 'sha256': core.sha256(ROOT / p)} for p in files]
    newids = {c['id_recuperacao'] for c in new}
    composite = {'versao': 1, 'situacao': 'reauditado_com_manifestos_atuais', 'pessoas_novas': 0, 'respostas_alteradas': 0,
        'cartoes': [c for c in cards if c['id_recuperacao'] in newids],
        'analises': [a for a in analyses if a['id_recuperacao'] in newids],
        'provas_compostas': compounds, 'fontes': sources,
        'chaves25_repartidas_reagrupadas': current['chaves25_repartidas_reagrupadas'],
        'nota': 'Reparo MG e etapa previa independente; recuperacao dos cartoes nao altera nenhuma resposta pessoal.'}
    combined = {c['id_recuperacao']: c for c in cards + separate['cartoes']}
    assert len(combined) == 41 and sum(c['n_pessoas'] for c in combined.values()) == 103
    result = {'versao': 1, 'cartoes': list(combined.values()), 'analises': analyses,
        'fontes': sources, 'indice_atual_sha256': core.sha256(index), 'novos_cartoes': 9, 'novas_pessoas': 0,
        'cartoes_reauditados': 41, 'pessoas_existentes': 103, 'provas_compostas': len(compounds)}
    for path, value in [('resultado.json', result), ('cartoes_compostos.json', composite), ('fora_chave_portatil.json', separate)]:
        scan.dump(out / path, value)
    print(json.dumps({k: result[k] for k in ['cartoes_reauditados', 'pessoas_existentes', 'novos_cartoes', 'novas_pessoas', 'provas_compostas']}))


def proofs_patch(out):
    result = read((out / 'resultado.json').relative_to(ROOT))
    composite = read((out / 'cartoes_compostos.json').relative_to(ROOT))
    separate = read((out / 'fora_chave_portatil.json').relative_to(ROOT))
    emit([patch_text(COMPOSITE, json_text(composite)), patch_text(DIFFERENT, json_text(separate))])


def mg_proof_patch(out):
    identity = read('tmp/fechamento_integral_1960/vinculos/mg01/mg405458.json')
    # As17fontes brutas nao mudaram. Recontamos as testemunhas127 no indice
    # atual, nao o perfil reparado do alvo, e relemos todos os literais alvo.
    for path, digest in identity['fontes25_sha256'].items():
        assert core.sha256(ROOT / path) == digest
    index = out / 'indice127.sqlite'
    conn = sqlite3.connect(index.as_uri() + '?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    for n in [405457, 405459]:
        p = core.fetch(conn, 'SELECT * FROM pessoas WHERE linha=?', (n,))[0]
        hits = core.fetch(conn, 'SELECT linha,uf,pasta,boletim,familia_atual,original,corrigido FROM pessoas WHERE perfil=? AND excluida=0', (p['perfil'],))
        assert hits == identity['identificacao_sem_usar_405458']['ocorrencias_completas127'][str(n)]
        assert p['corrigido'] == p['original']
    with (ROOT / core.FIXED_SOURCES[0]).open('rb') as stream:
        for p in identity['pessoas127']:
            stream.seek((p['linha'] - 1) * 64)
            assert stream.read(62).decode('latin1') == p['original']
    repair = next(r for r in read(REPAIRS)['reparos'] if r['linha127'] == 405458)
    actual = core.fetch(conn, 'SELECT * FROM pessoas WHERE linha=405458')[0]
    assert actual['corrigido'] == repair['texto_corrigido_proposto']
    assert [i + 1 for i, (a, b) in enumerate(zip(actual['original'], actual['corrigido'])) if a != b] == [20, 22]
    conn.close()
    identity['situacao'] = 'identidade_anterior_ao_reparo_reconferida_apos_integracao'
    identity['reparo_aprovado'] = repair
    identity['indice_historico_sha256'] = identity.pop('indice127_sha256')
    identity.pop('indice127')
    identity['indice_reauditoria_sha256'] = core.sha256(index)
    identity['limite'] = ('Identificacao precede reparo e nao usa respostas propostas do alvo. '
        'MG405458 recupera somente caracteres20/22, conserva unidade9, REC_TYPE3 e toda geografia; '
        'V2037 nao autoriza converter REC_TYPE3 em2. Nao identifica civilmente pessoas.')
    composite = read((out / 'cartoes_compostos.json').relative_to(ROOT))
    identity['alternativas_explicadas_sem_usar_texto_alvo'] = {n: composite['provas_compostas'][n] for n in ['405480', '405486']}
    identity['fontes'] = composite['fontes']
    emit([patch_text(MG_PROOF, json_text(identity))])


def manifest_patch(out):
    result = read((out / 'resultado.json').relative_to(ROOT))
    manifest = read(MANIFEST)
    oldids = [c['id_recuperacao'] for c in manifest['cartoes']]
    cards = {c['id_recuperacao']: c for c in result['cartoes']}
    manifest['cartoes'] = [cards.pop(key) for key in oldids] + list(cards.values())
    sources = {p['arquivo']: p['sha256'] for p in manifest['fontes']}
    sources.pop('references/resolucao_residuais_1960_evidencias/cartoes_fora_chave_fechada.json')
    for path in list(sources) + [COMPOSITE, DIFFERENT]:
        sources[path] = core.sha256(ROOT / path)
    manifest['fontes'] = [{'arquivo': p, 'sha256': h} for p, h in sources.items()]
    manifest['auditoria_integral_20260923'] = {'script': 'references/fechamento_integral_1960_vinculos_integrar.py',
        'script_sha256': core.sha256(Path(__file__)), 'cartoes_reauditados': 41, 'pessoas_existentes': 103,
        'comando_reproducao': 'python references/fechamento_integral_1960_vinculos_integrar.py --audit --out tmp/fechamento_integral_1960/vinculos/reauditoria_NOVA',
        'limite': 'As nove inclusoes preservam as23pessoas existentes; MG tem reparo pessoal previo em manifesto separado.'}
    repairs = read(REPAIRS)
    assert MG_PROOF not in {f['arquivo'] for f in repairs['fontes']}
    repairs['fontes'].append({'arquivo': MG_PROOF, 'sha256': core.sha256(ROOT / MG_PROOF)})
    emit([patch_text(MANIFEST, json_text(manifest)), patch_text(REPAIRS, json_text(repairs))])


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--records-patch', action='store_true')
    p.add_argument('--audit', action='store_true')
    p.add_argument('--proofs-patch', action='store_true')
    p.add_argument('--manifest-patch', action='store_true')
    p.add_argument('--mg-proof-patch', action='store_true')
    p.add_argument('--out')
    a = p.parse_args()
    if a.records_patch:
        records_patch()
    else:
        out = (ROOT / a.out).resolve()
        if not out.is_relative_to(BASE):
            raise ValueError('Saida fora do escopo')
        if a.audit: audit(out)
        elif a.proofs_patch: proofs_patch(out)
        elif a.manifest_patch: manifest_patch(out)
        elif a.mg_proof_patch: mg_proof_patch(out)
        else: raise ValueError('Escolha uma etapa')
