# -*- coding: utf-8 -*-
"""Gera os dois dicionários de variáveis de 1960 que o censobr publica no release
`censo_docs`, a partir dos dois publicados até aqui.

Os antigos são HTML exportado do Excel ("Publish as Web Page"), e este script os
usa como molde: o cabeçalho, o CSS, a largura das colunas e o rodapé saem
intactos do arquivo original, e só as linhas da tabela são refeitas, com as
mesmas classes de estilo. O resultado é o mesmo documento, atualizado.

O que muda em relação ao dicionário antigo está listado em
`microdata_1960_compilacao.md`. Em resumo: as variáveis que a compilação nova
não tem saem, as novas entram, os nomes que mudaram são trocados, três erros de
código são corrigidos e as seis listas longas que o arquivo antigo remetia a
abas de Excel inexistentes ("Ver aba V221") passam a vir impressas, do
`read_guides/1960_codigo_do_censo.csv`.

Roda da raiz do projeto:  python references/gera_dicionario_1960.py
"""

import csv
import io
import os
import re

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOLDE = os.path.join(RAIZ, "references", "censo_docs", "molde")
SAIDA = os.path.join(RAIZ, "references", "censo_docs")
CODIGO = os.path.join(RAIZ, "read_guides", "1960_codigo_do_censo.csv")

VALOR = [("Valor", "")]
# a convencao de tipos do projeto tem tres tipos -- string, float64 e int32 --, e
# as colunas logicas saem nela como 1 e 0, nao como TRUE e FALSE
SIM = ("1", "Sim")
NAO = ("0", "Não")
TEXTO = [("Texto", "")]
FALTA_127 = ("", "Informação faltante - Amostra de 1,27%")
NA_NO_25 = ("", "Não se aplica - Registro advindo da amostra de 25%")
NA_NO_127 = ("", "Não se aplica - Registro advindo da amostra de 1,27%")
NAO_APLICA_DOM = ("", "Não Aplicável (Domicílios Coletivos, Improvisados ou Boletins Individuais) ou "
                      "Informação Faltante (Registro Corrompido)")
SEM_AIMORES = ("", "Não aplicável - a Serra dos Aimorés era a região em litígio entre Minas Gerais e o "
                   "Espírito Santo, recenseada como unidade à parte, e não tem correspondente de hoje")


def codigo_do_censo(variavel):
    """as listas longas do Código do Censo, que o dicionário antigo não trazia"""
    out = []
    with io.open(CODIGO, encoding="utf-8-sig") as fh:
        for r in csv.DictReader(fh):
            if r["variavel"] == variavel:
                out.append((r["codigo"], r["rotulo"]))
    return out


# ------------------------------------------------------------------------------
# As variáveis do questionário, com os códigos do dicionário antigo. Três
# correções, todas conferidas no Código do Censo: V215 dava o mesmo rótulo aos
# códigos 7 e 8 e descrevia o 6 pela metade; "Peças Servindo Domitório",
# "Cananalização" e "Total de Comodos" eram erros de digitação.
# ------------------------------------------------------------------------------
V101 = ("Espécie do Domicílio", [
    ("1", "Domicílio Particular Único"),
    ("2", "Domicílio Particular 1ª Família"),
    ("3", "Domicílio Coletivo"),
    ("4", "Domicílio Particular 2ª Família"),
    ("5", "Domicílio Particular 3ª Família"),
    ("9", "Boletim Individual")])

V102 = ("Tipo do Domicílio", [
    ("4", "Durável"), ("5", "Rústico"), ("6", "Improvisado"), ("7", "Ignorado"), NAO_APLICA_DOM])

V103 = ("Condição de Ocupação", [
    ("7", "Próprio"), ("8", "Alugado"), ("9", "Outra"), ("0", "Ignorado"), NAO_APLICA_DOM])

V104 = ("Aluguel Mensal, em cruzeiros de 1960", [
    ("0", "Até Cr$ 500"), ("1", "de Cr$ 500 a 1.000"), ("2", "de Cr$ 1.001 a 2.000"),
    ("3", "de Cr$ 2.001 a 4.000"), ("4", "de Cr$ 4.001 a 6.000"), ("5", "de Cr$ 6.001 a 10.000"),
    ("6", "de Cr$ 10.001 a 20.000"), ("7", "de Cr$ 20.001 e Mais"), ("8", "não Paga Aluguel"),
    ("9", "Ignorado"), NAO_APLICA_DOM])

V105 = ("Abastecimento de Água", [
    ("9", "Rede Geral com Canalização Interna"), ("0", "Rede Geral com Canalização Externa"),
    ("1", "Poço/Nascente com canalização"), ("2", "Poço/Nascente sem canalização"),
    ("3", "Outra forma de abastecimento"), ("4", "Ignorado"), NAO_APLICA_DOM])

V106 = ("Instalação Sanitária", [
    ("4", "Rede de Esgoto"), ("5", "Fossa Asséptica"), ("6", "Fossa Rudimentar"),
    ("7", "Outro Escoadouro"), ("8", "não Tem"), ("9", "Ignorado"), NAO_APLICA_DOM])

V107 = ("Fogão", [
    ("9", "Lenha"), ("0", "Carvão"), ("1", "Elétrico"), ("2", "Gás"), ("3", "Óleo/Querosene"),
    ("4", "não Tem"), ("5", "Ignorado"), NAO_APLICA_DOM])

V108 = ("Iluminação Elétrica", [("5", "Tem"), ("6", "não Tem"), ("7", "Ignorado"), NAO_APLICA_DOM])
V109 = ("Rádio", [("7", "Tem"), ("8", "não Tem"), ("9", "Ignorado"), NAO_APLICA_DOM])
V110 = ("Geladeira", [("9", "Tem"), ("0", "não Tem"), ("1", "Ignorado"), NAO_APLICA_DOM])
V111 = ("Televisão", [("1", "Tem"), ("2", "não Tem"), ("3", "Ignorado"), NAO_APLICA_DOM])

V112 = ("Total de Cômodos", [
    ("Valor", ""),
    ("0", "Não havendo indicação do número total de cômodos (código do próprio questionário, "
          "Código do Censo, p. 25)"),
    NAO_APLICA_DOM])

V113 = ("Peças Servindo de Dormitório", [
    ("Valor", ""),
    ("0", "Não havendo indicação do número de peças servindo de dormitório (código do próprio "
          "questionário, Código do Censo, p. 25)"),
    NAO_APLICA_DOM])

UF_1960 = ("Unidade da Federação, no código do próprio Censo de 1960", [
    ("0", "Rondônia"), ("1", "Acre"), ("2", "Amazonas"), ("3", "Roraima"), ("4", "Pará"),
    ("6", "Amapá"), ("10", "Maranhão"), ("12", "Piauí"), ("14", "Ceará"),
    ("17", "Rio Grande do Norte"), ("19", "Paraíba"), ("21", "Pernambuco"),
    ("24", "Fernando de Noronha"), ("25", "Alagoas"), ("30", "Sergipe"), ("31", "Bahia"),
    ("40", "Minas Gerais"), ("50", "Serra dos Aimorés"), ("51", "Espírito Santo"),
    ("52", "Rio de Janeiro"), ("54", "Guanabara"), ("60", "São Paulo"), ("71", "Paraná"),
    ("74", "Santa Catarina"), ("81", "Rio Grande do Sul"), ("91", "Mato Grosso"),
    ("94", "Goiás"), ("97", "Distrito Federal")])

V118 = ("Situação de moradia, no código do questionário", [
    ("1", "Urbana"), ("3", "Suburbana"), ("5", "Rural")])

# pessoas
V202 = ("Sexo e condição de presença", [
    ("1", "Homem Presente"), ("2", "Mulher Presente"), ("3", "Homem Ausente"),
    ("4", "Mulher Ausente"), ("5", "Homem não Morador"), ("6", "Mulher não Morador")])

V203 = ("Relação Com Chefe", [
    ("7", "Chefe"), ("8", "Cônjuge"), ("9", "Filho Ou Enteado"), ("0", "Neto"),
    ("1", "Pais e Sogros"), ("2", "Outros Parentes"), ("3", "Agregado"),
    ("4", "Hóspede, pensionista ou Empregado Doméstico"), ("5", "Ignorado"),
    ("6", "Boletim Individual")])

V204 = ("Tipo de Idade - Meses Ou Anos", [
    ("0", "Meses"), ("1", "Anos"),
    ("5", "Idade acima de 99 anos (os valores da V204B indicam os dois últimos caracteres da idade)"),
    ("9", "Ignorado (a variável V204B indica necessariamente 999)")])

V204B = ("Idade Meses/Anos", [
    ("Valor", "Idade Em Meses (0-11), Se V204 = 0"),
    ("", "Idade Em Anos (1-99), Se V204 = 1"),
    ("", "Últimos Dois Dígitos da Idade Em Anos, Para Pessoas Com Mais de 99 Anos, Se V204 = 5"),])

V205 = ("Religião", [
    ("5", "Católica Romana"), ("6", "Protestante"), ("7", "Espírita"), ("8", "Budista"),
    ("9", "Israelita"), ("0", "Ortodoxa"), ("1", "Maometana"), ("2", "Outra Religião"),
    ("3", "Sem Religião"), ("4", "Ignorado")])

V206 = ("Cor", [
    ("4", "Branca"), ("5", "Preta"), ("6", "Amarela"), ("7", "Parda"), ("8", "Índia"),
    ("9", "Ignorado")])

V208 = ("Nacionalidade", [
    ("9", "Brasileiro Nato"), ("0", "Brasil Naturalizado"), ("1", "Estrangeiro")])

V209 = ("Procedência: Urbana Ou Rural (Para pessoas não naturais do município onde habitam)", [
    ("0", "Zona Rural de Outro Município"), ("1", "Zona Urbana de Outro Município"),
    ("2", "Procedência Desconhecida - para pessoas nascidas na UF onde residem ou marcados como "
          "não morador presente"),
    ("3", "Procedência Desconhecida - para pessoas não naturais da UF onde residem")])

V299 = ("Tempo de Imigração", [
    ("2", "Menos de 1 Ano"), ("3", "1 Ano"), ("4", "2 Anos"), ("5", "3 Anos"), ("6", "4 Anos"),
    ("7", "5 Anos"), ("8", "6 a 10 Anos"), ("9", "11 Anos e Mais"),
    ("1", "Sem declaração de tempo (naturalidade codificada como 01 ou 31)"),
    ("0", "Não se aplica - natural da Unidade da Federação onde reside (naturalidade codificada "
          "como 20). É o caso de 10.447.845 registros")])

V211 = ("Alfabetização", [
    ("0", "Lê e Frequenta Escola"), ("1", "Lê e não Frequenta Escola"),
    ("2", "não Lê e Frequenta Escola"), ("3", "não Lê e não Frequenta Escola"), ("4", "Ignorada"),
    ("", "Não aplicável (4 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])

V212 = ("Última Série Concluída", [
    ("4", "Primeira Série"), ("5", "Segunda Série"), ("6", "Terceira Série"), ("7", "Quarta Série"),
    ("8", "Quinta Série"), ("9", "Sexta Série"),
    ("0", "Está cursando o Primeiro ano do Elementar (não possui série concluída)"),
    ("1", "Nunca Frequentou Escola"), ("2", "Ignorado"),
    ("", "Não aplicável (4 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])

V213 = ("Grau do Curso", [
    ("2", "Elementar (Primário)"), ("3", "Médio Primeiro Ciclo (Ginasial)"),
    ("4", "Médio Segundo Ciclo (Secundário, Científico etc.)"), ("5", "Superior"),
    ("6", "Ignorado"), ("1", "Nunca Frequentou Escola"),
    ("0", "Está cursando o Primeiro ano do Elementar (não possui série concluída)"),
    ("", "Não aplicável (4 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])

V215 = ("Estado Conjugal", [
    ("6", "Casamento Civil e Religioso"), ("7", "Somente Casamento Civil"),
    ("8", "Somente Casamento Religioso"), ("9", "Vivendo Maritalmente"), ("0", "Solteiro"),
    ("1", "Separado"), ("2", "Desquitado"), ("3", "Divorciado"), ("4", "Viúvo"), ("5", "Ignorado"),
    ("", "Não aplicável (9 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])

V217 = ("Filhos Tidos", [
    ("Valor", ""),
    ("", "Não aplicável (9 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])
V218 = ("Filhos Vivos", [
    ("Valor", ""),
    ("", "Não aplicável (9 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])

V219 = ("Rendimentos mensais, em cruzeiros de 1960", [
    ("5", "Até Cr$ 2.100"), ("6", "de Cr$ 2.101 a 3.300"), ("7", "de Cr$ 3.301 a 4.500"),
    ("8", "de Cr$ 4.501 a 6.000"), ("9", "de Cr$ 6.001 a 10.000"), ("0", "de Cr$ 10.001 a 20.000"),
    ("1", "de Cr$ 20.001 a 50.000"), ("2", "de Cr$ 50.001 e Mais"), ("3", "não Tem"), ("4", "Ignorado"),
    ("", "Não aplicável (9 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])

V220 = ("Atividade não Econômica", [
    ("4", "Afazeres Domésticos"), ("5", "Estudante"), ("6", "Aposentado"), ("7", "Vive de Rendas"),
    ("8", "Doença Temporária"), ("9", "Invalidez Permanente"), ("0", "Detento"),
    ("1", "Sem Ocupação"), ("2", "Ignorado"), ("3", "Prejudicado (Economicamente ativos)"),
    ("", "Não aplicável (9 anos de idade ou menos) ou Informação Faltante (Registro Corrompido)")])

V223 = ("Ocupação Na Última Semana", [
    ("2", "Mesma Ocupação Declarada na V221"), ("3", "Outra Ocupação"), ("4", "Desempregado"),
    ("5", "Ignorado"),
    ("", "Não aplicável (9 anos de idade ou menos e/ou não trabalhou no ano anterior à data do "
         "Censo) ou Informação Faltante (Registro Corrompido)")])

V224 = ("Posição Na Ocupação", [
    ("0", "Membro da Família"), ("1", "Ignorado"), ("5", "Empregado Público"),
    ("6", "Empregado Particular"), ("7", "Trabalha Por Conta-própria"), ("8", "Parceiro Ou Meeiro"),
    ("9", "Empregador"),
    ("", "Não aplicável (9 anos de idade ou menos e/ou não trabalhou no ano anterior à data do "
         "Censo) ou Informação Faltante (Registro Corrompido)")])


# ------------------------------------------------------------------------------
# As colunas que o censobr acrescenta
# ------------------------------------------------------------------------------
GEO = [
    ("code_region", "Código da Região de hoje", VALOR + [SEM_AIMORES]),
    ("name_region", "Nome da Região de hoje", TEXTO + [SEM_AIMORES]),
    ("code_state", "Código da Unidade da Federação de hoje. A Guanabara entra como Rio de Janeiro (33) "
                   "e Fernando de Noronha como Pernambuco (26), porque é esse o território delas hoje",
     VALOR + [SEM_AIMORES]),
    ("abbrev_state", "Sigla da Unidade da Federação de hoje", TEXTO + [SEM_AIMORES]),
    ("name_state", "Nome da Unidade da Federação de hoje", TEXTO + [SEM_AIMORES]),
    ("code_muni", "Código do Município no padrão de hoje, de sete dígitos, o mesmo de 1991 a 2022. "
                  "Pelo crosswalk de read_guides/1960_municipios.csv", VALOR + [SEM_AIMORES]),
    ("situacao", "Situação do domicílio, agregando o quadro urbano e o suburbano",
     [("urbana", "Quadro urbano ou suburbano (V118 = 1 ou 3)"), ("rural", "Quadro rural (V118 = 5)")]),
    ("code_muni_1960", "Código do Município na Divisão Territorial Brasileira de 1960", VALOR),
    ("name_muni_1960", "Nome do Município em 1960", TEXTO),
    ("code_district_1960", "Código do Distrito no Código de Zonas Fisiográficas, Municípios e "
                           "Distritos de 1960", VALOR),
    ("name_district_1960", "Nome do Distrito em 1960", TEXTO +
     [("", "Nome não transcrito: restam 17 pares município-distrito, 3.843 domicílios, cujo código "
           "o Código de 1960 não traz impresso na relação do município")]),
    ("code_bairro_1960", "Código do Bairro no Código de Zonas Fisiográficas, Municípios e Distritos "
                         "de 1960, de 5410 a 5591. É a Circunscrição Censitária em que o Tomo XII do "
                         "Volume I publica a Guanabara: 9 zonas e 83 circunscrições", VALOR +
     [("", "Não aplicável - as demais unidades da federação")]),
    ("name_bairro_1960", "Bairro. Só na Guanabara, onde o censo codificou a cidade por bairro em vez "
                         "de por distrito", TEXTO +
     [("", "Não aplicável - as demais unidades da federação")]),
    ("name_region_1960", "Região em que os volumes do Censo de 1960 publicam os resultados",
     [("Norte", ""), ("Nordeste", ""), ("Leste", ""), ("Sul", ""), ("Centro-Oeste", "")]),
    ("code_state_1960", "Código da Unidade da Federação no padrão do IBGE em 1960: a Guanabara é 34 e "
                        "Fernando de Noronha é 20", VALOR + [SEM_AIMORES]),
    ("abbrev_state_1960", "Sigla da Unidade da Federação em 1960", TEXTO + [SEM_AIMORES]),
    ("name_state_1960", "Nome da Unidade da Federação em 1960, como a Série Nacional o publica", TEXTO),
]

AMOSTRA = ("censobr_amostra", "De qual das duas amostras do Censo de 1960 o registro vem. A de 1,27% "
                              "cobre as onze unidades da federação em que os microdados da de 25% não "
                              "sobreviveram; nas outras dezessete ela é subamostra daquela, e por isso "
                              "não entra", [
    ("25%", "Registro advindo da amostra de 25%, o Boletim de Amostra de um domicílio em cada quatro"),
    ("1,27%", "Registro advindo da amostra de 1,27%, a subamostra de uma pasta em vinte sorteada em 1965")])

TIPO_UNIDADE = ("censobr_tipo_unidade", "Espécie da unidade recenseada, derivada de V101", [
    ("domicilio particular", "V101 = 1, 2, 4 ou 5"),
    ("domicilio coletivo", "V101 = 3"),
    ("boletim individual", "V101 = 9. Morador de domicílio coletivo recenseado pessoa a pessoa pela "
                           "Lista CD 3, com as variáveis do domicílio em branco por construção. "
                           "Não ocorre na amostra de 1,27%")])

CHAVE = [
    ("v001", "Pasta. O lote de trabalho de cerca de 250 Boletins de Amostra, numerado num cadastro "
             "nacional, e a unidade sorteada na amostra de 1,27%", VALOR),
    ("v002", "Boletim de Amostra dentro da pasta", VALOR),
    ("v003", "Identificação: tipo de registro e numeração das pessoas dentro do domicílio",
     VALOR + [FALTA_127]),
    ("v004", "Dígito verificador", VALOR + [FALTA_127]),
]

CONTAGENS = [
    ("censobr_n_listadas", "Número de pessoas listadas no Boletim de Amostra", VALOR),
    ("censobr_n_residentes", "Número de moradores residentes do domicílio (exclusive não moradores "
                             "presentes)", VALOR),
    ("censobr_n_presentes", "Número de pessoas presentes no domicílio (exclusive moradores ausentes)",
     VALOR),
    ("censobr_n_familias", "Número de famílias no domicílio (no máximo 3 - o IBGE classifica "
                           "domicílios com 4 famílias ou mais como Coletivos)", VALOR),
]

DESENHO = [
    ("censobr_estrato", "Estrato do desenho amostral. Na amostra de 25% é a pasta cruzada com a "
                        "situação (18.400 estratos); na de 1,27% é a unidade da federação cruzada "
                        "com o grupo de situação da pasta (21 estratos), recalculada para as onze "
                        "unidades que entram na compilação", TEXTO),
    ("censobr_upa", "Unidade Primária de Amostragem. Na amostra de 25% é o domicílio, que é o que se "
                    "sorteia; na de 1,27% é a pasta", VALOR),
    ("censobr_fpc", "Correção de população finita da primeira etapa",
     [("0.25", "Amostra de 25%: um domicílio em quatro"),
      ("0.05", "Amostra de 1,27%: uma pasta em vinte")]),
    ("censobr_usa", "Unidade Secundária de Amostragem: o domicílio", VALOR),
    ("censobr_fpc2", "Correção de população finita da segunda etapa",
     [("1", "Amostra de 25%: não há segunda etapa, e ela não contribui para a variância"),
      ("0.25", "Amostra de 1,27%: um domicílio em quatro dentro da pasta")]),
    ("censobr_weight", "Peso final da pessoa para expansão. Calibrado aos resultados definitivos da "
                       "Série Nacional, vol. I, por unidade da federação, pelo raking de "
                       "Deville-Särndal com distância logit. Na amostra de 25% as margens são "
                       "município × situação da Sinopse Preliminar, sexo × faixa etária e "
                       "alfabetização; na de 1,27%, sexo × faixa etária, situação e alfabetização", VALOR),
    ("censobr_weight_fator", "Razão entre o peso final e o peso de desenho. Mede o quanto a "
                             "calibração deslocou cada registro", VALOR),
    ("censobr_weight_desenho", "Peso nominal do desenho, sem calibração",
     [("4", "Amostra de 25%: um domicílio em quatro"),
      ("78.740157480315", "Amostra de 1,27%: um domicílio em quatro, uma pasta em vinte")]),
    ("censobr_weight_nivel", "Nível em que ficou a âncora municipal da calibração",
     [("municipio x situacao", "A célula de situação do município foi usada como está"),
      ("municipio", "A célula de situação era instável e colapsou para o município inteiro"),
      NA_NO_127]),
    ("censobr_weight_ibge", "Peso inteiro do método que o IBGE descreve nos tomos da Série Regional: "
                            "razão a unidade da federação × situação, com peso inteiro sorteado para "
                            "fechar o total da Sinopse Preliminar. Serve para reproduzir os volumes "
                            "publicados, inclusive nos seus artefatos de arredondamento",
     [("3", ""), ("4", ""), ("5", ""), NA_NO_127]),
    ("censobr_weight_1965", "Peso calibrado aos quadros dos Resultados Preliminares de 1965",
     VALOR + [NA_NO_25]),
    ("censobr_weight_1965_fator", "Razão entre esse peso e o peso de desenho", VALOR + [NA_NO_25]),
]

def diag_comum(tabela):
  """as marcas de auditoria comuns as duas tabelas. censobr_diagnostico lista so
  as categorias que de fato ocorrem em cada uma: o dano de fita e da amostra de
  1,27%, e o que sobrevive na compilacao e o que veio das onze unidades dela."""
  diagnostico = [("sem_problema", "Registro íntegro"),
                 ("valor_isolado", "Um valor fora do dicionário, anulado e anotado em "
                                   "censobr_variaveis_anuladas")]
  if tabela == "households":
    diagnostico.append(("registro_perdido", "Família reconstruída a partir dos registros de pessoa, "
                                            "sem o registro de família correspondente"))
  return [
    ("censobr_favela", "Registro em favela. Só na Guanabara, onde o Código de Municípios e Distritos "
                       "dá código próprio às favelas", [SIM, NAO]),
    ("censobr_muni_corrigido", "Código de município corrigido na leitura: Alagoas vinha deslocada em "
                               "+200, Fernando de Noronha como 2701, o Distrito Federal como 9701 e a "
                               "Guanabara codificada por bairro", [SIM, NAO]),
    ("censobr_uf_corrigida", "Unidade da federação corrigida na leitura: 64 famílias de Porto Velho "
                             "estavam gravadas como Roraima", [SIM, NAO, NA_NO_25]),
    ("censobr_diagnostico", "Diagnóstico do dano de fita no registro. O arquivo da amostra de 25% não "
                            "sofreu dano: 948 MB sem um caractere fora de [0-9 ]",
     diagnostico + [NA_NO_25]),
    ("censobr_variaveis_anuladas", "Lista das variáveis cujo valor saiu do dicionário e foi anulado, "
                                   "separadas por espaço. Fica vazia, e não ausente, quando o registro "
                                   "não teve nenhuma variável anulada",
     TEXTO),
  ]


def secoes_domicilios():
    return [
        ("VARIÁVEIS GEOGRÁFICAS", None, GEO),
        ("VARIÁVEIS DE IDENTIFICAÇÃO DO REGISTRO", None, [
            ("censobr_idhousehold", "ID único do domicílio no Censo de 1960. Refeito na compilação: "
                                    "UF × 10.000.000 + sequência dentro da unidade da federação", VALOR),
            AMOSTRA, TIPO_UNIDADE] + CHAVE + [
            ("v100", "Total de pessoas declarado no registro de família", VALOR + [FALTA_127])]),
        ("CARACTERÍSTICAS DO DOMICÍLIO", None, [
            ("V101", V101[0], [c for c in V101[1] if c[0] not in ("4", "5")] +
             [("", "Os códigos 4 e 5 (2ª e 3ª famílias) não ocorrem nesta tabela: o domicílio leva o "
                   "código da família principal, e as famílias conviventes aparecem na tabela de "
                   "pessoas")]),
            ("V102", V102[0], V102[1]), ("V103", V103[0], V103[1]), ("V104", V104[0], V104[1]),
            ("V105", V105[0], V105[1]), ("V106", V106[0], V106[1]), ("V107", V107[0], V107[1]),
            ("V108", V108[0], V108[1]), ("V109", V109[0], V109[1]), ("V110", V110[0], V110[1]),
            ("V111", V111[0], V111[1]), ("V112", V112[0], V112[1]), ("V113", V113[0], V113[1])]),
        ("VARIÁVEIS GEOGRÁFICAS DO QUESTIONÁRIO", None, [
            ("UF", UF_1960[0], UF_1960[1]),
            ("V116", "Código do Município no padrão do Censo de 1960, como o arquivo o traz, sem as "
                     "correções aplicadas em code_muni_1960", VALOR),
            ("V117", "Distrito, no código do questionário", VALOR),
            ("V118", V118[0], V118[1])]),
        ("VARIÁVEIS DERIVADAS CALCULADAS A PARTIR DOS DADOS (ADICIONADAS PELO censobr)",
         "Características dos domicílios", CONTAGENS),
        ("VARIÁVEIS PARA IMPLEMENTAR O PLANO AMOSTRAL (ADICIONADAS PELO censobr)", None, DESENHO),
        ("VARIÁVEIS DE DIAGNÓSTICO E CONSISTÊNCIA (ADICIONADAS PELO censobr)", None, diag_comum("households") + [
            ("censobr_familia_origem", "Como a família foi reconstruída na leitura",
             [("registro", "A família tem o seu registro no arquivo"),
              ("registro_perdido", "A família foi reconstruída a partir dos registros de pessoa"),
              NA_NO_25]),
            ("censobr_convivente_isolada", "Família convivente cujo registro de família principal não "
                                           "está no arquivo", [SIM, NAO]),
            ("censobr_dois_chefes", "Domicílio com dois registros na posição de chefe",
             [SIM, NAO, NA_NO_25]),
            ("censobr_linha", "Número da linha do registro no arquivo de origem", VALOR)]),
    ]


def secoes_pessoas():
    return [
        ("VARIÁVEIS GEOGRÁFICAS", None, GEO),
        ("VARIÁVEIS DE IDENTIFICAÇÃO DO REGISTRO", None, [
            ("censobr_idperson", "ID único da pessoa no Censo de 1960. Refeito na compilação: "
                                 "UF × 10.000.000 + sequência dentro da unidade da federação", VALOR),
            ("censobr_idfamily", "ID único da família no Censo de 1960. O Boletim de Amostra era por "
                                 "família, não por domicílio", VALOR),
            ("censobr_idhousehold", "ID único do domicílio no Censo de 1960. É a chave para juntar "
                                    "esta tabela à de domicílios", VALOR),
            AMOSTRA, TIPO_UNIDADE] + CHAVE),
        ("CARACTERÍSTICAS DO DOMICÍLIO", None, [
            ("V101", V101[0], V101[1] +
             [("", "Nas famílias conviventes (códigos 4 e 5) a página do domicílio, V102 a V113, vem "
                   "em branco: o censo a perguntou uma vez só, no boletim da família principal")]),
            ("V102", V102[0], V102[1]), ("V103", V103[0], V103[1]), ("V104", V104[0], V104[1]),
            ("V105", V105[0], V105[1]), ("V106", V106[0], V106[1]), ("V107", V107[0], V107[1]),
            ("V108", V108[0], V108[1]), ("V109", V109[0], V109[1]), ("V110", V110[0], V110[1]),
            ("V111", V111[0], V111[1]), ("V112", V112[0], V112[1]), ("V113", V113[0], V113[1])]),
        ("VARIÁVEIS GEOGRÁFICAS DO QUESTIONÁRIO", None, [
            ("UF", UF_1960[0], UF_1960[1]),
            ("V116", "Código do Município no padrão do Censo de 1960, como o arquivo o traz, sem as "
                     "correções aplicadas em code_muni_1960", VALOR),
            ("V117", "Distrito, no código do questionário", VALOR),
            ("V118", V118[0], V118[1])]),
        ("VARIÁVEIS DE IDENTIFICAÇÃO BÁSICA", None, [
            ("V202", V202[0], V202[1]), ("V203", V203[0], V203[1]), ("V204", V204[0], V204[1]),
            ("V204B", V204B[0], V204B[1]), ("V205", V205[0], V205[1]), ("V206", V206[0], V206[1])]),
        ("MIGRAÇÃO", None, [
            ("V207", "Naturalidade: unidade da federação ou país de nascimento", codigo_do_censo("V207")),
            ("V208", V208[0], V208[1]), ("V209", V209[0], V209[1]), ("V299", V299[0], V299[1]),
            ("V210", "Lugar de residência anterior", codigo_do_censo("V210"))]),
        ("EDUCAÇÃO (APENAS PARA PESSOAS COM 5 ANOS OU MAIS)", None, [
            ("V211", V211[0], V211[1]), ("V212", V212[0], V212[1]), ("V213", V213[0], V213[1]),
            ("V214", "Curso completo", codigo_do_censo("V214") +
             [("", "Não aplicável (9 anos de idade ou menos)")])]),
        ("NUPCIALIDADE (APENAS PARA PESSOAS COM 10 ANOS OU MAIS)", None, [
            ("V215", V215[0], V215[1]),
            ("V216", "Ano do casamento", codigo_do_censo("V216") +
             [("", "Não aplicável (9 anos de idade ou menos)")])]),
        ("FECUNDIDADE (APENAS PARA PESSOAS COM 10 ANOS OU MAIS - INCLUSIVE HOMENS)", None, [
            ("V217", V217[0], V217[1]), ("V218", V218[0], V218[1])]),
        ("TRABALHO E RENDIMENTO", None, [
            ("V219", V219[0], V219[1]), ("V220", V220[0], V220[1]),
            ("V221", "Ocupação habitual", codigo_do_censo("V221") +
             [("", "Não aplicável (9 anos de idade ou menos e/ou não trabalhou no ano anterior "
                   "à data do Censo)")]),
            ("V223", V223[0], V223[1]),
            ("V223B", "Ramo e classe de atividade", codigo_do_censo("V223B") +
             [("", "Não aplicável (9 anos de idade ou menos e/ou não trabalhou no ano anterior "
                   "à data do Censo)")]),
            ("V224", V224[0], V224[1])]),
        ("VARIÁVEIS DERIVADAS CALCULADAS A PARTIR DOS DADOS (ADICIONADAS PELO censobr)",
         "Características dos domicílios", CONTAGENS),
        ("VARIÁVEIS PARA IMPLEMENTAR O PLANO AMOSTRAL (ADICIONADAS PELO censobr)", None, DESENHO),
        ("VARIÁVEIS DE DIAGNÓSTICO E CONSISTÊNCIA (ADICIONADAS PELO censobr)", None, diag_comum("population") + [
            ("censobr_tipo_registro", "Tipo do registro de pessoa no arquivo de origem",
             [("2", "Chefe"), ("3", "Demais pessoas"), NA_NO_25]),
            ("censobr_duplicata_mantida", "Linha repetida que foi mantida, com marca, por não se "
                                          "encaixar no mecanismo de cópia identificado",
             [SIM, NAO, NA_NO_25]),
            ("censobr_familia_origem", "Como a família foi reconstruída na leitura",
             [("registro", "A família tem o seu registro no arquivo"),
              ("registro_perdido", "A família foi reconstruída a partir dos registros de pessoa"),
              ("anexada_anterior", "Pessoa anexada à família anterior"), NA_NO_25]),
            ("censobr_v208_imputada", "Nacionalidade imputada deterministicamente a partir da "
                                      "naturalidade", [SIM, NAO, NA_NO_25]),
            ("censobr_v217_fora_da_faixa", "Filhos tidos fora da faixa do dicionário",
             [SIM, NAO, NA_NO_25]),
            ("censobr_v218_fora_da_faixa", "Filhos vivos fora da faixa do dicionário",
             [SIM, NAO, NA_NO_25]),
            ("censobr_flag_conjuge_mesmo_sexo", "Cônjuge do mesmo sexo do chefe. Marca de coerência, "
                                                "sem correção", [SIM, NAO, NA_NO_25]),
            ("censobr_flag_filho_mais_velho", "Filho mais velho incompatível com a idade do chefe. "
                                              "Marca de coerência, sem correção",
             [SIM, NAO, NA_NO_25]),
            ("censobr_flag_casamento_impossivel", "Ano de casamento incompatível com a idade. Marca "
                                                  "de coerência, sem correção",
             [SIM, NAO, NA_NO_25]),
            ("censobr_linha", "Número da linha do registro no arquivo de origem", VALOR)]),
    ]


# ------------------------------------------------------------------------------
# A emissão, nas classes do arquivo original
# ------------------------------------------------------------------------------
def esc(s):
    s = s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return s if s else "&nbsp;"


def gera(nome, secoes, cls_secao, cls_subsecao, largura_td, largura_pt, largura_rot,
         largura_rot_pt, largura_desc, largura_desc_pt):
    sfx = None
    fonte = os.path.join(MOLDE, "1960_dictionary_microdata_%s.html" % nome)
    t = io.open(fonte, encoding="windows-1252").read()
    sfx = re.search(r"class=xl\d\d(\d+)", t).group(1)

    linhas = []
    for titulo, subtitulo, variaveis in secoes:
        linhas.append(
            " <tr class=xl66{s} height=17 style='height:13.0pt'>\n"
            "  <td colspan=4 height=17 class={c}{s} width={w} style='border-right:.5pt solid black;"
            "height:13.0pt;width:{p}pt'>{t}</td>\n"
            " </tr>\n".format(s=sfx, c=cls_secao, w=largura_td, p=largura_pt, t=esc(titulo)))
        if subtitulo:
            linhas.append(
                " <tr class=xl66{s} height=17 style='height:13.0pt'>\n"
                "  <td colspan=4 height=17 class={c}{s} width={w} style='height:13.0pt;width:{p}pt'>"
                "{t}</td>\n"
                " </tr>\n".format(s=sfx, c=cls_subsecao, w=largura_td, p=largura_pt, t=esc(subtitulo)))
        for var, rotulo, codigos in variaveis:
            n = len(codigos)
            for i, (valor, desc) in enumerate(codigos):
                if i == 0 and n > 1:
                    linhas.append(
                        " <tr class=xl66{s} height=23 style='mso-height-source:userset;height:17.25pt'>\n"
                        "  <td rowspan={n} height={h} class=xl75{s} style='border-bottom:.5pt solid black;"
                        "height:{hp}pt;border-top:none'>{v}</td>\n"
                        "  <td rowspan={n} class=xl76{s} width={w} style='border-bottom:.5pt solid black;"
                        "border-top:none;width:{p}pt'>{r}</td>\n"
                        "  <td class=xl69{s} style='border-top:none;border-left:none'>{c}</td>\n"
                        "  <td class=xl70{s} width={wd} style='border-top:none;border-left:none;"
                        "width:{pd}pt'>{d}</td>\n"
                        " </tr>\n".format(s=sfx, n=n, h=23 * n, hp=round(17.25 * n, 2), v=esc(var),
                                          w=largura_rot, p=largura_rot_pt, r=esc(rotulo),
                                          c=esc(valor), d=esc(desc), wd=largura_desc, pd=largura_desc_pt))
                elif i == 0:
                    linhas.append(
                        " <tr class=xl66{s} height=23 style='mso-height-source:userset;height:17.25pt'>\n"
                        "  <td height=23 class=xl69{s} style='height:17.25pt;border-top:none'>{v}</td>\n"
                        "  <td class=xl71{s} width={w} style='border-top:none;border-left:none;"
                        "width:{p}pt'>{r}</td>\n"
                        "  <td class=xl69{s} style='border-top:none;border-left:none'>{c}</td>\n"
                        "  <td class=xl70{s} width={wd} style='border-top:none;border-left:none;"
                        "width:{pd}pt'>{d}</td>\n"
                        " </tr>\n".format(s=sfx, v=esc(var), w=largura_rot, p=largura_rot_pt,
                                          r=esc(rotulo), c=esc(valor), d=esc(desc), wd=largura_desc, pd=largura_desc_pt))
                else:
                    linhas.append(
                        " <tr class=xl66{s} height=23 style='mso-height-source:userset;height:17.25pt'>\n"
                        "  <td height=23 class=xl69{s} style='height:17.25pt;border-top:none;"
                        "border-left:none'>{c}</td>\n"
                        "  <td class=xl70{s} width={wd} style='border-top:none;border-left:none;"
                        "width:{pd}pt'>{d}</td>\n"
                        " </tr>\n".format(s=sfx, c=esc(valor), d=esc(desc), wd=largura_desc, pd=largura_desc_pt))

    # o molde fica intacto: troca-se só o trecho entre o primeiro cabecalho de
    # secao e a linha escondida que o Excel poe no fim
    corpo = t[t.index("<body"):]
    trs = re.findall(r" <tr\b.*?</tr>\n", corpo, re.S)
    primeiro = next(tr for tr in trs if "colspan=4" in tr and cls_secao + sfx in tr)
    escondida = trs[-1]
    ini = t.index(primeiro)
    fim = t.index(escondida)
    novo = t[:ini] + "".join(linhas) + t[fim:]

    dest = os.path.join(SAIDA, "1960_dictionary_microdata_%s.html" % nome)
    io.open(dest, "w", encoding="windows-1252", newline="\n").write(novo)
    nvar = sum(len(v) for _, _, v in secoes)
    ncod = sum(len(c) for _, _, v in secoes for _, _, c in v)
    print("%s: %d variaveis, %d linhas de codigo, %d bytes" % (nome, nvar, ncod, len(novo)))


def tabela_plana(nome, secoes):
    """o mesmo conteudo em forma tabular, que alimenta as duas abas da planilha"""
    linhas = []
    for titulo, subtitulo, variaveis in secoes:
        linhas.append(["secao", titulo, "", "", ""])
        if subtitulo:
            linhas.append(["subsecao", subtitulo, "", "", ""])
        for var, rotulo, codigos in variaveis:
            for i, (valor, desc) in enumerate(codigos):
                linhas.append(["codigo", var if i == 0 else "", rotulo if i == 0 else "", valor, desc])
    dest = os.path.join(SAIDA, "1960_dictionary_microdata_%s.csv" % nome)
    with io.open(dest, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["tipo_linha", "variavel", "rotulo", "codigo", "descricao"])
        w.writerows(linhas)
    print("%s: %d linhas para a planilha" % (nome, len(linhas)))


if __name__ == "__main__":
    os.makedirs(SAIDA, exist_ok=True)
    gera("households", secoes_domicilios(), "xl88", "xl91", 1062, 798, 422, 317, 371, 279)
    gera("population", secoes_pessoas(), "xl91", "xl94", 1033, 775, 413, 310, 341, 256)
    tabela_plana("households", secoes_domicilios())
    tabela_plana("population", secoes_pessoas())
