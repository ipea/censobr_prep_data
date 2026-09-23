import unittest
from conferir_preservacao_ce_1960 import approve_ce


class CompositeCETest(unittest.TestCase):
    def good(self):
        return {"adulto24_ocorrencias127": 1, "adulto24_ocorrencias25": 1,
            "alternativas_grupo25": [701181], "familias127_com_adulto24": [131521],
            "n127": 9, "n25": 9, "cartao_geografia_exatos": True, "V216_apenas00_63": True,
            "vizinhas_comprovadas": 145, "vizinhas_independentes_do_alvo": 144,
            "mapeamento_vizinhas_univoco": True, "respostas_alteradas": 0}

    def test_local_positive(self):
        self.assertTrue(approve_ce(self.good()))

    def test_nonunique_adult_rejected_in_either_source(self):
        for field in ("adulto24_ocorrencias127", "adulto24_ocorrencias25"):
            d = self.good(); d[field] = 2
            with self.assertRaises(ValueError):
                approve_ce(d)

    def test_competing_mapping_or_group_rejected(self):
        for field, value in [("mapeamento_vizinhas_univoco", False), ("alternativas_grupo25", [701181, 10]),
                             ("familias127_com_adulto24", [131521, 10])]:
            d = self.good(); d[field] = value
            with self.assertRaises(ValueError):
                approve_ce(d)

    def test_bad_card_or_count_or_response_rejected(self):
        for field, value in [("cartao_geografia_exatos", False), ("n25", 8), ("respostas_alteradas", 1), ("V216_apenas00_63", False)]:
            d = self.good(); d[field] = value
            with self.assertRaises(ValueError):
                approve_ce(d)


if __name__ == "__main__":
    unittest.main()
