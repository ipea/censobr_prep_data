import unittest
import csv
import json
from pathlib import Path
from preparar_reparos_residuais_texto_1960 import ALVOS, DANOS, aceitavel, mascarar


class ResidualRepairTests(unittest.TestCase):
    def test_only_declared_third_person_difference(self):
        self.assertTrue(aceitavel(540397, {'V212': [1, 4], 'V213': [1, 2]}))
        self.assertFalse(aceitavel(540399, {'V212': [1, 4]}))
        self.assertFalse(aceitavel(540397, {'V212': [1, 2]}))

    def test_target_keeps_all_other_answers(self):
        self.assertTrue(aceitavel(540394, {'V208': [None, 9]}))
        self.assertFalse(aceitavel(540394, {'V208': [None, 0]}))
        self.assertFalse(aceitavel(540394, {'AGE': [7, 8]}))

    def test_blank_does_not_authorize_another_missing_answer(self):
        self.assertFalse(aceitavel(760807, {'V218': [None, 0]}))

    def test_mask_only_nationality(self):
        with self.assertRaises(AssertionError):
            mascarar('0' * 62, '127', ['AGE'])

    def test_portable_proof_and_applied_manifest_agree(self):
        root = Path(__file__).resolve().parents[1]
        proof = json.loads((root / 'references/resolucao_residuais_1960_evidencias/texto_propostas.json').read_text(encoding='utf-8'))
        manifest = json.loads((root / 'read_guides/1960_amostra_127_reparos_fonte25.json').read_text(encoding='utf-8'))
        entries = {x['linha127']: x for x in manifest['reparos']}
        self.assertEqual(len(entries), 37)
        self.assertEqual({x['linha127'] for x in proof['reparos']}, ALVOS)
        self.assertEqual(set(proof['danos_sem_reparo']), DANOS)
        for case in proof['reparos']:
            self.assertEqual(case, entries[case['linha127']])
            before, after = case['texto_original'], case['texto_corrigido_proposto']
            self.assertEqual([i for i, (a, b) in enumerate(zip(before, after)) if a != b], [27])
            self.assertEqual((before[27], after[27]), (' ', '9'))
        self.assertTrue(all(x['n127'] == x['n25'] == 1 for x in proof['testemunhas_verificadas']))

    def test_unresolved_damage_preserves_literal_record(self):
        root = Path(__file__).resolve().parents[1]
        with (root / 'read_guides/1960_amostra_127_correcoes.csv').open(encoding='utf-8-sig', newline='') as stream:
            decisions = {int(row['linha']): row for row in csv.DictReader(stream)}
        with (root / 'data_raw/microdata/1960/amostra_127/HHOLDA.txt').open('rb') as stream:
            for line in DANOS:
                decision = decisions[line]
                stream.seek((line - 1) * 64)
                self.assertEqual(decision['texto_original'], stream.read(62).decode('latin1'))
                self.assertEqual(decision['texto_corrigido'], '')
                self.assertEqual(decision['decisao'], 'dano_salto_nao_resolvido')


if __name__ == '__main__':
    unittest.main()
