"""Conferencia delimitada de dois boletins SP e chave incompleta GB; nao altera dados."""
import argparse
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as old
from investigacao_residual_vinculos_detalhes_1960 import compare, serial


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    out = root / args.out
    if out.exists():
        raise FileExistsError(out)
    index = root / 'tmp/fechamento_registros_1960_20260922/recuperacao_atualizada_01/indice127.sqlite'
    conn = sqlite3.connect(index.as_uri() + '?mode=ro', uri=True)
    conn.row_factory = sqlite3.Row
    guides = old.load_guides(root)
    keys = {(60158, 118), (60158, 119)}
    cards25, people25 = old.read_source(root, 60, keys)
    payload = {'escopo': 'Indice preaplicacao: apenas 661571, 695175 e contexto GB. Fonte25 SP: apenas 60158/118 e 60158/119.',
               'sp': [], 'gb': {}}
    for line in [661571, 695175]:
        card = old.fetch(conn, 'SELECT * FROM familias WHERE linha=?', (line,))[0]
        people = old.fetch(conn, 'SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha', (line,))
        physical = old.fetch(conn, 'SELECT * FROM pessoas WHERE familia_fisica=? AND excluida=0 ORDER BY linha', (line,))
        key = (card['pasta'], card['boletim'])
        payload['sp'].append({'cartao127': serial(card), 'pessoas127_vinculo_vigente': [serial(p) for p in people],
            'pessoas127_posicao_fisica': [serial(p) for p in physical],
            'cartoes25': cards25[key], 'pessoas25': people25[key],
            'comparacao_do_grupo_logico': compare(people, people25[key], guides),
            'comparacao_do_grupo_fisico': compare(physical, people25[key], guides)})
    person = old.fetch(conn, 'SELECT * FROM pessoas WHERE linha=611254')[0]
    cards = old.fetch(conn, 'SELECT * FROM familias WHERE uf=54 AND pasta BETWEEN 54100 AND 54199 AND boletim=101 ORDER BY linha')
    payload['gb']['pessoa'] = serial(person)
    payload['gb']['cartoes_preservados_compativeis_com_pasta_e_boletim'] = [serial(c) for c in cards]
    payload['gb']['pessoas_cartao616230'] = [serial(p) for p in old.fetch(conn,
        'SELECT * FROM pessoas WHERE familia_atual=616230 AND excluida=0 ORDER BY linha')]
    payload['gb']['limite'] = 'Cartao 616230 e unico entre os preservados apos conferir distrito. Nao exclui cartao historico ausente. Fonte25 GB indisponivel.'
    paths = [index, root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt',
             root / 'data/release_legacy/Censo.1960.amostra.25porcento.sp.gz']
    payload['fontes_sha256'] = {str(p.relative_to(root)): old.sha256(p) for p in paths}
    conn.close()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'saida': str(out.relative_to(root)), 'sp': [
        {'cartao': x['cartao127']['linha'], 'n127_logico': x['comparacao_do_grupo_logico']['n127'],
         'n127_fisico': x['comparacao_do_grupo_fisico']['n127'], 'n25': len(x['pessoas25']),
         'composicao_logica25': x['comparacao_do_grupo_logico']['composicao25'],
         'composicao_fisica25': x['comparacao_do_grupo_fisico']['composicao25']} for x in payload['sp']],
         'cartoes_gb': [c['linha'] for c in cards]}, ensure_ascii=False))


if __name__ == '__main__':
    main()
