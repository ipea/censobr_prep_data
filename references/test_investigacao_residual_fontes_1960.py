import hashlib
import io
import unittest
from pathlib import Path
from investigacao_residual_fontes_1960 import digest_stream, published_identities


class FontesTest(unittest.TestCase):
    def test_digest_stream(self):
        text = b"a\r\nb\n"
        self.assertEqual(digest_stream(io.BytesIO(text)),
                         {"sha256": hashlib.sha256(text).hexdigest(), "bytes": 5, "linhas": 2})

    def test_published_cross_table_identities(self):
        result = published_identities(Path(__file__).parent / "censo_1960_resultados_preliminares_1965.csv")
        self.assertEqual(len(result), 15)
        self.assertEqual(sum(r["dominio_publicado"] for r in result), 12)
        self.assertTrue(all(r["iguais"] for r in result))
        self.assertEqual(result[0]["q1_menos_0a9"], 48761467)


if __name__ == "__main__":
    unittest.main()
