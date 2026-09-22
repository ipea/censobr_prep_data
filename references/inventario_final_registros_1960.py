"""Censo somente leitura dos bloqueios novos; nao executa nem replica a exportacao."""
from collections import Counter, defaultdict
import csv
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if len(sys.argv) != 2:
    raise SystemExit("Uso: python references/inventario_final_registros_1960.py tmp/PASTA_NOVA")
OUT = (ROOT / sys.argv[1]).resolve()
if not OUT.is_relative_to(ROOT / "tmp"):
    raise ValueError("Saida deve ficar sob tmp do projeto")
OUT.mkdir(parents=True, exist_ok=False)


def rows(path):
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


guide_path = ROOT / "read_guides/readguide_1960_amostra_127_pessoas.csv"
guide = []
for r in rows(guide_path):
    if r["variavel"] not in {"ID", "BARRA", "REC_TYPE"}:
        guide.append((r["variavel"], int(r["inicio"]) - 1, int(r["fim"]),
                      set(r["valores_validos"].split(";")) - {"", "NA"}))
correction_path = ROOT / "read_guides/1960_amostra_127_correcoes.csv"
corrections = {int(r["linha"]): r for r in rows(correction_path)}
duplicate_path = ROOT / "read_guides/1960_amostra_127_duplicatas.csv"
duplicate_decisions = {int(r["linha"]): r for r in rows(duplicate_path)}
link_path = ROOT / "read_guides/1960_amostra_127_vinculos.csv"
links = {int(r["linha"]): r for r in rows(link_path)}
raw_path = ROOT / "data_raw/microdata/1960/amostra_127/HHOLDA.txt"


def records():
    with raw_path.open(encoding="latin1") as f:
        for line, original in enumerate(f, 1):
            original = original.rstrip("\r\n")
            assert len(original) == 62
            correction = corrections.get(line, {})
            if correction:
                assert original == correction["texto_original"], line
            if correction.get("decisao") == "cartao_uf":
                continue
            text = correction.get("texto_corrigido") or original
            if correction.get("decisao") == "corrompida":
                text = " " * 16 + text[16] + " " * 37 + "\\" + text[55:]
            yield line, original, text


def field(value, valid):
    if not value.strip() or (value.startswith("-") and not value[1:].strip()):
        return None
    if valid:
        return value if value in valid else None
    return value if all(c in "0123456789 " for c in value) else None


seen = {}
repeated_groups = defaultdict(list)
family_keys = {}
family_by_line = {}
people = families = 0
for line, original, text in records():
    if text[16] == "1":
        uf = field(text[:2], set())
        if uf == "03" and text[2:6] == "0011":
            uf = "00"
        key = (uf, text[6:16])
        assert key not in family_keys, (line, key)
        family_keys[key] = line
        family_by_line[line] = text
        families += 1
        continue
    people += 1
    values = [field(text[start:end], valid) for _, start, end, valid in guide]
    # Mesmos componentes da assinatura R: navegacao, todos os campos parseados e tipo;
    # id_arquivo fica na chave do grupo; diagnosticos e textos nao compoem o perfil.
    signature = "|".join([text[6:8], text[8:13], text[13:16], text[6:16]] +
                         [v if v is not None else "NA" for v in values] + [text[16]])
    key = (text[55:62], signature)
    if key in seen:
        if not repeated_groups[key]:
            repeated_groups[key].append(seen[key])
        repeated_groups[key].append(line)
    else:
        seen[key] = line
    if line in duplicate_decisions:
        r = duplicate_decisions[line]
        assert (original, text) == (r["texto_original"], r["texto_corrigido"]), line
    if line in links:
        r = links[line]
        assert (original, text) == (r["texto_original"], r["texto_corrigido"]), line

pending_duplicates = []
approved_groups = 0
for (archive_id, signature), lines in repeated_groups.items():
    approved = [duplicate_decisions.get(n) for n in lines]
    if any(approved):
        assert all(approved), lines
        assert len({r["grupo"] for r in approved}) == 1
        assert all(int(r["n_antes"]) == len(lines) for r in approved)
        assert sum(r["acao"] == "manter" for r in approved) == int(approved[0]["n_manter"])
        approved_groups += 1
    else:
        pending_duplicates.append({"id_arquivo": archive_id, "linhas": lines})
del seen

recovery_path = ROOT / "read_guides/1960_amostra_127_cartoes_recuperados.json"
recovery = json.loads(recovery_path.read_text(encoding="utf-8"))
recovered_people = {p["linha"]: c for c in recovery["cartoes"] for p in c["pessoas"]}
assert len(recovered_people) == sum(c["n_pessoas"] for c in recovery["cartoes"])
confirmed_links = set(links)
conflicts_muni = []
conflicts_situation = []
family_counts = Counter()
unlinked_before = []
unlinked_after = []
group_before = defaultdict(list)
group_after = defaultdict(list)
removed = {n for n, r in duplicate_decisions.items() if r["acao"] == "remover"}
for line, original, text in records():
    if text[16] == "1" or line in removed:
        continue
    uf = field(text[:2], set())
    if uf == "03" and text[2:6] == "0011":
        uf = "00"
    key = (uf, text[6:16])
    if key not in family_keys:
        item = {"linha": line, "UF": uf, "V116": text[2:6], "chave": text[6:16],
                "tipo": text[16], "V203": text[19]}
        unlinked_before.append(item)
        group_before[key].append(item)
        if line not in links and line not in recovered_people:
            unlinked_after.append(item)
            group_after[key].append(item)
    if line in recovered_people:
        card = recovered_people[line]
        source_person = next(p for p in card["pessoas"] if p["linha"] == line)
        assert (original, text) == (source_person["texto_original"], source_person["texto_corrigido"])
        assert key not in family_keys and line not in links
    target = int(links[line]["linha_familia"]) if line in links else family_keys.get(key)
    if target is not None:
        family_counts[target] += 1
        family = family_by_line[target]
        if line in links:
            assert family == links[line]["texto_familia_corrigido"]
        if line not in confirmed_links:
            detail = {"linha": line, "linha_cartao": target, "UF": uf,
                      "chave": text[6:16], "pessoa": text, "cartao": family}
            if field(text[2:6], set()) is None or field(family[2:6], set()) is None or text[2:6] != family[2:6]:
                conflicts_muni.append(detail)
            if text[17] not in '135' or family[17] not in '135' or text[17] != family[17]:
                conflicts_situation.append(detail)

empty_cards = [{"linha": n, "texto": t} for n, t in family_by_line.items() if family_counts[n] == 0]
isolated_cards = []
previous = None
for n, text in sorted(family_by_line.items()):
    if text[18] in '45':
        allowed = previous is not None and previous[18] in '245'
        for start, end in [(0, 2), (2, 6), (6, 8), (8, 13)]:
            allowed = allowed and field(text[start:end], set()) is not None and text[start:end] == previous[start:end]
        if not allowed:
            isolated_cards.append({"linha": n, "texto": text})
    previous = text
corrupted_lines = {n for n, r in corrections.items() if r['decisao'] == 'corrompida'}
for group in pending_duplicates:
    group['indistinguibilidade_por_dano'] = bool(set(group['linhas']) & corrupted_lines)
unknown_key_rows = [r for r in unlinked_after if r['linha'] in corrupted_lines]

summary = {
    "pessoas_brutas_parseadas": people,
    "cartoes_familia_reais": families,
    "perfis_repetidos_total": len(repeated_groups),
    "ocorrencias_apos_primeira_total": sum(len(v) - 1 for v in repeated_groups.values()),
    "perfis_repetidos_decididos": approved_groups,
    "linhas_manifesto_duplicatas": len(duplicate_decisions),
    "remocoes_autorizadas_se_demais_bloqueios_resolvidos": len(removed),
    "perfis_repetidos_pendentes": len(pending_duplicates),
    "ocorrencias_apos_primeira_pendentes": sum(len(r["linhas"]) - 1 for r in pending_duplicates),
    "todas_linhas_nos_perfis_pendentes": sum(len(r["linhas"]) for r in pending_duplicates),
    "pessoas_sem_cartao_antes_manifesto": len(unlinked_before),
    "grupos_sem_cartao_antes_manifesto": len(group_before),
    "pessoas_reconciliadas_manifesto": len(links),
    "cartoes_recuperados_manifesto": len(recovery["cartoes"]),
    "pessoas_em_cartoes_recuperados": len(recovered_people),
    "conflitos_municipais_sem_reconciliacao": len(conflicts_muni),
    "conflitos_situacao_sem_reconciliacao": len(conflicts_situation),
    "pessoas_distintas_com_conflito_geografico": len({r["linha"] for r in conflicts_muni + conflicts_situation}),
    "cartoes_reais_sem_pessoas": len(empty_cards),
    "conviventes_reais_sem_principal_confirmado": len(isolated_cards),
    "linhas_corrompidas_sem_grupo_identificavel": len(unknown_key_rows),
    "pessoas_sem_cartao_apos_manifesto": len(unlinked_after),
    "grupos_sem_cartao_apos_manifesto": len(group_after),
    "grupos_pendentes_com_chefe_ou_conjuge": sum(any(r["tipo"] == "2" or r["V203"] in {"7", "8"} for r in members) for members in group_after.values()),
    "pessoas_pendentes_por_uf": dict(Counter(r["UF"] for r in unlinked_after)),
    "nota": "Inventario independente, nao reconstrucao R. Listas de bloqueios se sobrepoem. Tres linhas corrompidas agregadas por chave vazia nao demonstram uma familia comum. O perfil repetido resultante da anulacao de campos danificados nao comprova duplicacao. Conviventes enumeradas na ordem dos cartoes reais; a guarda R tambem verifica cartoes recuperados."
}
sources = [{"arquivo": str(p.relative_to(ROOT)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest()}
           for p in [raw_path, guide_path, correction_path, duplicate_path, link_path, recovery_path]]
result = {"resumo": summary, "fontes": sources, "duplicatas_pendentes": pending_duplicates,
          "vinculos_pendentes": unlinked_after,
          "conflitos_municipais": conflicts_muni, "conflitos_situacao": conflicts_situation,
          "cartoes_sem_pessoas": empty_cards, "conviventes_sem_principal": isolated_cards,
          "corrompidas_sem_grupo_identificavel": unknown_key_rows}
filename = "inventario_final.json"
destination = OUT / filename
with destination.open("x", encoding="utf-8") as f:
    json.dump(result, f, ensure_ascii=False, indent=2)
print(json.dumps(summary, ensure_ascii=False, indent=2))
