# Carta ao IBGE — defeitos verificados nas distribuições dos Censos Demográficos

**Destinatário:** Instituto Brasileiro de Geografia e Estatística — Diretoria de Pesquisas / Coordenação de Censos e Centro de Documentação e Disseminação de Informações
**Remetentes:** equipe do pacote `censobr` — Rafael H. M. Pereira (Ipea) e Rogério J. Barbosa (IESP-UERJ)
**Data:** setembro de 2026
**Anexo:** `carta_ibge_anexo.md` — 70 itens, com arquivo afetado, evidência medida e data de verificação

---

Prezados,

O `censobr` é um pacote de R, de código aberto e mantido no Ipea, que
distribui os microdados das amostras e os agregados por setor censitário dos
Censos Demográficos de 1960 a 2022 em formato pronto para análise. Os dados
que ele publica são os que o IBGE disponibiliza no FTP
(`ftp.ibge.gov.br/Censos/`), lidos e padronizados por um pipeline público e
reprodutível.

Ao preparar a versão 0.7.0 do pacote, conferimos arquivo a arquivo as
distribuições vigentes no FTP — os microdados de 1970, 1980, 1991, 2000, 2010
e 2022 e os agregados por setor de 2000, 2010 e 2022 — contra a documentação
que as acompanha e contra as tabulações publicadas no SIDRA. Encontramos
defeitos de dado, de documentação e de empacotamento que persistem na
distribuição atual. O anexo os descreve um a um, com o arquivo afetado
(nome, tamanho, data e soma de verificação), a evidência numérica e a data
da última conferência (12 e 13 de setembro de 2026). Cada item foi
verificado por uma segunda pessoa com a instrução de tentar refutá-lo; os
que o IBGE já corrigiu, ou que se mostraram problemas nossos, não constam.

São 70 itens: 17 de gravidade alta, 22 média e 31 baixa. Os de gravidade
alta afetam diretamente o conteúdo que o usuário obtém:

1. **1970.** Dois dos 27 arquivos de microdados, `DAMO70AL.txt` e
   `Damo70PE.txt`, contêm 1.785 registros de comprimento diferente dos 76
   bytes do layout: blocos de 18 ou 60 caracteres mudaram de posição, e o
   peso amostral, que ocupa as duas últimas posições, deixa de ser lido —
   900 registros ficam sem peso e 650 recebem um peso errado. Existiu cópia
   íntegra desses arquivos: a versão dos mesmos microdados harmonizada pelo
   Centro de Estudos da Metrópole não tem o defeito. Pedimos a
   redisponibilização a partir dela ou de cópia anterior do próprio IBGE.
2. **1980 e 1991 — nomes das variáveis.** As republicações em DBF nomeiam as
   variáveis com mnemônicos de até oito caracteres, limite do formato dBASE
   (COMODOS, PESOD, MIUFANT, SANESCOA; UFNOM, ALUGUEFX, RFAPCAPV), e a
   documentação que as acompanha repete esses mesmos mnemônicos. O código no
   formato V####, com que essas mesmas variáveis são identificadas nas
   distribuições anteriores, nos dicionários de referência e na literatura,
   não aparece uma única vez nas duas planilhas — e não se distribui tabela
   de correspondência. Quem quiser usar a republicação junto com qualquer
   trabalho anterior tem de reconstruir essa correspondência sozinho,
   variável a variável, num exercício que não é mecânico.
3. **1980.** A republicação em DBF (janeiro de 2025) não contém o Território
   de Fernando de Noronha (UF 20) e perde quatro variáveis presentes na
   distribuição anterior — V518 (município ou UF de residência anterior),
   V3, V4 e V6 (mesorregião, microrregião e distrito). Além disso, a
   variável de total de cômodos está corrompida em 47 municípios de Goiás e a
   de tempo de residência em Curitiba.
4. **1991.** A republicação em DBF não traz o identificador do questionário
   (a chave que liga as pessoas ao seu domicílio, presente na distribuição
   anterior); o dicionário rotula o código 16 de MIUFPAIS como Sergipe quando
   é a Bahia; e os pesos não reproduzem a população publicada em 91
   municípios.
5. **2000.** `RN.zip` traz, além dos três arquivos do Rio Grande do Norte,
   uma cópia integral dos três arquivos da Paraíba, idêntica à de `PB.zip` —
   quem lê a pasta inteira conta os paraibanos duas vezes —, e `BA.zip` traz
   um zip dentro do zip; nada disso consta do log.
6. **Agregados por setor de 2010.** Os arquivos `Pessoa02` de São Paulo
   (capital e demais municípios) têm os nomes das 170 variáveis deslocados
   em 85 posições em relação ao dicionário — o que está sob `V086` é a `V001`
   —, e o defeito sobreviveu à republicação de 15 de junho de 2026.
7. **Agregados por setor de 2022.** A variável `V0006` do Básico (domicílios
   imputados sobre ocupados) é publicada como proporção 0–1 no definitivo e
   como percentual 0–100 no preliminar, sob o mesmo rótulo "Percentual"; e 11
   setores do definitivo têm mais domicílios imputados do que ocupados.
8. **Transversal.** Só três arquivos de log de atualização existem em toda a
   árvore `/Censos/`; 1970, 1980, 1991, os setores de 2000 e o Censo 2022
   inteiro não têm nenhum, de modo que republicações (como a de 2025 dos
   microdados de 1970–1991) não deixam registro do que mudou. E nenhum
   microdado do Censo de 1960 é distribuído.

Nosso pedido é triplo: a correção, ou a republicação a partir de cópias
íntegras, dos arquivos dos itens de gravidade alta; a publicação de uma tabela
de correspondência entre os nomes dos campos das republicações em DBF e os
códigos das distribuições anteriores das mesmas amostras; e a manutenção de um
log de atualização por edição, como o IBGE já faz para os microdados de 2000 e
2010 e para os setores de 2010. Para tudo o que está no anexo temos os
scripts de verificação e podemos fornecê-los, assim como as versões
corrigidas que produzimos, se forem úteis ao Instituto.

Fazemos ainda uma pergunta de arquivo, que não é pedido de correção. O Volume
II dos Resultados Preliminares de 1960, de março de 1965, promete uma
publicação especial com a descrição detalhada do desenho da amostra de 1,27% e
os erros de amostragem que ele deixou de incluir. Não a localizamos: da Série
Especial de 1960, a Biblioteca tem apenas os volumes II e IV. Gostaríamos de
saber se ela chegou a existir, se há no arquivo do Instituto a descrição dos
estratos e das frações de sorteio dessa subamostra, e se os cartões perfurados
ou as fitas originais dela foram preservados.

Colocamo-nos à disposição para qualquer esclarecimento.

Atenciosamente,

Rafael H. M. Pereira — Instituto de Pesquisa Econômica Aplicada (Ipea)
Rogério J. Barbosa — Instituto de Estudos Sociais e Políticos, Universidade do Estado do Rio de Janeiro (IESP-UERJ)
