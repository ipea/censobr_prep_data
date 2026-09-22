from pathlib import Path
import unittest
from auditoria_recuperacao_cartoes_1960 import load_guides
from fechar_reparos_texto_1960 import compare_profile


class FinalCriteriaTests(unittest.TestCase):
    def setUp(self):
        self.guides = load_guides(Path(__file__).resolve().parents[1])
        self.source = '218980170100101712557209920003110095702025332321176000'
        self.text = '212138052189801725171255720R20003110095702025332321176\\0035191'
        self.text = self.text[:27] + '9' + self.text[28:]

    def test_target_missing_value_restored_only_with_permission(self):
        t = self.text[:27] + ' ' + self.text[28:]
        self.assertTrue(compare_profile(t, self.source, 'pessoas', {'V208'}, self.guides)[0])
        self.assertFalse(compare_profile(t, self.source, 'pessoas', set(), self.guides)[0])

    def test_context_difference_is_reported_not_normalized(self):
        # TargetV216 is57: change both sources to00/63 solely for this test.
        t = self.text[:38] + '00' + self.text[40:]
        s = self.source[:35] + '63' + self.source[37:]
        ok, delta = compare_profile(t, s, 'pessoas', set(), self.guides, True)
        self.assertTrue(ok); self.assertEqual(delta, {'V216': [0, 63]})
        self.assertEqual(t[38:40], '00')
        self.assertFalse(compare_profile(t, s, 'pessoas', set(), self.guides)[0])

    def test_other_legible_year_difference_blocked(self):
        t = self.text[:38] + '56' + self.text[40:]
        self.assertFalse(compare_profile(t, self.source, 'pessoas', set(), self.guides, True)[0])

    def test_partial_digit_must_be_preserved(self):
        # Original age25; blank last digit is recoverable, contradictory first digit isnot.
        good = self.text[:21] + '2 ' + self.text[23:]
        bad = self.text[:21] + '3 ' + self.text[23:]
        self.assertTrue(compare_profile(good, self.source, 'pessoas', {'AGE'}, self.guides)[0])
        self.assertFalse(compare_profile(bad, self.source, 'pessoas', {'AGE'}, self.guides)[0])

    def test_invalid_to_na_not_a_match(self):
        t = self.text[:50] + '9  ' + self.text[53:]
        s = self.source[:47] + '   ' + self.source[50:]
        self.assertFalse(compare_profile(t, s, 'pessoas', {'V223B'}, self.guides, True)[0])

    def test_legal_value_not_overwritten(self):
        t = self.text[:27] + '1' + self.text[28:]
        self.assertFalse(compare_profile(t, self.source, 'pessoas', {'V208'}, self.guides, True)[0])


if __name__ == '__main__':
    unittest.main()
