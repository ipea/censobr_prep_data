"""Confere alcance dos dezNA enganosos e geografia das pistas dofragmento855822."""
import argparse
import csv
import gzip
import json
from pathlib import Path

from auditoria_pendencias_texto_1960 import checksum


def integer_mentions(value, wanted, path=''):
    found = []
    if isinstance(value, dict):
        for key, item in value.items():
            if isinstance(item, int) and item in wanted:
                found.append({'caminho': path + '/' + key, 'linha': item})
            found.extend(integer_mentions(item, wanted, path + '/' + key))
    elif isinstance(value, list):
        for i, item in enumerate(value):
            found.extend(integer_mentions(item, wanted, path + '/' + str(i)))
    return found


def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--out', required=True)
    args = parser.parse_args(); root = Path(__file__).resolve().parents[1]
    out = root / args.out; assert not out.exists()
    evidence = root / 'references/investigacao_residual_texto_1960_evidencias.json'
    p = json.loads(evidence.read_text(encoding='utf-8'))
    numbers = set(p['cobertura']['dez_falsas_igualdades_nos22_antigos'])
    keys = {r['texto_atual'][8:16] for r in p['inventario124'] if r['linha'] in numbers}
    hashes = {str(evidence.relative_to(root)): checksum(evidence)}; affected = {}
    for suffix in ['duplicatas.csv', 'vinculos.csv']:
        path = root / ('read_guides/1960_amostra_127_' + suffix)
        hashes[str(path.relative_to(root))] = checksum(path)
        with path.open(encoding='utf-8-sig', newline='') as f:
            affected[suffix] = [row for row in csv.DictReader(f) if any(
                isinstance(value, str) and len(value) == 62 and value[:2] == '60' and value[8:16] in keys
                for value in row.values())]
    for suffix in ['reparos_fonte25.json', 'cartoes_recuperados.json', 'geografia_fonte25.json']:
        path = root / ('read_guides/1960_amostra_127_' + suffix)
        hashes[str(path.relative_to(root))] = checksum(path)
        affected[suffix] = integer_mentions(json.loads(path.read_text(encoding='utf-8')), numbers)
    wanted = {row['linha'] for row in p['fragmentos_maiores_coincidencias']['855822_primeiro_sem_espacos']
              if row['amostra'] == '25' and row['comprimento'] == 34}
    assert len(wanted) == 3
    path = root / 'data/release_legacy/Censo.1960.amostra.25porcento.sp.gz'
    hashes[str(path.relative_to(root))] = checksum(path)
    prefix_cards = []; selected = []; muni_cards = []; card = None
    with gzip.open(path, 'rt', encoding='latin1') as f:
        for n, line in enumerate(f, 1):
            text = line.rstrip('\r\n')
            if text[8:10] == '00':
                card = {'linha': n, 'texto': text}
                if text[29:35] == '643301':
                    muni_cards.append(card)
                    if text[:3] == '644':
                        prefix_cards.append(card)
            if n in wanted:
                selected.append({'linha': n, 'texto': text, 'cartao': card,
                                 'pasta': text[:5], 'municipio_cartao': card['texto'][29:33],
                                 'distrito_cartao': card['texto'][33:35]})
    for name, digest in hashes.items():
        assert checksum(root / name) == digest
    result = {'dez_linhas': sorted(numbers), 'cinco_chaves': sorted(keys),
              'dependencias_nos_manifestos_vigentes': affected,
              'conclusao_impacto': 'Nenhum dos cinco boletins ou dez registros participa das decisoes manifestadas pesquisadas; falso rótulo nao revoga aqueles reparos/vinculos/cartoes/duplicatas.',
              'fragmento855822': {'pistas34_de35': selected,
                   'cartoes25_compativeis_ao_segundo_prefixo_SP6433d01pasta644': prefix_cards,
                   'numero_cartoes_SP6433d01': len(muni_cards),
                   'pastas_SP6433d01': sorted({r['texto'][:5] for r in muni_cards}),
                   'limite': 'Dois trechos da linha podem pertencer a registros distintos. Ausencia de cartao compativel ao prefixo nao autoriza corrigir seus digitos.'},
              'fontes_sha256': hashes, 'auditor_sha256': checksum(Path(__file__))}
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'afetados': {key: len(value) for key, value in affected.items()},
                      'fragmento': selected, 'cartoes_prefixo': len(prefix_cards)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
