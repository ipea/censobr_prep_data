"""Reaplica sem mudar criterio a auditoria operacional anterior nos41cartoes recuperados x reais/entre si e o distrito operacionalPE.

Somente leitura do indice e dos manifestos. Saida exclusivamente em nova pasta
tmp. Reproduz a assinatura da guardaR com valores textuais, inclusiveNA e
multiplicidades; nao aprova/exclui familias e nao executa a pipeline.
"""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import re
import sqlite3

ROOT=Path(__file__).resolve().parents[1]
DEFAULT_INDEX="tmp/fechamento_integral_1960/vinculos/reauditoria01/indice127.sqlite"
MANIFEST="read_guides/1960_amostra_127_cartoes_recuperados.json"
PE="references/resolucao_residuais_1960_evidencias/distrito_pe_operacional.json"
CORRECTIONS="read_guides/1960_amostra_127_correcoes.csv"
DUPLICATES="read_guides/1960_amostra_127_duplicatas.csv"
LINKS="read_guides/1960_amostra_127_vinculos.csv"
PNAMES="V202 V203 V204 AGE V205 V206 V207 V208 V209 V299 V210 V211 V212 V213 V214 V215 V216 V217 V218 V219 V220 V221 V223 V223B V224".split()
FNAMES=[f"V{n}"for n in range(101,114)]+["V116","V118"]
RAW="data_raw/microdata/1960/amostra_127/HHOLDA.txt"


def sha(path):
    result=hashlib.sha256()
    with path.open("rb")as stream:
        while block:=stream.read(4*1024**2):result.update(block)
    return result.hexdigest()


def read_json(path):return json.loads(path.read_text(encoding="utf-8"))


def rows(path):
    with path.open(encoding="utf-8-sig",newline="")as stream:return list(csv.DictReader(stream))


def signature(uf,district,family,people):
    personal=["|".join("NA"if x is None else x for x in p)for p in people]
    return uf,district,tuple(family),tuple(sorted(Counter(personal).items()))


def parse_r(text,guide):
    """Replica aplica_layout da parse127, nao o hash numerico do indice."""
    values={};cancelled=[]
    for g in guide:
        name=g["variavel"]
        if name in{"BARRA","ID","REC_TYPE"}:continue
        value=text[int(g["inicio"])-1:int(g["fim"])]
        skip=value.startswith("-")and not value[1:].strip()
        blank=not value.strip()
        valid=set(g["valores_validos"].split(";"))-{"","NA"}
        bad=(bool(re.search(r"[^0-9 ]",value))and not skip)if g["valores_validos"]==""else(value not in valid and not skip and not blank)
        values[name]=None if skip or blank or bad else value
        if bad:cancelled.append(name)
    return values,cancelled


def tests():
    f=["1"]*15;p=["0"]*25;q=p.copy();q[3]="10"
    assert signature("21","07",f,[p,q])==signature("21","07",f,[q,p])
    assert signature("21","07",f,[p,p])!=signature("21","07",f,[p])
    assert signature("21","07",f,[p])!=signature("21","17",f,[p])
    assert signature("21","07",f,[p])!=signature("14","07",f,[p])
    q=p.copy();q[16]="63"
    assert signature("21","07",f,[p])!=signature("21","07",f,[q])
    g=[{"variavel":"A","inicio":"1","fim":"2","valores_validos":"00;01;NA"}]
    assert parse_r("X7",g)==({"A":None},["A"])
    assert parse_r("  ",g)==({"A":None},[])
    assert parse_r("- ",g)==({"A":None},[])
    return 8


def audit(index,out):
    out.mkdir(parents=True,exist_ok=False)
    manifest=read_json(ROOT/MANIFEST);pe=read_json(ROOT/PE)
    if len(manifest["cartoes"])!=41:raise ValueError("Escopo desta rodada deve ter41cartoes")
    corrections={int(r["linha"]):r for r in rows(ROOT/CORRECTIONS)}
    duplicates={int(r["linha"]):r for r in rows(ROOT/DUPLICATES)}
    links={int(r["linha"]):r for r in rows(ROOT/LINKS)}
    guides={kind:rows(ROOT/f"read_guides/readguide_1960_amostra_127_{kind}.csv")for kind in["familias","pessoas"]}
    paths=([MANIFEST,PE,CORRECTIONS,DUPLICATES,LINKS,RAW,"R/microdata_1960_amostra_127.R",
      Path(__file__).resolve().relative_to(ROOT).as_posix()]+
      [f"read_guides/readguide_1960_amostra_127_{kind}.csv"for kind in guides])
    hashes={p:sha(ROOT/p)for p in paths}
    index_hash=sha(index)
    index_proof=read_json(index.parent/"resultado.json")
    if index_proof["indice_atual_sha256"]!=index_hash:raise ValueError("Indice diverge da auditoria de origem")
    index_sources={x["arquivo"]:x["sha256"]for x in index_proof["fontes"]}
    for p in[CORRECTIONS,DUPLICATES,LINKS,RAW]+[x for x in paths if "readguide_"in x]:
        if index_sources.get(p)!=hashes[p]:raise ValueError(f"Indice nao corresponde ao arquivo atual: {p}")
    for evidence in[manifest,pe]:
        for f in evidence["fontes"]:
            file=(ROOT/f["arquivo"]).resolve()
            if not file.is_relative_to(ROOT)or sha(file)!=f["sha256"]:raise ValueError("Fonte divergente: "+f["arquivo"])
    con=sqlite3.connect(index.as_uri()+"?mode=ro",uri=True);con.row_factory=sqlite3.Row
    pe_index_rows=[dict(con.execute(f"SELECT linha,distrito,chave FROM {table} WHERE linha=?",(line,)).fetchone())
      for table,line in[("familias",238422),("pessoas",238423)]]
    pe_card=pe["cartao127"]["linha"];pe_people={p["linha"]for p in pe["pessoas127"]}
    if pe_card!=238422 or pe_people!={238423,239457,239458,239459,239460,239461}:raise ValueError("EscopoPE inesperado")
    if pe["distrito_original"]!="X7"or pe["distrito_operacional"]!="07":raise ValueError("DistritoPE inesperado")

    def prepare(row,kind):
        r=dict(row);n=r["linha"];original=r["original"];text=r["corrigido"]
        correction=corrections.get(n,{})
        if correction and correction["texto_original"]!=original:raise ValueError("Correcao diverge do indice")
        if text!=(correction.get("texto_corrigido")or original):raise ValueError("Texto corrigido desatualizado no indice")
        values,cancelled=parse_r(text,guides[kind])
        uf=values["UF"]
        if uf=="03"and values["V116"]=="0011":uf="00"
        district=text[6:8]
        if n in[238422,238423]:
            declared=pe["cartao127"]if n==238422 else next(p for p in pe["pessoas127"]if p["linha"]==n)
            if original!=declared["original"]or text!=declared["corrigido"]or district!="X7":raise ValueError("LiteralPE diverge")
            district="07"
        diagnosis=correction.get("decisao","sem_problema")
        damage=bool(cancelled)or diagnosis in{"corrompida","dano_salto_nao_resolvido"}
        return {"linha":n,"UF":uf,"distrito_original":text[6:8],"distrito_operacional":district,
          "pasta":text[8:13],"boletim":text[13:16],"original":original,"corrigido":text,
          "valores":values,"anuladas":cancelled,"diagnostico":diagnosis,"fora_da_comparacao":damage}

    def members(f):
        # Indice incorpora exclusoes e CSV. Consultar tambem a chave operacional
        # detecta integrantes que uma derivacao local poderia acrescentar.
        found={int(r["linha"]):dict(r)for r in con.execute(
          "SELECT * FROM pessoas WHERE familia_atual=? AND excluida=0 ORDER BY linha",(f["linha"],))}
        key=f["distrito_operacional"]+f["pasta"]+f["boletim"]
        for r in con.execute("SELECT * FROM pessoas WHERE uf=? AND chave=? AND excluida=0",(int(f["UF"]),key)):
            r=dict(r);override=links.get(r["linha"])
            destination=int(override["linha_familia"])if override else f["linha"]
            if destination==f["linha"]:found[r["linha"]]=r
        result=[]
        for n,p in sorted(found.items()):
            if duplicates.get(n,{}).get("acao")=="remover":raise ValueError("Indice nao aplicou exclusao")
            if n in links and int(links[n]["linha_familia"])!=f["linha"]:raise ValueError("Vinculo conflitante no indice")
            if p["familia_atual"]!=f["linha"]:raise ValueError("Derivacao encontrou membro nao incorporado no indice; revisar explicitamente")
            result.append(prepare(p,"pessoas"))
        return result

    recovered=[];seen_people=set()
    for card in manifest["cartoes"]:
        personal=[]
        declared={p["linha"]:p for p in card["pessoas"]}
        actual=list(con.execute("SELECT * FROM pessoas WHERE uf=? AND pasta=? AND boletim=? AND excluida=0 ORDER BY linha",
          (int(card["UF"]),int(card["pasta"]),int(card["boletim"]))))
        if set(declared)!={r["linha"]for r in actual}or len(actual)!=card["n_pessoas"]:raise ValueError("Composicao recuperada divergente")
        for p in actual:
            n=p["linha"];d=declared[n]
            if n in seen_people or p["familia_atual"]is not None or duplicates.get(n,{}).get("acao")=="remover":raise ValueError("Pessoa recuperada sobreposta/excluida")
            if(p["original"],p["corrigido"])!=(d["texto_original"],d["texto_corrigido"]):raise ValueError("Literal recuperado diverge")
            seen_people.add(n);prepared=prepare(p,"pessoas")
            if prepared["fora_da_comparacao"]:raise ValueError("Recuperado contem dano excluido pela guardaR")
            personal.append(prepared)
        values=card["familias"]
        for field in FNAMES:
            if field not in values or (values[field]is not None and not isinstance(values[field],str)):raise ValueError("Campo recuperado fora do formatoR")
        family=[values[n]for n in FNAMES]
        sig=signature(card["UF"],card["distrito"],family,[[p["valores"][n]for n in PNAMES]for p in personal])
        recovered.append({"id":card["id_recuperacao"],"UF":card["UF"],"distrito":card["distrito"],
          "pasta":card["pasta"],"boletim":card["boletim"],"familias":values,"pessoas":personal,
          "fonte_cartao":{"arquivo":card["arquivo_25"],"linha":card["linha_25"],"texto":card["texto_25"]},"signature":sig})
    wanted={r["signature"][:3]for r in recovered}
    real_candidates=[];n_real=0;n_eligible=0;n_cancelled=0;pe_broad=[];pe_record=None
    pe_values,_=parse_r(pe["cartao127"]["corrigido"],guides["familias"])
    pe_body=tuple(pe_values[n]for n in FNAMES)
    for row in con.execute("SELECT * FROM familias ORDER BY linha"):
        n_real+=1;f=prepare(row,"familias");body=tuple(f["valores"][n]for n in FNAMES)
        if f["fora_da_comparacao"]:n_cancelled+=1
        else:n_eligible+=1
        base=(f["UF"],f["distrito_operacional"],body)
        if f["UF"]=="21"and body==pe_body:pe_broad.append(f["linha"])
        if base not in wanted and f["linha"]!=pe_card:continue
        people=members(f)
        damage=f["fora_da_comparacao"]or any(p["fora_da_comparacao"]for p in people)
        sig=signature(f["UF"],f["distrito_operacional"],body,[[p["valores"][n]for n in PNAMES]for p in people])
        record={"cartao":f,"pessoas":people,"excluido_por_dano":damage,"signature":sig}
        if f["linha"]==pe_card:pe_record=record
        if base in wanted:real_candidates.append(record)
    if pe_record is None or {p["linha"]for p in pe_record["pessoas"]}!=pe_people:raise ValueError("GrupoPE incompleto")
    matches=[]
    for recovered_card in recovered:
        for real in real_candidates:
            if not real["excluido_por_dano"]and recovered_card["signature"]==real["signature"]:
                matches.append({"recuperado":recovered_card["id"],"cartao_real":real["cartao"]["linha"],
                  "pessoas_recuperadas":[p["linha"]for p in recovered_card["pessoas"]],"pessoas_reais":[p["linha"]for p in real["pessoas"]]})
    between=[]
    for i,a in enumerate(recovered):
        for b in recovered[i+1:]:
            if a["signature"]==b["signature"]:between.append([a["id"],b["id"]])
    pe_recovered=[r["id"]for r in recovered if r["signature"]==pe_record["signature"]]
    assert pe_broad==[238422],"Ha outro cartao com15camposPE; examinar composicao antes de concluir"
    def portable(record):return{k:v for k,v in record.items()if k!="signature"}
    summary={"cartoes_reais_lidos":n_real,"cartoes_reais_sem_campos_anulados_nem_diagnostico_excluido":n_eligible,
      "cartoes_reais_com_dano_excluidos":n_cancelled,"cartoes_recuperados":len(recovered),"pessoas_recuperadas":len(seen_people),
      "reais_com_territorio_e15campos_de_algum_recuperado":len(real_candidates),
      "coincidencias_recuperado_real":len(matches),"coincidencias_entre_recuperados":len(between),
      "PE_cartoes_reais_mesmos15campos_ignorando_distrito":pe_broad,"PE_coincidencias_com_recuperados":pe_recovered,
      "testes_internos":tests(),"novas_decisoes":0}
    changed=[p for p,h in hashes.items()if sha(ROOT/p)!=h]
    if changed or sha(index)!=index_hash:raise ValueError("Entradas alteradas durante conferencia: "+str(changed))
    result={"resumo":summary,"coincidencias_recuperado_real":matches,"coincidencias_entre_recuperados":between,
      "recuperados":[portable(r)for r in recovered],"candidatos_reais":[portable(r)for r in real_candidates],
      "PE":portable(pe_record),"indice":{"arquivo":index.relative_to(ROOT).as_posix(),"sha256":index_hash,
        "PE_no_indice":pe_index_rows,"derivacao_PE_aplicada_somente_em_memoria":True},
      "criterio":"Mesma UF e distrito operacional,15campos familiares textuais e multiconjunto25campos pessoais com multiplicidade; NA nao confunde dano porque grupo danificado e excluido.",
      "limites":["Nao executa R e nao declara que build completo chegaria a guarda: orfaos e outros bloqueios permanecem.",
        "Indice omite3registros corrompidos sem grupo e nao possui cartoes recuperados nem distritoPEderivado; estes41cartoes e2distritos sao acrescentados SOMENTE em memoria.",
        "Vinculos e exclusoes usam os manifestos atuais e o indice cujo hash/origem foi validado; nao se anexa pessoa por vizinhanca.",
        "A equivalencia verificada e da assinatura de coincidencia e do subconjunto41cartoes/PE; nao e equivalencia geral indice-pipeline.",
        "Nenhuma coincidencia autoriza exclusao ou fusao; resultado diferente de zero exige revisao localizada."],
      "fontes_sha256":hashes}
    (out/"conferencia.json").write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps(summary,ensure_ascii=False),flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser();parser.add_argument("--index",default=DEFAULT_INDEX);parser.add_argument("--out",required=True)
    args=parser.parse_args();index=(ROOT/args.index).resolve();out=(ROOT/args.out).resolve()
    if not index.is_relative_to(ROOT)or not out.is_relative_to(ROOT/"tmp"):raise ValueError("Caminhos fora do escopo")
    audit(index,out)
