import unittest
import resolver_vinculos_chaves_incompletas_1960 as audit


class PartialKeyTest(unittest.TestCase):
    def test_only_missing_character_can_vary(self):
        self.assertTrue(audit.compatible_key("01152 0067","0115290067"))
        self.assertFalse(audit.compatible_key("01152 0067","0315290067"))
        self.assertFalse(audit.compatible_key("01152 0067","0115290068"))

    def test_damage_not_general_wildcard(self):
        self.assertFalse(audit.compatible_key("01X5290067","0115290067"))
        self.assertFalse(audit.compatible_key("0115290067","011529006"))


if __name__=="__main__":unittest.main()
