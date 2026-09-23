import unittest
from collections import Counter
import investigacao_residual_vinculos_1960 as audit


class SearchTest(unittest.TestCase):
    def test_counts_prevent_merging_siblings(self):
        self.assertEqual(audit.group_candidates(["a","a"],{"a":{(1,2,3):1,(1,2,4):2}}),{(1,2,4)})

    def test_all_members_required(self):
        self.assertEqual(audit.group_candidates(["a","b"],{"a":{(1,2,3):1},"b":{(1,2,4):1}}),set())

    def test_empty_not_identity(self):
        self.assertEqual(audit.group_candidates([],{}),set())

    def test_missing_not_zero(self):
        self.assertNotEqual(audit.signatures(" "*54,"25"),audit.signatures("0"*54,"25"))

    def test_only_v216_omitted(self):
        a="0"*54;b=a[:35]+"63"+a[37:]
        self.assertNotEqual(audit.signatures(a,"25")[0],audit.signatures(b,"25")[0])
        self.assertEqual(audit.signatures(a,"25")[1],audit.signatures(b,"25")[1])

    def test_embedded_damage_not_blank(self):
        a="0"*19+"-"+"0"*42
        self.assertIn("-",audit.signatures(a,"127")[0])

    def test_documented_skip_becomes_blank(self):
        a="0"*46+"-"+" "*7+"\\0000001"
        self.assertEqual(audit.signatures(a,"127")[0][-8:]," "*8)

    def test_split_source_group_does_not_erase_candidate(self):
        self.assertEqual(audit.physical_card_context("12345002person",(10,"12345001card")),(None,None))
        self.assertEqual(audit.physical_card_context("12345002person",None),(None,None))
        self.assertEqual(audit.physical_card_context("12345002person",(10,"12345002card")),(10,"12345002card"))


if __name__=="__main__":unittest.main()
