import unittest
from pathlib import Path

import auditoria_pendencias_vinculos_1960 as audit


class GroupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.guides = audit.recovery.load_guides(Path(__file__).resolve().parents[1])
        data = audit.json.loads((Path(__file__).resolve().parents[1] / audit.RECOVERED).read_text(encoding="utf-8"))
        cls.card = next(c for c in data["cartoes"] if c["pasta"] == "40654")

    def fixture(self):
        card = self.card
        family25 = {"linha": card["linha_25"], "texto": card["texto_25"]}
        people25 = sorted([{"linha": p["linha_25"], "texto": p["texto_25"]} for p in card["pessoas"]], key=lambda p: p["linha"])
        people127 = [{"linha": p["linha"], "corrigido": p["texto_corrigido"], "familia_atual": None} for p in card["pessoas"]]
        return family25, people25, people127

    def test_missing_family_is_not_approved_link(self):
        f, p25, p127 = self.fixture()
        check = audit.compare_group([], p127, [f], p25, self.guides)
        self.assertEqual(check["motivos"], ["cartao127_ausente"])
        self.assertEqual(audit.classify(check, True), "cartao_ausente_com_composicao_exata")

    def test_multiplicity_matters(self):
        f, p25, p127 = self.fixture()
        check = audit.compare_group([], p127 + [p127[0]], [f], p25, self.guides)
        self.assertIn("composicao_integral_diverge", check["motivos"])

    def test_different_codes_are_not_equated(self):
        f, p25, p127 = self.fixture()
        start, end, _ = self.guides[("25", "pessoas")]["V216"]
        p25[0]["texto"] = p25[0]["texto"][:start] + "63" + p25[0]["texto"][end:]
        check = audit.compare_group([], p127, [f], p25, self.guides)
        self.assertIn("composicao_integral_diverge", check["motivos"])

    def test_bad_source_order_is_rejected(self):
        f, p25, p127 = self.fixture()
        p25[0]["texto"] = p25[0]["texto"][:8] + "09" + p25[0]["texto"][10:]
        check = audit.compare_group([], p127, [f], p25, self.guides)
        self.assertIn("ordens25_incompletas_ou_repetidas", check["motivos"])

    def test_other_link_is_not_overwritten(self):
        f, p25, p127 = self.fixture()
        p127[0]["familia_atual"] = 999
        check = audit.compare_group([], p127, [f], p25, self.guides)
        self.assertIn("pessoa_ja_atribuida_a_outro_cartao", check["motivos"])

    def test_absent_source_distinguished(self):
        f, p25, p127 = self.fixture()
        check = audit.compare_group([], p127, [], [], self.guides)
        self.assertEqual(audit.classify(check, False), "fonte25_nao_disponivel")
        self.assertEqual(audit.classify(check, True), "boletim_nao_encontrado_na25_por_chave")

    def test_other_keys_already_linked_are_not_lost(self):
        self.assertEqual(audit.extra_linked_lines([1, 2], [1, 2, 3]), [3])
        self.assertEqual(audit.extra_linked_lines([1, 2], [2, 1]), [])

    def test_two_exact_witnesses_and_only_v216_difference(self):
        a = [tuple(range(25)), tuple(range(1, 26)), tuple(range(2, 27))]
        position = audit.recovery.PERSON_NAMES.index("V216")
        a[2] = a[2][:position] + (0,) + a[2][position+1:]
        b = a[:2] + [a[2][:position] + (63,) + a[2][position+1:]]
        self.assertTrue(audit.bijection_without_v216(a, b)["aprovavel"])
        b[0] = (999,) + b[0][1:]
        self.assertFalse(audit.bijection_without_v216(a, b)["aprovavel"])

    def test_ambiguous_matching_rejected_even_with_two_witnesses(self):
        a = [tuple(range(25)), tuple(range(1, 26)), tuple(range(1, 26))]
        check = audit.bijection_without_v216(a, a)
        self.assertFalse(check["aprovavel"])
        self.assertIn("pareamento24_nao_unico", check["motivos"])

    def test_one_witness_not_enough(self):
        a = [tuple(range(25)), tuple(range(1, 26))]
        position = audit.recovery.PERSON_NAMES.index("V216")
        a[1] = a[1][:position] + (0,) + a[1][position+1:]
        b = [a[0], a[1][:position] + (63,) + a[1][position+1:]]
        self.assertFalse(audit.bijection_without_v216(a, b)["aprovavel"])

    def test_family_identity_preserves_repeated_members(self):
        a = [tuple(range(25)), tuple(range(1, 26)), tuple(range(2, 27)), tuple(range(2, 27))]
        self.assertTrue(audit.group_identity_preserving_v216(a, a)["aprovavel"])
        self.assertFalse(audit.group_identity_preserving_v216(a, a[:-1])["aprovavel"])

    def test_family_identity_does_not_generalize_v216_difference(self):
        a = [tuple(range(25)), tuple(range(1, 26)), tuple(range(2, 27))]
        pos = audit.recovery.PERSON_NAMES.index("V216")
        b = a[:2]+[a[2][:pos]+(99,)+a[2][pos+1:]]
        self.assertIn("V216_diverge_fora_00_63", audit.group_identity_preserving_v216(a, b)["motivos"])


if __name__ == "__main__":
    unittest.main()
