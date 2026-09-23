"""Prova localizada de quatro nacionalidades; emite proposta, nao muda producao."""
import argparse
import copy
import csv
import difflib
import gzip
import io
import json
from pathlib import Path

from auditoria_recuperacao_cartoes_1960 import PERSON_NAMES, load_guides, parse_profile, source_structure, rows
from auditoria_pendencias_texto_1960 import checksum
from conferir_reparos_texto_1960 import matching
from investigacao_residual_texto_1960 import body


ALVOS = {238423, 540394, 540399, 540461}
TESTEMUNHAS = {238423: [(238423, ['V208'])],
              540394: [(540390, []), (540396, [])],
              540399: [(540390, []), (540396, [])],
              540461: [(540456, []), (540457, [])]}
DIVERGENCIAS = {540397: {'V212': [1, 4], 'V213': [1, 2]}, 540458: {'V220': [1, 5]}}
DANOS = {760807, 760919, 760923, 760925, 761056, 761057, 761058, 806791, 806800, 806801}


def aceitavel(linha, diferencas):
    for campo, valores in diferencas.items():
        if campo == 'V208' and linha in ALVOS and valores == [None, 9]:
            continue
        if campo == 'V216' and set(valores) == {0, 63}:
            continue
        if DIVERGENCIAS.get(linha, {}).get(campo) == valores:
            continue
        return False
    return True


def mascarar(texto, amostra, campos):
    perfil = body(texto, amostra)
    for campo in campos:
        assert campo == 'V208'
        perfil = perfil[:9] + ' ' + perfil[10:]
    return perfil


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--out', required=True)
    parser.add_argument('--patch', action='store_true')
    args = parser.parse_args(); root = Path(__file__).resolve().parents[1]
    out = root / args.out; out.mkdir(parents=True, exist_ok=False)
    final_path = root / 'references/fechamento_registros_1960_evidencias/texto_selecao_final33.json'
    final = json.loads(final_path.read_text(encoding='utf-8'))
    guides = load_guides(root); proposals = []
    corrections_path = root / 'read_guides/1960_amostra_127_correcoes.csv'
    corrections = {int(r['linha']): r for r in rows(corrections_path)}
    for old in final['residuos']:
        if old['linha127'] not in ALVOS:
            continue
        case = copy.deepcopy(old)
        a = [r for r in case['grupo127'] if r['texto'][16] in '23']
        b = [r for r in case['grupo25'] if r['tipo'] == 'pessoas']
        fa = [r for r in case['grupo127'] if r['texto'][16] == '1']
        fb = [r for r in case['grupo25'] if r['tipo'] == 'familias']
        assert len(fa) == len(fb) == 1 and len(a) == len(b)
        assert not source_structure(fb[0], b)
        pa = [parse_profile(r['texto'], guides[('127', 'pessoas')], PERSON_NAMES) for r in a]
        pb = [parse_profile(r['texto'], guides[('25', 'pessoas')], PERSON_NAMES) for r in b]
        assert all(not bad for _, bad in pa + pb)
        edges = []; differences = {}
        for i, (p, _) in enumerate(pa):
            edge = []
            for j, (q, _) in enumerate(pb):
                delta = {name: [x, y] for name, x, y in zip(PERSON_NAMES, p, q) if x != y}
                if aceitavel(a[i]['linha'], delta):
                    edge.append(j); differences[i, j] = delta
            edges.append(edge)
        match = matching(edges, len(a)); assert match is not None
        assert all(sum(matching(edges, len(a), (i, j)) is not None for j in edge) == 1 for i, edge in enumerate(edges))
        pairs = [{'linha127': a[i]['linha'], 'linha25': b[j]['linha'],
                  'diferencas_preservadas': differences[i, j]} for i, j in sorted(match.items())]
        line = case['linha127']; target = next(p for p in pairs if p['linha127'] == line)
        assert target['diferencas_preservadas'] == {'V208': [None, 9]}
        source = next(r for r in b if r['linha'] == target['linha25'])
        before = case['texto_antes']; assert before[27] == ' '
        case.update({'motivos': [], 'aprovavel_no_criterio': True,
            'criterio_identidade_contexto': 'grupo_completo_com_divergencias_preservadas_v1',
            'texto_corrigido_proposto': before[:27] + '9' + before[28:],
            'propostas': [{'campo': 'V208', 'inicio': 28, 'fim': 28, 'antes': ' ', 'depois': '9', 'linhas25': [source['linha']]}],
            'fontes25_possiveis': [source], 'correspondencias_contexto': pairs,
            'divergencias_pessoais_preservadas': [p for p in pairs if p['diferencas_preservadas'] and p['linha127'] not in ALVOS],
            'testemunhas_identidade': [{'linha127': n, 'linha25': next(p['linha25'] for p in pairs if p['linha127'] == n),
                                      'campos_ignorados': ignored} for n, ignored in TESTEMUNHAS[line]],
            'geografia_parcial_preservada': ([{'linha127': n, 'campo': 'distrito', 'antes': 'X7', 'depois': '07'}
                                             for n in [238422, 238423]] if line == 238423 else [])})
        for row in case['grupo127']:
            expected_district = 'X7' if row['linha'] in {238422, 238423} else fb[0]['texto'][33:35]
            assert row['texto'][6:8] == expected_district
            assert (row['texto'][2:6], row['texto'][17]) == (fb[0]['texto'][29:33], fb[0]['texto'][35])
        proposals.append(case)
    assert {r['linha127'] for r in proposals} == ALVOS
    witness = {}
    for case in proposals:
        for w in case['testemunhas_identidade']:
            a = next(r for r in case['grupo127'] if r['linha'] == w['linha127'])
            b = next(r for r in case['grupo25'] if r['linha'] == w['linha25'])
            masked = mascarar(a['texto'], '127', w['campos_ignorados'])
            assert masked == mascarar(b['texto'], '25', w['campos_ignorados'])
            witness[w['linha127']] = dict(w, uf=case['chave'][0], arquivo=b['arquivo'], mascara=masked, n127=0, n25=0)
    raw = root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt'
    hashes = {str(p.relative_to(root)): checksum(p) for p in [raw, corrections_path, final_path]}
    with raw.open(encoding='latin1') as f:
        for n, raw_line in enumerate(f, 1):
            text = raw_line.rstrip('\r\n')
            if n in corrections:
                assert text == corrections[n]['texto_original']
                text = corrections[n]['texto_corrigido'] or text
            if text[16] not in '23':
                continue
            for w in witness.values():
                if text[:2] == str(w['uf']).zfill(2) and mascarar(text, '127', w['campos_ignorados']) == w['mascara']:
                    w['n127'] += 1
    for name in {w['arquivo'] for w in witness.values()}:
        path = root / name; hashes[name] = checksum(path)
        with gzip.open(path, 'rt', encoding='latin1') as f:
            for raw_line in f:
                text = raw_line.rstrip('\r\n')
                if text[8:10] == '00':
                    continue
                for w in witness.values():
                    if w['arquivo'] == name and mascarar(text, '25', w['campos_ignorados']) == w['mascara']:
                        w['n25'] += 1
    assert all(w['n127'] == w['n25'] == 1 for w in witness.values()), witness
    for name, digest in hashes.items():
        assert checksum(root / name) == digest
    payload = {'reparos': proposals, 'testemunhas_verificadas': list(witness.values()), 'fontes_sha256': hashes,
               'danos_sem_reparo': sorted(DANOS), 'limite': 'Identidade de registros; as divergencias de respostas ficam inalteradas. Nao inclui MG405458 nem imputa fontes ausentes.'}
    (out / 'propostas.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
    manifest_path = root / 'read_guides/1960_amostra_127_reparos_fonte25.json'
    old_manifest = manifest_path.read_text(encoding='utf-8'); manifest = json.loads(old_manifest)
    assert not ALVOS & {r['linha127'] for r in manifest['reparos']}
    manifest['reparos'].extend(proposals)
    new_manifest = json.dumps(manifest, ensure_ascii=False, indent=2) + '\n'
    old_csv = corrections_path.read_text(encoding='utf-8'); new_csv = old_csv
    for n in sorted(ALVOS | DANOS):
        row = dict(corrections[n])
        if n in ALVOS:
            case = next(r for r in proposals if r['linha127'] == n)
            row['decisao'] = 'reparo_fonte25'; row['texto_corrigido'] = case['texto_corrigido_proposto']
            row['explicacao'] = ('2026-09-22: V208 recuperado como9 por correspondencia localizada do grupo completo e testemunhos unicos; '
                'diferencas de terceiros preservadas, nunca recodificadas. Prova em1960_amostra_127_reparos_fonte25.json. '
                + ('Distrito literalX7 preservado;07 somente na prova geografica localizada.' if n == 238423 else
                   'Nacionalidade nao e inferida por lugar de nascimento.'))
        else:
            assert not row['texto_corrigido']
            row['decisao'] = 'dano_salto_nao_resolvido'
            row['explicacao'] = ('2026-09-22: digito depois do sinal de salto; dano preservado, nao reparado. '
                'NA produzido por leitura invalida nao demonstra igualdade ao branco da fonte25. '
                'Registro e demais respostas conservados; nao apagar caracteres para aprovar correspondencia.')
        original_line = next(line for line in old_csv.splitlines() if line.startswith(str(n) + ','))
        buf = io.StringIO(); writer = csv.writer(buf, lineterminator='\n', quoting=csv.QUOTE_ALL)
        writer.writerow(list(row.values())); replacement = buf.getvalue().rstrip('\n')
        replacement = replacement.replace('"' + str(n) + '",', str(n) + ',', 1)
        new_csv = new_csv.replace(original_line, replacement)
    patches = []
    for path, before, after in [(manifest_path, old_manifest, new_manifest), (corrections_path, old_csv, new_csv)]:
        diff = list(difflib.unified_diff(before.splitlines(), after.splitlines(), lineterm=''))
        patches.append('*** Update File: ' + str(path.relative_to(root)).replace('\\', '/') + '\n' + '\n'.join(
            '@@' if line.startswith('@@') else line for line in diff[2:]))
    patch = '*** Begin Patch\n' + '\n'.join(patches) + '\n*** End Patch\n'
    (out / 'proposta.patch').write_text(patch, encoding='utf-8')
    if args.patch:
        print(patch)
    else:
        print(json.dumps({'reparos': sorted(ALVOS), 'danos': sorted(DANOS), 'testemunhas': list(witness.values())}, ensure_ascii=False))


if __name__ == '__main__':
    main()
