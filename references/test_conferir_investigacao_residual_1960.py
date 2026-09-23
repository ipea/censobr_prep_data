from collections import Counter
import unittest
from conferir_investigacao_residual_1960 import profile, projected


class IndependentTest(unittest.TestCase):
    def test_invalid_digit_is_not_missing(self):
        with self.assertRaises(ValueError):
            profile("9 ", {"campo": (0, 2, {"00", "01"})}, ["campo"])

    def test_blank_is_distinct_from_zero(self):
        layout = {"campo": (0, 2, {"00", "01"})}
        self.assertEqual(profile("  ", layout, ["campo"]), (None,))
        self.assertEqual(profile("00", layout, ["campo"]), (0,))

    def test_projection_preserves_number_of_occurrences(self):
        p = tuple(range(25))
        self.assertEqual(sum(projected(Counter({p: 2})).values()), 2)
        q = p[:16] + (63,) + p[17:]
        self.assertEqual(sum(projected(Counter({p: 2, q: 1})).values()), 3)


if __name__ == "__main__":
    unittest.main()
