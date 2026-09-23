from collections import Counter
import copy
import json
from pathlib import Path
import unittest

from aplicar_residuais_duplicatas_1960 import APPROVED, load_guides, parse_profile, PERSON_NAMES, verify_case


class ResidualDecisionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = Path(__file__).resolve().parents[1]
        cls.guides = load_guides(cls.root)
        data = json.loads((cls.root / "references/investigacao_residual_1960_evidencias/duplicatas_fora_chave.json").read_text(encoding="utf-8"))
        cls.cases = [c for c in data["casos"] if tuple(c["avaliacao"]["chave127"]) in APPROVED]

    def witnesses(self, case):
        return Counter({parse_profile(p["corrigido"], self.guides[("127", "pessoas")], PERSON_NAMES)[0]: 1
                        for p in case["pessoas127"] if p["linha"] in case["avaliacao"]["testemunhas_exatas_unicas_UF"]})

    def test_two_source_occurrences_preserve_both(self):
        for case in self.cases:
            proof = verify_case(case, self.guides, self.witnesses(case))
            self.assertEqual([r["acao"] for r in proof["decisoes"]], ["manter", "manter"])

    def test_missing_person_not_ignored(self):
        case = copy.deepcopy(self.cases[0]); case["pessoas25"].pop()
        with self.assertRaisesRegex(ValueError, "Estrutura"):
            verify_case(case, self.guides, self.witnesses(case))

    def test_municipal_disagreement_rejected(self):
        case = copy.deepcopy(self.cases[0]); p = case["pessoas127"][0]
        p["corrigido"] = p["corrigido"][:2] + "9999" + p["corrigido"][6:]
        with self.assertRaisesRegex(ValueError, "Geografia"):
            verify_case(case, self.guides, self.witnesses(case))

    def test_unique_witnesses_required(self):
        with self.assertRaisesRegex(ValueError, "testemunhas"):
            verify_case(self.cases[0], self.guides, Counter())

    def test_other_card_is_not_ignored(self):
        case = copy.deepcopy(self.cases[0]); case["avaliacao"]["cartoes127_na_chave25"] = [{"linha": 99}]
        with self.assertRaisesRegex(ValueError, "alternativa"):
            verify_case(case, self.guides, self.witnesses(case))


if __name__ == "__main__":
    unittest.main()
