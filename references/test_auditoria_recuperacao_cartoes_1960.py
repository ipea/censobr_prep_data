"""Testes pequenos da auditoria; nao executam R nem escrevem dados de producao."""
from collections import Counter
import copy
import importlib.util
from pathlib import Path
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("recuperacao", ROOT / "references/auditoria_recuperacao_cartoes_1960.py")
audit = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(audit)


class RecuperacaoTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.guides = audit.load_guides(ROOT)

    def setUp(self):
        self.family = {"linha": 58692, "texto": "40090004008023               4523011000000000000000000"}
        self.source = [
            {"linha": 58693, "texto": "400900040180185412254169920001644165900000318423346000"},
            {"linha": 58694, "texto": "4009000402602664119541699200017210659000034        000"},
        ]
        self.people = [
            {"linha": 491756, "original": "4045230140090004316411954169200017210659000034-       \\0078085",
             "corrigido": "4045230140090004316411954169200017210659000034-       \\0078085", "familia_atual": None},
            {"linha": 491757, "original": "404523014009000431541225416920001644165900000318423346\\0078085",
             "corrigido": "404523014009000431541225416920001644165900000318423346\\0078085", "familia_atual": None},
        ]

    def evaluate(self, **kwargs):
        return audit.evaluate_group((40, 40090, 4), [self.family], self.source, self.people,
                                    self.guides, **kwargs)

    def test_real_mg_content_and_reverse_order(self):
        reasons, card = self.evaluate()
        self.assertEqual(reasons, [])
        self.assertEqual(len(card["pessoas"]), 2)
        self.assertEqual([r["linha_25"] for r in card["pessoas"]], [58694, 58693])
        self.assertEqual(card["UF"], "40")
        self.assertEqual(card["familias"]["V101"], "3")
        self.assertIsNone(card["familias"]["V113"])
        self.assertNotIn("linha", card)
        self.assertEqual(card["distrito"], "01")

    def test_declared_count(self):
        self.family["texto"] = self.family["texto"][:11] + "03" + self.family["texto"][13:]
        self.assertIn("v100_diverge_contagem25", self.evaluate()[0])

    def test_missing_person(self):
        self.people.pop()
        self.assertIn("composicao_integral_diverge", self.evaluate()[0])

    def test_extra_person(self):
        row = copy.deepcopy(self.people[0]); row["linha"] = 491758
        self.people.append(row)
        self.assertIn("composicao_integral_diverge", self.evaluate()[0])

    def test_indistinguishable_persons_not_individual_matches(self):
        self.people.append(copy.deepcopy(self.people[0]))
        self.assertIn("perfil127_nao_unico", self.evaluate()[0])

    def test_geography_not_part_of_profile_is_separately_required(self):
        self.people[0]["corrigido"] = "404524" + self.people[0]["corrigido"][6:]
        self.assertIn("geografia_pessoal_diverge_ou_ausente", self.evaluate()[0])

    def test_current_link_protected(self):
        self.people[0]["familia_atual"] = 55
        self.assertIn("pessoa_ja_vinculada", self.evaluate()[0])

    def test_pending_duplicate_protected(self):
        self.assertIn("duplicata_sem_decisao", self.evaluate(pending_duplicates={491756})[0])

    def test_collective_not_requires_family_members(self):
        self.assertEqual(self.evaluate()[0], [])

    def test_conviventes_require_separate_proof(self):
        for code in "2459":
            with self.subTest(code=code):
                self.family["texto"] = self.family["texto"][:13] + code + self.family["texto"][14:]
                self.assertIn("especie_fora_escopo_1_3", self.evaluate()[0])

    def test_duplicate_source_card(self):
        reasons, card = audit.evaluate_group((40, 40090, 4), [self.family, self.family],
                                             self.source, self.people, self.guides)
        self.assertIn("cartao25_nao_unico", reasons)
        self.assertIsNone(card)

    def test_invalid_key_keeps_people_in_report(self):
        reasons, card = audit.evaluate_group((40, None, 4), [], [], self.people, self.guides)
        self.assertEqual(reasons, ["chave127_invalida"])
        self.assertIsNone(card)
        connection = sqlite3.connect(":memory:")
        connection.row_factory = sqlite3.Row
        connection.execute("CREATE TABLE pessoas(linha INTEGER,uf INTEGER,pasta INTEGER,boletim INTEGER,excluida INTEGER)")
        connection.execute("INSERT INTO pessoas VALUES(19,40,NULL,4,0)")
        found = audit.fetch(connection, "SELECT linha FROM pessoas WHERE uf IS ? AND pasta IS ? AND boletim IS ? AND excluida=0", (40, None, 4))
        self.assertEqual(found, [{"linha": 19}])
        connection.close()

    def test_absent_source_card_not_duplicate_source_card(self):
        reasons, _ = audit.evaluate_group((40, 40090, 4), [], [], self.people, self.guides)
        self.assertEqual(reasons, ["cartao25_ausente"])

    def test_source_orders(self):
        self.source[1]["texto"] = self.source[1]["texto"][:8] + "01" + self.source[1]["texto"][10:]
        self.assertIn("ordens25_incompletas_ou_repetidas", self.evaluate()[0])
        self.assertIn("redundancias25_divergentes", self.evaluate()[0])

    def test_recognized_skip_does_not_hide_corruption(self):
        text = self.people[0]["corrigido"]
        good, invalid = audit.parse_profile(text, self.guides[("127", "pessoas")], audit.PERSON_NAMES)
        self.assertEqual(invalid, [])
        damaged, invalid = audit.parse_profile(text[:46] + "X  " + text[49:], self.guides[("127", "pessoas")], audit.PERSON_NAMES)
        self.assertIn("V221", invalid)
        self.assertEqual(good, damaged)  # igualdade de NA nao autoriza recuperacao
        self.people[0]["corrigido"] = text[:46] + "X  " + text[49:]
        self.assertIn("pessoa127_codigo_invalido", self.evaluate()[0])

    def test_zero_and_blank_remain_distinct(self):
        text = self.people[0]["corrigido"]
        a, _ = audit.parse_profile(text, self.guides[("127", "pessoas")], audit.PERSON_NAMES)
        b, _ = audit.parse_profile(text[:40] + "  " + text[42:], self.guides[("127", "pessoas")], audit.PERSON_NAMES)
        self.assertNotEqual(a, b)

    def test_v113_explicit_width_conversion(self):
        text = self.family["texto"][:26] + "003" + self.family["texto"][29:]
        values = audit.normalized_family(text, self.guides)
        self.assertEqual(values["V113"], "03")
        self.assertIsNone(values["V112"])

    def test_documented_family_skip(self):
        text = "4045230140090064113-                                  \\0078098"
        profile, invalid = audit.parse_profile(text, self.guides[("127", "familias")], audit.FAMILY_NAMES)
        self.assertEqual(invalid, [])
        self.assertEqual(profile[:13], (3,) + (None,) * 12)

    def test_skip_outside_documented_positions_or_with_remaining_content_is_invalid(self):
        text = "4045230140090064113-                                  \\0078098"
        _, invalid = audit.parse_profile(text[:22] + "1" + text[23:], self.guides[("127", "familias")], audit.FAMILY_NAMES)
        self.assertIn("V102", invalid)
        _, invalid = audit.parse_profile(text[:19] + " " + text[20:21] + "-" + text[22:],
                                         self.guides[("127", "familias")], audit.FAMILY_NAMES)
        self.assertIn("V104", invalid)

    def test_noncontiguous_source_people(self):
        self.source[1]["linha"] += 1
        self.assertIn("pessoas25_nao_contiguas_ao_cartao", self.evaluate()[0])

    def test_key_proximity_with_conflicting_species_and_composition_is_only_a_clue(self):
        self.assertEqual(audit.alternative_reasons(True, False, True, Counter({b"other": 3}),
            Counter({b"other": 3}), Counter({b"target": 2}), same_species=False), [])

    def test_same_blank_family_profile_with_own_disjoint_group_is_not_automatic_block(self):
        reasons = audit.alternative_reasons(True, True, False, Counter({b"different": 2}),
                                            Counter({b"different": 2, b"target": 2}), Counter({b"target": 2}), own_confirmed=True)
        self.assertEqual(reasons, [])

    def test_disjoint_people_without_source_confirmation_do_not_prove_occupied_card(self):
        self.assertIn("cartao_compativel_sem_grupo_proprio", audit.alternative_reasons(
            True, True, False, Counter({b"other": 2}), Counter({b"other": 2}), Counter({b"target": 2})))

    def test_same_family_without_own_group_is_unresolved(self):
        self.assertIn("cartao_compativel_sem_grupo_proprio", audit.alternative_reasons(
            True, True, False, Counter(), Counter(), Counter({b"target": 2})))

    def test_physical_composition_is_alternative_not_a_decision(self):
        self.assertIn("composicao_fisica_integral", audit.alternative_reasons(
            True, False, True, Counter(), Counter({b"target": 2}), Counter({b"target": 2})))

    def test_whole_group_with_other_geography_is_still_an_alternative(self):
        reasons = audit.alternative_reasons(False, False, True, Counter({b"target": 2}),
                                           Counter({b"target": 2}), Counter({b"target": 2}))
        self.assertIn("composicao_ligada_integral", reasons)
        self.assertIn("composicao_fisica_integral", reasons)

    def test_adjacent_card_with_other_body_and_composition_is_not_decisive(self):
        self.assertEqual(audit.alternative_reasons(True, False, False, Counter({b"other": 3}),
                         Counter({b"target": 2, b"other": 3}), Counter({b"target": 2})), [])


class GrupoProprioTests(unittest.TestCase):
    """Cartao alternativo PR70380/050: seis integrantes, duas testemunhas exatas."""

    @classmethod
    def setUpClass(cls):
        cls.guides = audit.load_guides(ROOT)

    def setUp(self):
        self.connection = sqlite3.connect(":memory:")
        self.connection.row_factory = sqlite3.Row
        self.addCleanup(self.connection.close)
        self.connection.execute("""CREATE TABLE pessoas(linha INTEGER,uf INTEGER,
          municipio INTEGER,distrito INTEGER,situacao INTEGER,excluida INTEGER,
          familia_atual INTEGER,perfil BLOB,corrigido TEXT,invalidos TEXT)""")
        self.texts127 = [
            "717145017038005021171525419920001721063603034311625117\\0141252",
            "7171450170380050312814354199200017210636030334-       \\0141252",
            "7171450170380050312911754199200006310000000035-       \\0141252",
            "7171450170380050312912154199200006442000000035-       \\0141252",
            "7171450170380050312312254199200011100000000034-       \\0141252",
            "7171450170380050311912254199200007320000000035-       \\0141252",
        ]
        self.family = {"linha": 860762, "uf": 71, "pasta": 70380, "boletim": 50,
                       "municipio": 7145, "distrito": 1, "situacao": 1, "invalidos": "",
                       "corrigido": "7171450170380050113-                                  \\0141252"}
        p, bad = audit.parse_profile(self.family["corrigido"], self.guides[("127", "familias")], audit.FAMILY_NAMES)
        self.assertEqual(bad, [])
        self.family["perfil"] = audit.profile_hash(p)
        self.family25 = {"linha": 125434, "texto": "70380050004063               7145011000000000000000000"}
        source_texts = [
            "703800500140141715254199920001721063603034311625117000",
            "7038005002202228143541999200017210636030334        000",
            "7038005003003019122541999200007320063000035        000",
            "7038005004904929121541999200006442063000035        000",
            "7038005005705729117541999200006310063000035        000",
            "7038005006506523122541999200011100063000034        000",
        ]
        self.people25 = [{"linha": 125435+i, "texto": t} for i, t in enumerate(source_texts)]
        self.refresh127()

    def refresh127(self):
        self.connection.execute("DELETE FROM pessoas")
        for i, t in enumerate(self.texts127):
            profile, invalid = audit.parse_profile(t, self.guides[("127", "pessoas")], audit.PERSON_NAMES)
            self.connection.execute("INSERT INTO pessoas VALUES(?,?,?,?,?,?,?,?,?,?)",
                (860763+i, 71, 7145, 1, 1, 0, 860762, audit.profile_hash(profile), t, ";".join(invalid)))

    def evaluate(self, pending=frozenset(), permitir_contexto=True):
        return audit.own_group_proof(self.connection, self.family, {(70380, 50): [self.family25]},
                                    {(70380, 50): self.people25}, self.guides, pending,
                                    permitir_contexto=permitir_contexto)[0]

    def test_default_contract_remains_strict(self):
        proof = audit.own_group_proof(self.connection, self.family, {(70380, 50): [self.family25]},
            {(70380, 50): self.people25}, self.guides, frozenset())[0]
        self.assertFalse(proof["confirmado"])
        self.assertEqual(proof["motivos"], ["composicao_propria_diverge"])
        self.assertEqual(proof["pares"], [])

    def test_full_equality_is_not_required_for_own_group_identity(self):
        before = audit.fetch(self.connection, "SELECT * FROM pessoas ORDER BY linha")
        source_before = copy.deepcopy(self.people25)
        proof = self.evaluate()
        self.assertTrue(proof["confirmado"])
        self.assertEqual(proof["criterio"], "grupo_proprio24_V216_preservado")
        self.assertEqual(proof["motivos_estritos"], ["composicao_propria_diverge"])
        self.assertEqual(proof["testemunhas_exatas_unicas127"], [860763, 860764])
        self.assertEqual(len(proof["pares"]), 6)
        self.assertEqual(sum(p["V216"][0] != p["V216"][1] for p in proof["pares"]), 4)
        self.assertEqual(before, audit.fetch(self.connection, "SELECT * FROM pessoas ORDER BY linha"))
        self.assertEqual(source_before, self.people25)
        self.assertFalse(proof["respostas_modificadas"])

    def test_exact_group_keeps_original_criterion(self):
        self.texts127 = [t[:38] + ("63" if t[38:40] == "00" else t[38:40]) + t[40:] for t in self.texts127]
        self.refresh127()
        proof = self.evaluate()
        self.assertTrue(proof["confirmado"])
        self.assertEqual(proof["criterio"], "composicao_integral25")

    def test_one_anchor_repeated_in_same_uf_blocks(self):
        self.connection.execute("INSERT INTO pessoas SELECT 1,uf,municipio,distrito,situacao,excluida,99,perfil,corrigido,invalidos FROM pessoas WHERE linha=860763")
        proof = self.evaluate()
        self.assertFalse(proof["confirmado"])
        self.assertIn("menos_de_duas_testemunhas_unicas_na127_UF", proof["motivos"])

    def test_other_uf_or_removed_profile_does_not_remove_anchor_uniqueness(self):
        self.connection.execute("INSERT INTO pessoas SELECT 1,40,municipio,distrito,situacao,excluida,99,perfil,corrigido,invalidos FROM pessoas WHERE linha=860763")
        self.connection.execute("INSERT INTO pessoas SELECT 2,uf,municipio,distrito,situacao,1,99,perfil,corrigido,invalidos FROM pessoas WHERE linha=860764")
        self.assertTrue(self.evaluate()["confirmado"])

    def test_additional_field_difference_blocks(self):
        t = self.texts127[2]; self.texts127[2] = t[:21] + "18" + t[23:]
        self.refresh127()
        proof = self.evaluate()
        self.assertFalse(proof["confirmado"])
        self.assertIn("diferenca_alem_de_V216", proof["motivos"])

    def test_other_v216_difference_blocks(self):
        t = self.texts127[2]; self.texts127[2] = t[:38] + "01" + t[40:]
        self.refresh127()
        proof = self.evaluate()
        self.assertFalse(proof["confirmado"])
        self.assertIn("diferenca_V216_fora_do_par_00_63", proof["motivos"])

    def test_repeated_24field_profile_blocks_even_with_same_multiplicity(self):
        self.texts127[3] = self.texts127[3][:18] + self.texts127[2][18:]
        self.people25[3]["texto"] = self.people25[3]["texto"][:14] + self.people25[4]["texto"][14:]
        self.refresh127()
        proof = self.evaluate()
        self.assertFalse(proof["confirmado"])
        self.assertIn("pareamento24_nao_unico", proof["motivos"])

    def test_other_original_impediments_remain_blocking(self):
        checks = [
            ("distrito_cartao_proprio_diverge", lambda: self.family.update(distrito=2)),
            ("duplicata_propria_pendente", lambda: None),
            ("geografia_propria_diverge", lambda: self.connection.execute("UPDATE pessoas SET municipio=7146 WHERE linha=860763")),
            ("v100_diverge_contagem25", lambda: self.family25.update(texto=self.family25["texto"][:11] + "07" + self.family25["texto"][13:])),
        ]
        for reason, change in checks:
            with self.subTest(reason=reason):
                old_family = dict(self.family); old_source = dict(self.family25)
                change()
                proof = self.evaluate({860763} if reason == "duplicata_propria_pendente" else frozenset())
                self.assertFalse(proof["confirmado"])
                self.assertIn(reason, proof["motivos"])
                self.family = old_family; self.family25 = old_source; self.refresh127()

    def test_recovery_target_still_requires_all_25fields(self):
        family = self.family25
        people = audit.fetch(self.connection, "SELECT * FROM pessoas ORDER BY linha")
        for p in people:
            p["original"] = p["corrigido"]; p["familia_atual"] = None
        reasons, card = audit.evaluate_group((71, 70380, 50), [family], self.people25, people, self.guides)
        self.assertIn("composicao_integral_diverge", reasons)
        self.assertIsNone(card)


if __name__ == "__main__":
    unittest.main(verbosity=2)
