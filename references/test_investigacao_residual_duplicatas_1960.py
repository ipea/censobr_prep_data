import unittest
from collections import Counter
from pathlib import Path

from investigacao_residual_duplicatas_1960 import (
    differences, load_guides, multiplicities, nearest_people, PERSON_NAMES,
    parse_profile, raw_signature, signature,
    assignment_ranges, substantive_distance,
)


class ResidualSearchTests(unittest.TestCase):
    def test_amazonas_repeticao_composicao_nao_ordem_literal(self):
        import json
        path = Path(__file__).resolve().parent / "investigacao_residual_1960_evidencias/duplicatas_qc_blocos_am_ma.json"
        evidence = json.loads(path.read_text(encoding="utf-8"))
        am = [r for r in evidence["comparacoes_mesma_posicao"] if r["linhaA"] < 9000]
        self.assertEqual(len(am), 17)
        self.assertEqual(sum(r["restante_fora_boletim_e_id_exato"] for r in am), 4)
        self.assertTrue(all(r["mesmo_multiconjunto_literal_fora_boletim_ID"]
                            for r in evidence["comparacao_sem_exigir_mesma_ordem"]))

    def test_contagem_ambiguidades_na_correspondencia_integral(self):
        a = (0,) * 25; b = (1, 1) + (0,) * 23
        x = (1, 0) + (0,) * 23
        result = assignment_ranges([a, a, b, b], [a, x, b], {a, b})
        self.assertTrue(result["viavel"])
        self.assertEqual([(r["minimo"], r["maximo"]) for r in result["intervalos"]], [(1, 2), (1, 2)])

    def test_igual_vizinho_nao_resolve_disputa_por_mesma_pessoa25(self):
        a = (0,) * 25; b = (1, 1, 1) + (0,) * 22
        self.assertFalse(assignment_ranges([a, a, b], [a, b, b], {a})["viavel"])

    def test_nao_remove_integrante_sem_duplicata_pendente(self):
        a = (0,) * 25; b = (1, 1, 1) + (0,) * 22
        self.assertFalse(assignment_ranges([a, b], [a], set())["viavel"])

    def test_repetidos_podem_ter_uma_ou_duas_ocorrencias(self):
        a = Counter({"a": 2, "b": 1})
        self.assertTrue(multiplicities(a, Counter({"a": 1, "b": 1}), {"a"}))
        self.assertTrue(multiplicities(a, a, {"a"}))
        self.assertFalse(multiplicities(a, Counter({"a": 3, "b": 1}), {"a"}))

    def test_nao_oculta_outros_integrantes(self):
        self.assertFalse(multiplicities(Counter({"a": 2, "b": 1}), Counter({"a": 2}), {"a"}))
        self.assertFalse(multiplicities(Counter({"a": 2, "b": 1}), Counter({"a": 2, "b": 2}), {"a"}))

    def test_v216_nao_e_ignorado_no_diagnostico(self):
        a = tuple(range(25)); b = list(a); b[16] = 63
        self.assertEqual(differences(a, b), [{"campo": "V216", "valor127": 16, "valor25": 63}])

    def test_assinatura_rapida_confere_com_guia(self):
        guides = load_guides(Path(__file__).resolve().parents[1])
        import gzip
        source = Path(__file__).resolve().parents[1] / "data/release_legacy/Censo.1960.amostra.25porcento.fn.gz"
        checked = 0
        with gzip.open(source, "rt", encoding="latin1") as f:
            for text in f:
                text = text.rstrip("\r\n")
                if text[8:10] == "00":
                    continue
                p, bad = parse_profile(text, guides[("25", "pessoas")], PERSON_NAMES)
                self.assertFalse(bad)
                self.assertEqual(signature(p, guides), raw_signature(text))
                checked += 1
        self.assertGreater(checked, 100)


if __name__ == "__main__":
    unittest.main()
