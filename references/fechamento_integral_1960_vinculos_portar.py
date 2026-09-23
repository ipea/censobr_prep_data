"""Emite trechos de artefato calculado para apply_patch, sem escrita propria."""
import argparse
import copy
import json
from pathlib import Path
import fechamento_integral_1960_vinculos_integrar as integration

ROOT = Path(__file__).resolve().parents[1]


def split(out):
    """Uma prova integral por caso evita um monolito de candidatos repetidos."""
    original = integration.read((out / 'cartoes_compostos.json').relative_to(ROOT))
    folder = out / 'portaveis'
    folder.mkdir(exist_ok=False)
    cards = []; paths = []
    for card in original['cartoes']:
        card = copy.deepcopy(card)
        name = 'cartao_composto_' + card['id_recuperacao'] + '.json'
        path = 'references/fechamento_integral_1960_evidencias/' + name
        card['prova_composta']['prova_arquivo'] = path
        card['verificacoes']['evidencia_alternativas'] = path
        proof = {k: v for k, v in original.items() if k not in ['cartoes', 'analises', 'provas_compostas']}
        proof['cartoes'] = [card]
        proof['analises'] = [a for a in original['analises'] if a['id_recuperacao'] == card['id_recuperacao']]
        proof['provas_compostas'] = {str(n): original['provas_compostas'][str(n)] for n in card['prova_composta']['cartoes_decisivos']}
        (folder / name).write_text(integration.json_text(proof), encoding='utf-8')
        cards.append(card); paths.append(path)
    bundle = {'versao': 1, 'cartoes': cards, 'arquivos_provas': paths, 'fontes': original['fontes'],
        'pessoas_novas': 0, 'respostas_alteradas': 0, 'nota': 'Cada prova contem todos os concorrentes examinados daquele caso.'}
    (folder / 'cartoes_compostos.json').write_text(integration.json_text(bundle), encoding='utf-8')
    print(json.dumps({'arquivos': paths + [integration.COMPOSITE]}))


def manifest(out):
    actual = integration.read(integration.MANIFEST)
    result = integration.read((out / 'resultado.json').relative_to(ROOT))
    bundle = integration.read((out / 'portaveis/cartoes_compostos.json').relative_to(ROOT))
    cards = {c['id_recuperacao']: c for c in result['cartoes']}
    cards.update({c['id_recuperacao']: c for c in bundle['cartoes']})
    prior_ids = [c['id_recuperacao'] for c in actual['cartoes']]
    actual['cartoes'] = [cards.pop(key) for key in prior_ids] + list(cards.values())
    files = [f['arquivo'] for f in actual['fontes'] if not f['arquivo'].endswith('/cartoes_fora_chave_fechada.json')]
    files += [integration.DIFFERENT, integration.COMPOSITE] + bundle['arquivos_provas']
    files += [f['arquivo'] for f in bundle['fontes']]
    files = list(dict.fromkeys(files))
    actual['fontes'] = [{'arquivo': p, 'sha256': integration.core.sha256(ROOT / p)} for p in files]
    actual['auditoria_integral_20260923'] = {'script': 'references/fechamento_integral_1960_vinculos_integrar.py',
        'script_sha256': integration.core.sha256(ROOT / 'references/fechamento_integral_1960_vinculos_integrar.py'),
        'cartoes_reauditados': 41, 'pessoas_existentes': 103, 'novos_cartoes': 9, 'pessoas_novas': 0,
        'comando_reproducao': 'python references/fechamento_integral_1960_vinculos_integrar.py --audit --out tmp/fechamento_integral_1960/vinculos/reauditoria_NOVA',
        'portabilidade': 'python references/fechamento_integral_1960_vinculos_portar.py --split --out tmp/fechamento_integral_1960/vinculos/reauditoria_NOVA',
        'limite': 'Nove cartoes para23pessoas existentes; MG tem reparo pessoal previo independente. Sem PR adicional.'}
    repairs = integration.read(integration.REPAIRS)
    repair_files = list(dict.fromkeys([f['arquivo'] for f in repairs['fontes']] +
        [integration.MG_PROOF] + [f['arquivo'] for f in bundle['fontes']]))
    repairs['fontes'] = [{'arquivo': p, 'sha256': integration.core.sha256(ROOT / p)} for p in repair_files]
    integration.emit([integration.patch_text(integration.MANIFEST, integration.json_text(actual)),
                      integration.patch_text(integration.REPAIRS, integration.json_text(repairs))])


def main(source, target, part, size=3000):
    assert source.is_relative_to(ROOT / 'tmp/fechamento_integral_1960/vinculos')
    assert target.is_relative_to(ROOT / 'references')
    text = json.dumps(json.loads(source.read_text(encoding='utf-8')), ensure_ascii=False, indent=2) + '\n'
    lines = text.splitlines()
    start, end = part * size, min((part + 1) * size, len(lines))
    assert start < len(lines)
    if start:
        marker = f'__TRANSFERENCIA_AUDITAVEL_PARTE_{part - 1}__'
        assert target.read_text(encoding='utf-8').splitlines() == lines[:start] + [marker]
        header = '*** Update File: ' + target.relative_to(ROOT).as_posix() + '\n@@\n-' + marker + '\n'
    else:
        assert not target.exists()
        header = '*** Add File: ' + target.relative_to(ROOT).as_posix() + '\n'
    marker = f'+__TRANSFERENCIA_AUDITAVEL_PARTE_{part}__\n' if end < len(lines) else ''
    print('*** Begin Patch\n' + header + ''.join('+' + x + '\n' for x in lines[start:end]) + marker + '*** End Patch')


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--source')
    p.add_argument('--target')
    p.add_argument('--part', type=int)
    p.add_argument('--out')
    p.add_argument('--split', action='store_true')
    p.add_argument('--manifest', action='store_true')
    p.add_argument('--whole', action='store_true')
    a = p.parse_args()
    if a.split: split((ROOT / a.out).resolve())
    elif a.manifest: manifest((ROOT / a.out).resolve())
    elif a.whole:
        integration.emit([integration.patch_text(a.target, integration.json_text(integration.read(a.source)))])
    else: main((ROOT / a.source).resolve(), (ROOT / a.target).resolve(), a.part)
