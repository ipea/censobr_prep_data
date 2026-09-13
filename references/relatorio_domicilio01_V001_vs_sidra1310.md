# `Domicilio01_V001` nos agregados por setor de 2010: o que a variável conta e por que excede a Tabela 1310 do SIDRA

**Data:** 2026-09-13 (substitui a versão de 2026-05-12)
**Escopo:** Censo Demográfico 2010, agregados por setor censitário, arquivo Domicilio01 — o que a `V001` conta, por que sua soma por município excede o total de domicílios publicado na Tabela 1310 do SIDRA, e onde isso se concentra. Não é defeito do pipeline nem do arquivo: é uma diferença de granularidade entre duas publicações do próprio IBGE.

---

## O que a `V001` conta

Dicionário oficial (IBGE 2011, seção 6.2):

| variável | descrição |
|---|---|
| `V001` | Domicílios particulares e domicílios coletivos |
| `V002` | Domicílios particulares permanentes |
| `V003` a `V241` | subcategorias de domicílios particulares permanentes |

`V001` é a única variável do arquivo que inclui domicílios coletivos. No
produto (`2010_tracts_DOMICILIO.parquet`, 310.120 setores, 5.565
municípios), `V001` soma 58.051.449 e `V002` 57.324.167 — a diferença,
727.282, é o que a `V001` conta além dos particulares permanentes.

Para domicílios coletivos, a unidade contada não é a instituição, é a
**unidade de habitação**. O manual *Base de informações do Censo
Demográfico 2010: Resultados do Universo por setor censitário —
Documentação do Arquivo* (IBGE, 2011) define, na seção 2.7.10:

> "A condição no domicílio foi caracterizada através da relação existente
> entre a pessoa responsável pela **unidade domiciliar (domicílio particular
> ou unidade de habitação em domicílio coletivo)** e cada um dos demais
> moradores…"

> "**Individual em domicílio coletivo** — para a pessoa só que residia em
> domicílio coletivo, ainda que **compartilhando a unidade de habitação** com
> outra(s) pessoa(s) com a(s) qual(is) não tinha laços de parentesco."

E na seção 2.5, sobre os instrumentos de coleta: "*Formulário de Domicílio
Coletivo — formulário utilizado para registrar os dados de identificação do
domicílio coletivo e listar as suas unidades com morador*". A seção 2.7.2
enumera o que é domicílio coletivo: hotéis, pensões, penitenciárias,
presídios, quartéis, asilos, conventos, hospitais com internação, alojamentos
de trabalhadores ou de estudantes. O termo "unidade de habitação" está só no
manual técnico (3 ocorrências); não aparece no glossário nem na página de
conceituação do Censo 2010 na web.

## O que o SIDRA conta

A Tabela 1310 ("Domicílios recenseados, por espécie e situação do
domicílio") conta cada instituição como um domicílio coletivo. Para o Brasil:

| SIDRA 1310 | Brasil | diferença para `V001` |
|---|---:|---:|
| Total (particular + coletivo) | 67.569.688 | −14,09% |
| Particular (todos) | 67.459.066 | −13,95% |
| Particular ocupado | 57.428.017 | +1,09% |
| Coletivo (todos) | 110.622 | |
| Coletivo com morador | 44.554 | |
| Particular ocupado + coletivo (todos) | 57.538.639 | +0,89% |
| **Particular ocupado + coletivo com morador** | **57.472.571** | **+578.878 (+1,007%)** |

A combinação semanticamente mais próxima da `V001` fica 578.878 abaixo dela.
Esse excedente é, em essência, o total de unidades de habitação em coletivos
institucionais no país, que o SIDRA conta como 44.554 instituições.

## Onde o excedente se concentra

Por UF, o excedente vai de +0,25% (MA, PI) a +2,28% (RO); São Paulo sozinho
responde por 35% dele.

| UF | `V001` | SIDRA (part. ocupado + col. com morador) | excedente | % |
|---|---:|---:|---:|---:|
| AC | 193.692 | 191.290 | 2.402 | +1,26% |
| AL | 851.101 | 847.657 | 3.444 | +0,41% |
| AM | 806.974 | 802.389 | 4.585 | +0,57% |
| AP | 158.453 | 157.118 | 1.335 | +0,85% |
| BA | 4.126.224 | 4.108.390 | 17.834 | +0,43% |
| CE | 2.380.173 | 2.371.156 | 9.017 | +0,38% |
| DF | 785.733 | 775.248 | 10.485 | +1,35% |
| ES | 1.113.408 | 1.104.150 | 9.258 | +0,84% |
| GO | 1.909.041 | 1.894.220 | 14.821 | +0,78% |
| MA | 1.661.659 | 1.657.479 | 4.180 | +0,25% |
| MG | 6.111.179 | 6.043.299 | 67.880 | +1,12% |
| MS | 775.003 | 764.683 | 10.320 | +1,35% |
| MT | 932.110 | 920.422 | 11.688 | +1,27% |
| PA | 1.877.876 | 1.867.908 | 9.968 | +0,53% |
| PB | 1.090.463 | 1.083.223 | 7.240 | +0,67% |
| PE | 2.574.137 | 2.552.411 | 21.726 | +0,85% |
| PI | 852.506 | 850.381 | 2.125 | +0,25% |
| PR | 3.340.516 | 3.307.364 | 33.152 | +1,00% |
| RJ | 5.299.014 | 5.250.703 | 48.311 | +0,92% |
| RN | 906.488 | 901.802 | 4.686 | +0,52% |
| RO | 468.316 | 457.866 | 10.450 | +2,28% |
| RR | 117.965 | 116.401 | 1.564 | +1,34% |
| RS | 3.653.000 | 3.606.964 | 46.036 | +1,28% |
| SC | 2.015.139 | 1.997.524 | 17.615 | +0,88% |
| SE | 595.769 | 593.467 | 2.302 | +0,39% |
| SP | 13.053.253 | 12.849.045 | 204.208 | +1,59% |
| TO | 402.257 | 400.011 | 2.246 | +0,56% |

Por município, 37,6% batem com o SIDRA dentro de 0,01% e 69,8% dentro de
0,5%; o excedente nacional vem da cauda:

| excedente (%) | municípios | % |
|---|---:|---:|
| até 0,01 | 2.093 | 37,6% |
| 0,01 a 0,5 | 1.790 | 32,2% |
| 0,5 a 2 | 1.395 | 25,1% |
| 2 a 5 | 199 | 3,6% |
| acima de 5 | 88 | 1,6% |

Os extremos são municípios pequenos que sediam unidades prisionais:

| município | UF | `V001` | SIDRA | excedente | % | setores |
|---|---|---:|---:|---:|---:|---:|
| Balbinos | SP | 2.807 | 477 | 2.330 | +488,5% | 6 |
| Pracinha | SP | 1.837 | 514 | 1.323 | +257,4% | 6 |
| Lavínia | SP | 5.420 | 1.772 | 3.648 | +205,9% | 20 |
| Álvaro de Carvalho | SP | 2.368 | 1.013 | 1.355 | +133,8% | 9 |
| Iaras | SP | 3.241 | 1.403 | 1.838 | +131,0% | 11 |
| Reginópolis | SP | 3.801 | 1.762 | 2.039 | +115,7% | 12 |
| São Pedro de Alcântara | SC | 2.414 | 1.143 | 1.271 | +111,2% | 12 |
| Serra Azul | SP | 4.989 | 2.590 | 2.399 | +92,6% | 16 |
| Marabá Paulista | SP | 2.417 | 1.265 | 1.152 | +91,1% | 10 |
| Guareí | SP | 6.535 | 3.697 | 2.838 | +76,8% | 23 |
| Itirapina | SP | 6.785 | 4.026 | 2.759 | +68,5% | 33 |
| Ilha de Itamaracá | PE | 9.081 | 5.471 | 3.610 | +66,0% | 63 |
| Pacaembu | SP | 5.988 | 3.655 | 2.333 | +63,8% | 26 |
| Irapuru | SP | 3.595 | 2.226 | 1.369 | +61,5% | 21 |
| Potim | SP | 7.262 | 4.660 | 2.602 | +55,8% | 22 |

## O setor da penitenciária

Balbinos (`code_muni` 3504701), nos seis setores do arquivo
`DOMICILIO01_SP2.xls` do IBGE — e, idênticos, no produto:

| setor | situação | `V001` | `V002` | `V003` |
|---|---|---:|---:|---:|
| 350470105000001 | urbano | 199 | 195 | 195 |
| 350470105000002 | urbano | 207 | 207 | 207 |
| 350470105000003 | rural | 59 | 59 | 59 |
| **350470105000004** | **rural** | **2.335** | **3** | X |
| 350470105000006 | urbano | 6 | 6 | 6 |
| 350470105000007 | urbano | 1 | 1 | X |

O 2.335 está no XLS do IBGE; `V003` (casas) é suprimido com `X` no setor 4
porque, com 3 domicílios particulares, o detalhe identificaria. Cruzando com
`Pessoa01_V001` (moradores) no mesmo setor, a razão moradores/`V001` é ≈ 1
nos setores de penitenciária e 2,3 a 3,5 nos residenciais:

| setor | `V001` | `V002` | moradores | moradores/`V001` |
|---|---:|---:|---:|---:|
| Balbinos, penitenciária | 2.335 | 3 | 2.249 | 0,96 |
| Balbinos, urbano | 207 | 207 | 500 | 2,42 |
| Iaras, penitenciária | 785 | 0 | 761 | 0,97 |
| Iaras, penitenciária | 768 | 4 | 762 | 0,99 |
| Iaras, residencial | 427 | 427 | 1.134 | 2,66 |
| Reginópolis, penitenciária | 2.021 | 4 | 2.007 | 0,99 |

Cada "domicílio" da `V001` nesses setores é uma cela com um morador. No
SIDRA, os mesmos municípios têm 4 (Balbinos), 4 (Pracinha), 5 (Reginópolis)
e 6 (Iaras) coletivos com morador.

## Consequências para o uso

- `V001` = domicílios particulares ocupados + unidades de habitação em
  domicílios coletivos com morador. Para domicílios particulares permanentes,
  `V002` não tem o problema.
- Setores com instituição coletiva se identificam por `V001 − V002` grande e
  `Pessoa01_V001 / V001 ≈ 1` ao mesmo tempo.
- Quem precisa reproduzir a Tabela 1310 usa a própria Tabela 1310; a soma da
  `V001` por município fica cerca de 1% acima, concentrada nos municípios com
  grandes instituições.

## Referências

- IBGE (2011). *Base de informações do Censo Demográfico 2010: Resultados do
  Universo por setor censitário — Documentação do Arquivo*. Rio de Janeiro.
  https://www.ipea.gov.br/redeipea/images/pdfs/base_de_informacoess_por_setor_censitario_universo_censo_2010.pdf
- SIDRA, Tabela 1310: https://sidra.ibge.gov.br/tabela/1310
- FTP do IBGE, agregados por setores censitários 2010:
  https://ftp.ibge.gov.br/Censos/Censo_Demografico_2010/Resultados_do_Universo/Agregados_por_Setores_Censitarios/
- Dicionário transcrito, seção 6.2:
  [`phgfsouza_census_tracts/transcripts/2010_dictionary_tracts.md`](phgfsouza_census_tracts/transcripts/2010_dictionary_tracts.md)
