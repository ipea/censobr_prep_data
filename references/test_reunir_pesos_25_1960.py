"""Fixtures sinteticas pequenas; nao le ou altera microdados de producao."""
import importlib.util
import json
from pathlib import Path
import unittest
import uuid

import pyarrow as pa
import pyarrow.parquet as pq

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("reunir", ROOT / "references/reunir_pesos_25_1960.py")
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def tables(kind="dom", keys=None):
    keys = [1, 2, 3] if keys is None else keys
    n = len(keys)
    columns = {"UF": pa.array([30] * n, pa.int32()),
        "censobr_idhousehold": pa.array(keys if kind == "dom" else [1] * n, pa.int32()),
        "V118": pa.array([1] * n, pa.int32()),
        "linha": pa.array([10, 12, 11][:n] if kind != "dom" else [10, 11, 12][:n], pa.int32()),
        "texto_bruto": pa.array(["a", None, "c"][:n]),
        "flag_bruta": pa.array([True, None, False][:n], pa.bool_())}
    raw = pa.table(columns)
    key = "censobr_idhousehold" if kind == "dom" else "linha"
    partial = raw.select(["UF", "censobr_idhousehold", "linha", "V118"])
    extra = {"situacao": pa.array(["urbana"] * n), "censobr_upa": columns["censobr_idhousehold"],
        "censobr_estrato": pa.array(["UF30_pasta1"] * n), "censobr_fpc": pa.array([0.25] * n),
        "censobr_weight_desenho": pa.array([4.0] * n), "censobr_weight": pa.array([3.5] * n),
        "censobr_weight_fator": pa.array([0.875] * n), "censobr_weight_nivel": pa.array(["UF"] * n),
        "censobr_weight_ibge": pa.array([4] * n, pa.int32())}
    for name, array in extra.items():
        partial = partial.append_column(name, array)
    complete = raw
    for name in extra:
        complete = complete.append_column(name, extra[name])
    return raw, partial, complete, key


class JoinTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.root = ROOT / "tmp" / ("teste_reunir_25_" + uuid.uuid4().hex)
        cls.root.mkdir()
        print("Fixtures preservadas em", cls.root.relative_to(ROOT), flush=True)

    def setUp(self):
        self.directory = self.root / self._testMethodName
        self.directory.mkdir()
        self.guard = mod.MemoryGuard(available=lambda: 8 * mod.GIB)

    def assemble(self, raw, partial, key="censobr_idhousehold"):
        a = self.directory / "raw.parquet"; b = self.directory / "partial.parquet"
        pq.write_table(raw, a, row_group_size=2)
        pq.write_table(partial, b, row_group_size=1)
        output = self.directory / "output.parquet"
        return mod.assemble_pair(a, b, output, "se", key, self.guard, batch_size=2)

    def test_preserves_all_columns_types_order_and_nulls(self):
        raw, partial, expected, key = tables()
        report = self.assemble(raw, partial)
        self.assertEqual(report["linhas"], 3)
        self.assertEqual(len(report["colunas_acrescidas"]), 9)
        actual = pq.read_table(self.directory / "output.parquet")
        self.assertTrue(actual.equals(expected, check_metadata=False))
        self.assertTrue(report["bruto_preservado_exato"])
        self.assertTrue(report["pesos_preservados_exatos"])

    def test_person_order_need_not_be_sorted(self):
        raw, partial, expected, key = tables("pes")
        report = self.assemble(raw, partial, key)
        self.assertEqual(report["chave_unica"], ["UF", "linha"])
        self.assertEqual(pq.read_table(self.directory / "output.parquet")["linha"].to_pylist(), [10, 12, 11])

    def test_permutation_same_length_rejected(self):
        raw, partial, _, key = tables()
        with self.assertRaisesRegex(ValueError, "Conteudo divergente"):
            self.assemble(raw, partial.take(pa.array([2, 0, 1])))

    def test_common_nonkey_difference_rejected(self):
        raw, partial, _, key = tables()
        partial = partial.set_column(partial.schema.get_field_index("V118"), "V118", pa.array([1, 5, 1], pa.int32()))
        with self.assertRaisesRegex(ValueError, "V118"):
            self.assemble(raw, partial)

    def test_global_duplicate_across_batches_rejected(self):
        raw, partial, _, key = tables(keys=[1, 2, 1])
        with self.assertRaisesRegex(ValueError, "global duplicada"):
            self.assemble(raw, partial)

    def test_missing_key_rejected(self):
        raw, partial, _, key = tables()
        partial = partial.drop(["UF"])
        with self.assertRaisesRegex(ValueError, "Chaves.*ausentes"):
            self.assemble(raw, partial)

    def test_null_key_rejected(self):
        raw, partial, _, key = tables(keys=[1, None, 3])
        with self.assertRaisesRegex(ValueError, "Chave ausente"):
            self.assemble(raw, partial)

    def test_common_type_drift_rejected(self):
        raw, partial, _, key = tables()
        partial = partial.set_column(partial.schema.get_field_index("V118"), "V118", pa.array([1, 1, 1], pa.int64()))
        with self.assertRaisesRegex(ValueError, "Tipo/nullable"):
            self.assemble(raw, partial)

    def test_missing_weight_column_rejected(self):
        raw, partial, _, key = tables()
        with self.assertRaisesRegex(ValueError, "nove colunas"):
            self.assemble(raw, partial.drop(["censobr_weight"]))

    def test_unapproved_extra_column_rejected(self):
        raw, partial, _, key = tables()
        partial = partial.append_column("extra_nao_autorizada", pa.array([1, 2, 3]))
        with self.assertRaisesRegex(ValueError, "nove colunas"):
            self.assemble(raw, partial)

    def test_wrong_count_rejected(self):
        raw, partial, _, key = tables()
        with self.assertRaisesRegex(ValueError, "quantidade"):
            self.assemble(raw, partial.slice(0, 2))

    def test_wrong_uf_rejected(self):
        raw, partial, _, key = tables()
        raw = raw.set_column(0, "UF", pa.array([31] * 3, pa.int32()))
        partial = partial.set_column(0, "UF", pa.array([31] * 3, pa.int32()))
        with self.assertRaisesRegex(ValueError, "UF incorreta"):
            self.assemble(raw, partial)

    def test_no_overwrite(self):
        raw, partial, _, key = tables()
        self.assemble(raw, partial)
        with self.assertRaises(FileExistsError):
            mod.assemble_pair(self.directory / "raw.parquet", self.directory / "partial.parquet",
                self.directory / "output.parquet", "se", key, self.guard, 2)

    def test_memory_thresholds(self):
        guard = mod.MemoryGuard(available=lambda: 3 * mod.GIB)
        with self.assertRaisesRegex(MemoryError, "requer 4"):
            guard.check("inicio", start=True)
        guard.check("batch")
        guard = mod.MemoryGuard(available=lambda: mod.GIB)
        with self.assertRaisesRegex(MemoryError, "requer 2"):
            guard.check("batch")

    def test_orchestration_full_parity_and_hashes(self):
        raw_root = self.directory / "raw"; partial_root = self.directory / "partial"
        pilot_root = self.directory / "pilot"; out = self.directory / "out"
        for folder in [raw_root / "se", partial_root / "saidas_parciais/se", pilot_root / "se",
                       partial_root / "resultados", partial_root / "manifestos", out]:
            folder.mkdir(parents=True)
        provenance = {}
        for raw_name, weighted_name, key in mod.FILES:
            raw, partial, complete, _ = tables("dom" if key == "censobr_idhousehold" else "pes")
            p = raw_root / "se" / raw_name
            pq.write_table(raw, p)
            provenance[mod.label(p)] = mod.hashes(p, self.guard)["md5"]
            pq.write_table(partial, partial_root / "saidas_parciais/se" / weighted_name)
            pq.write_table(complete, pilot_root / "se" / weighted_name)
        mod.write_json(partial_root / "manifestos/se_antes.json", provenance)
        mod.write_json(partial_root / "resultados/se.json", {"status": "concluido_auxiliar_parcial", "hashes_alterados": []})
        result = mod.run_uf("se", raw_root, partial_root, out, pilot_root, self.guard, 2)
        self.assertEqual(result["status"], "concluido_staging_nao_promovido")
        self.assertTrue((out / "se/APROVADO.json").exists())
        self.assertFalse((out / "se/FALHA.json").exists())
        self.assertEqual(result["entradas"], result["hashes_entradas_depois"])
        self.assertEqual(len(result["arquivos"]), 2)
        for record in result["arquivos"]:
            self.assertTrue(record["paridade_piloto_todas_colunas"]["igualdade_exata"])

        # Falha depois da escrita: arquivo existe, mas nunca recebe aprovacao.
        out_failure = self.directory / "out_failure"; out_failure.mkdir()
        pilot = pilot_root / "se/domicilios_pesos.parquet"
        bad = pq.read_table(pilot)
        bad = bad.set_column(bad.schema.get_field_index("texto_bruto"), "texto_bruto", pa.array(["ERRADO", None, "c"]))
        pq.write_table(bad, pilot)
        result = mod.run_uf("se", raw_root, partial_root, out_failure, pilot_root, self.guard, 2)
        self.assertEqual(result["status"], "falhou_nao_promover")
        self.assertTrue((out_failure / "se/domicilios_pesos.parquet").exists())
        self.assertTrue((out_failure / "se/FALHA.json").exists())
        self.assertFalse((out_failure / "se/APROVADO.json").exists())

    def test_failure_preserves_incomplete_folder(self):
        partial = self.directory / "partial"
        (partial / "resultados").mkdir(parents=True)
        mod.write_json(partial / "resultados/se.json", {"status": "falhou", "hashes_alterados": []})
        out = self.directory / "out"; out.mkdir()
        result = mod.run_uf("se", self.directory / "raw", partial, out, None, self.guard, 2)
        self.assertEqual(result["status"], "falhou_nao_promover")
        self.assertTrue((out / "se/FALHA.json").exists())
        self.assertFalse((out / "se/APROVADO.json").exists())


if __name__ == "__main__":
    program = unittest.main(verbosity=2, exit=False)
    mod.write_json(JoinTests.root / "resultado_testes.json", {
        "testes": program.result.testsRun, "sucesso": program.result.wasSuccessful(),
        "erros": [(str(test), traceback) for test, traceback in program.result.errors],
        "falhas": [(str(test), traceback) for test, traceback in program.result.failures]})
    raise SystemExit(0 if program.result.wasSuccessful() else 1)
