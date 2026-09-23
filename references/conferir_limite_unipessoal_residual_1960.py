"""Checagem delimitada: os199 alvos exatos remanescentes sao unipessoais?"""
import json
from collections import Counter
from pathlib import Path
from auditoria_recuperacao_cartoes_1960 import sha256

ROOT=Path(__file__).resolve().parents[1]
SOURCE="tmp/investigacao_residual_1960_20260922/vinculos/detalhes01/detalhes.json"
TARGET="references/resolucao_residuais_1960_evidencias/conferencia199_unipessoais.json"


def run():
    doc=json.loads((ROOT/SOURCE).read_text(encoding="utf-8"))
    groups=[g for g in doc["grupos"]if g["classe"]=="composicao25_exata_na_chave_cartao_ainda_pendente"]
    lines=[n for g in groups for n in g["linhas_alvo"]]
    assert len(lines)==len(set(lines))==199 and len(groups)==80
    histogram=Counter(len(g["linhas_contexto"])for g in groups)
    result={"pergunta":"Ha caso unipessoal impedido estruturalmente por exigir duas testemunhas nos199 alvos?",
      "resposta":"Nao. Os80 grupos completos tem de2 a8 pessoas. Numero de alvos nao e tamanho da familia.",
      "grupos":80,"alvos":199,"grupos_unipessoais":sum(n for size,n in histogram.items()if size==1),
      "tamanhos_contexto":[{"pessoas_por_grupo":size,"grupos":n}for size,n in sorted(histogram.items())],
      "limite":"Verifica este impedimento estrutural especifico, nao aprova os199 nem demonstra que nenhum outro criterio possa ser aprofundado.",
      "cobertura":[{"grupo":g["grupo"],"linhas_alvo":g["linhas_alvo"],"linhas_contexto":g["linhas_contexto"],
        "composicao25_exata":g["comparacao_na_chave"]["composicao25"],
        "chave127":g["chave127"],"testemunhas_unicas_por_chave":g["testemunhas_unicas_por_chave"]}for g in groups],
      "fonte":{"arquivo":SOURCE,"sha256":sha256(ROOT/SOURCE)},"novas_varreduras_nacionais":0}
    out=ROOT/TARGET
    if out.exists():raise FileExistsError(out)
    out.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({k:result[k]for k in["alvos","grupos","grupos_unipessoais","tamanhos_contexto"]}))


if __name__=="__main__":run()
