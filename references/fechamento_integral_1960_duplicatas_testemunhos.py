"""Concilia todos os casos e explicita qual informacao falta, sem inferir pessoas."""
from collections import Counter
import json
from pathlib import Path
import sqlite3

import auditoria_recuperacao_cartoes_1960 as base

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tmp/fechamento_integral_1960/duplicatas"
inventory = json.loads((OUT / "inventario458.json").read_text(encoding="utf-8"))
search = json.loads((OUT / "nacional/resultado.json").read_text(encoding="utf-8"))
recheck = json.loads((OUT / "reavaliacao_integral.json").read_text(encoding="utf-8"))
hypothesis = json.loads((OUT / "nacional/hipotese_um_campo.json").read_text(encoding="utf-8"))
contexts = {tuple(c["chave"]): c for c in search["contextos"]}
checks = {tuple(c["chave"]): c for c in recheck["contextos"]}
relaxed = {tuple(c["chave"]): c for c in hypothesis["contextos"]}
alternatives = json.loads((OUT / "nacional/aprofundamento.json").read_text(encoding="utf-8"))
connection = sqlite3.connect((OUT / "indice127.sqlite").as_uri() + "?mode=ro", uri=True)
connection.row_factory = sqlite3.Row
guides = base.load_guides(ROOT)
assert "v100" not in guides[("127", "familias")]
assert "v100" in guides[("25", "familias")]
cases = []
with (ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt").open("rb") as raw:
    for group in inventory["grupos"]:
        texts = []
        for row in group["registros127"]:
            raw.seek((row["linha"] - 1) * 64)
            original = raw.read(64).decode("latin1").rstrip("\r\n")
            assert original == row["original"]
            texts.append(original)
        key = tuple(group["chave"]) if group["chave"] else None
        result = {"grupo": group["id"], "chave": group["chave"], "linhas127": group["linhas127"],
            "exclusoes_historicas_sem_prova": group["exclusoes_antigas_sem_prova"],
            "textos_brutos_relidos": texts, "identidade_literal_bruta": len(set(texts)) == 1,
            "textos_corrigidos": [r["corrigido"] for r in group["registros127"]],
            "identidade_literal_apos_reparo": len({r["corrigido"] for r in group["registros127"]}) == 1,
            "decisao_nova": None, "razao_historica": group["razao_principal"]}
        if key is None:
            result.update({"nao_ha_identidade_literal": True,
                "informacao_faltante": "Texto legivel anterior a corrupcao dos fragmentos951432/951433 e identificacao do boletim; a conversao de ambos para NA nao e identidade.",
                "hipoteses_nao_identificadas": "Os dois fragmentos podem ter origens e respostas diferentes; nem o numero de pessoas historicas e demonstrado."})
        else:
            context = contexts[key]; check = checks[key]
            assert result["identidade_literal_apos_reparo"]
            assert check["motivos_criterio_vigente"]
            result["motivos_atuais"] = check["motivos_criterio_vigente"]
            result["n_pessoas127_no_contexto"] = check["n_pessoas127"]
            result["n_pessoas25_na_chave"] = check["n_pessoas25"]
            result["contagem_perfil25_na_chave"] = check["contagens"].get(str(min(group["linhas127"])))
            result["alternativas_composicao24"] = [a for a in alternatives if a["chave127"] == list(key)]
            result["ensaio_ate_um_campo_nao_aprovado"] = relaxed[key]
            normalized = group["registros127"][0]["corrigido"]
            result["registro_sem_ordinal_individual"] = {"ID_compartilhado": normalized[55:62],
                "REC_TYPE_compartilhado": normalized[16], "n_textos_corrigidos_completos_iguais": len(texts)}
            result["testemunho_indistinguibilidade_HHOLDA_isolado"] = {
                "hipotese_A": {"pessoas_historicas": len(texts), "ocorrencias_por_pessoa": [1] * len(texts)},
                "hipotese_B": {"pessoas_historicas": 1, "ocorrencias_por_pessoa": [len(texts)]},
                "sequencia_de_textos_corrigidos_observavel_igual": True,
                "reparo_preexistente_nao_prova_duplicacao": not result["identidade_literal_bruta"],
                "nao_e_intervalo_estimado_nem_afirmacao_sobre_o_que_ocorreu": True,
                "limite": "A e B sao duas historias possiveis do mesmo texto127. Os motivos atuais registram por que nao foi demonstrado qual historia e compativel com o correspondente25; nao anulam evidencias parciais."}
            if key[0] not in base.UF:
                result["informacao_faltante"] = "Fonte estadual25 ou boletim/listagem original que preserve ordens pessoais e quantidade declarada; copias de HHOLDA com os mesmos bytes nao acrescentam essa informacao."
            elif "divergencia_V216_fora_par_00_63" in check["motivos_criterio_vigente"]:
                result["informacao_faltante"] = "Contraprova do grupo e das divergencias de casamento, ou criterio metodologico explicito que preserve respostas divergentes sem declara-las equivalentes."
            elif any("geografia" in reason or "distrito" in reason for reason in check["motivos_criterio_vigente"]):
                result["informacao_faltante"] = "Correspondencia documental que resolva a divergencia de geografia, separadamente da coincidencia pessoal."
            else:
                result["informacao_faltante"] = "Correspondente integral com multiplicidades identificadas, ou documento que explique as pessoas/campos/cartoes concorrentes; igualdade do perfil repetido isolado nao basta."
        cases.append(result)

unused = {"posicao32": [{"valor": value, "cartoes": n} for value, n in connection.execute(
    "SELECT substr(corrigido,32,1),count(*) FROM familias GROUP BY substr(corrigido,32,1)")],
    "posicoes35_54": [{"valor": value, "cartoes": n} for value, n in connection.execute(
    "SELECT substr(corrigido,35,20),count(*) FROM familias GROUP BY substr(corrigido,35,20)")],
    "conclusao": "A posicao32 nao contem contagem (somente0/branco);35a54 sao brancos em todos174467cartoes. Nao foi encontrado total pessoal oculto nas posicoes nao utilizadas pelo guia familiar."}
assert len(cases) == 458 and sum(len(c["linhas127"]) for c in cases) == 918
assert sum(c["identidade_literal_bruta"] for c in cases) == 456
assert sum(c["identidade_literal_apos_reparo"] for c in cases) == 457
assert sum(len(c["exclusoes_historicas_sem_prova"]) for c in cases) == 127
summary = {"grupos": 458, "linhas": 918, "grupos_legiveis_texto_bruto_integral_identico": 456,
    "grupos_legiveis_iguais_somente_apos_reparo_de_layout": 1,
    "grupos_nao_identicos_corrompidos": 1, "contextos_legiveis": 395,
    "grupos_sem_fonte25_da_UF": sum(c["chave"] is not None and c["chave"][0] not in base.UF for c in cases),
    "linhas_historicamente_excluidas_sem_prova": 127,
    "grupos_com_exclusao_historica": sum(bool(c["exclusoes_historicas_sem_prova"]) for c in cases),
    "novas_decisoes_aplicadas": 0}
tracked = ["preparacao.json", "inventario458.json", "nacional/resultado.json", "nacional/aprofundamento.json",
    "nacional/hipotese_um_campo.json", "reavaliacao_integral.json", "alternativas_familias_e_concorrentes.json"]
result = {"resumo": summary, "conferencia_posicoes_nao_mapeadas": unused,
    "evidencias": [{"arquivo": str((OUT / path).relative_to(ROOT)), "sha256": base.sha256(OUT / path)} for path in tracked],
    "casos": cases}
with (OUT / "testemunhos458.json").open("x", encoding="utf-8") as stream:
    json.dump(result, stream, ensure_ascii=False, indent=2)
print(json.dumps(summary, ensure_ascii=False))
