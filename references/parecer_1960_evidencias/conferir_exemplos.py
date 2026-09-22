"""Conferir o estado ilustrado em 22/09/2026. Somente leitura; sem R.

Nao executa regras de reparo, deduplicacao, vinculo ou ajuste de pesos.
Depois de corrigir os dados, algumas assercoes deste retrato antigo devem falhar.
"""
from pathlib import Path
from collections import defaultdict
import csv
import gzip
import hashlib
import json
import math
import re
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT/'data_raw/microdata/1960'
NOTES = Path(__file__).resolve().parent
P127 = BASE/'amostra_127/pessoas_1960_amostra_127.parquet'
D127 = BASE/'amostra_127/domicilios_1960_amostra_127.parquet'
RAW = BASE/'amostra_127/HHOLDA.txt'
result = {'escopo': 'Estado dos exemplos, nao homologacao ou novo processamento'}

# Trechos literais transcritos no caderno: conferir bytes de texto de cada linha.
expected = defaultdict(dict)
for line in (NOTES/'vinculos.md').read_text(encoding='utf-8').splitlines():
    match = re.match(r'^(HHOLDA|gzip BA|gzip PB)\s+(\d+)\s{2}(.*)$', line)
    if match:
        source, number, value = match.groups()
        expected[source][int(number)] = value
paths = {'HHOLDA': RAW,
    'gzip BA': ROOT/'data/release_legacy/Censo.1960.amostra.25porcento.ba.gz',
    'gzip PB': ROOT/'data/release_legacy/Censo.1960.amostra.25porcento.pb.gz'}
assert len(expected) == 3 and sum(map(len, expected.values())) >= 20
for name, targets in expected.items():
    reader = gzip.open(paths[name], 'rt', encoding='latin-1') if name.startswith('gzip') else paths[name].open(encoding='latin-1')
    found = set()
    with reader as stream:
        for number, line in enumerate(stream, 1):
            if number in targets:
                assert line.rstrip('\r\n') == targets[number], f'Trecho divergente: {name} {number}'
                found.add(number)
            if number >= max(targets):
                break
    assert found == set(targets)
result['trechos_literais_conferidos'] = {k: len(v) for k, v in expected.items()}

def read_person(number, cols):
    table = pq.read_table(P127, columns=cols, filters=[('linha','=',number)])
    assert table.num_rows == 1
    return table.to_pylist()[0]

girl = read_person(302261, ['V202','V203','V204','V204B','V116','censobr_idhousehold'])
assert [girl[x] for x in ['V202','V203','V204','V204B','V116']] == [2,9,1,5,3138]
assert girl['censobr_idhousehold'] == 47171
result['menina_ipiau_estado_atual'] = girl

family = pq.read_table(P127, columns=['linha'], filters=[('censobr_idhousehold','=',49430)]).to_pylist()
assert sorted(x['linha'] for x in family) == [315733,315736]
result['boletim118_pessoas_no_destino_atual'] = family
pb = pq.read_table(P127, columns=['linha'], filters=[('linha','>=',168801),('linha','<=',168807)]).to_pylist()
assert len(pb) == 5 and {168805,168806}.isdisjoint(x['linha'] for x in pb)
result['pb_linhas_mantidas'] = [x['linha'] for x in pb]

rs = read_person(951431, ['V212','V213','V214'])
assert list(rs.values()) == [0,6,20]
rs25 = pq.read_table(BASE/'amostra_25/rs/pessoas.parquet', columns=['V212','V213','V214'], filters=[('linha','=',252042)]).to_pylist()
assert len(rs25) == 1 and list(rs25[0].values()) == [6,2,0]
with (ROOT/'read_guides/1960_amostra_127_correcoes.csv').open(encoding='utf-8-sig', newline='') as stream:
    repair = [x for x in csv.DictReader(stream) if int(x['linha']) == 951431]
assert len(repair) == 1
fragment = repair[0]['texto_original'].split('\\',1)[1].replace(' ','')
assert fragment[33:37] == '6200' and repair[0]['texto_corrigido'][33:37] == '0620'
result['rs_escolaridade'] = {'fragmento_original':fragment[33:37], 'reparo':repair[0]['texto_corrigido'][33:37], 'parquet127':rs, 'parquet25':rs25[0]}

ro = pq.read_table(BASE/'compilada/ro/pessoas.parquet', columns=['V118','V202','censobr_weight']).to_pylist()
assert len(ro) == 675 and not any(x['V118'] == 5 for x in ro)
present = [x for x in ro if x['V202'] in (1,2,5,6)]
assert len(present) == 666 and math.isclose(math.fsum(x['censobr_weight'] for x in present),70232,abs_tol=1e-6)
with (BASE/'compilada/validacao_definitivos.csv').open(encoding='utf-8-sig', newline='') as stream:
    omitted = [x for x in csv.DictReader(stream) if x['uf60']=='0' and x['tabela']=='34' and x['item']=='rural']
assert omitted == []
result['ro'] = {'pessoas':len(ro),'presentes':len(present),'rurais':0,'linhas_rurais_no_relatorio':len(omitted)}

readers = []
for path in sorted((BASE/'amostra_25').glob('*/pessoas_pesos.parquet')):
    table = pq.read_table(path, columns=['censobr_weight'], filters=[('V204','=',9),('V202','in',[1,2,5,6]),('V211','in',[0,1])])
    readers.append({'uf':path.parent.name,'n':table.num_rows,'peso':math.fsum(table['censobr_weight'].to_pylist())})
assert len(readers) == 17 and sum(x['n'] for x in readers) == 9395
result['leitores25_idade_ignorada'] = {'n':sum(x['n'] for x in readers),'peso':math.fsum(x['peso'] for x in readers),'ufs':readers}

water = pq.read_table(D127, columns=['linha','V102','V105','censobr_weight'],filters=[('linha','in',[303650,284026])]).to_pylist()
assert len(water)==2
byline = {x['linha']:x for x in water}
assert byline[303650]['V105']==4 and byline[284026]['V102']==6 and byline[284026]['V105'] is None
result['agua'] = water

digest = hashlib.sha256()
with RAW.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024*1024),b''):
        digest.update(chunk)
result['HHOLDA_sha256'] = digest.hexdigest()
result['resultado'] = 'Todas as assercoes dos exemplos passaram. Nenhum arquivo foi modificado.'
print(json.dumps(result, indent=2, ensure_ascii=False, allow_nan=False))
