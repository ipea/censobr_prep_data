from pathlib import Path
import unittest

from auditoria_recuperacao_cartoes_1960 import load_guides
from conferir_reparos_texto_1960 import matching, compatible


class GroupTests(unittest.TestCase):
    def test_group_missing_person(self):
        self.assertIsNone(matching([[0], [0]], 2))

    def test_group_can_reassign(self):
        self.assertEqual(matching([[0, 1], [0]], 2), {0: 1, 1: 0})

    def test_legitimate_equal_siblings_kept(self):
        self.assertEqual(len(matching([[0, 1], [0, 1]], 2)), 2)

    def test_forced_nonedge_rejected(self):
        self.assertIsNone(matching([[0], [1]], 2, (0, 1)))

    def test_possible_alternatives(self):
        self.assertIsNotNone(matching([[0, 1], [0, 1]], 2, (0, 0)))
        self.assertIsNotNone(matching([[0, 1], [0, 1]], 2, (0, 1)))

    def test_forced_match_cannot_steal(self):
        self.assertIsNone(matching([[0, 1], [0]], 2, (0, 0)))

    def setUp(self):
        self.guides = load_guides(Path(__file__).resolve().parents[1])
        self.source = '218980170100101712557209920003110095702025332321176000'
        self.text = '212192012189801721171255720R20003110095702025332321176\\0036358'
        # Construct a complete127 counterpart from literal25 field positions.
        for name, (start, end, _) in self.guides[('127', 'pessoas')].items():
            if name not in self.guides[('25', 'pessoas')]:
                continue
            a, b, _ = self.guides[('25', 'pessoas')][name]
            self.text = self.text[:start] + self.source[a:b] + self.text[end:]

    def test_invalid_character_only_can_be_recovered(self):
        broken = self.text[:27] + 'R' + self.text[28:]
        self.assertTrue(compatible(broken, self.source, 'pessoas', {'decisao': 'valor_isolado'}, self.guides))

    def test_legal_different_code_not_recovered(self):
        broken = self.text[:27] + '1' + self.text[28:]
        self.assertFalse(compatible(broken, self.source, 'pessoas', {'decisao': 'valor_isolado'}, self.guides))

    def test_v216_zero_and_63_not_equivalent(self):
        altered = self.text[:38] + '63' + self.text[40:]
        self.assertFalse(compatible(altered, self.source, 'pessoas', {'decisao': 'valor_isolado'}, self.guides))

    def test_required_blank_is_damaged(self):
        broken = self.text[:27] + ' ' + self.text[28:]
        self.assertTrue(compatible(broken, self.source, 'pessoas', {'decisao': 'valor_isolado'}, self.guides, {'V208'}))

    def test_optional_blank_not_silently_repaired(self):
        broken = self.text[:38] + '  ' + self.text[40:]
        self.assertFalse(compatible(broken, self.source, 'pessoas', {'decisao': 'valor_isolado'}, self.guides, {'V208'}))


if __name__ == '__main__':
    unittest.main()
