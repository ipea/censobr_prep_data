import unittest
from investigacao_familias_repetidas_1960 import composition_key


class FamilyKeyTest(unittest.TestCase):
    def test_order_is_irrelevant(self):
        self.assertEqual(composition_key(14, 1, "card", ["a", "b"]), composition_key(14, 1, "card", ["b", "a"]))

    def test_twins_are_not_collapsed(self):
        self.assertNotEqual(composition_key(14, 1, "card", ["a", "b"]), composition_key(14, 1, "card", ["a", "b", "b"]))

    def test_geography_and_card_are_required(self):
        a = composition_key(14, 1, "card", ["a", "b"])
        self.assertNotEqual(a, composition_key(14, 2, "card", ["a", "b"]))
        self.assertNotEqual(a, composition_key(14, 1, "other", ["a", "b"]))


if __name__ == "__main__":
    unittest.main()
