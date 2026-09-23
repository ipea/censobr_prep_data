"""Contraprovas locais; unicidade nacional continua documentada na prova de origem."""
import copy
import json
from pathlib import Path
import sqlite3
import unittest

from aprofundar_preservacao_duplicatas_1960 import compare
from auditoria_recuperacao_cartoes_1960 import load_guides, parse_profile, PERSON_NAMES, profile_hash


class AlternativeHouseholdTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[1]
        cls.guides = load_guides(root)
        cls.cases = json.loads((root / "references/resolucao_residuais_duplicatas_alternativos_1960_evidencias.json").read_text(encoding="utf-8"))["casos"]

    def database(self, people, uf, witnesses):
        # Simula contagens de UF controladas; nao substitui a varredura nacional.
        connection = sqlite3.connect(":memory:")
        connection.execute("CREATE TABLE pessoas(uf INTEGER,perfil BLOB,excluida INTEGER)")
        profiles = {}
        for person in people:
            p = parse_profile(person["corrigido"], self.guides[("127", "pessoas")], PERSON_NAMES)[0]
            profiles[profile_hash(p)] = 1 if person["linha"] in witnesses else 2
        connection.executemany("INSERT INTO pessoas VALUES(?,?,0)",
                               [(uf, p) for p, n in profiles.items() for _ in range(n)])
        self.addCleanup(connection.close)
        return connection

    def run_case(self, case, other=False, zero_witnesses=False):
        if other:
            card, people = case["outro_cartao127"], case["outras_pessoas127"]
            sourcecard, sourcepeople = case["fonte25_outro_cartao"], case["fonte25_outras_pessoas"]
            check = case["avaliacao_grupo_proprio_do_alternativo"]
        else:
            target = case["grupo_alvo"]
            card, people = target["cartoes127"][0], target["pessoas127"]
            sourcecard, sourcepeople = target["cartao25"], target["pessoas25"]
            check = case["avaliacao_alvo"]
        witnesses = [] if zero_witnesses else check["testemunhas_exatas_unicas_UF127"]
        connection = self.database(people, case["chave127"][0], witnesses)
        return compare(connection, card, people, sourcecard, sourcepeople, self.guides)

    def test_targets_and_competitors_have_separate_matching_groups(self):
        for case in self.cases:
            self.assertEqual(self.run_case(case)["motivos"], [])
            self.assertEqual(self.run_case(case, other=True)["motivos"], [])

    def test_competitor_cannot_take_target_group(self):
        for case in self.cases:
            changed = copy.deepcopy(case)
            changed["fonte25_outro_cartao"] = case["grupo_alvo"]["cartao25"]
            changed["fonte25_outras_pessoas"] = case["grupo_alvo"]["pessoas25"]
            self.assertIn("composicao_ou_quantidade_diverge", self.run_case(changed, other=True)["motivos"])

    def test_missing_person_blocks(self):
        changed = copy.deepcopy(self.cases[0])
        changed["grupo_alvo"]["pessoas25"].pop()
        self.assertIn("composicao_ou_quantidade_diverge", self.run_case(changed)["motivos"])

    def test_municipal_code_disagreement_blocks(self):
        changed = copy.deepcopy(self.cases[0])
        card = changed["grupo_alvo"]["cartao25"]
        card["texto"] = card["texto"][:29] + "9999" + card["texto"][33:]
        self.assertIn("cartao_ou_distrito_diverge", self.run_case(changed)["motivos"])

    def test_nationally_nonunique_witnesses_block(self):
        for case in self.cases:
            self.assertIn("menos2testemunhas_exatas_unicas", self.run_case(case, zero_witnesses=True)["motivos"])


if __name__ == "__main__":
    unittest.main()
