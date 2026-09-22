import unittest
from auditoria_pendencias_texto_1960 import fields, issues, key


class TextTests(unittest.TestCase):
    def test_branco_permitido_e_invalido_diferem(self):
        guide = [('A', 0, 1, {'1', '2'}, True), ('B', 1, 2, {'1', '2'}, False)]
        result = fields('  ', guide)
        self.assertTrue(result['A']['valido'])
        self.assertFalse(result['B']['valido'])

    def test_codigo_zero_nao_equivale_ignorado(self):
        guide = [('V216', 0, 2, {'00', '63'}, True)]
        self.assertNotEqual(fields('00', guide), fields('63', guide))

    def test_chave_danificada_nao_vira_numero(self):
        self.assertEqual(key('4060510140654177'), (40, 40654, 177))
        self.assertIsNone(key('40    01  654177'))

    def test_barra_fora_lugar_detectada(self):
        text = '1' * 54 + '\\1234567'
        self.assertFalse(issues(text, [])['estrutura'])
        self.assertTrue(issues(text[:30] + '\\' + text[31:], [])['estrutura'])

    def test_letra_nao_e_ausencia(self):
        guide = [('V208', 0, 1, {'9', '0', '1'}, False)]
        self.assertFalse(fields('R', guide)['V208']['valido'])


if __name__ == '__main__':
    unittest.main()
