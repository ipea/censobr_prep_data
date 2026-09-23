import itertools
import json
from pathlib import Path
import unittest

from auditoria_recuperacao_cartoes_1960 import load_guides
from investigacao_residual_texto_1960 import assignment, body, candidate_mask, make_search, hits, pattern
from conferir_complementos_residuais_texto_1960 import integer_mentions


class InvestigationTests(unittest.TestCase):
    def test_assignment_global_not_greedy(self):
        cost = [[1, 2, 8], [1, 9, 8], [9, 8, 1]]
        got = sum(cost[i][j] for i, j in assignment(cost))
        want = min(sum(cost[i][j] for i, j in enumerate(p)) for p in itertools.permutations(range(3)))
        self.assertEqual(got, want)

    def test_mask_never_relaxes_legible(self):
        self.assertTrue(candidate_mask('123400', '1234..'))
        self.assertFalse(candidate_mask('123599', '1234..'))
        self.assertFalse(candidate_mask('1234', '1234..'))

    def test_anchor_still_checks_whole_mask(self):
        queries = {'x': {'mask': '123456789012....123'}}
        anchors, bad = make_search(queries)
        self.assertFalse(bad)
        self.assertEqual(hits('1234567890129999123', anchors, queries), ['x'])
        self.assertEqual(hits('1234567890129999124', anchors, queries), [])

    def test_partial_digit_survives(self):
        guides = load_guides(Path(__file__).resolve().parents[1])
        text = '6062348361852154352911254269200004200000000Z35-       \\0124811'
        mask = pattern(text, '127', guides)
        self.assertEqual(mask[24:26], '0.')
        self.assertFalse(candidate_mask(body(text, '127').replace('0Z', '10'), mask))

    def test_noise_after_skip_does_not_become_blank(self):
        guides = load_guides(Path(__file__).resolve().parents[1])
        damaged = '60623483618521543520109542692000042-       9          \\0124811'
        source = '61852154064064201095426992000042                   000'
        self.assertFalse(candidate_mask(body(source, '25'), pattern(damaged, '127', guides)))

    def test_nested_manifest_references(self):
        data = {'pessoas': [{'linha': 760807}, {'grupo': {'linha127': 760919}}]}
        self.assertEqual({r['linha'] for r in integer_mentions(data, {760807, 760919})}, {760807, 760919})

    def test_portable_coverage_and_no_affected_decisions(self):
        root = Path(__file__).resolve().parents[1]
        main = json.loads((root / 'references/investigacao_residual_texto_1960_evidencias.json').read_text(encoding='utf-8'))
        extra = json.loads((root / 'references/investigacao_residual_texto_1960_complementos.json').read_text(encoding='utf-8'))
        self.assertEqual(len({r['linha'] for r in main['inventario124']}), 124)
        self.assertEqual(main['cobertura']['linhas25'], 18055053)
        self.assertEqual(len(main['cobertura']['dez_falsas_igualdades_nos22_antigos']), 10)
        self.assertTrue(all(not value for value in extra['dependencias_nos_manifestos_vigentes'].values()))
        self.assertEqual(len(extra['fragmento855822']['pistas34_de35']), 3)
        self.assertEqual(extra['fragmento855822']['cartoes25_compativeis_ao_segundo_prefixo_SP6433d01pasta644'], [])


if __name__ == '__main__':
    unittest.main()
