"""Conferencia leve das evidencias versionadas, sem tmp, fontes brutas ou R."""
import json
from pathlib import Path
import unittest

from empacotar_evidencias_registros_1960 import expand_table


EVIDENCE = Path(__file__).resolve().parent / "fechamento_registros_1960_evidencias"


class PortableEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture = json.loads((EVIDENCE / "fixtures_decisoes.json").read_text(encoding="utf-8"))
        cls.dup = expand_table(cls.fixture["duplicatas954"])
        cls.links = expand_table(cls.fixture["vinculos166"])
        cls.pr = expand_table(cls.fixture["vinculos_pr3"])

    def test_exact_counts(self):
        self.assertEqual(len(self.dup), 1908)
        self.assertEqual(len({r["linha"] for r in self.dup}), 1908)
        self.assertEqual(len({r["grupo"] for r in self.dup}), 954)
        self.assertEqual(sum(r["acao"] == "remover" for r in self.dup), 490)
        self.assertEqual(len(self.links), 166)
        self.assertEqual(len({r["linha"] for r in self.links}), 166)
        self.assertEqual(len(self.pr), 3)

    def test_character_columns_and_literals(self):
        for row in self.dup + self.links + self.pr:
            self.assertTrue(all(isinstance(value, str) for value in row.values()))
            self.assertEqual(len(row["texto_original"]), 62)
            self.assertEqual(len(row["texto_corrigido"]), 62)
            self.assertTrue(row["justificativa"])

    def test_legitimate_equal_profiles_and_restorations_kept(self):
        actions = {int(r["linha"]): r["acao"] for r in self.dup}
        for line in (164631, 164633, 211049, 392256, 217736):
            self.assertEqual(actions[line], "manter")

    def test_653_context_ids_cover_links_and_destination_cards(self):
        ids = self.fixture["linhas127_contexto_vinculos166"]
        self.assertEqual(len(ids), 653)
        self.assertEqual(len(set(ids)), 653)
        for row in self.links:
            self.assertIn(int(row["linha"]), ids)
            self.assertIn(int(row["linha_familia"]), ids)

    def test_individual_ambiguity_not_hidden(self):
        row = next(r for r in self.links if r["linha"] == "425558")
        self.assertEqual(set(row["linha_pessoa_25"].split(";")), {"898627", "898631"})

    def test_three_pr_links_preserve_corrupt_municipality_literal(self):
        self.assertEqual({r["linha_familia"] for r in self.pr}, {"887255"})
        self.assertEqual({r["linha"] for r in self.pr}, {"887256", "888718", "888719"})
        row = next(r for r in self.pr if r["linha"] == "887256")
        self.assertEqual(row["texto_corrigido"][2:6], "724Z")
        self.assertEqual(row["texto_original"], row["texto_corrigido"])

    def test_residuals_remain_separate_from_954_decisions(self):
        residuals = json.loads((EVIDENCE / "duplicatas_residuais463.json").read_text(encoding="utf-8"))
        self.assertEqual(residuals["resumo"]["grupos"], 463)
        self.assertEqual(residuals["resumo"]["exclusoes_antigas_sem_prova"], 127)
        lines = {line for group in residuals["grupos"] for line in group["linhas127"]}
        self.assertEqual(len(lines), 928)
        self.assertFalse(lines & {int(r["linha"]) for r in self.dup})


if __name__ == "__main__":
    unittest.main()
