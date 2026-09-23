import unittest
from resolver_cartoes_chaves_fonte25_1960 import pair_group


class PairingTest(unittest.TestCase):
    def make(self,age=30,year=0):
        p=list(range(25));p[3]=age;p[16]=year;return tuple(p)

    def test_preserve_only_year_difference(self):
        self.assertEqual(pair_group([self.make()],[self.make(year=63)]),[0])

    def test_other_response_not_accepted(self):
        with self.assertRaises(ValueError):pair_group([self.make()],[self.make(age=31)])

    def test_year_outside_pair_not_accepted(self):
        with self.assertRaises(ValueError):pair_group([self.make()],[self.make(year=62)])

    def test_equal_siblings_are_not_unique_witnesses(self):
        with self.assertRaises(ValueError):pair_group([self.make(),self.make()],[self.make(),self.make()])

    def test_missing_person_blocked(self):
        with self.assertRaises(ValueError):pair_group([self.make(),self.make(age=40)],[self.make()])


if __name__=="__main__":unittest.main()
