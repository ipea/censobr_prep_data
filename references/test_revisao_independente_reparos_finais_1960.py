"""Testes pequenos do QC final; nao executam R nem leem fontes integrais."""
from copy import deepcopy
import json
from pathlib import Path
import unittest

from revisao_independente_reparos_finais_1960 import BASE, NEW, check_fix, check_geo_delivery, check_group
from revisao_independente_reparos_1960 import csvrows
from empacotar_evidencias_registros_1960 import expand_table


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "references/fechamento_registros_1960_evidencias"


class FinalRepairQC(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads((EVIDENCE / "texto_selecao_final33.json").read_text(encoding="utf-8"))
        cls.fixes = {r["linha127"]: r for r in manifest["reparos"]}
        cls.geo = json.loads((EVIDENCE / "geografia_pr_candidatos.json").read_text(encoding="utf-8"))["candidatos"][0]
        cls.guides = {(sample, kind): {r["variavel"]: r for r in csvrows(ROOT / f"read_guides/readguide_1960_amostra_{sample}_{kind}.csv")}
                      for sample in ("127", "25") for kind in ("pessoas", "familias")}

    def case(self, line):
        fix = deepcopy(self.fixes[line])
        fixes = {n: deepcopy(f) for n, f in self.fixes.items() if f["chave"] == fix["chave"]}
        return deepcopy(fix["grupo127"]), deepcopy(fix["grupo25"]), fixes

    def reject(self, rg, sg, fixes, geo=False):
        with self.assertRaises(AssertionError):
            check_group(rg, sg, fixes, self.guides, geo)

    def test_all_ten_new_repairs_in_nine_complete_groups(self):
        checked = set()
        for line in sorted(NEW):
            rg, sg, fixes = self.case(line)
            result = check_group(rg, sg, fixes, self.guides)
            checked.update(r["linha127"] for r in result["reparos"])
            self.assertEqual(result["bijecoes_possiveis"], 1)
        self.assertEqual(checked, NEW)

    def test_all_thirty_three_candidate_repairs(self):
        checked = set()
        for line in sorted(self.fixes):
            if line not in checked:
                rg, sg, fixes = self.case(line)
                checked.update(fixes)
                check_group(rg, sg, fixes, self.guides)
        self.assertEqual(len(checked), 33)

    def test_partial_digit_retained(self):
        fix = deepcopy(self.fixes[803760])
        check_fix(fix, self.guides)
        proposal = next(p for p in fix["propostas"] if p["campo"] == "V112")
        self.assertEqual((proposal["antes"], proposal["depois"]), ("0 ", "07"))
        proposal["depois"] = "17"
        with self.assertRaises(AssertionError):
            check_fix(fix, self.guides)

    def test_change_outside_declared_fields_rejected(self):
        fix = deepcopy(self.fixes[607904])
        fix["texto_corrigido_proposto"] = "1" + fix["texto_corrigido_proposto"][1:]
        with self.assertRaises(AssertionError):
            check_fix(fix, self.guides)

    def test_wrong_field_position_rejected(self):
        fix = deepcopy(self.fixes[607904]); fix["propostas"][0]["inicio"] += 1
        with self.assertRaises(AssertionError):
            check_fix(fix, self.guides)

    def test_incorrect_value_even_valid_rejected(self):
        rg, sg, fixes = self.case(607904)
        fixes[607904]["propostas"][0]["depois"] = "0"
        text = fixes[607904]["texto_corrigido_proposto"]
        fixes[607904]["texto_corrigido_proposto"] = text[:44] + "0" + text[45:]
        self.reject(rg, sg, fixes)

    def test_joint_card_repair_needs_person_repair(self):
        rg, sg, fixes = self.case(607903); del fixes[607904]
        self.reject(rg, sg, fixes)

    def test_joint_person_repair_needs_card_repair(self):
        rg, sg, fixes = self.case(607904); del fixes[607903]
        self.reject(rg, sg, fixes)

    def test_missing_person_rejected(self):
        rg, sg, fixes = self.case(607903)
        self.reject(rg[:-1], sg, fixes)

    def test_second_card_rejected(self):
        rg, sg, fixes = self.case(607903)
        other = deepcopy(rg[0]); other["linha"] += 9999999
        self.reject(rg + [other], sg, fixes)

    def test_source_person_order_rejected(self):
        rg, sg, fixes = self.case(607903)
        sg[1], sg[2] = sg[2], sg[1]
        self.reject(rg, sg, fixes)

    def test_reversing_127_person_order_preserves_matching(self):
        rg, sg, fixes = self.case(607903)
        result = check_group(rg[:1] + list(reversed(rg[1:])), sg, fixes, self.guides)
        self.assertEqual(result["bijecoes_possiveis"], 1)

    def test_invalid_context_does_not_become_compatible_NA(self):
        rg, sg, fixes = self.case(803760)
        descriptor = self.guides["127", "pessoas"]["V218"]
        start, end = int(descriptor["inicio"]) - 1, int(descriptor["fim"])
        text = rg[1]["texto"]
        rg[1]["texto"] = text[:start] + "Z" * (end - start) + text[end:]
        self.reject(rg, sg, fixes)

    def test_context_V216_difference_outside_00_63_rejected(self):
        rg, sg, fixes = self.case(803760)
        descriptor = self.guides["25", "pessoas"]["V216"]
        start, end = int(descriptor["inicio"]) - 1, int(descriptor["fim"])
        text = sg[1]["texto"]
        sg[1]["texto"] = text[:start] + "64" + text[end:]
        self.reject(rg, sg, fixes)

    def test_person_target_cannot_use_V216_tolerance(self):
        rg, sg, fixes = self.case(607904)
        for sample, rows, index in (("127", rg, 1), ("25", sg, 1)):
            descriptor = self.guides[sample, "pessoas"]["V216"]
            start, end = int(descriptor["inicio"]) - 1, int(descriptor["fim"])
            text = rows[index]["texto"]
            rows[index]["texto"] = text[:start] + ("00" if sample == "127" else "63") + text[end:]
        self.reject(rg, sg, fixes)

    def test_geography_preserves_literal(self):
        rg, sg = deepcopy(self.geo["grupo127"]), deepcopy(self.geo["grupo25"])
        before = deepcopy(rg)
        result = check_group(rg, sg, {}, self.guides, geo=True)
        self.assertEqual(rg, before)
        self.assertEqual(result["bijecoes_possiveis"], 1)
        self.assertEqual(result["diferencas_cartao_antes"], {"V116": [None, 7240]})

    def test_geography_disagreeing_legible_digit_rejected(self):
        rg, sg = deepcopy(self.geo["grupo127"]), deepcopy(self.geo["grupo25"])
        rg[0]["texto"] = rg[0]["texto"][:4] + "5" + rg[0]["texto"][5:]
        self.reject(rg, sg, {}, geo=True)

    def test_geography_incomplete_group_rejected(self):
        self.reject(self.geo["grupo127"][:-1], self.geo["grupo25"], {}, geo=True)

    def test_geography_district_conflict_rejected(self):
        rg, sg = deepcopy(self.geo["grupo127"]), deepcopy(self.geo["grupo25"])
        rg[2]["texto"] = rg[2]["texto"][:6] + "08" + rg[2]["texto"][8:]
        self.reject(rg, sg, {}, geo=True)

    def delivery(self):
        manifest = json.loads((ROOT / "read_guides/1960_amostra_127_geografia_fonte25.json").read_text(encoding="utf-8"))
        fixture = json.loads((EVIDENCE / "fixtures_decisoes.json").read_text(encoding="utf-8"))
        links = expand_table(fixture["vinculos_pr3"])
        result = check_group(self.geo["grupo127"], self.geo["grupo25"], {}, self.guides, geo=True)
        return manifest, links, result

    def test_three_geo_links_and_stable_manifest(self):
        manifest, links, result = self.delivery()
        checked = check_geo_delivery(manifest, links, self.geo["grupo127"], self.geo["grupo25"], result)
        self.assertEqual(checked["vinculos_confirmados"], 3)

    def test_wrong_source_person_rejected(self):
        manifest, links, result = self.delivery()
        links[0]["linha_pessoa_25"] = "708708"
        with self.assertRaises(AssertionError):
            check_geo_delivery(manifest, links, self.geo["grupo127"], self.geo["grupo25"], result)

    def test_wrong_family_link_rejected(self):
        manifest, links, result = self.delivery()
        links[0]["linha_familia"] = "887254"
        with self.assertRaises(AssertionError):
            check_geo_delivery(manifest, links, self.geo["grupo127"], self.geo["grupo25"], result)

    def test_literal_geo_repair_instead_of_derivation_rejected(self):
        manifest, links, result = self.delivery()
        links[0]["texto_corrigido"] = links[0]["texto_corrigido"].replace("724Z", "7240")
        with self.assertRaises(AssertionError):
            check_geo_delivery(manifest, links, self.geo["grupo127"], self.geo["grupo25"], result)


if __name__ == "__main__":
    unittest.main()
