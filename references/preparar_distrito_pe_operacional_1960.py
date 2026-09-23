"""Materializa decisao PE localizada e patch auditavel dos cinco vinculos."""
import argparse
import csv
import io
import json
from pathlib import Path
from auditoria_recuperacao_cartoes_1960 import sha256

ROOT=Path(__file__).resolve().parents[1]
PROPOSAL="references/resolucao_residuais_1960_evidencias/distrito_pe_proposta.json"
APPROVED="references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"
LINKS="read_guides/1960_amostra_127_vinculos.csv"


def prepare():
    source=json.loads((ROOT/PROPOSAL).read_text(encoding="utf-8"))
    assert source["vinculos_pendentes"]==[239457,239458,239459,239460,239461]
    assert len(source["cartoes127_mesma_chave_territorio"])==1
    assert source["cartoes127_mesma_chave_territorio"][0]["linha"]==238422
    result={"versao":1,"id":"PE-22366-154-distrito", "acao":"derivar_distrito_preservar_textos",
      "criterio":"Cartao existente unico em toda127 sob toda chave legivel;15campos familiares exatos;6pessoas pareadas preservando apenasV21600/63;chefe unico nas duas fontes antes do reparoV208;0digitolegivel substituido.",
      "UF":"21","pasta":"22366","boletim":"154","municipio":"2166","situacao":"5","distrito_original":"X7","distrito_operacional":"07",
      "linhas_reparadas":[238422,238423],"linhas_vinculadas":source["vinculos_pendentes"],
      "cartao127":source["cartao127"],"pessoas127":source["pessoas127"],"cartao25":source["cartao25"],"pessoas25":source["pessoas25"],
      "pares":source["comparacao_pessoas"],"testemunha_previa_sem_V208":source["testemunha_previa_sem_V208"],
      "prova_texto":"references/resolucao_residuais_1960_evidencias/texto_propostas.json",
      "prova_alternativas":PROPOSAL,"alternativas_sob_toda_chave_legivel":0,
      "pistas_amplas_examinadas":326,"pistas_amplas_que_exigiriam_trocar_boletim_legivel":source["alternativas_restantes_busca_ampla"],
      "exclusoes":0,"pessoas_novas":0,"respostas_pessoais_alteradas":False,"textos_alterados":False}
    files=[p for p in source["fontes_sha256"]if p not in[LINKS,"read_guides/1960_amostra_127_duplicatas.csv"]]+[PROPOSAL]
    result["fontes"]=[{"arquivo":p,"sha256":sha256(ROOT/p)}for p in files]
    out=ROOT/APPROVED
    if out.exists():raise FileExistsError(out)
    out.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps({"prova":APPROVED,"sha256":sha256(out),"vinculos":result["linhas_vinculadas"]}))


def patch():
    data=json.loads((ROOT/APPROVED).read_text(encoding="utf-8"))
    path=ROOT/LINKS
    with path.open(encoding="utf-8-sig",newline="")as stream:
        reader=csv.DictReader(stream);rows=list(reader);fields=reader.fieldnames
    existing={int(r["linha"])for r in rows}
    if existing&set(data["linhas_vinculadas"]):raise ValueError("Vinculo ja registrado")
    people={p["linha"]:p for p in data["pessoas127"]}
    new=[]
    for n in data["linhas_vinculadas"]:
        p=people[n];family=data["cartao127"]
        pair=next(x for x in data["pares"]if x["linha127"]==n)
        row={"linha":n,"linha_familia":238422,"texto_original":p["original"],"texto_corrigido":p["corrigido"],
          "texto_familia_original":family["original"],"texto_familia_corrigido":family["corrigido"],
          "fonte_25":"data/release_legacy/Censo.1960.amostra.25porcento.pe.gz","linha_pessoa_25":pair["linha25"],"linha_familia_25":data["cartao25"]["linha"],
          "justificativa":"PE22366/154: distrito operacional X7->07 somente no cartao238422 e chefe238423, com textos intactos; grupo6 pareado integralmente, preservando V21600/63 da239457; testemunha238423 unica antesV208, chave legivel e cartao unicos. Prova: "+APPROVED}
        if set(row)!=set(fields):raise ValueError((set(row),fields))
        buffer=io.StringIO();writer=csv.DictWriter(buffer,fieldnames=fields,lineterminator="\n");writer.writerow(row);new.append(buffer.getvalue().rstrip("\n"))
    tail=path.read_text(encoding="utf-8-sig").splitlines()[-1]
    print("*** Begin Patch\n*** Update File: "+LINKS+"\n@@\n "+tail+"\n"+"\n".join("+"+x for x in new)+"\n*** End Patch")


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--emit-patch",action="store_true");args=parser.parse_args()
    patch()if args.emit_patch else prepare()
