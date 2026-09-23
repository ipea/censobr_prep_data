import copy
import json
from pathlib import Path
import unittest

from preparar_disposicoes_familias_1960 import disposition, load_guides


class HouseholdDispositionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[1]
        cls.guides = load_guides(cls.root)
        cls.groups = json.loads((cls.root / "references/investigacao_residual_1960_evidencias/familias_coincidentes.json").read_text(encoding="utf-8"))["conjuntos"]

    def test_all_ten_have_explicit_disposition(self):
        results = [disposition(g["cartoes"], self.guides)[0] for g in self.groups]
        self.assertEqual(results.count("preservar_distintos_entre_fontes"), 5)
        self.assertEqual(results.count("pendente"), 5)

    def test_amazonas_equality_cannot_authorize_exclusion(self):
        for group in self.groups[:2]:
            action, checks = disposition(group["cartoes"], self.guides)
            self.assertEqual(action, "pendente")
            self.assertTrue(all("fonte25_nao_disponivel" in c["motivos"] for c in checks))

    def test_matching_separate_forms_not_civil_identity(self):
        group = next(g for g in self.groups if g["cartoes"][0]["linha"] == 229398)
        action, checks = disposition(group["cartoes"], self.guides)
        self.assertEqual(action, "preservar_distintos_entre_fontes")
        self.assertTrue(all(c["composicao25_exata"] for c in checks))
        self.assertNotEqual(checks[0]["linha_cartao25"], checks[1]["linha_cartao25"])

    def test_lost_source_person_blocks(self):
        group = copy.deepcopy(next(g for g in self.groups if g["cartoes"][0]["linha"] == 229398))
        group["cartoes"][0]["registros25_da_chave"].pop()
        self.assertEqual(disposition(group["cartoes"], self.guides)[0], "pendente")

    def test_not_every_valid_different_code_is_00_63(self):
        group = copy.deepcopy(next(g for g in self.groups if g["cartoes"][0]["linha"] == 304706))
        person = group["cartoes"][0]["registros25_da_chave"][1]
        person["texto"] = person["texto"][:35] + "35" + person["texto"][37:]
        action, checks = disposition(group["cartoes"], self.guides)
        self.assertEqual(action, "pendente")
        self.assertIn("V216_fora00_63", checks[0]["motivos"])


if __name__ == "__main__":
    unittest.main()
