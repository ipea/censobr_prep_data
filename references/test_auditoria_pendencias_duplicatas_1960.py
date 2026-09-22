"""Testa a exigencia de grupo completo e contagem, nao identidade individual."""
from collections import Counter
from copy import deepcopy
from pathlib import Path
import unittest

from auditoria_pendencias_duplicatas_1960 import evaluate_context, load_guides, reconcile_counts


class MultiplicityTests(unittest.TestCase):
    def test_identical_siblings_preserved(self):
        self.assertEqual(reconcile_counts(Counter(parent=1, child=2), Counter(parent=1, child=2), {"child": 2}), [])

    def test_repeated_copy_requires_full_group(self):
        self.assertEqual(reconcile_counts(Counter(parent=1, child=3), Counter(parent=1, child=2), {"child": 3}), [])

    def test_missing_parent_blocks(self):
        self.assertIn("perfis_integrantes_do_grupo_divergem", reconcile_counts(Counter(child=2), Counter(parent=1, child=2), {"child": 2}))

    def test_extra_person_blocks(self):
        self.assertIn("perfis_integrantes_do_grupo_divergem", reconcile_counts(Counter(parent=1, child=2, extra=1), Counter(parent=1, child=2), {"child": 2}))

    def test_other_profile_multiplicity_blocks(self):
        self.assertIn("quantidade_de_outro_perfil_diverge", reconcile_counts(Counter(parent=2, child=2), Counter(parent=1, child=2), {"child": 2}))

    def test_more_source_children_do_not_fabricate_rows(self):
        self.assertIn("multiplicidade25_fora_dos_limites127", reconcile_counts(Counter(child=2), Counter(child=3), {"child": 2}))

    def test_different_group_same_profile_blocks(self):
        self.assertIn("mesmo_perfil_fora_do_conjunto_repetido", reconcile_counts(Counter(child=4), Counter(child=2), {"child": 2}))

    def test_source_absence_does_not_allow_zero_people(self):
        self.assertIn("multiplicidade25_fora_dos_limites127", reconcile_counts(Counter(child=2), Counter(), {"child": 2}))


class RealContextTests(unittest.TestCase):
    def setUp(self):
        self.guides = load_guides(Path(__file__).resolve().parents[1])
        self.key = (19, 19030, 134)
        f127 = "1919220119030134111478154680206003                    \\0025075"
        texts127 = [
            "191922011903013421171483718919181721095515157352925157\\0025075",
            "1919220119030134312812637189181831100955030334-       \\0025075",
            "19192201190301343119105371892000311-                  \\0025075",
            "1919220119030134311911337189191831100000000031-       \\0025075",
            "19192201190301343119105371892000311-                  \\0025075",
            "19192201190301343119101371892000-                     \\0025075",
        ]
        texts25 = [
            "190301340140141714837189919181721095515157352925157000",
            "1903013402802828126371899181831100955030334        000",
            "19030134034034191053718992000311                   000",
            "19030134045045191053718992000311                   000",
            "19030134059059191013718992000                      000",
            "1903013406106119113371899191831100000000031        000",
        ]
        self.f127 = [{"linha": 164628, "corrigido": f127}]
        self.p127 = [{"linha": 164629 + i, "corrigido": text} for i, text in enumerate(texts127)]
        self.f25 = [{"linha": 21416, "texto": "190301340040614781546802060031922011000000000000000000"}]
        self.p25 = [{"linha": 21417 + i, "texto": text} for i, text in enumerate(texts25)]
        self.pending = [{"linhas": [164631, 164633]}]

    def evaluate(self, projection=False, family_attributes=False):
        return evaluate_context(self.key, self.f127, self.p127, self.f25, self.p25,
                                self.pending, self.guides, match_without_v216=projection,
                                allow_family_attribute_differences=family_attributes)

    def replace_v216(self, row, sample, code):
        name = "corrigido" if sample == "127" else "texto"
        start, end, _ = self.guides[(sample, "pessoas")]["V216"]
        row[name] = row[name][:start] + code + row[name][end:]

    def test_real_equal_children_have_two_source_ordinals(self):
        reasons, counts = self.evaluate()
        self.assertEqual(reasons, [])
        self.assertEqual(counts[164631]["n25"], 2)
        self.assertEqual(counts[164631]["linhas25"], [21419, 21420])

    def test_wrong_family_body_blocks(self):
        text = self.f127[0]["corrigido"]
        self.f127[0]["corrigido"] = text[:19] + "6" + text[20:]
        self.assertIn("corpo_cartao127_25_diverge_ou_invalido", self.evaluate()[0])

    def test_absent_card_blocks(self):
        self.f127.clear()
        self.assertIn("cartao127_ausente_ou_nao_unico", self.evaluate()[0])

    def test_nonunique_source_card_blocks(self):
        self.f25.append(deepcopy(self.f25[0]))
        self.assertIn("cartao25_ausente_ou_nao_unico", self.evaluate()[0])

    def test_invalid_code_not_equal_missing(self):
        text = self.p127[2]["corrigido"]
        self.p127[2]["corrigido"] = text[:32] + "X" + text[33:]
        self.assertIn("pessoa127_codigo_invalido", self.evaluate()[0])

    def test_archive_id_difference_blocks(self):
        self.p127[2]["corrigido"] = self.p127[2]["corrigido"][:-1] + "6"
        self.assertIn("conjunto127_difere_no_texto_integral", self.evaluate()[0])

    def test_municipality_difference_blocks(self):
        text = self.p127[2]["corrigido"]
        self.p127[2]["corrigido"] = text[:2] + "1924" + text[6:]
        self.assertIn("geografia_pessoal127_diverge", self.evaluate()[0])

    def test_bad_source_count_blocks(self):
        text = self.f25[0]["texto"]
        self.f25[0]["texto"] = text[:11] + "07" + text[13:]
        self.assertIn("v100_diverge_contagem25", self.evaluate()[0])

    def test_bad_source_ordinal_blocks(self):
        text = self.p25[3]["texto"]
        self.p25[3]["texto"] = text[:8] + "03" + text[10:]
        self.assertIn("ordens25_incompletas_ou_repetidas", self.evaluate()[0])

    def test_one_source_sibling_missing_blocks(self):
        self.p25.pop(3)
        self.assertIn("v100_diverge_contagem25", self.evaluate()[0])

    def test_127_other_family_member_missing_blocks(self):
        self.p127.pop(0)
        self.assertIn("perfis_integrantes_do_grupo_divergem", self.evaluate()[0])

    def test_projected_match_preserves_real_difference(self):
        self.replace_v216(self.p127[0], "127", "00")
        self.replace_v216(self.p25[0], "25", "63")
        before127 = deepcopy(self.p127); before25 = deepcopy(self.p25)
        self.assertIn("perfis_integrantes_do_grupo_divergem", self.evaluate()[0])
        self.assertEqual(self.evaluate(projection=True)[0], [])
        self.assertEqual(self.p127, before127)
        self.assertEqual(self.p25, before25)

    def test_projected_match_does_not_ignore_arbitrary_year(self):
        self.replace_v216(self.p127[0], "127", "00")
        self.replace_v216(self.p25[0], "25", "54")
        self.assertIn("divergencia_V216_fora_par_00_63", self.evaluate(projection=True)[0])

    def test_projection_does_not_merge_distinct_127_variants(self):
        self.replace_v216(self.p127[0], "127", "00")
        other = deepcopy(self.p127[0]); other["linha"] = 199999
        self.replace_v216(other, "127", "63")
        self.p127.append(other)
        self.assertIn("projecao24_funde_perfis_distintos", self.evaluate(projection=True)[0])

    def test_projection_does_not_merge_distinct_25_variants(self):
        self.replace_v216(self.p25[0], "25", "00")
        other = deepcopy(self.p25[0]); other["linha"] = 299999
        self.replace_v216(other, "25", "63")
        self.p25.append(other)
        self.assertIn("projecao24_funde_perfis_distintos", self.evaluate(projection=True)[0])

    def test_projection_still_blocks_changed_age(self):
        self.replace_v216(self.p127[0], "127", "00")
        self.replace_v216(self.p25[0], "25", "63")
        start, end, _ = self.guides[("25", "pessoas")]["AGE"]
        text = self.p25[0]["texto"]
        self.p25[0]["texto"] = text[:start] + "49" + text[end:]
        self.assertIn("perfis_integrantes_do_grupo_divergem", self.evaluate(projection=True)[0])

    def test_construction_difference_does_not_change_person_count(self):
        text = self.f127[0]["corrigido"]
        self.f127[0]["corrigido"] = text[:19] + "6" + text[20:]
        before = deepcopy(self.f127)
        self.assertIn("corpo_cartao127_25_diverge_ou_invalido", self.evaluate()[0])
        self.assertEqual(self.evaluate(family_attributes=True)[0], [])
        self.assertEqual(self.f127, before)

    def test_species_difference_remains_blocked(self):
        start, end, _ = self.guides[("127", "familias")]["V101"]
        text = self.f127[0]["corrigido"]
        self.f127[0]["corrigido"] = text[:start] + "3" + text[end:]
        self.assertIn("corpo_cartao127_25_diverge_ou_invalido", self.evaluate(family_attributes=True)[0])

    def test_family_municipality_difference_remains_blocked(self):
        text = self.f127[0]["corrigido"]
        self.f127[0]["corrigido"] = text[:2] + "1924" + text[6:]
        self.assertIn("corpo_cartao127_25_diverge_ou_invalido", self.evaluate(family_attributes=True)[0])

    def test_invalid_family_attribute_remains_blocked(self):
        text = self.f127[0]["corrigido"]
        self.f127[0]["corrigido"] = text[:19] + "X" + text[20:]
        self.assertIn("corpo_cartao127_25_diverge_ou_invalido", self.evaluate(family_attributes=True)[0])

    def test_wrong_source_card_key_blocks(self):
        text = self.f25[0]["texto"]
        self.f25[0]["texto"] = "19032" + text[5:]
        self.assertIn("chave_cartao25_diverge", self.evaluate(projection=True, family_attributes=True)[0])

    def test_wrong_source_person_key_blocks(self):
        text = self.p25[0]["texto"]
        self.p25[0]["texto"] = "19032" + text[5:]
        self.assertIn("chave_pessoa25_diverge", self.evaluate(projection=True, family_attributes=True)[0])

    def test_wrong_127_card_key_blocks(self):
        text = self.f127[0]["corrigido"]
        self.f127[0]["corrigido"] = text[:8] + "19032" + text[13:]
        self.assertIn("chave_cartao127_diverge", self.evaluate(projection=True, family_attributes=True)[0])


if __name__ == "__main__":
    unittest.main()
